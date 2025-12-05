-- ==============================================================================
-- BLOQUE 1: CONFIGURACIÓN ESTRUCTURAL (Cumple NFR-007, LOE)
-- ==============================================================================

-- 1.1 Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- Para ASS-GPS-001

-- 1.2 Definición de Enums (Tipos de datos estandarizados)

-- Roles del sistema (Jerarquía)
CREATE TYPE public.rol_usuario AS ENUM (
    'super_admin',  -- Gestiona planes y pagos globales
    'org_admin',    -- Dueño de la empresa (RRHH)
    'manager',      -- Supervisor de equipo
    'auditor',      -- Solo lectura para cumplimiento legal
    'employee'      -- Marca asistencia
);

-- Estado de Suscripción (Multi-tenancy)
CREATE TYPE public.estado_suscripcion AS ENUM (
    'prueba',     -- 14 días trial
    'activo',     -- Pagado
    'vencido',    -- Mora (Solo lectura)
    'cancelado'   -- Soft delete organizacional
);

-- Estado de Pago (Para transferencias bancarias MT-PAY-503)
CREATE TYPE public.estado_pago AS ENUM (
    'pendiente', -- Subido por OrgAdmin, esperando SuperAdmin
    'aprobado',  -- Validado en banco
    'rechazado'  -- Comprobante ilegible o falso
);

-- Tipos de Permisos (PER-CAT-201)
CREATE TYPE public.tipo_permiso AS ENUM (
    'enfermedad',            -- Certificado médico requerido
    'maternidad_paternidad', -- Licencia extendida
    'calamidad_domestica',   -- Sin goce (opcional)
    'vacaciones',            -- Goce de sueldo
    'legal_votacion',        -- Obligatorio por ley
    'dia_compensatorio',     -- Por horas extras (Art 56 LOE)
    'otro'
);

-- Estado de Flujo (PER-FLO-202)
CREATE TYPE public.estado_aprobacion AS ENUM (
    'pendiente',
    'aprobado_manager', -- Aprobación parcial (si hay doble flujo)
    'aprobado_rrhh',    -- Aprobación final
    'rechazado',
    'cancelado_usuario'
);

-- Origen de Marcación (ASS-GPS-001, ASS-QR-003)
CREATE TYPE public.origen_marcacion AS ENUM (
    'gps_movil',
    'qr_fijo',
    'offline_sync', -- ASS-OFF-004
    'web_panel'     -- Manual (ej: olvido)
);

-- Gravedad de Alertas (NOT-LEG-302)
CREATE TYPE public.gravedad_alerta AS ENUM (
    'informativa',   -- Ej: Recordatorio
    'advertencia',   -- Ej: Tardanza
    'legal_grave'    -- Ej: >40h semanales, <11h descanso
);


-- ==============================================================================
-- BLOQUE 2: ESTRUCTURA ORGANIZACIONAL (MT-DAT-501, MT-PLAN-502)
-- ==============================================================================

-- 2.1 Planes de Suscripción (Definido por Super Admin)
CREATE TABLE public.planes_suscripcion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    max_empleados INT NOT NULL,
    max_managers INT NOT NULL,
    almacenamiento_gb INT DEFAULT 5,
    precio_mensual NUMERIC(10,2) NOT NULL,
    funciones_avanzadas JSONB DEFAULT '{}', -- { "api": true, "white_label": false }
    activo BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 2.2 Organizaciones (Clientes)
CREATE TABLE public.organizaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ruc VARCHAR(13) NOT NULL UNIQUE, -- Identificador único fiscal
    razon_social VARCHAR(200) NOT NULL,
    plan_id UUID REFERENCES public.planes_suscripcion(id),
    
    estado_suscripcion public.estado_suscripcion DEFAULT 'prueba',
    fecha_fin_suscripcion TIMESTAMPTZ,
    
    -- Configuración Legal Global (SCH-LEG-102)
    -- JSONB permite flexibilidad ante cambios en la ley sin migrar DB
    configuracion_legal JSONB DEFAULT '{
        "tolerancia_entrada_min": 15,
        "tiempo_descanso_min": 60,
        "max_horas_extras_dia": 4,
        "inicio_jornada_nocturna": "22:00"
    }',
    
    logo_url TEXT,
    eliminado BOOLEAN DEFAULT FALSE,
    creado_en TIMESTAMPTZ DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 2.3 Perfiles de Usuario (Vinculado a Supabase Auth)
CREATE TABLE public.perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organizacion_id UUID REFERENCES public.organizaciones(id), -- Null para Super Admin
    
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cedula VARCHAR(15) UNIQUE, 
    
    rol public.rol_usuario DEFAULT 'employee',
    cargo VARCHAR(100),
    jefe_inmediato_id UUID REFERENCES public.perfiles(id), -- Jerarquía
    
    telefono VARCHAR(20),
    foto_perfil_url TEXT,
    
    activo BOOLEAN DEFAULT TRUE, -- False = Despedido (Login bloqueado)
    eliminado BOOLEAN DEFAULT FALSE,
    
    creado_en TIMESTAMPTZ DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 2.4 Pagos y Facturación (MT-PAY-503)
CREATE TABLE public.pagos_suscripciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id),
    plan_id UUID NOT NULL REFERENCES public.planes_suscripcion(id),
    
    monto NUMERIC(10,2) NOT NULL,
    comprobante_url TEXT NOT NULL, -- Foto de transferencia
    referencia_bancaria VARCHAR(100),
    
    estado public.estado_pago DEFAULT 'pendiente',
    validado_por_id UUID REFERENCES public.perfiles(id), -- Super Admin
    observaciones TEXT,
    
    fecha_pago TIMESTAMPTZ DEFAULT NOW(),
    fecha_validacion TIMESTAMPTZ
);

-- 2.5 Sucursales (Geocercas)
CREATE TABLE public.sucursales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id) ON DELETE CASCADE,
    
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT,
    
    -- Geofencing (ASS-GPS-001)
    ubicacion_central GEOGRAPHY(POINT, 4326),
    radio_metros INT DEFAULT 50 CHECK (radio_metros >= 20), -- Min 20m por precisión GPS
    
    tiene_qr_habilitado BOOLEAN DEFAULT FALSE, -- ASS-QR-003
    device_id_qr_asignado VARCHAR(100), -- Tablet autorizada para generar QRs
    
    eliminado BOOLEAN DEFAULT FALSE,
    creado_en TIMESTAMPTZ DEFAULT NOW()
);


-- ==============================================================================
-- BLOQUE 3: GESTIÓN DE TIEMPO (SCH-PLT-101, ASS-GPS-001)
-- ==============================================================================

-- 3.1 Plantillas de Horarios
CREATE TABLE public.plantillas_horarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id) ON DELETE CASCADE,
    
    nombre VARCHAR(100) NOT NULL, -- Ej: "Administrativo 8-5"
    
    hora_entrada TIME NOT NULL,
    hora_salida TIME NOT NULL,
    tiempo_descanso_minutos INT DEFAULT 60,
    
    dias_laborales INT[] DEFAULT '{1,2,3,4,5}', -- 1=Lunes
    es_rotativo BOOLEAN DEFAULT FALSE,
    
    eliminado BOOLEAN DEFAULT FALSE,
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 3.2 Asignación de Horarios (Historial)
CREATE TABLE public.asignaciones_horarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    perfil_id UUID NOT NULL REFERENCES public.perfiles(id),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id), -- Desnormalizado para RLS
    plantilla_id UUID REFERENCES public.plantillas_horarios(id),
    
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE, -- NULL = Vigente
    
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 3.3 Registros de Asistencia (TABLA PRINCIPAL)
CREATE TABLE public.registros_asistencia (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    perfil_id UUID NOT NULL REFERENCES public.perfiles(id),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id),
    sucursal_id UUID REFERENCES public.sucursales(id),
    
    tipo_registro VARCHAR(20) CHECK (tipo_registro IN ('entrada', 'salida', 'inicio_break', 'fin_break')),
    
    -- Tiempos (ASS-OFF-004)
    fecha_hora_marcacion TIMESTAMPTZ NOT NULL, -- Hora real (User timestamp)
    fecha_hora_servidor TIMESTAMPTZ DEFAULT NOW(), -- Hora de llegada al servidor
    
    -- Geolocalización y Fraude (NFR-004)
    ubicacion_gps GEOGRAPHY(POINT, 4326),
    precision_metros NUMERIC(10,2),
    esta_dentro_geocerca BOOLEAN,
    es_mock_location BOOLEAN DEFAULT FALSE, -- Detectado FakeGPS
    
    -- Evidencia (ASS-EVI-002)
    evidencia_foto_url TEXT NOT NULL, 
    device_id VARCHAR(100),
    device_model VARCHAR(100),
    
    origen public.origen_marcacion DEFAULT 'gps_movil',
    notas TEXT, -- Justificación si marcó fuera de rango
    
    eliminado BOOLEAN DEFAULT FALSE,
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para reportes rápidos
CREATE INDEX idx_asistencia_perfil ON public.registros_asistencia(perfil_id, fecha_hora_marcacion DESC);
CREATE INDEX idx_asistencia_org_fecha ON public.registros_asistencia(organizacion_id, fecha_hora_marcacion);

-- 3.4 Códigos QR Temporales (ASS-QR-003)
CREATE TABLE public.qr_codigos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sucursal_id UUID NOT NULL REFERENCES public.sucursales(id),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id),
    
    token_hash TEXT NOT NULL, -- Hash seguro
    fecha_expiracion TIMESTAMPTZ NOT NULL, -- 5 min de vida
    
    usado_por_id UUID REFERENCES public.perfiles(id),
    fecha_uso TIMESTAMPTZ,
    
    es_valido BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMPTZ DEFAULT NOW()
);


-- ==============================================================================
-- BLOQUE 4: PERMISOS Y CUMPLIMIENTO (PER-CAT-201, NOT-LEG-302)
-- ==============================================================================

-- 4.1 Solicitudes de Permisos
CREATE TABLE public.solicitudes_permisos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id),
    solicitante_id UUID NOT NULL REFERENCES public.perfiles(id),
    
    tipo public.tipo_permiso NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    dias_totales INT NOT NULL,
    
    motivo_detalle TEXT,
    documento_url TEXT, -- Certificado Médico (PER-DOC-203)
    
    estado public.estado_aprobacion DEFAULT 'pendiente',
    
    -- Trazabilidad de aprobación
    aprobado_por_id UUID REFERENCES public.perfiles(id),
    fecha_resolucion TIMESTAMPTZ,
    comentario_resolucion TEXT,
    
    creado_en TIMESTAMPTZ DEFAULT NOW(),
    actualizado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 4.2 Banco de Horas Compensatorias (PER-COM-204)
CREATE TABLE public.banco_horas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id),
    empleado_id UUID NOT NULL REFERENCES public.perfiles(id),
    
    cantidad_horas NUMERIC(5,2) NOT NULL, -- Positivo (Extras) / Negativo (Compensado)
    concepto TEXT NOT NULL, -- "Extras semana 40", "Compensación dia libre"
    
    -- Auditoría legal
    aprobado_por_id UUID REFERENCES public.perfiles(id),
    acepta_renuncia_pago BOOLEAN DEFAULT FALSE, -- Checkbox Art. 56 LOE
    
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 4.3 Alertas de Cumplimiento (El "Chivato" Legal)
CREATE TABLE public.alertas_cumplimiento (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id),
    empleado_id UUID REFERENCES public.perfiles(id),
    
    tipo_alerta VARCHAR(50) NOT NULL, -- 'EXCESO_40H', 'SIN_DESCANSO'
    detalle_tecnico JSONB, -- { "horas_trabajadas": 45, "limite": 40 }
    gravedad public.gravedad_alerta DEFAULT 'advertencia',
    
    estado VARCHAR(20) DEFAULT 'pendiente', -- 'pendiente', 'justificado'
    justificacion_auditor TEXT,
    
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 4.4 Auditoría Log Inmutable (Regla 8.3.1)
CREATE TABLE public.auditoria_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacion_id UUID, -- Puede ser NULL si es Super Admin
    actor_id UUID REFERENCES auth.users(id),
    
    accion VARCHAR(100) NOT NULL, -- 'UPDATE_PLAN', 'APPROVE_VACATION'
    tabla_afectada VARCHAR(50),
    registro_id UUID,
    datos_anteriores JSONB,
    datos_nuevos JSONB,
    
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    creado_en TIMESTAMPTZ DEFAULT NOW()
);

-- 4.5 Notificaciones Push (NOT-PUSH-301)
CREATE TABLE public.notificaciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id),
    usuario_destino_id UUID NOT NULL REFERENCES public.perfiles(id),
    
    titulo VARCHAR(150),
    mensaje TEXT,
    tipo VARCHAR(50),
    leido BOOLEAN DEFAULT FALSE,
    
    creado_en TIMESTAMPTZ DEFAULT NOW()
);


-- ==============================================================================
-- BLOQUE 5: POLÍTICAS DE SEGURIDAD (ROW LEVEL SECURITY)
-- ==============================================================================

-- 5.1 Funciones Helper (Optimizan rendimiento de RLS)
CREATE OR REPLACE FUNCTION public.get_my_org_id()
RETURNS UUID AS $$
    SELECT organizacion_id FROM public.perfiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.rol_usuario AS $$
    SELECT rol FROM public.perfiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 5.2 Habilitar RLS en TODAS las tablas
ALTER TABLE public.organizaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sucursales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plantillas_horarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registros_asistencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solicitudes_permisos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banco_horas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alertas_cumplimiento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pagos_suscripciones ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------
-- POLÍTICAS: ORGANIZACIONES
-- ------------------------------------------------------------------
-- Ver: Super Admin (todas), Empleados (la suya propia)
CREATE POLICY "Ver organizacion propia" ON public.organizaciones
FOR SELECT TO authenticated 
USING (
    (public.get_my_role() = 'super_admin') 
    OR 
    (id = public.get_my_org_id())
);

-- Editar: Solo Org Admin (su propia empresa) y Super Admin
CREATE POLICY "Editar organizacion" ON public.organizaciones
FOR UPDATE TO authenticated
USING (
    (public.get_my_role() = 'super_admin')
    OR
    (id = public.get_my_org_id() AND public.get_my_role() = 'org_admin')
);

-- ------------------------------------------------------------------
-- POLÍTICAS: PERFILES (USUARIOS)
-- ------------------------------------------------------------------
-- Ver: Super Admin (todos), Otros (solo de su misma organización)
CREATE POLICY "Ver perfiles" ON public.perfiles
FOR SELECT TO authenticated
USING (
    (public.get_my_role() = 'super_admin')
    OR
    (organizacion_id = public.get_my_org_id())
);

-- Editar: Super Admin, Org Admin (en su org), Usuario (solo sus datos básicos)
-- Nota: La edición granular se controla mejor via UI o Trigger, aquí abrimos update general si es admin
CREATE POLICY "Admin gestiona perfiles" ON public.perfiles
FOR UPDATE TO authenticated
USING (
    (public.get_my_role() = 'super_admin')
    OR
    (organizacion_id = public.get_my_org_id() AND public.get_my_role() = 'org_admin')
    OR
    (id = auth.uid()) -- Usuario actualiza su foto/teléfono
);

-- ------------------------------------------------------------------
-- POLÍTICAS: REGISTROS ASISTENCIA
-- ------------------------------------------------------------------
-- Ver: 
-- 1. Empleado: Solo sus registros
-- 2. Manager/Admin/Auditor: Todos los de su organización
CREATE POLICY "Ver asistencia" ON public.registros_asistencia
FOR SELECT TO authenticated
USING (
    -- Caso 1: Soy yo mismo
    perfil_id = auth.uid()
    OR
    -- Caso 2: Soy Staff de la misma organización
    (
        organizacion_id = public.get_my_org_id() 
        AND 
        public.get_my_role() IN ('org_admin', 'manager', 'auditor')
    )
    OR
    -- Caso 3: Super Admin
    public.get_my_role() = 'super_admin'
);

-- Insertar: Empleado para sí mismo (o Admin corrigiendo)
CREATE POLICY "Marcar asistencia" ON public.registros_asistencia
FOR INSERT TO authenticated
WITH CHECK (
    perfil_id = auth.uid() 
    OR 
    (organizacion_id = public.get_my_org_id() AND public.get_my_role() = 'org_admin')
);

-- ------------------------------------------------------------------
-- POLÍTICAS: PERMISOS Y SOLICITUDES
-- ------------------------------------------------------------------
-- Misma lógica que asistencia
CREATE POLICY "Ver permisos" ON public.solicitudes_permisos
FOR SELECT TO authenticated
USING (
    solicitante_id = auth.uid()
    OR
    (organizacion_id = public.get_my_org_id() AND public.get_my_role() IN ('org_admin', 'manager', 'auditor'))
);

CREATE POLICY "Gestionar permisos" ON public.solicitudes_permisos
FOR ALL TO authenticated
USING (
    -- Crear mis solicitudes
    solicitante_id = auth.uid()
    OR
    -- Aprobar/Rechazar (Solo Managers y Admins de mi org)
    (organizacion_id = public.get_my_org_id() AND public.get_my_role() IN ('org_admin', 'manager'))
);

-- ------------------------------------------------------------------
-- POLÍTICAS: PAGOS (Sensible)
-- ------------------------------------------------------------------
CREATE POLICY "Ver pagos" ON public.pagos_suscripciones
FOR SELECT TO authenticated
USING (
    public.get_my_role() = 'super_admin'
    OR
    (organizacion_id = public.get_my_org_id() AND public.get_my_role() = 'org_admin')
);

CREATE POLICY "Crear pagos" ON public.pagos_suscripciones
FOR INSERT TO authenticated
WITH CHECK (
    organizacion_id = public.get_my_org_id() AND public.get_my_role() = 'org_admin'
);


-- ==============================================================================
-- BLOQUE 6: STORAGE Y SUS POLÍTICAS
-- ==============================================================================

-- Insertar buckets en configuración de Supabase
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES 
('evidencias', 'evidencias', false, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp']),
('documentos_legales', 'documentos_legales', false, 5242880, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
('comprobantes_pago', 'comprobantes_pago', false, 2097152, ARRAY['image/jpeg', 'image/png', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;


-- 6.1 Política: Evidencias (Cualquier empleado sube, staff ve)
CREATE POLICY "Subir evidencia propia" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'evidencias' AND auth.uid() = owner);

CREATE POLICY "Ver evidencias org" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'evidencias' AND (auth.uid() = owner OR EXISTS (
    SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol IN ('org_admin', 'manager', 'auditor')
)));

-- 6.2 Política: Documentos Legales (Privado médico)
CREATE POLICY "Subir doc legal" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'documentos_legales' AND auth.uid() = owner);

CREATE POLICY "Ver doc legal RRHH" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'documentos_legales' AND (auth.uid() = owner OR EXISTS (
    SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol IN ('org_admin', 'manager', 'auditor')
)));

-- 6.3 Política: Comprobantes Pago (Solo Admin y SuperAdmin)
CREATE POLICY "Subir pago" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'comprobantes_pago' AND EXISTS (
    SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'org_admin'
));

CREATE POLICY "Ver pago" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'comprobantes_pago' AND EXISTS (
    SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol IN ('org_admin', 'super_admin')
));


-- ==============================================================================
-- BLOQUE 7: AUTOMATIZACIÓN Y REGLAS DE NEGOCIO
-- ==============================================================================

-- 7.1 Sincronización Auth -> Perfiles
-- Crea el perfil automáticamente cuando un usuario se registra/es invitado
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.perfiles (id, nombres, apellidos, rol, organizacion_id)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'nombres', 'Usuario'),
        COALESCE(NEW.raw_user_meta_data->>'apellidos', 'Nuevo'),
        COALESCE((NEW.raw_user_meta_data->>'rol')::public.rol_usuario, 'employee'),
        (NEW.raw_user_meta_data->>'organizacion_id')::uuid
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- 7.2 Validación Legal de Horarios (LOE Art. 52, 53)
-- Impide crear jornadas ilegales (>12h totales, sin descanso)
CREATE OR REPLACE FUNCTION public.validar_jornada_legal()
RETURNS TRIGGER AS $$
DECLARE
    duracion_horas NUMERIC;
BEGIN
    -- Calcular duración
    IF NEW.hora_salida >= NEW.hora_entrada THEN
        duracion_horas := EXTRACT(EPOCH FROM (NEW.hora_salida - NEW.hora_entrada))/3600;
    ELSE
        duracion_horas := EXTRACT(EPOCH FROM ((NEW.hora_salida + INTERVAL '24h') - NEW.hora_entrada))/3600;
    END IF;

    -- Regla: Máx 12 horas (incluyendo extras potenciales)
    IF duracion_horas > 12 THEN
        RAISE EXCEPTION 'La jornada no puede exceder 12 horas (Art. 52 LOE)';
    END IF;

    -- Regla: Descanso obligatorio
    IF duracion_horas > 6 AND NEW.tiempo_descanso_minutos < 30 THEN
        RAISE EXCEPTION 'Jornadas >6h requieren mínimo 30 min descanso (Art. 53 LOE)';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_legal_horario
BEFORE INSERT OR UPDATE ON public.plantillas_horarios
FOR EACH ROW EXECUTE PROCEDURE public.validar_jornada_legal();


-- 7.3 Actualizar Timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_org_time BEFORE UPDATE ON public.organizaciones FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
CREATE TRIGGER update_perf_time BEFORE UPDATE ON public.perfiles FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();


-- 7.4 RPC MAESTRO: Check-in Seguro (Llamar desde Flutter)
-- Maneja GPS, Geocerca y Registro en una sola transacción atómica
CREATE OR REPLACE FUNCTION public.marcar_asistencia(
    lat FLOAT, 
    long FLOAT, 
    foto_path TEXT, 
    tipo_marcacion TEXT, -- 'entrada', 'salida'
    sucursal_manual_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    usr_perfil RECORD;
    punto_gps GEOGRAPHY(POINT, 4326);
    sucursal_cercana RECORD;
    distancia FLOAT;
    dentro_rango BOOLEAN;
    nuevo_id UUID;
BEGIN
    -- 1. Identificar usuario
    SELECT * INTO usr_perfil FROM public.perfiles WHERE id = auth.uid();
    IF usr_perfil.id IS NULL THEN RAISE EXCEPTION 'Usuario no encontrado'; END IF;

    -- 2. Punto GPS
    punto_gps := ST_SetSRID(ST_MakePoint(long, lat), 4326);

    -- 3. Buscar Sucursal más cercana (o la seleccionada)
    SELECT id, radio_metros, ubicacion_central, 
           ST_Distance(ubicacion_central, punto_gps) as dist
    INTO sucursal_cercana
    FROM public.sucursales
    WHERE organizacion_id = usr_perfil.organizacion_id
    AND (sucursal_manual_id IS NULL OR id = sucursal_manual_id)
    ORDER BY ubicacion_central <-> punto_gps LIMIT 1;

    -- 4. Validar Geocerca
    IF sucursal_cercana.id IS NOT NULL THEN
        distancia := sucursal_cercana.dist;
        dentro_rango := distancia <= sucursal_cercana.radio_metros;
    ELSE
        dentro_rango := FALSE; 
        distancia := 0;
    END IF;

    -- 5. Insertar
    INSERT INTO public.registros_asistencia (
        perfil_id, organizacion_id, sucursal_id, tipo_registro,
        fecha_hora_marcacion, ubicacion_gps, esta_dentro_geocerca, 
        evidencia_foto_url, origen
    ) VALUES (
        usr_perfil.id, usr_perfil.organizacion_id, sucursal_cercana.id, tipo_marcacion,
        NOW(), punto_gps, dentro_rango, foto_path, 'gps_movil'
    ) RETURNING id INTO nuevo_id;

    RETURN json_build_object('success', true, 'id', nuevo_id, 'dentro_rango', dentro_rango);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

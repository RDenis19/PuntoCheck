class AuditoriaLog {
  final String id;
  final String? organizacionId;
  /// ID del usuario actor (auth.users / perfiles.id).
  /// Compatibilidad: en algunos esquemas se llama `usuario_responsable_id`.
  final String? usuarioResponsableId;
  final String accion;
  final String? tablaAfectada;
  /// Compatibilidad: `registro_id` o `id_registro_afectado`.
  final String? idRegistroAfectado;

  /// Compatibilidad:
  /// - esquemas antiguos: `detalle_cambio` (jsonb)
  /// - esquema objetivo: `datos_anteriores` + `datos_nuevos` (jsonb)
  final Map<String, dynamic>? detalleCambio;
  final Map<String, dynamic>? datosAnteriores;
  final Map<String, dynamic>? datosNuevos;

  /// Compatibilidad: `ip_origen` o `ip_address`.
  final String? ipOrigen;
  final String? userAgent;
  final DateTime? creadoEn;

  // Actor embebido (resuelto en cliente).
  final String? actorNombres;
  final String? actorApellidos;
  final String? actorCedula;
  final String? actorRol;
  final String? actorSucursalId;

  AuditoriaLog({
    required this.id,
    this.organizacionId,
    this.usuarioResponsableId,
    required this.accion,
    this.tablaAfectada,
    this.idRegistroAfectado,
    this.detalleCambio,
    this.datosAnteriores,
    this.datosNuevos,
    this.ipOrigen,
    this.userAgent,
    this.creadoEn,
    this.actorNombres,
    this.actorApellidos,
    this.actorCedula,
    this.actorRol,
    this.actorSucursalId,
  });

  factory AuditoriaLog.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] ?? json['perfiles'];
    final actorMap = actor is Map ? Map<String, dynamic>.from(actor) : null;

    final datosAntesRaw = json['datos_anteriores'];
    final datosNuevosRaw = json['datos_nuevos'];
    final datosAnteriores = datosAntesRaw is Map
        ? Map<String, dynamic>.from(datosAntesRaw)
        : null;
    final datosNuevos =
        datosNuevosRaw is Map ? Map<String, dynamic>.from(datosNuevosRaw) : null;

    final detalleRaw = json['detalle_cambio'];
    Map<String, dynamic>? detalleCambio;
    if (detalleRaw is Map) {
      detalleCambio = Map<String, dynamic>.from(detalleRaw);
    } else if (datosAnteriores != null || datosNuevos != null) {
      detalleCambio = {
        if (datosAnteriores != null) 'datos_anteriores': datosAnteriores,
        if (datosNuevos != null) 'datos_nuevos': datosNuevos,
      };
    }

    return AuditoriaLog(
      id: json['id'],
      organizacionId: json['organizacion_id'],
      usuarioResponsableId:
          (json['usuario_responsable_id'] ?? json['actor_id'])?.toString(),
      accion: json['accion'],
      tablaAfectada: json['tabla_afectada'],
      idRegistroAfectado:
          (json['id_registro_afectado'] ?? json['registro_id'])?.toString(),
      detalleCambio: detalleCambio,
      datosAnteriores: datosAnteriores,
      datosNuevos: datosNuevos,
      ipOrigen: (json['ip_origen'] ?? json['ip_address'])?.toString(),
      userAgent: json['user_agent'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : null,
      actorNombres: actorMap?['nombres']?.toString(),
      actorApellidos: actorMap?['apellidos']?.toString(),
      actorCedula: actorMap?['cedula']?.toString(),
      actorRol: actorMap?['rol']?.toString(),
      actorSucursalId: actorMap?['sucursal_id']?.toString(),
    );
  }

  String? get actorNombreCompleto {
    final nombres = actorNombres?.trim();
    final apellidos = actorApellidos?.trim();
    if ((nombres == null || nombres.isEmpty) && (apellidos == null || apellidos.isEmpty)) {
      return null;
    }
    return [nombres, apellidos]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(' ');
  }

  AuditoriaLog copyWithActor({
    String? nombres,
    String? apellidos,
    String? cedula,
    String? rol,
    String? sucursalId,
  }) {
    return AuditoriaLog(
      id: id,
      organizacionId: organizacionId,
      usuarioResponsableId: usuarioResponsableId,
      accion: accion,
      tablaAfectada: tablaAfectada,
      idRegistroAfectado: idRegistroAfectado,
      detalleCambio: detalleCambio,
      datosAnteriores: datosAnteriores,
      datosNuevos: datosNuevos,
      ipOrigen: ipOrigen,
      userAgent: userAgent,
      creadoEn: creadoEn,
      actorNombres: nombres ?? actorNombres,
      actorApellidos: apellidos ?? actorApellidos,
      actorCedula: cedula ?? actorCedula,
      actorRol: rol ?? actorRol,
      actorSucursalId: sucursalId ?? actorSucursalId,
    );
  }
}

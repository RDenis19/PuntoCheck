// ===== INICIO MOCK ORGANIZACIONES (ELIMINAR CUANDO HAYA BACKEND) =====
class MockOrganization {
  final String id;
  final String nombre;
  final String logoUrl;
  final String adminNombre;
  final String adminEmail;
  final int empleados;
  final int activosHoy;
  final double promedioAsistencia;
  final String estado;
  final DateTime creadaEl;
  final DateTime ultimoAcceso;

  const MockOrganization({
    required this.id,
    required this.nombre,
    required this.logoUrl,
    required this.adminNombre,
    required this.adminEmail,
    required this.empleados,
    required this.activosHoy,
    required this.promedioAsistencia,
    required this.estado,
    required this.creadaEl,
    required this.ultimoAcceso,
  });
}

final mockOrganizations = <MockOrganization>[
  MockOrganization(
    id: 'org_techsolutions',
    nombre: 'TechSolutions S.A.',
    logoUrl: '',
    adminNombre: 'Ana Martínez',
    adminEmail: 'ana@techsolutions.com',
    empleados: 120,
    activosHoy: 87,
    promedioAsistencia: 93.5,
    estado: 'activa',
    creadaEl: DateTime(2024, 1, 10),
    ultimoAcceso: DateTime(2025, 10, 31, 9, 12),
  ),
  MockOrganization(
    id: 'org_logitrans',
    nombre: 'LogiTrans Express',
    logoUrl: '',
    adminNombre: 'Carlos López',
    adminEmail: 'carlos@logitrans.com',
    empleados: 45,
    activosHoy: 28,
    promedioAsistencia: 88.2,
    estado: 'prueba',
    creadaEl: DateTime(2025, 2, 5),
    ultimoAcceso: DateTime(2025, 10, 30, 17, 40),
  ),
  MockOrganization(
    id: 'org_saludplus',
    nombre: 'SaludPlus Clínica',
    logoUrl: '',
    adminNombre: 'María Pérez',
    adminEmail: 'maria@saludplus.com',
    empleados: 80,
    activosHoy: 60,
    promedioAsistencia: 96.1,
    estado: 'suspendida',
    creadaEl: DateTime(2023, 11, 20),
    ultimoAcceso: DateTime(2025, 9, 15, 11, 5),
  ),
];
// ===== FIN MOCK ORGANIZACIONES =====

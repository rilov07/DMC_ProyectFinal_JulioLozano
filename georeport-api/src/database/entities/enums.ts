// TypeScript mirrors of the Postgres enum types created in
// *-CreateSchema.ts. Values MUST match db/01-schema.sql exactly; entities
// bind to the existing Postgres type via `enumName`, never let TypeORM
// invent one (Design: Andamiaje y esquema de base, Interfaces / Contracts).

export enum EstadoIncidencia {
  REPORTADO = 'reportado',
  VALIDADO = 'validado',
  ASIGNADO = 'asignado',
  EN_PROCESO = 'en_proceso',
  RESUELTO = 'resuelto',
  DESCARTADO = 'descartado',
}

export enum CausalDescarte {
  RECHAZADO = 'rechazado',
  DUPLICADO = 'duplicado',
  FUERA_DE_AMBITO = 'fuera_de_ambito',
}

export enum Prioridad {
  ALTA = 'ALTA',
  MEDIA = 'MEDIA',
  BAJA = 'BAJA',
}

export enum RolUsuario {
  VALIDADOR = 'VALIDADOR',
  RESPONSABLE = 'RESPONSABLE',
  SUPERVISOR = 'SUPERVISOR',
  ADMIN = 'ADMIN',
}

export enum TipoEvidencia {
  REPORTE = 'REPORTE',
  CIERRE = 'CIERRE',
}

export enum EstadoCarga {
  COMPLETA = 'COMPLETA',
  PENDIENTE = 'PENDIENTE',
}

export enum ActorTipo {
  USUARIO = 'USUARIO',
  SISTEMA = 'SISTEMA',
}

export enum TipoNotificacion {
  ASIGNACION = 'ASIGNACION',
  CAMBIO_ESTADO = 'CAMBIO_ESTADO',
  ESCALAMIENTO = 'ESCALAMIENTO',
}

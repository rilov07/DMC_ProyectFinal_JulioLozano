// Ported verbatim from db/02-seed.sql (read-only reference).
export interface TipoIncidenciaSeed {
  nombre: string;
  plazoPorDefectoHoras: number;
}

export const TIPO_INCIDENCIA_CATALOG: TipoIncidenciaSeed[] = [
  { nombre: 'Pistas o carreteras en mal estado', plazoPorDefectoHoras: 120 },
  { nombre: 'Bache', plazoPorDefectoHoras: 72 },
  { nombre: 'Accidente que interrumpe el tránsito', plazoPorDefectoHoras: 4 },
  { nombre: 'Huaico', plazoPorDefectoHoras: 6 },
  { nombre: 'Derrumbe', plazoPorDefectoHoras: 8 },
  { nombre: 'Inundación', plazoPorDefectoHoras: 8 },
  { nombre: 'Problema de señalización', plazoPorDefectoHoras: 96 },
  { nombre: 'Semáforo averiado', plazoPorDefectoHoras: 24 },
  { nombre: 'Daño en guardavías', plazoPorDefectoHoras: 72 },
  { nombre: 'Falla de drenaje', plazoPorDefectoHoras: 48 },
  { nombre: 'Túnel afectado', plazoPorDefectoHoras: 12 },
  { nombre: 'Puente dañado o bloqueado', plazoPorDefectoHoras: 6 },
];

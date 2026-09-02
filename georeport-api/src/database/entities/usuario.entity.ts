import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { RolUsuario } from './enums';

// Internal roles only — the citizen has no account (ADR-0005).
@Entity('usuario')
export class UsuarioEntity {
  @PrimaryGeneratedColumn({ type: 'int' })
  id!: number;

  @Column({ type: 'text' })
  nombre!: string;

  @Column({ type: 'text', unique: true })
  email!: string;

  @Column({ name: 'hash_password', type: 'text' })
  hashPassword!: string;

  @Column({ type: 'enum', enum: RolUsuario, enumName: 'rol_usuario' })
  rol!: RolUsuario;

  @Column({ type: 'boolean', default: true })
  activo!: boolean;
}

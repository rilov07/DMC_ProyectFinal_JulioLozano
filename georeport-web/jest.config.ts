import type { Config } from 'jest';

// Run through the plain Jest CLI, not the Angular unit-test builder, whose
// Jest support is experimental (Design: Andamiaje y esquema de base,
// Decision 6).
const config: Config = {
  preset: 'jest-preset-angular',
  setupFilesAfterEnv: ['<rootDir>/setup-jest.ts'],
  testEnvironment: 'jsdom',
  roots: ['<rootDir>/src'],
};

export default config;

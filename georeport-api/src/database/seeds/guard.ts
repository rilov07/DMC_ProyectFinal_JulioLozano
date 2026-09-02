// GUARD (Design: Andamiaje y esquema de base, Decision 5): must be asked
// for by name and refuses to run when NODE_ENV=production. A flag would be
// one typo away from a dangerous path; this script is not.
//
// `exit` is injectable so the RED/GREEN unit test can assert behavior
// without killing the Jest process.
export function assertNotProduction(
  env: NodeJS.ProcessEnv = process.env,
  log: (message: string) => void = (message) => console.error(message),
  exit: (code: number) => void = (code) => process.exit(code),
): void {
  if (env.NODE_ENV === 'production') {
    log(
      '\n*** NOT PRODUCTION DATA ***\nseed:dev-fixtures refuses to run with NODE_ENV=production.\n' +
        'zona/usuario fixtures are placeholders — see db/README.md and the root README.\n',
    );
    exit(1);
  }
}

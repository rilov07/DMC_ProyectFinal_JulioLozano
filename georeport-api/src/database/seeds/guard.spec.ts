import { assertNotProduction } from './guard';

// RED/GREEN pair for tasks.md 6.4/6.5: seed-dev-fixtures MUST exit 1 with a
// "NOT PRODUCTION DATA" banner when NODE_ENV=production, and MUST be a
// no-op otherwise.
describe('assertNotProduction', () => {
  it('exits 1 with a NOT PRODUCTION DATA banner when NODE_ENV=production', () => {
    const log = jest.fn<void, [string]>();
    const exit = jest.fn<void, [number]>();

    assertNotProduction({ NODE_ENV: 'production' }, log, exit);

    expect(exit).toHaveBeenCalledWith(1);
    expect(log).toHaveBeenCalledWith(expect.stringContaining('NOT PRODUCTION DATA'));
  });

  it('does not exit when NODE_ENV is not production', () => {
    const log = jest.fn<void, [string]>();
    const exit = jest.fn<void, [number]>();

    assertNotProduction({ NODE_ENV: 'test' }, log, exit);
    assertNotProduction({}, log, exit);

    expect(exit).not.toHaveBeenCalled();
    expect(log).not.toHaveBeenCalled();
  });
});

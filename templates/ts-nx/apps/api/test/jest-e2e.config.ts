export default {
  displayName: 'api-e2e',
  preset: '../../jest.preset.cjs',
  testEnvironment: 'node',
  transform: {
    '^.+\\.[tj]s$': ['ts-jest', { tsconfig: '<rootDir>/test/tsconfig.e2e.json' }],
  },
  moduleFileExtensions: ['ts', 'js', 'html'],
  testRegex: '\\.e2e-spec\\.ts$',
  rootDir: '..',
};

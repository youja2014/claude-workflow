// @nx/enforce-module-boundaries enforces tag-based dependency rules.
// Each project.json declares "tags". Edges are allowed only as listed here.
//
// Tag taxonomy:
//   scope:api      — backend (apps/api and libs that back it)
//   scope:web      — frontend (apps/web and libs that back it)
//   scope:shared   — code usable by both sides (libs/shared-*)
//   type:app       — deployable app (apps/*)
//   type:feature   — user-facing feature library
//   type:util      — pure utility/type library

import nx from '@nx/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import prettier from 'eslint-config-prettier';

export default [
  ...nx.configs['flat/base'],
  ...nx.configs['flat/typescript'],
  ...nx.configs['flat/javascript'],
  {
    ignores: ['**/dist', '**/node_modules', '**/build', '**/.next', '**/coverage'],
  },
  {
    files: ['**/*.{ts,tsx,js,jsx,mjs,cjs}'],
    languageOptions: {
      parser: tsParser,
      parserOptions: { ecmaVersion: 'latest', sourceType: 'module' },
    },
    rules: {
      '@nx/enforce-module-boundaries': [
        'error',
        {
          enforceBuildableLibDependency: true,
          allow: [],
          depConstraints: [
            { sourceTag: 'scope:api', onlyDependOnLibsWithTags: ['scope:api', 'scope:shared'] },
            { sourceTag: 'scope:web', onlyDependOnLibsWithTags: ['scope:web', 'scope:shared'] },
            { sourceTag: 'scope:shared', onlyDependOnLibsWithTags: ['scope:shared'] },
            { sourceTag: 'type:app', onlyDependOnLibsWithTags: ['type:feature', 'type:util'] },
            { sourceTag: 'type:feature', onlyDependOnLibsWithTags: ['type:feature', 'type:util'] },
            { sourceTag: 'type:util', onlyDependOnLibsWithTags: ['type:util'] },
          ],
        },
      ],
    },
  },
  prettier,
];

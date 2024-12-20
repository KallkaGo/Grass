import antfu from '@antfu/eslint-config'

export default antfu({
  react: true,
  formatters: true,
  rules: {
    'no-alert': 'off',
    'react-refresh/only-export-components': 'off',
    'unused-imports/no-unused-imports': 'warn',
    'unused-imports/no-unused-vars': 'warn',
    'no-debugger': 'warn',
    'no-console': 'warn',
    'no-unused-vars': 'warn',
    'node/prefer-global/process': 'off',
    '@typescript-eslint/no-use-before-define': [
      'error',
      {
        functions: false,
        classes: false,
        variables: true,
      },
    ],
    'style/no-tabs': ['error', { allowIndentationTabs: true }],
  },
  ignores: [
    'public/**/*',
    'static/**/*',
  ],
})

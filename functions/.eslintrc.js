module.exports = {
  root: true,
  env: {
    es2021: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
    ecmaVersion: 2021,
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "node_modules",
    ".eslintrc.js"
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  settings: {
    "import/parsers": {
      "@typescript-eslint/parser": [".ts", ".tsx"]
    },
    "import/resolver": {
      "typescript": {
        "alwaysTryTypes": true,
        "project": "./tsconfig.json"
      },
      "node": {
        "extensions": [".js", ".jsx", ".ts", ".tsx"],
        "moduleDirectory": ["node_modules", "src/"]
      }
    }
  },
  rules: {
    "quotes": ["error", "double"],
    "semi": ["error", "always"],
    "object-curly-spacing": ["error", "always"],
    "max-len": ["error", { "code": 120 }],
    "require-jsdoc": "off",
    "comma-dangle": "off",
    "@typescript-eslint/no-empty-function": "off",
    "import/no-unresolved": ["error", { "ignore": ["^firebase-functions/v2/.+$", "^firebase-functions/.+$"] }],
    "import/no-extraneous-dependencies": ["error", { "devDependencies": ["**/*.test.ts", "**/*.spec.ts", "**/test/**/*.ts"] }],
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "no-console": ["warn", { "allow": ["warn", "error"] }]
  },
};
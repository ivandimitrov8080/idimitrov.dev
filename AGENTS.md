# AGENTS.md

Welcome agentic coding agents! This repository follows strict functional, statically-typed, and reproducible development principles using Haskell (Hakyll, Servant), Elm, and Nix. This guide helps you build, lint, test, and maintain code consistency within this project ecosystem.

---

## 🏗️ Build, Lint, and Test Commands

### Build

- **Haskell Site Generator:**
  - Compile: `devenv tasks run build:site --mode before`
  - Build static site: `devenv tasks run build:frontend --mode before`
- **Elm Frontend:**
  - Compile: `devenv tasks run build:frontend --mode before`
- **Backend/Generators:**
  - Server: `devenv tasks run build:server --mode before`
  - Generators: `devenv tasks run build:generators --mode before`
  - API Elm Library: `devenv tasks run build:library --mode before`
- **Combined via Nix/Devenv:**
  - Build everything: `devenv tasks run build`

### Lint / Format

- **Format everything** `nix fmt`

### Test

- **No tests for now** `No tests`

---

## 🧑‍💻 Code Style Guidelines

### Imports

- **Haskell:**
  - Alphabetically sorted
  - Group: external, internal, qualified, unqualified
  - One import per line
- **Elm:**
  - Alphabetically sorted
  - Grouped: core, external
  - One import per line
- **Nix:**
  - Alphabetical for inputs/modules

### Formatting

- **General:** nix fmt after changes have been made

### Types

- **Explicit type signatures** preferred—especially for public functions (Haskell, Elm)
- Use algebraic types to model domain and error cases
- Avoid using global variables or implicit state
- Prefer union types and enums for categorical data

### Naming Conventions

- **Functions/Variables:** camelCase
- **Types/Modules:** PascalCase
- **Constants:** UPPER_CASE
- **Filenames:** kebab-case or snake_case for scripts/binaries
- **Elm modules:** PascalCase, files must match module

### Error Handling

- **Haskell:**
  - Prefer safe composition (Either/Maybe/monads) over exceptions or `error`, `undefined`
  - No use of `unsafePerformIO` outside tightly controlled effects
- **Elm:**
  - Model all failure via `Result`, `Maybe`, custom types
  - Avoid runtime exceptions; no partial functions
- **Nix:**
  - Prefer fail-fast scripts or derivations
  - Use statix to catch anti-patterns

### Project Structure

- **One public module per file**
- **Explicit exports** at file/module header if possible
- **Tests** should be grouped by feature or module
- **Templates/Static**: store in dedicated folder (see templates/, static/)

### Comments/Docs

- Start multiline comments with triple -- or -- |
- Add Haddock type (`-- |`) to public Haskell definitions
- Markdown in posts/articles should use code blocks and headings

### Version Control / Hooks

- All code must pass pre-commit:

```yaml
Pre-commit hooks enabled (see .pre-commit-config.yaml):
  - deadnix (Nix dead code)
  - elm-format (Elm formatting)
  - nixfmt (Nix formatting)
  - ormolu (Haskell formatting)
  - prettier (text/JSON format)
  - statix (Nix anti-patterns)
```

Do not commit if a hook fails. Format/clean up before each commit.

---

## Nix / Flake Considerations

- All builds/tests must be reproducible from flake.nix
- If you add dependencies, update both flake.nix and the corresponding package config (elm.json, cabal, etc.)
- Security best practices: Use SSL, security headers, networking/firewall as per flake.nix nginx config

---

## Tooling Reference

- **Editors:** neovim with lsp for Haskell/Elm/Nix (see devenv/nixvim config)
- **Watch/reload:** watchexec, browser-sync
- **Database:** built-in postgres service for development

---

## Cursor/Copilot/Other AI Coding Rules

_No Cursor or Copilot rules are present; update this section if .cursor/rules/ or .github/copilot-instructions.md appears._

---

## TL;DR (Quick Reference for Agents)

- Build: `devenv tasks run build`, then run build commands as above
- Format before commit: `nix fmt`
- Test: no tests for now
- All code must pass pre-commit hooks before merge
- Stick to code style guidelines for language
- If in doubt, refer to this file!

---

Happy coding! Functional purity, reproducible builds, and statically-typed joy for all agentic contributors.

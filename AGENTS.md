# AGENTS.md

## Cursor Cloud specific instructions

### Overview

PharoSmalltalkInteropServer is a Pharo Smalltalk web API server (Teapot framework, default port 8086). The entire runtime lives inside a Pharo image — there are no external services (no databases, no Docker, no Node.js).

### Pharo environment

- Pharo 13 VM and image are installed in `/workspace/pharo-dev/`.
- The project is pre-loaded into the saved image via Metacello from the local repo (`gitlocal:///workspace/src`).
- The `pharo` script at `/workspace/pharo-dev/pharo` runs the VM in headless mode.

### Starting the server

```bash
# Start SisServer in a background tmux session (stays running):
tmux new-session -d -s pharo-server '/workspace/pharo-dev/pharo /workspace/pharo-dev/Pharo.image eval --no-quit "SisServer current start. Processor activeProcess suspend"'
```

The server listens on port 8086. Verify with:
```bash
curl -s http://localhost:8086/get-settings
```

### Running tests

Tests run against the live server via the HTTP API:
```bash
curl -s "http://localhost:8086/run-package-test?package_name=Sis-Tests"
curl -s "http://localhost:8086/run-package-test?package_name=Sis-Tests-Dummy"
```

Alternatively, run tests from the CLI without a running server (uses smalltalkCI conventions):
```bash
/workspace/pharo-dev/pharo /workspace/pharo-dev/Pharo.image eval --save "SisServer current start. (Smalltalk packages detect: [:pkg | pkg name = 'Sis-Tests']) testSuite run"
```

### Reloading code changes

After modifying `.class.st` files in `src/`, reload from the local repo:
```bash
/workspace/pharo-dev/pharo /workspace/pharo-dev/Pharo.image eval --save \
  "Metacello new baseline: 'PharoSmalltalkInteropServer'; repository: 'gitlocal:///workspace/src'; load."
```
Then restart the server to pick up changes.

### Gotchas

- The Pharo image is stateful. Always use `--save` when loading code via `eval` to persist changes.
- The baseline's `postload:` automatically calls `SisServer current start`, so loading the project also starts the server within the eval process. For a long-running server, use the `--no-quit` + `Processor activeProcess suspend` pattern shown above.
- There is no separate lint tool; Smalltalk code quality is validated through the test suite.
- String literal evaluation via `/eval/` requires proper Smalltalk quoting (`'single quotes'`). JSON-escaped double quotes around Smalltalk strings are treated as comments.

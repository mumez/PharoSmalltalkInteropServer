# PharoSmalltalkInteropServer

[![CI](https://github.com/mumez/PharoSmalltalkInteropServer/actions/workflows/main.yml/badge.svg)](https://github.com/mumez/PharoSmalltalkInteropServer/actions/workflows/main.yml)

A powerful web API server that bridges Pharo Smalltalk environments with external tools, enabling seamless integration with AI agents, editors, and other development tools. The server provides comprehensive introspection and manipulation capabilities for Smalltalk code.

## Features

- **Code Evaluation**: Execute Smalltalk expressions and return results
- **Settings Management**: Dynamically configure server settings via API endpoints
- **Code Introspection**: Retrieve source code, comments, and metadata for classes and methods
- **Search & Discovery**: Find classes, traits, methods, references, and implementors
- **Package Management**: Export and import packages in Tonel format
- **Test Execution**: Run test suites at package or class level
- **Project Installation**: Install Smalltalk projects using Metacello
- **UI Debugging**: Capture screenshots and extract UI structure for World morphs, Spec presenters, and Roassal visualizations
- **MCP Protocol**: Designed as a Model Context Protocol server core for AI integration

## Installation

### Prerequisites
- Pharo Smalltalk image (tested with Pharo 12+)

### Install via Metacello
Execute in Pharo Playground:

```Smalltalk
Metacello new
  baseline: 'PharoSmalltalkInteropServer';
  repository: 'github://mumez/PharoSmalltalkInteropServer:main/src';
  load.
```

## Quick Start

The server **automatically starts** after installation (on default port 8086) and **auto-restarts** whenever the Pharo image starts up. You can immediately start using the API:

```bash
# Evaluate a Smalltalk expression
curl -X POST http://localhost:8086/eval/ \
  -H "Content-Type: application/json" \
  -d '{"code": "42 factorial"}'

# Search for classes
curl "http://localhost:8086/search-classes-like?class_name_query=String"

# Get class source code
curl "http://localhost:8086/get-class-source?class_name=OrderedCollection"

# Get method source code
curl "http://localhost:8086/get-method-source?class_name=OrderedCollection&method_name=add:"
```

## API

The server exposes a RESTful API for Smalltalk introspection and manipulation. All endpoints return standardized JSON responses:

- **Success**: `{"success": true, "result": "..."}`
- **Error**: `{"success": false, "error": {"description": "...", "stack_trace": "...", "receiver": {...}}}`

### Code Evaluation

```bash
curl -X POST http://localhost:8086/eval/ \
  -H "Content-Type: application/json" \
  -d '{"code": "3 + 4 * 5"}'
# => {"success":true,"result":35}
```

### Code Introspection

```bash
# List classes in a package
curl "http://localhost:8086/list-classes?package_name=Sis-Core"

# Get class definition source
curl "http://localhost:8086/get-class-source?class_name=SisServer"

# Get class comment
curl "http://localhost:8086/get-class-comment?class_name=SisServer"

# List methods in a class
curl "http://localhost:8086/list-methods?class_name=SisServer"

# Get instance method source
curl "http://localhost:8086/get-method-source?class_name=SisServer&method_name=start"

# Get class-side method source
curl "http://localhost:8086/get-method-source?class_name=Array&method_name=with:&is_class_method=true"
```

### Search

```bash
# Search classes by prefix
curl "http://localhost:8086/search-classes-like?class_name_query=Sis"

# Search method selectors
curl "http://localhost:8086/search-methods-like?method_name_query=asJson"

# Find implementors of a method
curl "http://localhost:8086/search-implementors?method_name=printOn:"

# Find references to a symbol
curl "http://localhost:8086/search-references?method_name=start"
```

### Package Operations

```bash
# List all packages
curl http://localhost:8086/list-packages

# Export a package (Tonel format)
curl "http://localhost:8086/export-package?package_name=Sis-Core&path=/tmp/export"

# Import a package
curl "http://localhost:8086/import-package?path=/tmp/export/Sis-Core"
```

### Test Execution

```bash
# Run all tests in a package
curl "http://localhost:8086/run-package-test?package_name=Sis-Tests"

# Run tests for a specific class
curl "http://localhost:8086/run-class-test?class_name=SisTest"
```

### Settings Management

The API accepts both camelCase and snake_case keys (e.g., `stackSize` or `stack_size`), which are automatically normalized to camelCase:

```bash
# Get current settings
curl http://localhost:8086/get-settings

# Apply new settings
curl -X POST http://localhost:8086/apply-settings \
  -H "Content-Type: application/json" \
  -d '{"settings": {"stackSize": 150, "customKey": "value"}}'
```

For complete API specification, see [API.md](API.md).

## Server Management

### Start / Stop / Restart

```Smalltalk
SisServer current start.   "Start the server"
SisServer current stop.    "Stop the server"
SisServer restart.         "Restart (stop, reset, start)"
```

### Configuration

```Smalltalk
"Change server port (default: 8086)"
SisServer teapotConfig at: #port put: 9090.

"View current configuration"
SisServer teapotConfig.

"Configure server settings"
SisServer current settings at: #stackSize put: 200.

"View current settings"
SisServer current settings.
```

### Environment Variables

Default values can be overridden via environment variables before starting the Pharo image:

| Variable | Description | Default |
|---|---|---|
| `PHARO_SIS_PORT` | Server port | `8086` |
| `PHARO_SIS_SCREENSHOT_DIR` | Screenshot save directory | system temp dir |

### Request Announcements

SisServer fires `SisRequestAnnouncement` events before and after each request is processed, allowing external code to observe or react to API calls.

```Smalltalk
"Subscribe to all request events"
SisServer current
    subscribeOnRequest: [ :announcement |
        Transcript crShow: ('{1} {2}' format: { announcement type. announcement teapotRequest url }) ]
    for: Transcript.

"Unsubscribe when done"
SisServer current unsubscribe: Transcript.
```

Each `SisRequestAnnouncement` carries:
- `type` — `#before` (fired before processing) or `#after` (fired after processing)
- `teapotRequest` — the raw Teapot request object, including the URL and other request details

## Development

### Running Tests
```Smalltalk
"Run all server tests"
(Smalltalk packages detect: [:pkg | pkg name = 'Sis-Tests']) testSuite run

"Run specific test class"
SisTest suite run
```

### Project Structure
```
src/
├── BaselineOfPharoSmalltalkInteropServer/  # Metacello baseline configuration
├── Sis-Core/                               # Core server implementation
├── Sis-Tests/                              # Main test suite
└── Sis-Tests-Dummy/                        # Test fixtures
```

## Dependencies

- **Teapot**: HTTP server framework
- **NeoJSON**: JSON serialization/deserialization
- **Zinc HTTP Components**: HTTP client capabilities
- **Tonel**: Package serialization format

## Use Cases

- **AI Code Assistants**: Enable AI agents to understand and manipulate Smalltalk code
- **IDE Integration**: Connect external editors with Smalltalk environments
- **Code Analysis Tools**: Build tools that analyze Smalltalk codebases
- **Remote Development**: Access Smalltalk environments from remote tools
- **Educational Platforms**: Create interactive Smalltalk learning environments

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

See [LICENSE](LICENSE) file for details.

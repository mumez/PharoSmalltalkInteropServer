# PharoSmalltalkInteropServer

[![CI](https://github.com/mumez/PharoSmalltalkInteropServer/actions/workflows/main.yml/badge.svg)](https://github.com/mumez/PharoSmalltalkInteropServer/actions/workflows/main.yml)

A powerful web API server that bridges Pharo Smalltalk environments with external tools, enabling seamless integration with AI agents, editors, and other development tools. The server provides comprehensive introspection and manipulation capabilities for Smalltalk code.

## Features

- **Code Evaluation**: Execute Smalltalk expressions and return results
- **Code Introspection**: Retrieve source code, comments, and metadata for classes and methods
- **Search & Discovery**: Find classes, traits, methods, references, and implementors
- **Package Management**: Export and import packages in Tonel format
- **Test Execution**: Run test suites at package or class level
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

### Basic Server Operations

```Smalltalk
"Start the server"
SisServer current start

"Stop the server"
SisServer current stop

"Check server status"
SisServer current
```

### Configuration

```Smalltalk
"Change server port (default: 8086)"
SisServer teapotConfig at: #port put: 9090

"View current configuration"
SisServer teapotConfig
```

### Auto-restart Behavior
After the first start, SisServer automatically restarts when the Pharo image starts up, ensuring continuous availability.

## API

The server exposes a RESTful API with comprehensive Smalltalk introspection and manipulation capabilities. 

For complete API documentation with detailed examples, see [API.md](API.md).

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

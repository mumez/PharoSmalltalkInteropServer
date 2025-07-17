# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PharoSmalltalkInteropServer is a Smalltalk-based web API server that provides interoperability between Smalltalk environments and external tools like AI agents or editors. It serves as an MCP (Model Context Protocol) server core for Smalltalk integration.

## Architecture

### Core Components

- **SisServer** (`src/Sis-Core/SisServer.class.st`): Main server class using Teapot web framework
  - Singleton pattern via `SisServer current`
  - RESTful API endpoints for Smalltalk operations
  - Auto-restart on image startup via `startUp:` class method
  - Default port: 8086 (configurable via `SisServer teapotConfig at: #port put: <port>`)

### Package Structure

- **Sis-Core**: Core server implementation
- **Sis-Tests**: Main test suite with comprehensive API testing
- **Sis-Tests-Dummy**: Dummy test fixtures for testing export/import functionality

### API Endpoints

The server provides extensive Smalltalk introspection and manipulation capabilities:

- Code evaluation (`/eval/`)
- Package/class/method listing and source retrieval
- Search functionality (classes, traits, methods, references, implementors)
- Package export/import (Tonel format)
- Test execution (package and class level)
- Project installation (`/install-project`) using Metacello

## Development Commands

### Server Management
```smalltalk
SisServer current start   "Start the server"
SisServer current stop    "Stop the server"
```

### Configuration
```smalltalk
SisServer teapotConfig at: #port put: 8080   "Change port"
```

### Running Tests
```smalltalk
(Smalltalk packages detect: [:pkg | pkg name = 'Sis-Tests']) testSuite run
```

### Package Installation
```smalltalk
Metacello new
  baseline: 'PharoSmalltalkInteropServer';
  repository: 'github://mumez/PharoSmalltalkInteropServer:main/src';
  load.
```

## File Formats

- **`.class.st`**: Smalltalk class definitions in Tonel format
- **`.trait.st`**: Smalltalk trait definitions in Tonel format
- **`package.st`**: Package metadata files

## Key Implementation Details

- Uses Teapot web framework for HTTP handling
- JSON request/response format via NeoJSON
- Error handling wraps all operations in `returnResultDo:` pattern
- SystemNavigation for code introspection
- TonelWriter/TonelReader for package export/import
- ZnEasy HTTP client for testing

## Testing Strategy

The test suite (`SisTest`) validates all API endpoints by:
- Starting HTTP requests against running server
- Validating JSON response structure (`success` flag, `result`/`error` fields)
- Using fixture classes/traits for consistent test data
- Testing both positive and error cases

## Dependencies

- Teapot (HTTP server framework)
- NeoJSON (JSON handling)
- Zinc HTTP Components (HTTP client for tests)
- SystemNavigation (code introspection)
- Tonel (package serialization format)
- Metacello (project installation and management)
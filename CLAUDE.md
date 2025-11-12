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
- Settings management (`/apply-settings`, `/get-settings`) - Dynamic server configuration
- Package/class/method listing and source retrieval
- Search functionality (classes, traits, methods, references, implementors)
- Package export/import (Tonel format)
- Test execution (package and class level)
- Project installation (`/install-project`) using Metacello
- UI debugging (`/read-screen`) - Screenshot capture and UI structure extraction for World morphs, Spec presenters, and Roassal visualizations

## Development Commands

### Server Management
```smalltalk
SisServer current start   "Start the server"
SisServer current stop    "Stop the server"
SisServer restart         "Restart the server (stop, reset, start)"
```

### Configuration
```smalltalk
SisServer teapotConfig at: #port put: 8080   "Change port"

"Settings management"
SisServer current settings at: #stackSize put: 200   "Change stack size"
SisServer current settings   "View current settings"
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
- Comprehensive error reporting via `returnError:by:` with stack traces and receiver context
- Settings management via instance variable with default values:
  - Default settings defined in `SisServer class >> defaultSettings`
  - Settings accessible via `/apply-settings` (POST) and `/get-settings` (GET) endpoints
  - Key naming flexibility: Accepts both camelCase and snake_case keys (e.g., `stackSize` or `stack_size`), with automatic normalization to camelCase
  - Common settings: `stackSize` (controls error stack trace depth, default: 100)
- SystemNavigation for code introspection
- TonelWriter/TonelReader for package export/import
- ZnEasy HTTP client for testing
- UI debugging via `/read-screen` endpoint:
  - Captures PNG screenshots to temp directory
  - Extracts morph hierarchies with geometry, colors, and structure
  - Supports Spec presenter introspection with recursive hierarchy extraction (up to 3 levels)
  - Supports Roassal canvas analysis with shape/edge details
  - Target types: 'world' (morphs), 'spec' (Spec presenters), 'roassal' (Roassal visualizations)

### Error Response Structure

When errors occur, the server returns detailed error information:

```json
{
  "success": false,
  "error": {
    "description": "Error type (e.g., 'ZeroDivide')",
    "stack_trace": "Complete call stack leading to the error",
    "receiver": {
      "class": "Class name of the object that received the failing message",
      "self": "String representation of the receiver object",
      "variables": {"varName": "varValue"}
    }
  }
}
```

## Testing Strategy

The test suite (`SisTest`) validates all API endpoints by:
- Starting HTTP requests against running server
- Validating JSON response structure (`success` flag, `result`/`error` fields)
- Using fixture classes/traits for consistent test data
- Testing both positive and error cases
- Comprehensive error response validation including stack traces and receiver information
- Error case testing with `testEvalWithError` (validates ZeroDivide error handling)

## Dependencies

- Teapot (HTTP server framework)
- NeoJSON (JSON handling)
- Zinc HTTP Components (HTTP client for tests)
- SystemNavigation (code introspection)
- Tonel (package serialization format)
- Metacello (project installation and management)
# API Documentation

Complete API specification is available in [OpenAPI 3.0 format](spec/openapi.json).

## Overview

This server provides a RESTful API with JSON responses for Smalltalk code introspection and manipulation. All endpoints return a standardized response format:

**Success Response:**
```json
{
  "success": true,
  "result": "..."
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error description"
}
```

## API Categories

### Code Evaluation
- `POST /eval/` - Execute Smalltalk expressions and return results

### Package Operations
- `GET /list-packages` - Get list of all packages
- `GET /export-package` - Export package to specified path
- `GET /import-package` - Import package from specified path

### Class Operations
- `GET /list-classes` - Get list of classes in a package
- `GET /list-extended-classes` - Get list of extended classes in a package
- `GET /get-class-source` - Get source code of a class
- `GET /get-class-comment` - Get comment of a class

### Method Operations
- `GET /list-methods` - Get list of methods in a package
- `GET /get-method-source` - Get source code of a specific method

### Search Operations
- `GET /search-classes-like` - Search class names that start with the given query
- `GET /search-traits-like` - Search trait names that start with the given query
- `GET /search-methods-like` - Search method selectors that start with the given query
- `GET /search-references` - Find all references to a given symbol
- `GET /search-implementors` - Find all implementors of a given method selector
- `GET /search-references-to-class` - Find all references to a given class

### Test Operations
- `GET /run-package-test` - Run all tests in a package
- `GET /run-class-test` - Run all tests in a class

## Usage Examples

### Evaluate Smalltalk Code
```bash
curl -X POST http://localhost:8086/eval/ \
  -H "Content-Type: application/json" \
  -d '{"code": "5 rem: 3"}'
```

**Response:**
```json
{
  "success": true,
  "result": 2
}
```

### Search Classes
```bash
curl "http://localhost:8086/search-classes-like?class_name_query=SisFixture"
```

**Response:**
```json
{
  "success": true,
  "result": ["SisFixtureClassForTest"]
}
```

### Get Method Source
```bash
curl "http://localhost:8086/get-method-source?class_name=SisFixtureClassForTest&method_name=testMethodBbb"
```

**Response:**
```json
{
  "success": true,
  "result": "testMethodBbb\n\t^ TestSymbolBBB"
}
```


### Run Package Tests
```bash
curl "http://localhost:8086/run-package-test?package_name=Sis-Tests-Dummy"
```

**Response:**
```json
{
  "success": true,
  "result": "3 ran, 3 passed, 0 failed, 0 errors"
}
```

## Error Handling

When an error occurs, the API returns a standardized error response:

```json
{
  "success": false,
  "error": "Class 'NonExistentClass' not found"
}
```

Common error scenarios:
- Missing required parameters
- Invalid class or method names
- Package not found
- Compilation errors in evaluated code
- File system errors during export/import operations
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
  "error": {
    "description": "Error description",
    "stack_trace": "Full stack trace of the error",
    "receiver": {
      "class": "Class name where error occurred",
      "self": "String representation of the receiver object",
      "variables": {
        "variableName": "variableValue"
      }
    }
  }
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

### Project Operations
- `GET /install-project` - Install a project using Metacello

### UI Debugging
- `GET /read-screen` - UI screen reader for debugging Pharo UI issues, captures screenshots and extracts morph hierarchy with bounds, colors, and structure

### Settings Management
- `POST /apply-settings` - Apply server settings
- `GET /get-settings` - Get current server settings

## Detailed Endpoint Documentation

### Read Screen (`GET /read-screen`)

Captures screenshot and extracts UI structure for debugging Pharo UI issues. Supports multiple UI frameworks: World morphs, Spec presenters, and Roassal visualizations.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `target_type` | string | 'world' | UI type to inspect: 'world' (morphs), 'spec' (Spec windows/presenters), or 'roassal' (Roassal canvases) |
| `capture_screenshot` | boolean | true | Include PNG screenshot in response |

**Response Structure for World:**
```json
{
  "success": true,
  "result": {
    "screenshot": "/private/tmp/pharo-ui-2025-11-03T00-44-31.462729+01-00.png",
    "target_type": "world",
    "structure": {
      "totalMorphs": 12,
      "displayedMorphCount": 1,
      "morphs": [
        {
          "class": "MenubarMorph",
          "visible": true,
          "bounds": {
            "x": 0,
            "y": 0,
            "width": 976,
            "height": 18
          },
          "backgroundColor": "(Color r: 0.883... alpha: 0.8)",
          "owner": "WorldMorph",
          "submorphCount": 8
        }
      ]
    },
    "summary": "World with 12 top-level morphs"
  }
}
```

**Response Structure for Spec:**
```json
{
  "success": true,
  "result": {
    "target_type": "spec",
    "structure": {
      "windowCount": 1,
      "presenters": [
        {
          "title": "Welcome",
          "class": "SpWindowPresenter",
          "extent": "(700@550)",
          "hasMenu": false,
          "presenter": {
            "class": "StWelcomeBrowser",
            "childCount": 2,
            "isVisible": true,
            "children": []
          }
        }
      ]
    },
    "summary": "1 Spec presenter(s)"
  }
}
```

**Response Structure for Roassal:**
```json
{
  "success": true,
  "result": {
    "target_type": "roassal",
    "structure": {
      "canvasCount": 1,
      "canvases": [
        {
          "class": "RSAthensMorph",
          "canvasClass": "RSCanvas",
          "bounds": {"x": 203, "y": 145, "width": 490, "height": 467},
          "backgroundColor": "Color blue",
          "zoomLevel": "1.0",
          "shapeCount": 5,
          "shapes": [
            {
              "class": "RSCircle",
              "color": "(Color r: 1.0 g: 0.0 b: 0.0 alpha: 0.2)",
              "position": "(0.0@0.0)",
              "extent": "(5.0@5.0)"
            }
          ],
          "edgeCount": 0,
          "edges": [],
          "nodeCount": 0
        }
      ]
    },
    "summary": "1 Roassal canvas(es)"
  }
}
```

**Data Extraction for Morphs (target_type='world'):**
- Class name (type identification)
- Bounds (x, y, width, height coordinates)
- Visibility state
- Background color
- Structure (owner, submorphs count)
- Text content (if available)

**Data Extraction for Spec (target_type='spec'):**
- Window title and class name
- Geometry (extent, position)
- Window state (maximized, minimized, resizable)
- Decorations (menu, toolbar, statusbar presence)
- Presenter hierarchy (recursive with max depth of 3 levels)
- Presenter class name, child count, and content properties (label, text, value, placeholder, etc.)
- Enablement and visibility state of presenters

**Data Extraction for Roassal (target_type='roassal'):**
- Canvas detection via recursive search through morph tree
- Canvas location and geometry (bounds)
- Visual properties (visibility, background color)
- Canvas metadata (extent, zoom level)
- Shape details: class, color, position, extent, label, text
- Edge details: source, target, color, label
- Node and edge counts

**Implementation Details:**
- **World morphs display limit**: Only the first 10 top-level morphs are extracted (for performance)
- **Spec presenter recursion depth**: Presenter hierarchy is extracted up to 3 levels deep
- **Screenshot file naming**: Files are stored in system temp directory as `/tmp/pharo-ui-{timestamp}.png` where timestamp is ISO 8601 format with colons replaced by dashes
- **Roassal canvas detection**: Uses recursive `allMorphs` search to find RSAthensMorph instances throughout entire morph tree

### Apply Settings (`POST /apply-settings`)

Updates server settings dynamically. Settings are applied immediately and persist for the current server session.

**Request Body:**
```json
{
  "settings": {
    "stackSize": 200,
    "customKey": "customValue"
  }
}
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `settings` | object | Dictionary of setting key-value pairs to apply |

**Response:**
```json
{
  "success": true,
  "result": "Settings applied successfully"
}
```

**Common Settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `stackSize` | integer | 100 | Maximum stack trace depth for error reporting |


### Get Settings (`GET /get-settings`)

Retrieves current server settings.

**Response:**
```json
{
  "success": true,
  "result": {
    "stackSize": 100,
    "customKey": "customValue"
  }
}
```

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

When an error occurs, the API returns a standardized error response with detailed error information:

```json
{
  "success": false,
  "error": {
    "description": "ZeroDivide",
    "stack_trace": "SmallInteger>>/\nUndefinedObject>>DoIt\n...",
    "receiver": {
      "class": "SmallInteger",
      "self": "1",
      "variables": {}
    }
  }
}
```

### Error Response Fields

- **description**: Brief error type or message
- **stack_trace**: Complete stack trace showing the call chain that led to the error
- **receiver**: Information about the object that received the message causing the error
  - **class**: The class of the receiver object
  - **self**: String representation of the receiver object
  - **variables**: Instance variables of the receiver object with their names and values (when available)

Common error scenarios:
- Missing required parameters
- Invalid class or method names
- Package not found
- Compilation errors in evaluated code
- Runtime errors (division by zero, message not understood, etc.)
- File system errors during export/import operations
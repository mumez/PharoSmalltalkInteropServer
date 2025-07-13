# API

```json
{
  "tools": [
    {
      "name": "eval",
      "description": "Evaluate Smalltalk code and return the result",
      "parameters": { "code": "string" }
    },
    {
      "name": "list_packages",
      "description": "Get list of all packages"
    },
    {
      "name": "list_classes",
      "description": "Get list of classes in a package",
      "parameters": { "package_name": "string" }
    },
    {
      "name": "list_extended_classes",
      "description": "Get list of extended classes in a package",
      "parameters": { "package_name": "string" }
    },
    {
      "name": "list_methods",
      "description": "Get list of methods in a package",
      "parameters": { "package_name": "string" }
    },
    {
      "name": "get_class_source",
      "description": "Get source code of a class",
      "parameters": { "class_name": "string" }
    },
    {
      "name": "get_method_source",
      "description": "Get source code of a specific method",
      "parameters": {
        "class_name": "string",
        "method_name": "string"
      }
    },
    {
      "name": "get_class_comment",
      "description": "Get comment of a class",
      "parameters": { "class_name": "string" }
    },
    {
      "name": "search_classes_like",
      "description": "Search class names that start with the given query (case-insensitive)",
      "parameters": { "class_name_query": "string" }
    },
    {
      "name": "search_traits_like",
      "description": "Search trait names that start with the given query (case-insensitive)",
      "parameters": { "trait_name_query": "string" }
    },
    {
      "name": "search_methods_like",
      "description": "Search method selectors that start with the given query",
      "parameters": { "method_name_query": "string" }
    },
    {
      "name": "search_references",
      "description": "Find all references to a given symbol (method/variable/class)",
      "parameters": { "program_symbol": "string" }
    },
    {
      "name": "search_implementors",
      "description": "Find all implementors of a given method selector",
      "parameters": { "method_name": "string" }
    },
    {
      "name": "search_references_to_class",
      "description": "Find all references to a given class",
      "parameters": { "class_name": "string" }
    },
    {
      "name": "export_package",
      "description": "Export package to specified path",
      "parameters": {
        "package_name": "string",
        "path": "string"
      }
    },
    {
      "name": "import_package",
      "description": "Import package from specified path",
      "parameters": {
        "package_name": "string",
        "path": "string"
      }
    },
    {
      "name": "run_package_test",
      "description": "Run all tests in a package",
      "parameters": { "package_name": "string" }
    },
    {
      "name": "run_class_test",
      "description": "Run all tests in a class",
      "parameters": { "class_name": "string" }
    }
  ]
}
```
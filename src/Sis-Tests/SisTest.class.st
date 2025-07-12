Class {
	#name : 'SisTest',
	#superclass : 'TestCase',
	#category : 'Sis-Tests',
	#package : 'Sis-Tests'
}

{ #category : 'private' }
SisTest >> baseUrl [
	| port |
	port := SisServer current teapotConfig at: #port ifAbsent: [8086].
	^ ('http://localhost:{1}' format: { port } ) asUrl.
]

{ #category : 'private' }
SisTest >> get: anUrl [
	| resp |
	resp := ZnEasy get: anUrl.
	^ NeoJSONReader fromString:  resp  contents
]

{ #category : 'private' }
SisTest >> post: anUrl dictionary:  dict [
	| json resp |
	json := NeoJSONWriter  toString: dict.
	resp := ZnEasy post: anUrl data:  (ZnEntity json: json).
	^ NeoJSONReader fromString:  resp  contents
]

{ #category : 'tests' }
SisTest >> testEval [
	| url postData resp result |
	url := self baseUrl / 'eval'.
	postData := { ('code' -> '5 rem: 3') } asDictionary.
	resp := self post: url dictionary: postData.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: result  equals:  2
]

{ #category : 'tests' }
SisTest >> testExportPackage [
	| url resp result tempDir |
	tempDir := FileSystem workingDirectory / 'temp_export'.
	tempDir ensureCreateDirectory.
	url := self baseUrl / 'export-package'.
	url queryAt: 'package_name' put: 'Sis-Tests'.
	url queryAt: 'output_path' put: tempDir absolutePath pathString.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includesSubstring: 'exported to').
	tempDir deleteAll
]

{ #category : 'tests' }
SisTest >> testGetClassComment [
	| url resp result |
	url := self baseUrl / 'get-class-comment'.
	url queryAt: 'class_name' put: 'SisFixtureClassForTest'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: result equals: 'SisFixtureClassForTest is a fixture class for SIS testing'
]

{ #category : 'tests' }
SisTest >> testGetClassSource [
	| url resp result |
	url := self baseUrl / 'get-class-source'.
	url queryAt: 'class_name' put: 'SisFixtureClassForTest'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includesSubstring: 'SisFixtureClassForTest').
	self assert: (result includesSubstring: 'testMethodAaa').
	self assert: (result includesSubstring: 'instVarA')
]

{ #category : 'tests' }
SisTest >> testGetMethodSource [
	| url resp result |
	url := self baseUrl / 'get-method-source'.
	url queryAt: 'class_name' put: 'SisFixtureClassForTest'.
	url queryAt: 'method_name' put: 'testMethodBbb'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includesSubstring: 'testMethodBbb').
	self assert: (result includesSubstring: 'TestSymbolBBB')
]

{ #category : 'tests' }
SisTest >> testListClasses [
	| url resp result |
	url := self baseUrl / 'list-classes'.
	url queryAt: 'package_name' put: 'Sis-Tests'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includes: 'SisTest').
	self assert: (result includes: 'SisFixtureClassForTest')
]

{ #category : 'tests' }
SisTest >> testListExtendedClasses [
	| url resp result |
	url := self baseUrl / 'list-extended-classes'.
	url queryAt: 'package_name' put: 'System-Object Events'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includes: 'Object')
]

{ #category : 'tests' }
SisTest >> testListMethods [
	| url resp result |
	url := self baseUrl / 'list-methods'.
	url queryAt: 'package_name' put: 'Sis-Tests'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includes: 'SisTest>>#testEval').
	self assert: (result includes: 'SisFixtureClassForTest>>#testMethodBbb')
]

{ #category : 'tests' }
SisTest >> testListPackages [
	| url resp result |
	url := self baseUrl / 'list-packages'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result   includes: 'Sis-Core').
	self assert: (result   includes: 'Sis-Tests')
]

{ #category : 'tests' }
SisTest >> testRunClassTest [
	| url resp result |
	url := self baseUrl / 'run-class-test'.
	url queryAt: 'class_name' put: 'SisDummyTest'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includesSubstring: '2 ran, 2 passed, ')
]

{ #category : 'tests' }
SisTest >> testRunPackageTest [
	| url resp result |
	url := self baseUrl / 'run-package-test'.
	url queryAt: 'package_name' put: 'Sis-Tests-Dummy'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includesSubstring: '3 ran, 3 passed, ')
]

{ #category : 'tests' }
SisTest >> testSearchClassesLike [
	| url resp result |
	url := self baseUrl / 'search-classes-like'.
	url queryAt: 'class_name_query' put: 'SisFixture'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includes: 'SisFixtureClassForTest')
]

{ #category : 'tests' }
SisTest >> testSearchImplementors [
	| url resp result |
	url := self baseUrl / 'search-implementors'.
	url queryAt: 'method_name' put: 'testMethodAaa'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result isKindOf: Array).
	self assert: result size > 0.
	self assert: ((result first at: 'class') = 'SisFixtureClassForTest').
	self assert: ((result first at: 'method') = 'testMethodAaa')
]

{ #category : 'tests' }
SisTest >> testSearchMethodLike [
	| url resp result |
	url := self baseUrl / 'search-methods-like'.
	url queryAt: 'method_name_query' put: 'testMethodAa'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assertCollection: result   equals: #('testMethodAaa' 'testMethodAab')
]

{ #category : 'tests' }
SisTest >> testSearchReferences [
	| url resp result |
	url := self baseUrl / 'search-references'.
	url queryAt: 'program_symbol' put: 'TestSymbolBBB'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result isKindOf: Array).
	self assert: result size > 0.
	self assert: ((result first at: 'class') = 'SisFixtureClassForTest').
	self assert: ((result first at: 'method') = 'testMethodBbb')
]

{ #category : 'tests' }
SisTest >> testSearchReferencesToClass [
	| url resp result |
	url := self baseUrl / 'search-references-to-class'.
	url queryAt: 'class_name' put: 'SisFixtureClassForTest'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result isKindOf: Array)
]

{ #category : 'tests' }
SisTest >> testSearchTraitsLike [
	| url resp result |
	url := self baseUrl / 'search-traits-like'.
	url queryAt: 'traits_name_query' put: 'T'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result isKindOf: Array)
]

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
SisTest >> testEvalWithError [
	| url postData resp errorInfo receiver stackTrace |
	url := self baseUrl / 'eval'.
	postData := { ('code' -> '1 / 0') } asDictionary.
	resp := self post: url dictionary: postData.
	self deny: (resp at: #success).
	errorInfo := resp at: #error.
	self assert: (errorInfo at: #description) equals: 'ZeroDivide'.
	self assert: (errorInfo includesKey: #stack_trace).
	stackTrace := errorInfo at: #stack_trace.
	self assert: (stackTrace includesSubstring: 'SmallInteger>>/').
	receiver := errorInfo at: #receiver.
	self assert: (receiver at: #class) equals: 'SmallInteger'.
	self assert: (receiver at: #self) equals: '1'
]

{ #category : 'tests' }
SisTest >> testExportImportPackage [
	| url resp result tempDir |
	tempDir := FileSystem workingDirectory / 'temp_export'.
	tempDir ensureCreateDirectory.
	url := self baseUrl / 'export-package'.
	url queryAt: 'package_name' put: 'Sis-Tests-Dummy'.
	url queryAt: 'path' put: tempDir absolutePath pathString.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result beginsWith: 'Sis-Tests-Dummy exported to: ').
	
	url := self baseUrl / 'import-package'.
	url queryAt: 'package_name' put: 'Sis-Tests-Dummy'.
	url queryAt: 'path' put: tempDir absolutePath pathString.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result beginsWith: 'Sis-Tests-Dummy imported from: ').
	
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
SisTest >> testInstallProject [
	| url resp result errorDesc |
	url := self baseUrl / 'install-project'.
	url queryAt: 'project_name' put: 'PharoSmalltalkInteropServer'.
	url queryAt: 'repository_url' put: 'github://mumez/PharoSmalltalkInteropServer:main/src'.
	url queryAt: 'load_groups' put: 'NonExistentGroupA, NonExistentGroupB'.
	resp := self get: url.
	self deny: (resp at: #success).
	result := resp at: #error.
	errorDesc := result at: #description.
	self assert: ((errorDesc beginsWith: 'Error: Name not found') or: [errorDesc beginsWith: 'MetacelloConflictingProjectError:']). "for CI"
	
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
	self assert: (result includes: 'Sis-Core').
	self assert: (result includes: 'Sis-Tests')
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
SisTest >> testReadScreenDefault [
	| url resp result structure summary |
	url := self baseUrl / 'read-screen'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.

	"Verify structure was extracted"
	structure := result at: #structure.
	self assert: (structure includesKey: #morphs).
	self assert: (structure includesKey: #totalMorphs).
	self assert: (structure at: #totalMorphs) > 0.

	"Verify summary was built"
	summary := result at: #summary.
	self assert: (summary includesSubstring: 'World with').

	"Verify target type was returned"
	self assert: (result at: #target_type) equals: 'world'
]

{ #category : 'tests' }
SisTest >> testReadScreenNoScreenshot [
	| url resp result structure |
	url := self baseUrl / 'read-screen'.
	url queryAt: 'capture_screenshot' put: 'false'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.

	"Verify no screenshot file was created"
	self deny: (result includesKey: #screenshot).

	"Verify structure was still extracted"
	structure := result at: #structure.
	self assert: (structure includesKey: #morphs)
]

{ #category : 'tests' }
SisTest >> testReadScreenResponseStructure [
	| url resp result |
	url := self baseUrl / 'read-screen'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.

	"Verify required response fields"
	self assert: (result includesKey: #target_type).
	self assert: (result includesKey: #structure).
	self assert: (result includesKey: #summary).

	"Verify structure is a dictionary"
	self assert: ((result at: #structure) isKindOf: Dictionary).

	"Verify summary is a string"
	self assert: ((result at: #summary) isKindOf: String)
]

{ #category : 'tests' }
SisTest >> testReadScreenRoassal [
	| url resp result structure summary canvases |
	url := self baseUrl / 'read-screen'.
	url queryAt: 'target_type' put: 'roassal'.
	url queryAt: 'capture_screenshot' put: 'false'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.

	"Verify target type is returned"
	self assert: (result at: #target_type) equals: 'roassal'.

	"Verify structure has required keys"
	structure := result at: #structure.
	self assert: (structure includesKey: #canvases).
	self assert: (structure includesKey: #canvasCount).

	"Verify canvases is an array"
	canvases := structure at: #canvases.
	self assert: (canvases isKindOf: Array).

	"Verify each canvas has expected properties"
	canvases do: [ :canvas |
		self assert: (canvas includesKey: #class).
		self assert: (canvas includesKey: #bounds).
		self assert: (canvas includesKey: #visible).
		self assert: (canvas includesKey: #canvasClass).
		"Node/edge counts may not be present if canvas is empty"
		(canvas includesKey: #nodeCount) ifTrue: [
			self assert: ((canvas at: #nodeCount) >= 0) ].
		(canvas includesKey: #edgeCount) ifTrue: [
			self assert: ((canvas at: #edgeCount) >= 0) ].
		(canvas includesKey: #shapeCount) ifTrue: [
			self assert: ((canvas at: #shapeCount) >= 0) ].
	].

	"Verify summary mentions roassal"
	summary := result at: #summary.
	self assert: (summary includesSubstring: 'Roassal')
]

{ #category : 'tests' }
SisTest >> testReadScreenSpec [
	| url resp result structure summary presenters |
	url := self baseUrl / 'read-screen'.
	url queryAt: 'target_type' put: 'spec'.
	url queryAt: 'capture_screenshot' put: 'false'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.

	"Verify target type is returned"
	self assert: (result at: #target_type) equals: 'spec'.

	"Verify structure has presenters key and windowCount"
	structure := result at: #structure.
	self assert: (structure includesKey: #presenters).
	self assert: (structure includesKey: #windowCount).
	presenters := structure at: #presenters.
	self assert: (presenters isKindOf: Array).

	"Verify each presenter has expected properties"
	presenters do: [ :presenter |
		self assert: (presenter includesKey: #class).
		self assert: (presenter includesKey: #title).
		self assert: (presenter includesKey: #hasMenu).
		self assert: (presenter includesKey: #presenter).
	].

	"Verify summary mentions spec"
	summary := result at: #summary.
	self assert: (summary includesSubstring: 'Spec')
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
	self assert: result size equals: 1 .
	self assert: (result first at: 'class') equals: 'SisFixtureClassForTest'.
	self assert: (result first at: 'method') equals: 'testMethodAaa'
]

{ #category : 'tests' }
SisTest >> testSearchMethodLike [
	| url resp result |
	url := self baseUrl / 'search-methods-like'.
	url queryAt: 'method_name_query' put: 'testMethodAa'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assertCollection: result sorted equals: #('testMethodAaa' 'testMethodAab')
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
	self assert: result size equals: 1.
	self assert: (result first at: 'class') equals: 'SisFixtureClassForTest'.
	self assert: (result first at: 'method') equals: 'testMethodBbb'
]

{ #category : 'tests' }
SisTest >> testSearchReferencesToClass [
	| url resp result |
	url := self baseUrl / 'search-references-to-class'.
	url queryAt: 'class_name' put: 'SisTest'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: result size equals: 1.
	self assert: (result first at: 'package') equals: 'Sis-Tests'.
	self assert: (result first at: 'class') equals: 'SisFixtureClassForTest'.
	self assert: (result first at: 'method') equals: 'testMethodAaa'
]

{ #category : 'tests' }
SisTest >> testSearchTraitsLike [
	| url resp result |
	url := self baseUrl / 'search-traits-like'.
	url queryAt: 'trait_name_query' put: 'SisFixtureTrait'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assertCollection: result  equals: #('SisFixtureTraitForTest')
]

{ #category : 'tests' }
SisTest >> testApplySettings [
	| url postData resp result getUrl getResp getResult |
	url := self baseUrl / 'apply-settings'.
	postData := { ('settings' -> { ('stackSize' -> 200). ('customKey' -> 'customValue') } asDictionary) } asDictionary.
	resp := self post: url dictionary: postData.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includesSubstring: 'Settings applied successfully').

	"Verify settings were actually applied"
	getUrl := self baseUrl / 'get-settings'.
	getResp := self get: getUrl.
	self assert: (getResp at: #success).
	getResult := getResp at: #result.
	self assert: (getResult at: #stackSize) equals: 200.
	self assert: (getResult at: #customKey) equals: 'customValue'
]

{ #category : 'tests' }
SisTest >> testGetSettings [
	| url resp result |
	url := self baseUrl / 'get-settings'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result isKindOf: Dictionary).
	self assert: (result includesKey: #stackSize)
]

{ #category : 'tests' }
SisTest >> testApplySettingsWithSnakeCaseKeys [
	"Test that snake_case keys are normalized to camelCase"
	| url postData resp result getUrl getResp getResult |
	url := self baseUrl / 'apply-settings'.
	postData := { ('settings' -> { ('stack_size' -> 150). ('custom_key' -> 'snakeCaseValue') } asDictionary) } asDictionary.
	resp := self post: url dictionary: postData.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includesSubstring: 'Settings applied successfully').

	"Verify settings were normalized to camelCase"
	getUrl := self baseUrl / 'get-settings'.
	getResp := self get: getUrl.
	self assert: (getResp at: #success).
	getResult := getResp at: #result.
	self assert: (getResult at: #stackSize) equals: 150.
	self assert: (getResult at: #customKey) equals: 'snakeCaseValue'
]

{ #category : 'tests' }
SisTest >> testApplySettingsWithMixedCaseKeys [
	"Test that both camelCase and snake_case keys can be used together"
	| url postData resp result getUrl getResp getResult |
	url := self baseUrl / 'apply-settings'.
	postData := { ('settings' -> { ('stackSize' -> 180). ('another_key' -> 'mixedValue') } asDictionary) } asDictionary.
	resp := self post: url dictionary: postData.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result includesSubstring: 'Settings applied successfully').

	"Verify both settings were applied correctly"
	getUrl := self baseUrl / 'get-settings'.
	getResp := self get: getUrl.
	self assert: (getResp at: #success).
	getResult := getResp at: #result.
	self assert: (getResult at: #stackSize) equals: 180.
	self assert: (getResult at: #anotherKey) equals: 'mixedValue'
]

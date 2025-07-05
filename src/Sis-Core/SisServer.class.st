Class {
	#name : 'SisServer',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'teapotConfig'
	],
	#category : 'Sis-Core',
	#package : 'Sis-Core'
}

{ #category : 'instance creation' }
SisServer class >> configure:  assocArray [
	| inst |
	inst := self new.
	inst teapotConfig: assocArray.
	^ inst 
]

{ #category : 'factory' }
SisServer >> createTeapot [

	^ (Teapot configure: self teapotConfig)
		  POST: '/eval/' -> [ :req | self handleEval: req ];
		  GET: '/list-packages' -> [ :req | self handleListPackages: req ];
		  GET: '/list-classes' -> [ :req | self handleListClasses: req ];
		  GET: '/get-package-source' -> [ :req | self handleGetPackageSource: req ];
		  GET: '/get-class-source' -> [ :req | self handleGetClassSource: req ];
		  GET: '/get-method-source' -> [ :req | self handleGetMethodSource: req ];
		  GET: '/get-trait-method-source' -> [ :req | self handleGetTraitMethodSource: req ];
		  GET: '/get-class-comment' -> [ :req | self handleGetClassComment: req ];
		  GET: '/search-elements' -> [ :req | self handleSearchElements: req ];
		  GET: '/export-package' -> [ :req | self handleExportPackage: req ];
		  GET: '/import-package' -> [ :req | self handleImportPackage: req ];
		  GET: '/run-test' -> [ :req | self handleRunTest: req ]
]

{ #category : 'defaults' }
SisServer >> defaultTeapotConfig [

	^ {
		  (#defaultOutput -> #json).
		  (#port -> 8086) }
]

{ #category : 'handling' }
SisServer >> handleEval: request [
	^ self returnResultDo: [
			  | requestJson code |
			  requestJson := NeoJSONReader fromString: request entity contents.
			  code := requestJson at: #code.
			  self class compiler evaluate: code ]
]

{ #category : 'handling' }
SisServer >> handleListClasses: request [
	^ self returnResultDo: [
			  | packageName |
			  packageName := request at: #package_name.
			  ((self packageOrganizer packageNamed: packageName) classes
				   collect: [ :each | each name ]) sorted ]
]

{ #category : 'handling' }
SisServer >> handleListPackages: request [
	^ self returnResultDo: [
		  (Smalltalk packages collect: [ :each | each name ]) sorted ]
]

{ #category : 'handling' }
SisServer >> handleGetPackageSource: request [
	^ self returnResultDo: [
		  | packageName package |
		  packageName := request at: #package_name.
		  package := self packageOrganizer packageNamed: packageName.
		  package mcPackage snapshot definitions collect: [ :each | each source ] ]
]

{ #category : 'handling' }
SisServer >> handleGetClassSource: request [
	^ self returnResultDo: [
		  | className class |
		  className := request at: #class_name.
		  class := Smalltalk globals at: className asSymbol.
		  class definitionForNautilus ]
]

{ #category : 'handling' }
SisServer >> handleGetMethodSource: request [
	^ self returnResultDo: [
		  | className methodName class method |
		  className := request at: #class_name.
		  methodName := request at: #method_name.
		  class := Smalltalk globals at: className asSymbol.
		  method := class methodNamed: methodName asSymbol.
		  method sourceCode ]
]

{ #category : 'handling' }
SisServer >> handleGetTraitMethodSource: request [
	^ self returnResultDo: [
		  | traitName methodName trait method |
		  traitName := request at: #trait_name.
		  methodName := request at: #method_name.
		  trait := Smalltalk globals at: traitName asSymbol.
		  method := trait methodNamed: methodName asSymbol.
		  method sourceCode ]
]

{ #category : 'handling' }
SisServer >> handleGetClassComment: request [
	^ self returnResultDo: [
		  | className class |
		  className := request at: #class_name.
		  class := Smalltalk globals at: className asSymbol.
		  class comment ]
]

{ #category : 'handling' }
SisServer >> handleSearchElements: request [
	^ self returnResultDo: [
		  | query types results |
		  query := request at: #query.
		  types := request at: #types.
		  results := OrderedCollection new.
		  
		  (types includes: 'package') ifTrue: [
		    results addAll: ((Smalltalk packages select: [ :pkg | pkg name includesSubstring: query ])
		      collect: [ :pkg | { 'type' -> 'package'. 'name' -> pkg name } asDictionary ]) ].
		  
		  (types includes: 'class') ifTrue: [
		    results addAll: ((Smalltalk allClasses select: [ :cls | cls name includesSubstring: query ])
		      collect: [ :cls | { 'type' -> 'class'. 'name' -> cls name } asDictionary ]) ].
		  
		  (types includes: 'trait') ifTrue: [
		    results addAll: ((Smalltalk allTraits select: [ :trait | trait name includesSubstring: query ])
		      collect: [ :trait | { 'type' -> 'trait'. 'name' -> trait name } asDictionary ]) ].
		  
		  (types includes: 'method') ifTrue: [
		    results addAll: ((Smalltalk allClasses flatCollect: [ :cls | cls methods ]) 
		      select: [ :method | method selector includesSubstring: query ]
		      thenCollect: [ :method | { 'type' -> 'method'. 'class' -> method methodClass name. 'name' -> method selector } asDictionary ]) ].
		  
		  results asArray ]
]

{ #category : 'handling' }
SisServer >> handleExportPackage: request [
	^ self returnResultDo: [
		  | packageName outputPath package |
		  packageName := request at: #package_name.
		  outputPath := request at: #output_path.
		  package := self packageOrganizer packageNamed: packageName.
		  (MCFileTreeWriter on: package mcPackage snapshot) writeToPath: outputPath.
		  'Package exported successfully' ]
]

{ #category : 'handling' }
SisServer >> handleImportPackage: request [
	^ self returnResultDo: [
		  | sourcePath |
		  sourcePath := request at: #source_path.
		  (MCFileTreeReader on: sourcePath asFileReference) load.
		  'Package imported successfully' ]
]

{ #category : 'handling' }
SisServer >> handleRunTest: request [
	^ self returnResultDo: [
		  | testName testClass testSelector result |
		  testName := request at: #test_name.
		  testClass := Smalltalk globals at: (testName copyUpTo: $>) asSymbol.
		  testSelector := (testName copyAfter: $>) asSymbol.
		  result := testClass new runCase: testSelector.
		  result ]
]

{ #category : 'private' }
SisServer >> packageOrganizer [
	^ RPackageOrganizer default
]

{ #category : 'private' }
SisServer >> returnResultDo: aBlock [
	| resultDict |
	resultDict := { ('success' -> false) } asDictionary.
	[ resultDict at: 'result' put: aBlock value ]
		on: Error
		do: [ :ex |
				resultDict at: 'error' put: ex description.
				^ resultDict ].
	resultDict at: 'success' put: true.
	^ resultDict
]

{ #category : 'actions' }
SisServer >> start [
	self teapot start
]

{ #category : 'actions' }
SisServer >> stop [
	self teapot stop
]

{ #category : 'accessing' }
SisServer >> teapot [

	^ teapot ifNil: [ teapot := self createTeapot ]
]

{ #category : 'accessing' }
SisServer >> teapot: anObject [

	teapot := anObject
]

{ #category : 'accessing' }
SisServer >> teapotConfig [

	^ teapotConfig ifNil: [ teapotConfig := self defaultTeapotConfig ]
]

{ #category : 'accessing' }
SisServer >> teapotConfig: anObject [

	teapotConfig := anObject
]

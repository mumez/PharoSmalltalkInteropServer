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
		  GET: '/list-extended-classes'
			  -> [ :req | self handleListExtendedClasses: req ];
		  GET: '/list-methods' -> [ :req | self handleListMethods: req ];
		  GET:
			  '/get-class-source' -> [ :req | self handleGetClassSource: req ];
		  GET:
			  '/get-method-source'
			  -> [ :req | self handleGetMethodSource: req ];
		  GET:
			  '/get-class-comment'
			  -> [ :req | self handleGetClassComment: req ];
		  GET:
			  '/search-elements' -> [ :req | self handleSearchElements: req ];
		  GET: '/search-classes-like' -> [ :req | self handleSearchClassesLike: req ];
		  GET: '/search-traits-like' -> [ :req | self handleSearchTraitsLike: req ];
		  GET: '/search-methods-like' -> [ :req | self handleSearchMethodsLike: req ];
		  GET: '/search-references' -> [ :req | self handleSearchReferences: req ];
		  GET: '/search-implementers' -> [ :req | self handleSearchImplementers: req ];
		  GET: '/export-package' -> [ :req | self handleExportPackage: req ];
		  GET: '/import-package' -> [ :req | self handleImportPackage: req ];
		  GET:
			  '/run-package-test' -> [ :req | self handleRunPackageTest: req ];
		  GET: '/run-class-test' -> [ :req | self handleRunClassTest: req ]
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
SisServer >> handleExportPackage: request [

	^ self returnResultDo: [
			  | packageName outputPath snapshot outputPathRef writer |
			  packageName := request at: #package_name.
			  outputPath := request at: #output_path.
			  snapshot := (MCPackage named: packageName) snapshot.
			  outputPathRef := outputPath asFileReference.
			  writer := TonelWriter on: outputPathRef ensureCreateDirectory.
			  writer writeSnapshot: snapshot.
			  packageName , ' exported to: ' , outputPathRef absolutePath pathString ]
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
SisServer >> handleGetClassSource: request [
	^ self returnResultDo: [
			  | className targetClass |
			  className := request at: #class_name.
			  targetClass := Smalltalk globals at: className asSymbol.
			  TonelWriter sourceCodeOf: targetClass ]
]

{ #category : 'handling' }
SisServer >> handleGetMethodSource: request [

	^ self returnResultDo: [
			  | tokens isClassSide className methodName targetClass |
			  tokens := (request at: #class_name) findTokens: ' '.
			  isClassSide := tokens size = 2.
			  className := tokens first.
			  methodName := request at: #method_name.
			  targetClass := Smalltalk globals at: className asSymbol.
			  isClassSide ifTrue: [ targetClass := targetClass class ].
			  targetClass sourceCodeAt: methodName asSymbol ]
]

{ #category : 'handling' }
SisServer >> handleImportPackage: request [

	^ self returnResultDo: [
			  | packageName sourcePath reader sourcePathRef |
			  packageName := request at: #package_name.
			  sourcePath := request at: #source_path.
			  sourcePathRef := sourcePath asFileReference.
			  reader := TonelReader on: sourcePathRef fileName: packageName.
			  reader loadPackage.
			  packageName , ' imported from: ' , sourcePathRef absolutePath pathString ]
]

{ #category : 'handling' }
SisServer >> handleListClasses: request [
	^ self returnResultDo: [
			  | packageName |
			  packageName := request at: #package_name.
			  ((self packageOrganizer packageNamed: packageName)
				  classes collect: [ :each | each name ]) sorted ]
]

{ #category : 'handling' }
SisServer >> handleListExtendedClasses: request [
	^ self returnResultDo: [
			  | packageName |
			  packageName := request at: #package_name.
			  (self packageOrganizer packageNamed: packageName)
				  extendedClassNames sorted ]
]

{ #category : 'handling' }
SisServer >> handleListMethods: request [
	^ self returnResultDo: [
			  | packageName |
			  packageName := request at: #package_name.
			(self packageOrganizer packageNamed: packageName) inspect.
			  ((self packageOrganizer packageNamed: packageName)
				  methods collect: [:each  | each printString ]) sorted ]
]

{ #category : 'handling' }
SisServer >> handleListPackages: request [
	^ self returnResultDo: [
		  (Smalltalk packages collect: [ :each | each name ]) sorted ]
]

{ #category : 'handling' }
SisServer >> handleRunClassTest: request [

	^ self returnResultDo: [
			  | className testClass suite |
			  className := request at: #class_name.
			  testClass := Smalltalk globals at: className asSymbol.
			  suite := testClass suite.
			  suite run printString ]
]

{ #category : 'handling' }
SisServer >> handleRunPackageTest: request [
	^ self returnResultDo: [
			  | packageName suite |
			  packageName := request at: #package_name.
			  suite := (self packageOrganizer packageNamed: packageName)
				           testSuite.
			  suite run printString ]
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
SisServer >> handleSearchClassesLike: request [
	^ self returnResultDo: [
		  | query nav results |
		  query := request at: #class_name_query.
		  nav := SystemNavigation default.
		  results := OrderedCollection new.
		  
		  nav allClassNamesStartingWith: query do: [ :className |
		    results add: { 'name' -> className } asDictionary ].
		  
		  results asArray ]
]

{ #category : 'handling' }
SisServer >> handleSearchTraitsLike: request [
	^ self returnResultDo: [
		  | query results |
		  query := request at: #traits_name_query.
		  results := OrderedCollection new.
		  
		  Smalltalk allTraits do: [ :trait |
		    (trait name beginsWith: query) ifTrue: [
		      results add: { 'name' -> trait name } asDictionary ] ].
		  
		  results asArray ]
]

{ #category : 'handling' }
SisServer >> handleSearchMethodsLike: request [
	^ self returnResultDo: [
		  | query nav results |
		  query := request at: #method_name_query.
		  nav := SystemNavigation default.
		  results := OrderedCollection new.
		  
		  nav allSelectorsStartingWith: query do: [ :selector |
		    results add: { 'name' -> selector } asDictionary ].
		  
		  results asArray ]
]

{ #category : 'handling' }
SisServer >> handleSearchReferences: request [
	^ self returnResultDo: [
		  | symbol nav results |
		  symbol := request at: #program_symbol.
		  nav := SystemNavigation default.
		  results := OrderedCollection new.
		  
		  (nav allReferencesTo: symbol asSymbol) do: [ :method |
		    results add: {
		      'class' -> method methodClass name.
		      'method' -> method selector.
		      'package' -> method package name
		    } asDictionary ].
		  
		  results asArray ]
]

{ #category : 'handling' }
SisServer >> handleSearchImplementers: request [
	^ self returnResultDo: [
		  | selector nav results |
		  selector := request at: #selector_symbol.
		  nav := SystemNavigation default.
		  results := OrderedCollection new.
		  
		  (nav allImplementorsOf: selector asSymbol) do: [ :method |
		    results add: {
		      'class' -> method methodClass name.
		      'method' -> method selector.
		      'package' -> method package name
		    } asDictionary ].
		  
		  results asArray ]
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

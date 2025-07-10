Class {
	#name : 'SisServer',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'teapotConfig'
	],
	#classInstVars : [
		'current',
		'teapotConfig',
		'inst'
	],
	#category : 'Sis-Core',
	#package : 'Sis-Core'
}

{ #category : 'instance creation' }
SisServer class >> configure:  settingsDict [
	| inst |
	inst := self new.
	inst teapotConfig: settingsDict.
	^ inst 
]

{ #category : 'instance creation' }
SisServer class >> createStarted [

	inst := self configure: self teapotConfig.
	inst start.
	^ inst
]

{ #category : 'accessing' }
SisServer class >> current [

	^ current ifNil: [ current :=  self createStarted]
]

{ #category : 'accessing' }
SisServer class >> current: anObject [

	current := anObject
]

{ #category : 'defaults' }
SisServer class >> defaultTeapotConfig [

	^ {
		  (#defaultOutput -> #json).
		  (#port -> 8086) } asDictionary
]

{ #category : 'class initialization' }
SisServer class >> initialize [
	SessionManager default registerUserClassNamed: self name.
	
	teapotConfig := self defaultTeapotConfig.
]

{ #category : 'system startup' }
SisServer class >> startUp: isImageStarting [

	isImageStarting ifFalse: [ ^ self ].
	
	current ifNotNil: [ current stop ].
	current := nil.
	
	Smalltalk session
		addDeferredStartupAction: [ self current ]
]

{ #category : 'accessing' }
SisServer class >> teapotConfig [
	^  teapotConfig
]

{ #category : 'factory' }
SisServer >> createTeapot [

	^ (Teapot configure: self teapotConfig associations)
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
			  '/search-classes-like'
			  -> [ :req | self handleSearchClassesLike: req ];
		  GET:
			  '/search-traits-like'
			  -> [ :req | self handleSearchTraitsLike: req ];
		  GET:
			  '/search-methods-like'
			  -> [ :req | self handleSearchMethodsLike: req ];
		  GET:
			  '/search-references'
			  -> [ :req | self handleSearchReferences: req ];
		  GET: '/search-implementers'
			  -> [ :req | self handleSearchImplementers: req ];
		  GET: '/search-references-to-class'
			  -> [ :req | self handleSearchReferencesToClass: req ];
		  GET: '/export-package' -> [ :req | self handleExportPackage: req ];
		  GET: '/import-package' -> [ :req | self handleImportPackage: req ];
		  GET:
			  '/run-package-test' -> [ :req | self handleRunPackageTest: req ];
		  GET: '/run-class-test' -> [ :req | self handleRunClassTest: req ]
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
SisServer >> handleSearchClassesLike: request [

	^ self returnResultDo: [
			  | query nav results |
			  query := request at: #class_name_query.
			  nav := SystemNavigation default.
			  results := OrderedCollection new.
			  nav
				  allClassNamesStartingWith: query
				  do: [ :className |
				  results add: className ]
				  caseSensitive: false.
			  results  ]
]

{ #category : 'handling' }
SisServer >> handleSearchImplementers: request [

	^ self returnResultDo: [
			  | selector nav results |
			  selector := request at: #method_name.
			  nav := SystemNavigation default.
			  results := OrderedCollection new.

			  (nav allImplementorsOf: selector asSymbol) do: [ :method |
					  results add: {
							  ('class' -> method methodClass name).
							  ('method' -> method selector).
							  ('package' -> method package name) } asDictionary ].

			  results asArray ]
]

{ #category : 'handling' }
SisServer >> handleSearchMethodsLike: request [

	^ self returnResultDo: [
			  | query nav results |
			  query := request at: #method_name_query.
			  nav := SystemNavigation default.
			  results := OrderedCollection new.

			  nav
				  allSelectorsStartingWith: query
				  do: [ :selector | results add: selector ].

			  results ]
]

{ #category : 'handling' }
SisServer >> handleSearchReferences: request [

	^ self returnResultDo: [
			  | symbol nav |
			  symbol := request at: #program_symbol.
			  nav := SystemNavigation default.
			  (nav allReferencesTo: symbol asSymbol) collect: [ :method |
					  {
						  ('class' -> method methodClass name).
						  ('method' -> method selector).
						  ('package' -> method package name) } asDictionary ] ]
]

{ #category : 'handling' }
SisServer >> handleSearchReferencesToClass: request [

	^ self returnResultDo: [
			  | className nav targetClass |
			  className := request at: #class_name.
			  nav := SystemNavigation default.
			  targetClass := Smalltalk globals at: className asSymbol.


			  (targetClass allCallsOnIn: nav) collect: [ :method |
					  {
						  ('class' -> method methodClass name).
						  ('method' -> method selector).
						  ('package' -> method package name) } asDictionary ] ]
]

{ #category : 'handling' }
SisServer >> handleSearchTraitsLike: request [

	^ self returnResultDo: [
			  | query results |
			  query := request at: #traits_name_query.
			  results := (Smalltalk globals allTraits select: [ :trait |
				              trait name beginsWith: query caseSensitive: false ])
				             collect: [ :each | each name ].

			  results ]
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

	^ teapotConfig ifNil: [ teapotConfig := self class defaultTeapotConfig ]
]

{ #category : 'accessing' }
SisServer >> teapotConfig: anObject [

	teapotConfig := anObject
]

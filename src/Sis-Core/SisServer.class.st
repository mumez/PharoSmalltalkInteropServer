Class {
	#name : 'SisServer',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'teapotConfig'
	],
	#classInstVars : [
		'current',
		'teapotConfig'
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
	| inst |
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
		  POST: '/eval' -> [ :req | self handleEval: req ];
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
		  GET: '/search-implementors'
			  -> [ :req | self handleSearchImplementors: req ];
		  GET: '/search-references-to-class'
			  -> [ :req | self handleSearchReferencesToClass: req ];
		  GET: '/export-package' -> [ :req | self handleExportPackage: req ];
		  GET: '/import-package' -> [ :req | self handleImportPackage: req ];
		  GET:
			  '/run-package-test' -> [ :req | self handleRunPackageTest: req ];
		  GET: '/run-class-test' -> [ :req | self handleRunClassTest: req ];
		  GET:
			  '/install-project' -> [ :req | self handleInstallProject: req ];
		  GET: '/read-screen' -> [ :req | self handleReadScreen: req ]
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
			  outputPath := request at: #path.
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
			  sourcePath := request at: #path.
			  sourcePathRef := sourcePath asFileReference.
			  reader := TonelReader on: sourcePathRef fileName: packageName.
			  reader loadPackage.
			  reader snapshot updatePackage: reader package.
			  packageName , ' imported from: '
			  , sourcePathRef absolutePath pathString ]
]

{ #category : 'handling' }
SisServer >> handleInstallProject: request [

	^ self returnResultDo: [
			  | projectName  repositoryUrl loadGroups loadOptions registration |
			  projectName := request at: #project_name.
			  repositoryUrl := request at: #repository_url.
			  loadGroups := request at: #load_groups ifAbsent: [ '' ].
			  loadOptions := (loadGroups findTokens: ',') collect: #trim.
			  [registration := Metacello new
				                  baseline: projectName;
				                  repository: repositoryUrl;
				                  load: loadOptions.
			  'Installed: ' , registration printString] on: MCMergeOrLoadWarning do:[ :ex | Error signal: ex description] ]
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
			  self testResultStringFrom: suite run ]
]

{ #category : 'handling' }
SisServer >> handleRunPackageTest: request [

	^ self returnResultDo: [
			  | packageName suite |
			  packageName := request at: #package_name.
			  suite := (self packageOrganizer packageNamed: packageName)
				           testSuite.
			  self testResultStringFrom: suite run ]
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
SisServer >> handleSearchImplementors: request [

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
			  query := request at: #trait_name_query.
			  results := (Smalltalk globals allTraits select: [ :trait |
				              trait name beginsWith: query caseSensitive: false ])
				             collect: [ :each | each name ].

			  results ]
]

{ #category : 'handling' }
SisServer >> handleReadScreen: request [
	^ self returnResultDo: [
		| targetType captureScreenshotParam captureScreenshot form filename timestamp structure response tempDir |
		targetType := request at: #target_type ifAbsent: [ 'world' ].
		captureScreenshotParam := request at: #capture_screenshot ifAbsent: [ 'true' ].
		captureScreenshot := captureScreenshotParam asLowercase = 'true'.

		"Capture screenshot if requested"
		filename := nil.
		captureScreenshot ifTrue: [
			timestamp := DateAndTime now asString copyReplaceAll: ':' with: '-'.
			tempDir := FileLocator temp.
			filename := (tempDir / ('pharo-ui-', timestamp, '.png')) fullName.
			form := self currentWorld imageForm.
			PNGReadWriter putForm: form onFileNamed: filename
		].

		"Extract structure based on target type"
		structure := targetType = 'spec'
			ifTrue: [ self extractSpecStructure ]
			ifFalse: [ targetType = 'roassal'
				ifTrue: [ self extractRoassalStructure ]
				ifFalse: [ self extractWorldStructure ] ].

		response := Dictionary new.
		filename ifNotNil: [ response at: #screenshot put: filename ].
		response at: #target_type put: targetType.
		response at: #structure put: structure.
		response at: #summary put: (self buildSummaryFor: targetType structure: structure).
		response
	]
]

{ #category : 'private' }
SisServer >> returnResultDo: aBlock [
	| resultDict |
	resultDict := { ('success' -> false) } asDictionary.
	[ resultDict at: 'result' put: aBlock value ]
		on: Error
		do: [ :ex | ^ self returnError: ex by: resultDict ].
	resultDict at: 'success' put: true.
	^ resultDict
]

{ #category : 'private' }
SisServer >> returnError: anError by: resultDict [
	| errorInfo signalerContext |
	errorInfo := Dictionary new.
	errorInfo at: 'description' put: anError description.
	signalerContext := anError signalerContext.
	errorInfo at: 'stack_trace' put: (String streamContents: [:strm | signalerContext debugStack: 500 on: strm]).
	errorInfo at: 'receiver' put: (self receiverErrorInfoFrom: signalerContext receiver).
	resultDict at: 'error' put: errorInfo.
	^ resultDict
]

{ #category : 'private' }
SisServer >> receiverErrorInfoFrom: receiverObject [
	| receiverErrorInfo values |
	receiverErrorInfo := Dictionary new.
	receiverErrorInfo at: 'self' put: receiverObject asString.
	receiverErrorInfo at: 'class' put: receiverObject className.
	values := Dictionary new.
	receiverObject class allInstVarNames do: [ :nm | values at: nm put: (receiverObject instVarNamed: nm ) asString].
	receiverErrorInfo at: 'variables' put: values.
	^ receiverErrorInfo
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

{ #category : 'private' }
SisServer >> testResultStringFrom: aTestResult [
	^ String streamContents: [ :aStream | aTestResult fileOutOn: aStream ].
]

{ #category : 'private - ui extraction' }
SisServer >> buildSummaryFor: targetType structure: structure [
	"Generate human-readable summary"
	targetType = 'spec' ifTrue: [
		| presenters |
		presenters := structure at: #presenters ifAbsent: [ #() ].
		^ presenters size asString, ' Spec presenter(s)' ].

	targetType = 'roassal' ifTrue: [
		| canvases |
		canvases := structure at: #canvases ifAbsent: [ #() ].
		^ canvases size asString, ' Roassal canvas(es)' ].

	^ 'World with ', self currentWorld submorphs size asString, ' top-level morphs'
]

{ #category : 'private - ui extraction' }
SisServer >> extractWorldStructure [
	"Extract morphs from World with comprehensive properties"
	| morphs morphList |
	morphs := self currentWorld submorphs first: (self currentWorld submorphs size min: 10).
	morphList := morphs collect: [ :morph | self extractMorphData: morph ].
	^ Dictionary new
		at: #totalMorphs put: self currentWorld submorphs size;
		at: #displayedMorphCount put: morphs size;
		at: #morphs put: morphList;
		yourself
]

{ #category : 'private - ui extraction' }
SisServer >> extractMorphData: morph [
	"Extract properties of a single morph"
	| info bounds color |
	info := Dictionary new.
	info at: #class put: morph class name.

	"Geometry"
	bounds := morph bounds.
	info at: #bounds put: (Dictionary new
		at: #x put: bounds left;
		at: #y put: bounds top;
		at: #width put: bounds width;
		at: #height put: bounds height;
		yourself).

	"Visual properties"
	info at: #visible put: morph visible.
	(morph respondsTo: #color) ifTrue: [
		color := morph color.
		info at: #backgroundColor put: color asString ].

	"Structure"
	info at: #submorphCount put: morph submorphs size.
	(morph respondsTo: #owner) ifTrue: [
		info at: #owner put: (morph owner ifNotNil: [ morph owner class name ]) ].

	"Content if it has text"
	(morph respondsTo: #text) ifTrue: [
		info at: #text put: morph text asString ].

	^ info
]

{ #category : 'private - ui extraction' }
SisServer >> extractSpecStructure [
	"Extract all open Spec windows and their properties.
	Handles both Pharo 12 (SpWindowPresenter instances) and Pharo 13 (SpWindow morphs with presenters)."
	| windows presenters |

	(Smalltalk globals includesKey: #SpWindowPresenter) ifFalse: [
		^ Dictionary new at: #presenters put: #(); yourself
	].

	"Try Pharo 12 approach: SpWindowPresenter instances"
	windows := (Smalltalk globals at: #SpWindowPresenter) allInstances
		select: [ :w | w isOpen and: [ w isDisplayed ] ].

	"If empty, try Pharo 13 approach: SpWindow morphs with presenter property"
	windows isEmpty ifTrue: [
		windows := (self currentWorld submorphs select: [ :m | m class name = 'SpWindow' ])
			select: [ :spWindow |
				(spWindow respondsTo: #presenter) and: [ spWindow presenter notNil ] ]
			thenCollect: [ :spWindow | spWindow presenter ]
	].

	presenters := windows collect: [ :window |
		self extractWindowInfo: window
	].

	^ Dictionary new
		at: #presenters put: presenters;
		at: #windowCount put: presenters size;
		yourself
]

{ #category : 'private - ui extraction' }
SisServer >> extractWindowInfo: aWindow [
	"Extract properties of a Spec window presenter"
	| info hasMenu hasToolbar hasStatusBar |
	info := Dictionary new.

	"Window properties"
	info at: #title put: (aWindow title ifNil: [ 'Untitled' ]).
	info at: #class put: aWindow class name.

	"Geometry"
	(aWindow respondsTo: #initialExtent) ifTrue: [
		info at: #extent put: (aWindow initialExtent ifNotNil: [ aWindow initialExtent asString ]) ].
	(aWindow respondsTo: #initialPosition) ifTrue: [
		info at: #position put: (aWindow initialPosition ifNotNil: [ aWindow initialPosition asString ]) ].

	"Window state"
	(aWindow respondsTo: #isMaximized) ifTrue: [ info at: #isMaximized put: aWindow isMaximized ].
	(aWindow respondsTo: #isMinimized) ifTrue: [ info at: #isMinimized put: aWindow isMinimized ].
	(aWindow respondsTo: #isResizable) ifTrue: [ info at: #isResizable put: aWindow isResizable ].

	"Decorations"
	hasMenu := (aWindow respondsTo: #hasMenu) and: [ aWindow hasMenu ].
	hasToolbar := (aWindow respondsTo: #hasToolbar) and: [ aWindow hasToolbar ].
	hasStatusBar := (aWindow respondsTo: #hasStatusBar) and: [ aWindow hasStatusBar ].

	info at: #hasMenu put: hasMenu.
	info at: #hasToolbar put: hasToolbar.
	info at: #hasStatusBar put: hasStatusBar.

	"Presenter hierarchy"
	(aWindow respondsTo: #presenter) ifTrue: [
		info at: #presenter put: (self extractPresenterInfo: aWindow presenter depth: 3)
	].

	^ info
]

{ #category : 'private - ui extraction' }
SisServer >> extractPresenterInfo: aPresenter depth: maxDepth [
	"Recursively extract presenter hierarchy up to maxDepth with content"
	| info children |

	info := Dictionary new.
	info at: #class put: aPresenter class name.

	"Name/label if available"
	(aPresenter respondsTo: #name) ifTrue: [
		info at: #name put: (aPresenter name ifNotNil: [ aPresenter name asString ]) ].

	"Content properties for debugging"
	(aPresenter respondsTo: #label) ifTrue: [
		info at: #label put: (aPresenter label ifNotNil: [ aPresenter label asString ]) ].
	(aPresenter respondsTo: #text) ifTrue: [
		info at: #text put: (aPresenter text ifNotNil: [ aPresenter text asString ]) ].
	(aPresenter respondsTo: #value) ifTrue: [
		info at: #value put: (aPresenter value ifNotNil: [ aPresenter value asString ]) ].
	(aPresenter respondsTo: #placeholder) ifTrue: [
		info at: #placeholder put: (aPresenter placeholder ifNotNil: [ aPresenter placeholder asString ]) ].
	(aPresenter respondsTo: #isEnabled) ifTrue: [
		info at: #isEnabled put: aPresenter isEnabled ].
	(aPresenter respondsTo: #isVisible) ifTrue: [
		info at: #isVisible put: aPresenter isVisible ].

	"Extract children if depth allows"
	children := #().
	maxDepth > 0 ifTrue: [
		(aPresenter respondsTo: #presenters) ifTrue: [
			children := (aPresenter presenters collect: [ :child |
				self extractPresenterInfo: child depth: (maxDepth - 1)
			]) asArray
		]
	].

	info at: #children put: children.
	info at: #childCount put: children size.

	^ info
]

{ #category : 'private - ui extraction' }
SisServer >> extractRoassalStructure [
	"Extract Roassal canvases from World morphs (recursive search)"
	| roassalMorphs canvasInfoList |

	(Smalltalk globals includesKey: #RSAthensMorph) ifFalse: [
		^ Dictionary new at: #canvases put: #(); yourself ].

	"Find RSAthensMorph instances recursively throughout the morph tree"
	roassalMorphs := self currentWorld allMorphs select: [ :morph |
		morph class name = 'RSAthensMorph' ].

	canvasInfoList := roassalMorphs collect: [ :morph |
		self extractRoassalCanvasInfo: morph ].

	^ Dictionary new
		at: #canvases put: canvasInfoList;
		at: #canvasCount put: canvasInfoList size;
		yourself
]

{ #category : 'private - ui extraction' }
SisServer >> extractRoassalCanvasInfo: roassalMorph [
	"Extract properties from a Roassal visualization morph with shape details"
	| info canvas bounds shapes edges |

	info := Dictionary new.

	"Basic properties"
	info at: #class put: roassalMorph class name.

	"Geometry"
	bounds := roassalMorph bounds.
	info at: #bounds put: (Dictionary new
		at: #x put: bounds left;
		at: #y put: bounds top;
		at: #width put: bounds width;
		at: #height put: bounds height;
		yourself).

	"Visual properties"
	info at: #visible put: roassalMorph visible.
	(roassalMorph respondsTo: #color) ifTrue: [
		info at: #backgroundColor put: roassalMorph color asString ].

	"Canvas information"
	canvas := nil.
	(roassalMorph respondsTo: #canvas) ifTrue: [
		canvas := roassalMorph canvas.
		canvas ifNotNil: [
			info at: #canvasClass put: canvas class name.

			"Extract actual shapes with details"
			shapes := #().
			(canvas respondsTo: #shapes) ifTrue: [
				shapes := (canvas shapes asArray collect: [ :shape |
					self extractRoassalShapeInfo: shape
				]) asArray.
				info at: #shapes put: shapes.
				info at: #shapeCount put: shapes size ].

			"Extract edges with details"
			edges := #().
			(canvas respondsTo: #edges) ifTrue: [
				edges := (canvas edges asArray collect: [ :edge |
					self extractRoassalEdgeInfo: edge
				]) asArray.
				info at: #edges put: edges.
				info at: #edgeCount put: edges size ].

			"Node count for summary"
			(canvas respondsTo: #nodes) ifTrue: [
				info at: #nodeCount put: canvas nodes size ].

			"Canvas extent"
			(canvas respondsTo: #extent) ifTrue: [
				info at: #canvasExtent put: canvas extent asString ].

			"Camera/zoom level if available"
			(canvas respondsTo: #camera) ifTrue: [
				(canvas camera notNil and: [ canvas camera respondsTo: #scale ]) ifTrue: [
					info at: #zoomLevel put: canvas camera scale asString ] ] ] ].

	^ info
]

{ #category : 'private - ui extraction' }
SisServer >> extractRoassalShapeInfo: shape [
	"Extract details about a Roassal shape for debugging"
	| info |

	info := Dictionary new.
	info at: #class put: shape class name.

	"Position - safely extract"
	(shape respondsTo: #position) ifTrue: [
		[ | pos |
			pos := shape position.
			pos ifNotNil: [ info at: #position put: pos asString ]
		] on: Error do: [ "Skip on error" ]
	].

	"Extent - safely extract"
	(shape respondsTo: #extent) ifTrue: [
		[ | ext |
			ext := shape extent.
			ext ifNotNil: [ info at: #extent put: ext asString ]
		] on: Error do: [ "Skip on error" ]
	].

	"Color - safely extract"
	(shape respondsTo: #color) ifTrue: [
		[ | col |
			col := shape color.
			col ifNotNil: [ info at: #color put: col asString ]
		] on: Error do: [ "Skip on error" ]
	].

	"Text content if available - safely extract"
	(shape respondsTo: #text) ifTrue: [
		[ | txt |
			txt := shape text.
			txt ifNotNil: [ info at: #text put: txt asString ]
		] on: Error do: [ "Skip on error" ]
	].

	"Label if available - safely extract"
	(shape respondsTo: #label) ifTrue: [
		[ | lbl |
			lbl := shape label.
			lbl ifNotNil: [ info at: #label put: lbl asString ]
		] on: Error do: [ "Skip on error" ]
	].

	^ info
]

{ #category : 'private - ui extraction' }
SisServer >> extractRoassalEdgeInfo: edge [
	"Extract details about a Roassal edge for debugging"
	| info |

	info := Dictionary new.
	info at: #class put: edge class name.

	"Source and target if available - safely extract"
	(edge respondsTo: #from) ifTrue: [
		[ | src |
			src := edge from.
			src ifNotNil: [ info at: #from put: src class name ]
		] on: Error do: [ "Skip on error" ]
	].
	(edge respondsTo: #to) ifTrue: [
		[ | tgt |
			tgt := edge to.
			tgt ifNotNil: [ info at: #to put: tgt class name ]
		] on: Error do: [ "Skip on error" ]
	].

	"Color - safely extract"
	(edge respondsTo: #color) ifTrue: [
		[ | col |
			col := edge color.
			col ifNotNil: [ info at: #color put: col asString ]
		] on: Error do: [ "Skip on error" ]
	].

	"Label if available - safely extract"
	(edge respondsTo: #label) ifTrue: [
		[ | lbl |
			lbl := edge label.
			lbl ifNotNil: [ info at: #label put: lbl asString ]
		] on: Error do: [ "Skip on error" ]
	].

	^ info
]

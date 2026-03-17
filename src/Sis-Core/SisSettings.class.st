Class {
	#name : 'SisSettings',
	#superclass : 'Object',
	#instVars : [
		'settingsDict'
	],
	#classInstVars : [
		'default'
	],
	#category : 'Sis-Core',
	#package : 'Sis-Core'
}

{ #category : 'instance creation' }
SisSettings class >> default [
	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
SisSettings class >> defaultCopied [
	^ self new initFrom: self default
]

{ #category : 'class initialization' }
SisSettings class >> initialize [
	super initialize.
	default := nil
]

{ #category : 'actions-dictionary' }
SisSettings >> at: key [
	^ self settingsDict at: key
]

{ #category : 'actions-dictionary' }
SisSettings >> at: key ifAbsent: aBlock [
	^ self settingsDict at: key ifAbsent: aBlock
]

{ #category : 'actions-dictionary' }
SisSettings >> at: key ifAbsentPut: aBlock [
	^ self settingsDict at: key ifAbsentPut: aBlock
]

{ #category : 'actions-dictionary' }
SisSettings >> at: key put: value [
	^ self settingsDict at: key put: value
]

{ #category : 'actions-dictionary' }
SisSettings >> keys [
	^ self settingsDict keys
]

{ #category : 'accessing' }
SisSettings >> defaultOutput [
	^ self at: #defaultOutput ifAbsentPut: [ #json ]
]

{ #category : 'accessing' }
SisSettings >> defaultOutput: aSymbol [
	self at: #defaultOutput put: aSymbol
]

{ #category : 'initialization' }
SisSettings >> initialize [
	settingsDict := nil
]

{ #category : 'initialization' }
SisSettings >> initFrom: otherSettings [
	self initialize.
	otherSettings settingsDict keysAndValuesDo: [ :k :v |
		self settingsDict at: k put: v ]
]

{ #category : 'accessing' }
SisSettings >> port [
	^ self at: #port ifAbsentPut: [ 8086 ]
]

{ #category : 'accessing' }
SisSettings >> port: aNumber [
	self at: #port put: aNumber
]

{ #category : 'accessing-private' }
SisSettings >> settingsDict [
	^ settingsDict ifNil: [ settingsDict := IdentityDictionary new ]
]

{ #category : 'accessing-private' }
SisSettings >> settingsDict: anObject [
	settingsDict := anObject
]

{ #category : 'accessing' }
SisSettings >> stackSize [
	^ self at: #stackSize ifAbsentPut: [ 100 ]
]

{ #category : 'accessing' }
SisSettings >> stackSize: aNumber [
	self at: #stackSize put: aNumber
]

{ #category : 'accessing-keys' }
SisSettings >> teapotConfigKeys [
	^ #(#defaultOutput #port)
]

{ #category : 'accessing-keys' }
SisSettings >> definedSettingsKeys [
	^ #(#stackSize)
]

{ #category : 'private' }
SisSettings >> ensureDefinedKeys [
	self definedSettingsKeys do: [:each | self perform: each asSymbol ]
]

{ #category : 'converting' }
SisSettings >> teapotConfig [
	^ self teapotConfigKeys inject: Dictionary new into: [ :dict :key |
		dict at: key put: (self perform: key);
		yourself ]
]

{ #category : 'converting' }
SisSettings >> asDictionary [
    self ensureDefinedKeys.
	^ (self keys collect: [ :each | each -> (self at: each)]) asDictionary
]

"
SisFixtureClassForTest is a fixture class for SIS testing
"
Class {
	#name : 'SisFixtureClassForTest',
	#superclass : 'Object',
	#instVars : [
		'instVarA',
		'instVarB'
	],
	#category : 'Sis-Tests',
	#package : 'Sis-Tests'
}

{ #category : 'actions' }
SisFixtureClassForTest >> testMethodAaa [
	^ SisTest
]

{ #category : 'actions' }
SisFixtureClassForTest >> testMethodAab [
]

{ #category : 'actions' }
SisFixtureClassForTest >> testMethodBbb [
	^ #TestSymbolBBB
]

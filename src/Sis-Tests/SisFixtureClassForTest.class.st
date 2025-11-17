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

{ #category : 'class methods' }
SisFixtureClassForTest class >> testClassMethodCcc [
	"A class-side method for testing the is_class_method parameter"
	^ #TestClassMethodCCC
]

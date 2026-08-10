Class {
	#name : 'SisDummyTest',
	#superclass : 'TestCase',
	#category : 'SIS-DummyTests',
	#package : 'SIS-DummyTests'
}

{ #category : 'tests' }
SisDummyTest >> testAdd [
	| ans |
	ans := 3 + 2.
	self assert: ans equals: 5
]

{ #category : 'tests' }
SisDummyTest >> testSubtract [
	| ans |
	ans := 3 - 2.
	self assert: ans equals: 1
]

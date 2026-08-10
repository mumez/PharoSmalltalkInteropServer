Class {
	#name : 'SisDummyTest2',
	#superclass : 'TestCase',
	#category : 'SIS-DummyTests',
	#package : 'SIS-DummyTests'
}

{ #category : 'tests' }
SisDummyTest2 >> testReversed [
	self assert: 'Smalltalk' reversed equals: 'klatllamS'
]

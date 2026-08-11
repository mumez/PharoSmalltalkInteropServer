Class {
	#name : 'SisDummyTest2',
	#superclass : 'TestCase',
	#category : 'Sis-DummyTests',
	#package : 'Sis-DummyTests'
}

{ #category : 'tests' }
SisDummyTest2 >> testReversed [
	self assert: 'Smalltalk' reversed equals: 'klatllamS'
]

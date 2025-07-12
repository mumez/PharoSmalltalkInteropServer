Class {
	#name : 'SisDummyTest2',
	#superclass : 'TestCase',
	#category : 'Sis-Tests-Dummy',
	#package : 'Sis-Tests-Dummy'
}

{ #category : 'tests' }
SisDummyTest2 >> testReversed [
	self assert: 'Smalltalk' reversed equals: 'klatllamS'
]

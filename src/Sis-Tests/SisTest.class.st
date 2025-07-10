Class {
	#name : 'SisTest',
	#superclass : 'TestCase',
	#category : 'Sis-Tests',
	#package : 'Sis-Tests'
}

{ #category : 'private' }
SisTest >> baseUrl [
	| port |
	port := SisServer current teapotConfig at: #port ifAbsent: [8086].
	^ ('http://localhost:{1}' format: { port } ) asUrl.
]

{ #category : 'private' }
SisTest >> getContent: anUrl [
	| resp |
	resp := ZnEasy get: anUrl.
	^ NeoJSONReader fromString:  resp  contents
]

{ #category : 'tests' }
SisTest >> testListPackages [
	| url resp result |
	url := self baseUrl / 'list-packages'.
	resp := self getContent: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result   includes: 'Sis-Core')
]

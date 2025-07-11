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
SisTest >> get: anUrl [
	| resp |
	resp := ZnEasy get: anUrl.
	^ NeoJSONReader fromString:  resp  contents
]

{ #category : 'private' }
SisTest >> post: anUrl dictionary:  dict [
	| json resp |
	json := NeoJSONWriter  toString: dict.
	resp := ZnEasy post: anUrl data:  (ZnEntity json: json).
	^ NeoJSONReader fromString:  resp  contents
]

{ #category : 'tests' }
SisTest >> testEval [
	| url postData resp result |
	url := self baseUrl / 'eval'.
	postData := { ('code' -> '5 rem: 3') } asDictionary.
	resp := self post: url dictionary: postData.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: result  equals:  2
]

{ #category : 'tests' }
SisTest >> testListPackages [
	| url resp result |
	url := self baseUrl / 'list-packages'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assert: (result   includes: 'Sis-Core')
]

{ #category : 'tests' }
SisTest >> testSearchMethodLike [
	| url resp result |
	url := self baseUrl / 'search-methods-like'.
	url queryAt: 'method_name_query' put: 'testMethodAa'.
	resp := self get: url.
	self assert: (resp at: #success).
	result := resp at: #result.
	self assertCollection: result   equals: #('testMethodAaa' 'testMethodAab')
]

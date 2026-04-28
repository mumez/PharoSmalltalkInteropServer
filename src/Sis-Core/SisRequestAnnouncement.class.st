Class {
	#name : 'SisRequestAnnouncement',
	#superclass : 'Announcement',
	#instVars : [
		'teapotRequest',
		'type'
	],
	#category : 'Sis-Core',
	#package : 'Sis-Core'
}

{ #category : 'instan' }
SisRequestAnnouncement class >> after: aTeapotRequest [
	^ self new
		  type: #after;
		  teapotRequest: aTeapotRequest;
		  yourself
]

{ #category : 'instan' }
SisRequestAnnouncement class >> before: aTeapotRequest [
	^ self new
		  type: #before;
		  teapotRequest: aTeapotRequest;
		  yourself
]

{ #category : 'printin' }
SisRequestAnnouncement >> printOn: aStream [
	self type printOn: aStream.
	aStream space.
	self teapotRequest url printOn: aStream
	
]

{ #category : 'accessing' }
SisRequestAnnouncement >> teapotRequest [

	^ teapotRequest
]

{ #category : 'accessing' }
SisRequestAnnouncement >> teapotRequest: anObject [

	teapotRequest := anObject
]

{ #category : 'accessing' }
SisRequestAnnouncement >> type [

	^ type
]

{ #category : 'accessing' }
SisRequestAnnouncement >> type: anObject [

	type := anObject
]

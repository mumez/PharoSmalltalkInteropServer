Class {
	#name : 'BaselineOfPharoSmalltalkInteropServer',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPharoSmalltalkInteropServer',
	#package : 'BaselineOfPharoSmalltalkInteropServer'
}

{ #category : 'baselines' }
BaselineOfPharoSmalltalkInteropServer >> baseline: spec [

	<baseline>
	spec for: #pharo do: [
			spec postLoadDoIt: #postload:package:.
			self teapot: spec.
			spec package: 'Sis-Core' with: [ spec requires: #( 'Teapot' ) ].
			spec
				package: 'Sis-Tests'
				with: [ spec requires: #( 'Sis-Tests-Dummy' ) ].
			spec package: 'Sis-Tests-Dummy'.
			spec
				group: 'default' with: #( 'Core' 'Tests' );
				group: 'Core' with: #( 'Sis-Core' );
				group: 'Tests' with: #( 'Sis-Tests' 'Sis-Tests-Dummy' ) ]
]

{ #category : 'baselines' }
BaselineOfPharoSmalltalkInteropServer >> postload: loader package: packageSpec [

	(Smalltalk globals at: #SisServer) current start
]

{ #category : 'external projects' }
BaselineOfPharoSmalltalkInteropServer >> teapot: spec [

	spec baseline: 'Teapot' with: [
			spec
				repository: 'https://github.com/zeroflag/Teapot';
				loads: 'default' ]
]

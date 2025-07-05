"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestSisCore',
	#superclass : 'PackageManifest',
	#category : 'Sis-Core-Manifest',
	#package : 'Sis-Core',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestSisCore class >> ruleUncommonMessageSendRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGPackageDefinition #(#'Sis-Core')) #'2025-07-05T22:17:00.029+09:00') )
]

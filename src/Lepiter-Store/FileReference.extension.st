Extension { #name : #FileReference }

{ #category : #'*Lepiter-Store' }
FileReference class >> leFromJsonV3Dictionary: aDictionary [
	"Create a new instance of the receiver from the supplied dictionary."

	^ (aDictionary at: #filename) asFileReference
]

{ #category : #'*Lepiter-Store' }
FileReference class >> leFromJsonV4Dictionary: aDictionary [
	"Create a new instance of the receiver from the supplied dictionary."

	^ (aDictionary at: #filename) asFileReference
]

{ #category : #'*Lepiter-Store' }
FileReference class >> leJsonV3MappingFor: aNeoJSONMapper [
	"Dates are encoded as their type and a single string in default Date format"

	aNeoJSONMapper for: self do: [ :mapping | 
		mapping
			mapProperty: #'__type' 
			getter: [ :object | object class leJsonV3Name ] 
			setter: [ :um | self error: 'Objects should not be read here' ].
		mapping 
			mapProperty: #filename
			getter: [ :object | object fullName ]
			setter: [ :fileString | fileString asFileReference ] ].

]

{ #category : #'*Lepiter-Store' }
FileReference class >> leJsonV3Name [

	^ #file
]

{ #category : #'*Lepiter-Store' }
FileReference class >> leJsonV4MappingFor: aNeoJSONMapper [
	"Dates are encoded as their type and a single string in default Date format"

	aNeoJSONMapper for: self do: [ :mapping | 
		mapping
			mapProperty: #'__type' 
			getter: [ :object | object class leJsonV4Name ] 
			setter: [ :um | self error: 'Objects should not be read here' ].
		mapping 
			mapProperty: #filename
			getter: [ :object | object fullName ]
			setter: [ :fileString | fileString asFileReference ] ].

]

{ #category : #'*Lepiter-Store' }
FileReference class >> leJsonV4Name [

	^ #file
]

Class {
	#name : #LeHtmlExporterAnnotationVisitor,
	#superclass : #Object,
	#traits : 'TLeAnnotationParseNodeVisitor',
	#classTraits : 'TLeAnnotationParseNodeVisitor classTrait',
	#instVars : [
		'stream',
		'externalPicturesWriter'
	],
	#category : #'Lepiter-HTML-Exporter'
}

{ #category : #html }
LeHtmlExporterAnnotationVisitor >> exportImageTagForPath: filePath forAnnotation: anExampleAnnotation [
	stream
		<< ('<img src="{1}" alt="{2}"/>' format: {
			filePath asHTMLString. 
			filePath asHTMLString });
		cr.

]

{ #category : #accessing }
LeHtmlExporterAnnotationVisitor >> externalPicturesWriter [
	^ externalPicturesWriter
]

{ #category : #accessing }
LeHtmlExporterAnnotationVisitor >> externalPicturesWriter: aDataWriter [
	externalPicturesWriter := aDataWriter
]

{ #category : #accessing }
LeHtmlExporterAnnotationVisitor >> labelStringForAnnotation: anExampleAnnotation [
	| rbMethod example resultObject |
	
	rbMethod := anExampleAnnotation imageObject.
	rbMethod isDefined ifFalse: [ ^ '<method not defined>' ].  
	
	example := rbMethod compiledMethod
		gtExample asExampleWithResult.
	example canBeExecuted 
		ifFalse: [ ^ '<cannot execute>' ].
	example run.
	example hasResult 
		ifFalse: [ ^ '<something failed during example execution>' ].
	
	resultObject := example returnValue.
	^ anExampleAnnotation labelNode 
		labelFor: resultObject
]

{ #category : #accessing }
LeHtmlExporterAnnotationVisitor >> stream [
	^ stream
]

{ #category : #accessing }
LeHtmlExporterAnnotationVisitor >> stream: anObject [
	stream := anObject
]

{ #category : #generated }
LeHtmlExporterAnnotationVisitor >> visitClassAnnotation: aClassAnnotation [
	| classNameArgument |
	
	aClassAnnotation hasLabel ifTrue: [ 
		^ self writeClassLabel: aClassAnnotation ].
	
	classNameArgument := aClassAnnotation nameNode.
	stream
		<< '<span class="class_annotation">';
		<< classNameArgument value source asHTMLString;
		<< '<span class="class_definition">';
		<< classNameArgument behavior definition trimBoth asHTMLString;
		<< '<br></span></span>'; cr.

]

{ #category : #generated }
LeHtmlExporterAnnotationVisitor >> visitExampleAnnotation: anExampleAnnotation [	
	self visitAnnotation: anExampleAnnotation. 
		
	anExampleAnnotation hasLabel ifTrue: [ 
		^ self writeExampleLabelFor: anExampleAnnotation ].
	self writeExampleViewOrCodeFor: anExampleAnnotation
]

{ #category : #generated }
LeHtmlExporterAnnotationVisitor >> visitMethodAnnotation: aMethodAnnotation [
	| methodNameArgument |
	
	aMethodAnnotation hasLabel ifTrue: [ 
		^ self writeMethodLabel: aMethodAnnotation ].
	
	methodNameArgument := aMethodAnnotation nameNode.
	stream
		<< '<span class="method_annotation">';
		<< methodNameArgument source asHTMLString;
		<< '<span class="method_definition">';
		<< methodNameArgument imageObject sourceCode asHTMLString;
		<< '</span></span>'; cr.

]

{ #category : #html }
LeHtmlExporterAnnotationVisitor >> writeClassLabel: anAnnotation [
	stream
		<< '<code class="class_label">';
		<< anAnnotation label;
		<< '</code>'

]

{ #category : #html }
LeHtmlExporterAnnotationVisitor >> writeCodeForExample: anExample [
	stream
		<< '<div class="example_definition">';
		<< '<figure class="codeBlock gtexample-src paragraphWidth">';
		<< '<pre>';
		<< '<code class="hljs smalltalk">';
		<< anExample method sourceCode asHTMLString;
		<< '</code>';
		<< '</pre>';
		<< '</figure>';
		<< '</div>'; cr.

]

{ #category : #html }
LeHtmlExporterAnnotationVisitor >> writeExampleLabelFor: anExampleAnnotation [
	stream
		<< '<code class="example_inlined">'
		<< (self labelStringForAnnotation: anExampleAnnotation) asHTMLString;
		<< '</code>'
]

{ #category : #html }
LeHtmlExporterAnnotationVisitor >> writeExampleResultForAnnotation: anExampleAnnotation [
	| filePath |
	self externalPicturesWriter ifNil: [
		stream
			<< '<div class=""example_result"">';
			<< anExampleAnnotation imageObject compiledMethod gtExample result printString trimBoth asHTMLString;
			<< '</div>'; cr.
		^ self ].
	
	filePath := self externalPicturesWriter
		exampleResultReferenceFor: anExampleAnnotation.
		
	stream
		<< ('<figure class="{1}">' format: { anExampleAnnotation alignment ifNil: [ 
			GtDocumentConstants defaultAlignment ] }); 
		cr.
		
	self 
		exportImageTagForPath: filePath
		forAnnotation:anExampleAnnotation.
	
	stream
		<< '</figure>'; cr

]

{ #category : #html }
LeHtmlExporterAnnotationVisitor >> writeExampleViewOrCodeFor: exampleAnnotation [	
	| rbMethod example |
	rbMethod := exampleAnnotation imageObject.
	rbMethod isDefined ifFalse: [ ^ self ].  
	example := rbMethod compiledMethod gtExample.
	
	stream
		<< '<div class="example_annotation">';
		<< '<div class="example_display">'.
	
	exampleAnnotation noCode ifFalse: [
		self writeCodeForExample: example ].
	
	((exampleAnnotation previewExpanded or: [ 
		exampleAnnotation noCode ]) and: [ 
			example canBeExecuted ]) ifTrue: [
				self writeExampleResultForAnnotation: exampleAnnotation ].
	
	stream
		<< '</div>';
		<< '</div>'; cr.

]

{ #category : #html }
LeHtmlExporterAnnotationVisitor >> writeMethodLabel: anAnnotation [
	stream
		<< '<code class="method_label">';
		<< anAnnotation label;
		<< '</code>'

]

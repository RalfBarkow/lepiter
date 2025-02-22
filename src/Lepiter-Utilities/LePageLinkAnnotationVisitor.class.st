Class {
	#name : #LePageLinkAnnotationVisitor,
	#superclass : #LeAnnotationParseNodeVisitor,
	#traits : 'TSmaCCComponentVisitor + (TLeAnnotationParseNodeVisitor - {#acceptNode:})',
	#classTraits : 'TSmaCCComponentVisitor classTrait + TLeAnnotationParseNodeVisitor classTrait',
	#category : #'Lepiter-Utilities-Utilities'
}

{ #category : #generated }
LePageLinkAnnotationVisitor >> visitPageAnnotation: aPageAnnotation [

	super visitPageAnnotation: aPageAnnotation.
	self composite links add: (LeTextualPageLink new 
		node: aPageAnnotation;
		targetPageTitle: aPageAnnotation linkUID;
		targetDatabaseUUID: aPageAnnotation dbUuidString)
]

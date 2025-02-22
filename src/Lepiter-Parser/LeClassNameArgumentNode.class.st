Class {
	#name : #LeClassNameArgumentNode,
	#superclass : #LeNameArgumentNode,
	#instVars : [
		'classToken'
	],
	#category : #'Lepiter-Parser'
}

{ #category : #generated }
LeClassNameArgumentNode >> acceptVisitor: anAnnotationParseVisitor [
	^ anAnnotationParseVisitor visitClassNameArgument: self
]

{ #category : #accessing }
LeClassNameArgumentNode >> behavior [
	^ Smalltalk
		at: value source asSymbol
		ifPresent: [ :cls | 
			classToken isNil
				ifTrue: [ cls ]
				ifFalse: [ cls class ] ]
]

{ #category : #generated }
LeClassNameArgumentNode >> classToken [
	^ classToken
]

{ #category : #generated }
LeClassNameArgumentNode >> classToken: aSmaCCToken [
	classToken := aSmaCCToken
]

{ #category : #accessing }
LeClassNameArgumentNode >> imageObject [
	^ self behavior
]

{ #category : #generated }
LeClassNameArgumentNode >> tokenVariables [
	^ #(#classToken #name #equals #value)
]

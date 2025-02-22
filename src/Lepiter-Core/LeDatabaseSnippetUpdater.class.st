"
I update {{gtClass:LeBlock}} instances.
I properly update {{gtMethod:LeBlock>>#text}}, and {{gtMethod:LeContent>>#editTime|label=#selector}} and {{gtMethod:LeContent>>#editEmail|label=#selector}} values.
Use me by calling {{gtMethod:LeBlock>>#updateText:}} {{gtExample:LeDatabaseBlockUpdaterExamples>>#updateBlockOneToTwo_Simplified_Text}} 
You can also use {{gtMethod:LeBlock>>#updateString:}} {{gtExample:LeDatabaseBlockUpdaterExamples>>#updateBlockOneToTwo_Simplified_String}} 


"
Class {
	#name : #LeDatabaseSnippetUpdater,
	#superclass : #LeSnippetBuilder,
	#traits : 'TLeContentUpdater',
	#classTraits : 'TLeContentUpdater classTrait',
	#instVars : [
		'database'
	],
	#category : #'Lepiter-Core-Builders'
}

{ #category : #'api - accessing' }
LeDatabaseSnippetUpdater >> block: aSnippet [
	self 
		deprecated: 'Use #snippet: instead.' 
		transformWith: '`@receiver block: `@arg' -> '`@receiver snippet: `@arg'.
	^ self snippet: aSnippet.
]

{ #category : #'api - accessing' }
LeDatabaseSnippetUpdater >> database [
	^ database
]

{ #category : #'api - accessing' }
LeDatabaseSnippetUpdater >> database: aDatabase [
	database = aDatabase ifTrue: [ ^ self ].
	database := aDatabase.
]

{ #category : #'private - testing' }
LeDatabaseSnippetUpdater >> hasContent [
	<return: #Boolean>
	^ self snippet hasText
]

{ #category : #'private - testing' }
LeDatabaseSnippetUpdater >> hasDatabase [
	^ self database isKindOf: LeDatabase
]

{ #category : #initialization }
LeDatabaseSnippetUpdater >> initialize [
	super initialize.
	database := LeDatabase null.
]

{ #category : #'api - accessing' }
LeDatabaseSnippetUpdater >> snippet: aSnippet [
	content := aSnippet
]

{ #category : #'api - updating' }
LeDatabaseSnippetUpdater >> update [
	"Currently we update immediately for individual method calls"
	<return: #LeTextSnippet>
	^ self block
]

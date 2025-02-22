Class {
	#name : #LeAnnotationStylerVisitor,
	#superclass : #LeAnnotationParseNodeVisitor,
	#traits : 'TSmaCCComponentVisitor + (TLeAnnotationParseNodeVisitor - {#acceptNode:})',
	#classTraits : 'TSmaCCComponentVisitor classTrait + TLeAnnotationParseNodeVisitor classTrait',
	#instVars : [
		'styler',
		'normalFontSize'
	],
	#category : #'Lepiter-UI-Snippet-Text styler'
}

{ #category : #styling }
LeAnnotationStylerVisitor >> applyButtonAttributeFor: aChangesAnnotation [
	^ GtButtonAttribute new
		beAppend;
		stencil:
			(GtButtonStencilBuilder new
				label: GtDocumentConstants applyButtonLabel;
				icon: GtDocumentConstants applyButtonIcon;
				action: [ aChangesAnnotation changes applyChanges ])
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> changes [
	^ self composite changes
]

{ #category : #private }
LeAnnotationStylerVisitor >> changesFor: aChangesAnnotation [
	^ aChangesAnnotation filename
		ifNotNil: [ :fn | 
			self changes
				at: fn
				ifAbsentPut: [ | fileNameWithExtension filename changes |
					fileNameWithExtension := (fn
						endsWith: GtDocumentConstants changesFileExtension)
						ifTrue: [ fn ]
						ifFalse: [ fn , GtDocumentConstants changesFileExtension ].
					filename := self resolve: fileNameWithExtension.
					changes := GtEpicea new.
					changes ombuFile: filename.
					changes
						when: GtEpiceaUpdatedAnnouncement
						send: #handleEpiceaUpdate:
						to: self styler.
					changes ] ]
]

{ #category : #styling }
LeAnnotationStylerVisitor >> createButtonAttributeFor: aChangesAnnotation [
	^ GtButtonAttribute new
		beAppend;
		stencil:
			(GtButtonStencilBuilder new
				label: GtDocumentConstants createButtonLabel;
				icon: GtDocumentConstants createButtonIcon;
				action: [ :aButton | aButton phlow spawnObject: aChangesAnnotation changes ])
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> elements [
	^ self composite elements
]

{ #category : #private }
LeAnnotationStylerVisitor >> exampleFor: aMethodDefinition [
	^ self examples
		at: aMethodDefinition
		ifAbsentPut: [ [ | example |
			example := aMethodDefinition compiledMethod gtExample
				asExampleWithResult.
			example run.
			example ]
				on: Error
				do: [ :ex | ex return: nil ] ]
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> examples [
	^ self composite examples
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> expanded [
	^ self composite expanded
]

{ #category : #styling }
LeAnnotationStylerVisitor >> hasCursorInside: start to: end [
	self composite editor ifNil: [ ^ false ].
	^ self composite editor cursors
		anySatisfy: [ :each | each position between: start and: end ]
]

{ #category : #initialization }
LeAnnotationStylerVisitor >> initialize [
	super initialize.

	normalFontSize := 16
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> normalFontSize [
	^ normalFontSize
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> normalFontSize: anObject [
	normalFontSize := anObject
]

{ #category : #private }
LeAnnotationStylerVisitor >> resolve: aFilenameString [
	"Search for the supplied file name in the database or working directory"
	| fileReference |

	self snippetViewModel snippetModel database monitor ifNotNil: 
		[ :aMonitor |
		
		fileReference := aMonitor localRoot / aFilenameString.
		fileReference exists ifTrue: 
			[ ^ fileReference ] ].

	^ FileLocator workingDirectory / aFilenameString.
]

{ #category : #private }
LeAnnotationStylerVisitor >> restyleWhenClassChanged: aClassAnnotation [
	aClassAnnotation nameNode
		ifNotNil:
			[ :node | self styler restyleWhenClassChanged: node stringValue asSymbol ]
]

{ #category : #private }
LeAnnotationStylerVisitor >> restyleWhenMethodChanged: aMethodAnnotation [
	aMethodAnnotation nameNode
		ifNotNil: [ :node | 
			self styler
				restyleWhenMethodChanged: node methodName
				inClass:
					(node stringValue
						,
							(node classToken isNil
								ifTrue: [ '' ]
								ifFalse: [ ' class' ])) asSymbol ]
]

{ #category : #private }
LeAnnotationStylerVisitor >> showMarkup [
	^ self styler showMarkup
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> snippetViewModel [
	^ self styler snippetViewModel
]

{ #category : #private }
LeAnnotationStylerVisitor >> sourceDirectory [
	^ '.' asFileReference
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleAnnotationWithMarkup: anAnnotation [
	self utility
		subtleMarkupsInText: self text
		start: anAnnotation parent startPosition
		stop: anAnnotation parent stopPosition
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleApplyButtonFor: aChangesAnnotation [
	aChangesAnnotation changes
		ifNotNil: [ :changes | 
			changes hasImpact
				ifFalse: [ ^ self ].
			(self text
				from: aChangesAnnotation parent stopPosition
				to: aChangesAnnotation parent stopPosition)
				attribute: (self applyButtonAttributeFor: aChangesAnnotation) ]
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleAutoHidingAnnotation: anAnnotation [
	| anAttribute aMarkerAttribute aStartPosition aStopPosition aSubText |

	self showMarkup
		ifTrue: [ ^ self ].
	anAnnotation isDefined
		ifFalse: [ ^ self ].
		
	aStartPosition := anAnnotation parent startPosition - 1 max: 1.
	aStopPosition := anAnnotation parent stopPosition min: self text size.
	aSubText := self text from: aStartPosition to: aStopPosition.
	
	"when https://github.com/feenkcom/gtoolkit/issues/1430 is solved this should be refactored!
	The issue was not really solved, the associated commits solve another issue. The editor is still requiered."
	self flag: #TODO.

	aMarkerAttribute := BrTextInvisibleMarkerAttribute new.

	"so that we will be able to find where to add adornment attribute dynamically"
	aSubText attribute: aMarkerAttribute.

	anAttribute := BrTextAdornmentDynamicAttribute new
		beReplace;
		stencil: [ :aTBrTextEditorTextualPiece :anEditorElement | #() ].

	(self hasCursorInside: aStartPosition to: aStopPosition)
		ifFalse: [ aSubText attribute: anAttribute ].

	aSubText
		onCursorEnter: [ :aTextEditor |
			"we have a reference to the attribute instance. find its interval dynamically"
			aTextEditor text
				findAttribute: aMarkerAttribute
				indicesDo: [ :aStart :anEnd | | cursorIndex |
					cursorIndex := aTextEditor cursors first position.
					"and now that we know valid attribute indices we can work with them"
					(cursorIndex between: aStart-2 and: anEnd) ifTrue:
						[ (aTextEditor text
							from: aStart
							to: anEnd) clearAttributes: [ :eachAttribute | eachAttribute == anAttribute ] ] ] ]

		leave: [ :aTextEditor |
			aTextEditor text
				findAttribute: aMarkerAttribute
				indicesDo: [ :aStart :anEnd |
					(aTextEditor text 
						from: aStart
						to: anEnd) attribute: anAttribute ] ]
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleButton: anAnnotation for: object defaultLabel: aLabelBlock withTool: aBlock [
	"Style the buttons for gtClass and gtMethod annotations"
	| attribute |

	anAnnotation isDefined
		ifFalse: [ ^ self ].
		
	attribute := GtButtonAttribute new
		beAppend;
		stencil: [
			| button label |
			
			label := object
				ifNil: [ anAnnotation nameNode
						ifNil: [ '' ]
						ifNotNil: [ :name | (name value ifNil: [ name ]) source ] ]
				ifNotNil: [ :obj | 
					anAnnotation labelNode
						ifNil: [ aLabelBlock value: obj ]
						ifNotNil: [ :node | node labelFor: obj ] ].
			button := LeSnippetStylerVisitor textLinkButtonPadding: (BlInsets top: 2) margin: BlInsets empty.
			button aptitude glamorousCodeFont.
			button
				beSmallSize;
				label: label;
				action: [ :aButton | aButton phlow spawnTool: (aBlock cull: aButton) ].
			button ].

	self text
		attribute: attribute
		from: anAnnotation parent startPosition
		to: anAnnotation parent stopPosition
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleButton: anAnnotation for: object withTool: aBlock [
	self
		styleButton: anAnnotation
		for: object
		defaultLabel: #printString
		withTool: aBlock
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleButton: anAnnotation withTool: aBlock [
	self
		styleButton: anAnnotation
		for: anAnnotation imageObject
		withTool: aBlock
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleCreateButtonFor: aChangesAnnotation [
	| changes |

	changes := aChangesAnnotation changes.

	(changes notNil and: [ changes hasChanges ])
		ifFalse: [ ^ self ].

	self text
		attribute: (self createButtonAttributeFor: aChangesAnnotation)
		from: aChangesAnnotation parent stopPosition
		to: aChangesAnnotation parent stopPosition
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleExpandingExample: anExampleAnnotation [
	| attribute |

	anExampleAnnotation isDefined
		ifFalse: [ ^ self ].

	attribute := GtExamplePreviewAttribute new
		withCache: self elements key: anExampleAnnotation source;
		beAppend;
		example: anExampleAnnotation imageObject compiledMethod gtExample asExampleWithResult;
		codeExpanded: anExampleAnnotation codeExpanded;
		noCode: anExampleAnnotation noCode;
		previewExpanded: anExampleAnnotation previewExpanded;
		previewShowSelector:
			(anExampleAnnotation previewShowSelector
				ifNil: [ GtDocumentConstants defaultShowSelector ]);
		previewHeight:
			(anExampleAnnotation previewHeight
				ifNil: [ GtDocumentConstants defaultPreviewHeight ]).

	(self text
		from: anExampleAnnotation parent startPosition
		to: anExampleAnnotation parent stopPosition) attribute: attribute
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleExpandingObject: aClassAnnotation withDefault: aSymbol [
	| cacheKey attribute |
	aClassAnnotation isDefined
		ifFalse: [ ^ self ].

	cacheKey := aClassAnnotation source.
	
	attribute := GtCachedTextExpandButtonAttribute new
		isExpanded: (self expanded at: cacheKey ifAbsentPut: [ aClassAnnotation expanded ]);
		attributesCreatingBlock: [
			GtResizablePreviewAttribute new
				withCache: self elements key: cacheKey;
				result: aClassAnnotation imageObject;
				showSelector: (aClassAnnotation showSelector ifNil: [ aSymbol ]);
				height: (aClassAnnotation height ifNil: [ GtDocumentConstants defaultPreviewHeight ]) ];
		onCachingDo: [ :aBoolean :theAttribute | self expanded at: cacheKey put: aBoolean ].

	self text
		attribute: attribute
		from: aClassAnnotation parent startPosition
		to: aClassAnnotation parent stopPosition
]

{ #category : #'private - styling' }
LeAnnotationStylerVisitor >> styleLinkButton: aLink text: aSubText [
	"Style the buttons for gtPage annotations"

	aSubText
		appendingAdornment: [ :aTBrTextEditorTextualPiece :anEditorElement | 
			| button page |
			page := self snippetViewModel snippetModel outgoingTextualLinks
				detect: [ :eachLink | eachLink node = aLink ]
				ifFound: [ :theLink | theLink target ]
				ifNone: [ nil ].
			button := LeSnippetStylerVisitor 
				textLinkButtonPadding: aTBrTextEditorTextualPiece wordPadding 
				margin: aTBrTextEditorTextualPiece wordMargin
				valid: page isNotNil.
			button 
				model: page;
				label: aLink linkUID;
				action: [ :aButton | self snippetViewModel snippetModel spawnLinkTarget: aLink from: aButton ].
			button ]
]

{ #category : #styling }
LeAnnotationStylerVisitor >> styleName: aClassAnnotation spawning: aBlock [
	| nameNode aLinkColor |

	(nameNode := aClassAnnotation nameNode)
		ifNil: [ ^ self ].

	aLinkColor := nameNode isDefined
		ifTrue: [ BrGlamorousColors textMarkupColor ]
		ifFalse: [ BrGlamorousColors linkWithErrorColor ].

	(self text from: nameNode startPosition to: nameNode stopPosition)
		foreground: aLinkColor
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> styler [
	^ composite styler
]

{ #category : #accessing }
LeAnnotationStylerVisitor >> text [
	^ self composite text
]

{ #category : #styling }
LeAnnotationStylerVisitor >> utility [
	^ GtDocumentUtility
]

{ #category : #visiting }
LeAnnotationStylerVisitor >> visitAnnotation: anAnnotation [
	self styleAnnotationWithMarkup: anAnnotation.
	self styleAutoHidingAnnotation: anAnnotation.
	super visitAnnotation: anAnnotation
]

{ #category : #visiting }
LeAnnotationStylerVisitor >> visitChangesAnnotation: aChangesAnnotation [
	(self changesFor: aChangesAnnotation)
		ifNotNil: [ :changes | 
			aChangesAnnotation changes: changes.
			self styler subscribeToSystem ].
	super visitChangesAnnotation: aChangesAnnotation.
	self
		styleButton: aChangesAnnotation
		for: aChangesAnnotation imageObject
		defaultLabel: [ :obj | obj ombuFile basename ]
		withTool: [ GtPhlowTool default object: aChangesAnnotation imageObject ].
	self
		styleExpandingObject: aChangesAnnotation
		withDefault: GtDocumentConstants defaultChangesShowSelector.
	self styleApplyButtonFor: aChangesAnnotation
]

{ #category : #visiting }
LeAnnotationStylerVisitor >> visitClassAnnotation: aClassAnnotation [

	super visitClassAnnotation: aClassAnnotation.
	self restyleWhenClassChanged: aClassAnnotation.
	self
		styleName: aClassAnnotation
		spawning: [ :anEvent | 
			anEvent target phlow
				spawnTool: (GtClassCoderTool observedClass: aClassAnnotation imageObject) ].
	self
		styleButton: aClassAnnotation
		withTool: [ GtClassCoderTool forClass: aClassAnnotation imageObject ].
	self
		styleExpandingObject: aClassAnnotation
		withDefault: GtDocumentConstants defaultClassShowSelector
]

{ #category : #visiting }
LeAnnotationStylerVisitor >> visitExampleAnnotation: anExampleAnnotation [
	| result |
	super visitExampleAnnotation: anExampleAnnotation.
	self restyleWhenMethodChanged: anExampleAnnotation.
	self
		styleName: anExampleAnnotation
		spawning:
			[ :anEvent | anEvent target phlow spawnObject: anExampleAnnotation imageObject ].
	result := (self exampleFor: anExampleAnnotation imageObject)
		ifNotNil: [ :example | 
			example hasResult
				ifTrue: [ example result returnValue ] ].
	anExampleAnnotation hasLabel
		ifTrue: [ self
				styleButton: anExampleAnnotation
				for: result
				withTool: [ GtPhlowTool default object: result ] ]
		ifFalse: [ self styleExpandingExample: anExampleAnnotation ]
]

{ #category : #visiting }
LeAnnotationStylerVisitor >> visitMethodAnnotation: aMethodAnnotation [
	super visitMethodAnnotation: aMethodAnnotation.
	self restyleWhenMethodChanged: aMethodAnnotation.
	self
		styleName: aMethodAnnotation
		spawning:
			[ :anEvent | anEvent target phlow spawnObject: aMethodAnnotation imageObject ].
	self
		styleButton: aMethodAnnotation
		withTool: [ GtMethodCoderTool compiledMethod: aMethodAnnotation imageObject ].
	self
		styleExpandingObject: aMethodAnnotation
		withDefault: GtDocumentConstants defaultMethodShowSelector
]

{ #category : #generated }
LeAnnotationStylerVisitor >> visitPageAnnotation: aPageAnnotation [
	| linkText |

	super visitPageAnnotation: aPageAnnotation.
	linkText := self text
		from: aPageAnnotation parent startPosition
		to: aPageAnnotation parent stopPosition.
	self styleLinkButton: aPageAnnotation text: linkText.

]

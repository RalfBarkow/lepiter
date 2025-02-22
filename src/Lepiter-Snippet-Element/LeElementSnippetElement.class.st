"
LeElementSnippetElement displays the result of a code snippet, which must return an object that responds to #asElement.

Clicking on the ""Browse Code"" button opens a snippet editor for modifying the source snippet.

"
Class {
	#name : #LeElementSnippetElement,
	#superclass : #LeTextualSnippetElement,
	#traits : 'TBlElementError',
	#classTraits : 'TBlElementError classTrait',
	#instVars : [
		'sceneContainer',
		'elementContainer',
		'coderElement',
		'coderToolbar',
		'coderDecorationBar',
		'coderContainer',
		'snippetResizer',
		'coderResizer',
		'showCoderToggle',
		'maximizerLook'
	],
	#category : #'Lepiter-Snippet-Element-Snippet'
}

{ #category : #initialization }
LeElementSnippetElement >> createCoderContainer [
	^ BlElement new
		layout: (BlGridLayout horizontal columnCount: 2);
		padding: (BlInsets all: 5);
		constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ]
]

{ #category : #initialization }
LeElementSnippetElement >> createCoderDecorationBar [
	^ BlElement new
		constraintsDo: [ :c |
			c horizontal exact: 8.
			c vertical matchParent ];
		geometry: (BlRoundedRectangleGeometry cornerRadii: (BlCornerRadii new topLeft: 4; topRight: 0; bottomRight: 0; bottomLeft: 4))
]

{ #category : #initialization }
LeElementSnippetElement >> createCoderElement [
	^ GtSourceCoderEditorElement new
		padding: (BlInsets top: 5 left: 7 bottom: 5 right: 0);
		margin: BlInsets empty;
		vExact: 100;
		hMatchParent
]

{ #category : #initialization }
LeElementSnippetElement >> createCoderToolbar [
	^ GtCoderActionsElement new
		margin: (BlInsets left: 5)
]

{ #category : #initialization }
LeElementSnippetElement >> createElementContainer [
	^ BrHorizontalPane new
		hMatchParent;
		vExact: 100;
		padding: (BlInsets all: 5)
]

{ #category : #initialization }
LeElementSnippetElement >> createSceneContainer [
	^ BrVerticalPane new
		hMatchParent;
		vFitContent;
		clipChildren: false
]

{ #category : #initialization }
LeElementSnippetElement >> createShowCodeToggleButton [
	^ BrToggle new
		beSmallSize;
		constraintsDo: [ :c |
			c ignoreByLayout.
			c ignored horizontal alignRight.
			c ignored vertical alignBottom ];
		margin: (BlInsets all: 10);
		padding: (BlInsets all: 10);
		zIndex: 10;
		aptitude: BrGlamorousButtonWithIconAptitude + BrGlamorousToggleBackgroundAptitude;
		icon: BrGlamorousIcons browse asElement;
		label: 'Browse Code' asString;
		when: BrToggleActivatedEvent
			do: [ :anEvent | self snippetViewModel showCode ];
		when: BrToggleDeactivatedEvent
			do: [ :anEvent | self snippetViewModel hideCode ];
		yourself
]

{ #category : #initialization }
LeElementSnippetElement >> createVerticalResizer [
	^ BrResizer new
		aptitude: BrGlamorousResizerAptitude;
		elevation: (BlRelativeElevation elevation: 1000);
		beBottom;
		constraintsDo: [ :c | c ignoreByLayout ]
]

{ #category : #accessing }
LeElementSnippetElement >> editor [ 
	"Answer the current editor element"

	^ coderElement
]

{ #category : #'private - coder' }
LeElementSnippetElement >> ensureCoderCreated [
	"The coder element is initialized lazily only when view model's #shouldShowCode is true"
	
	self isCoderCreated
		ifTrue: [ ^ self ].

	coderElement := self createCoderElement.
	coderElement editor addEventHandler: (LeEditorReachedBorderEventHandler new snippetElement: self).
	coderDecorationBar := self createCoderDecorationBar.
	coderToolbar := self createCoderToolbar.

	coderContainer := self createCoderContainer.
	coderContainer
		addChild: coderDecorationBar;
		addChild: coderElement;
		addChild: coderToolbar
]

{ #category : #accessing }
LeElementSnippetElement >> exceptionAction [

	^ [
		elementContainer removeChildNamed: #displayElement.
		exception ifNotNil: [ | exceptionElement |
				exceptionElement := (self errorStencil arguments: { exception }) create.
				exceptionElement constraintsDo: [ :c | 
					c horizontal fitContent.
					c vertical fitContent.
					c frame vertical alignCenter.
					c frame horizontal alignCenter ].
				elementContainer addChild: exceptionElement as: #displayElement ] ]
]

{ #category : #private }
LeElementSnippetElement >> generateDisplayElement [
	[[		
		self snippetViewModel doItAllRequestedBy: self ]
		on: Error
			do: [ :ex | self exception: ex ]]
		on: GtCoderEvaluationUnhandledError
			do: [ :ex | self exception: ex exception ]
]

{ #category : #'private - coder' }
LeElementSnippetElement >> hideCoder [	
	self isCoderCreated
		ifFalse: [ ^ self ].
	
	(sceneContainer hasChild: coderContainer)
		ifTrue: [ sceneContainer removeChild: coderContainer ].
	
	(elementContainer hasChild: coderResizer)
		ifTrue: [ elementContainer removeChild: coderResizer ]
]

{ #category : #initialization }
LeElementSnippetElement >> initialize [
	super initialize.
	
	self vFitContent.
	self hMatchParent.
	
	sceneContainer := self createSceneContainer.
	elementContainer := self createElementContainer.

	sceneContainer addChild: elementContainer as: #elementContainer.
	sceneContainer addChild: (snippetResizer := self createVerticalResizer
		target: elementContainer;
		when: BlResizerResizedEvent do: [ :anEvent |
			self snippetViewModel setElementHeightTo: anEvent extent y ]).

	showCoderToggle := self createShowCodeToggleButton.
	sceneContainer addChild: showCoderToggle.
	sceneContainer addAptitude: (maximizerLook := BrGlamorousWithMaximizerAptitude new
			// #displayElement;
			preferredBackground: BrGlamorousColors backdropColor).

	self onSnippetViewModelFocused: false
]

{ #category : #initialization }
LeElementSnippetElement >> initializeCoderAddOns: anObject [
	"Initialise the keyboard shortcuts in the code editor"

	anObject addOns
		"Create New snippet (after the current snippet)"
		addShortcut: (LeSnippetSplitSnippetShortcut new combination: (self keyboardShortcut: #SplitSnippet));
		"Delete previous character, or merge with previous snippet"	
		addShortcut: (LeSnippetDeletePreviousShortcut new combination: (self keyboardShortcut: #DeletePrevious));
		"Indent LeSnippet"
		addShortcut: (LeSnippetIndentSnippetShortcut new combination: (self keyboardShortcut: #IndentSnippet));
		"Unindent LeSnippet"
		addShortcut: (LeSnippetUnindentSnippetShortcut new combination: (self keyboardShortcut: #UnindentSnippet));
		"Move Snippet up"
		addShortcut: (LeSnippetMoveSnippetUpShortcut new combination: (self keyboardShortcut: #MoveSnippetUp));
		"Move Snippet down"
		addShortcut: (LeSnippetMoveSnippetDownShortcut new combination: (self keyboardShortcut: #MoveSnippetDown))
]

{ #category : #'private - coder' }
LeElementSnippetElement >> isCoderCreated [
	<return: #Boolean>

	^ coderContainer notNil
]

{ #category : #'private - event handling' }
LeElementSnippetElement >> onCodeEvaluated: anEvaluatedAnnouncement [
	(anEvaluatedAnnouncement isRequestedByElementOrItsChild: self)
		ifFalse: [ ^ self ].

	self setElement: [ anEvaluatedAnnouncement evaluationResult value ]
]

{ #category : #'private - event handling' }
LeElementSnippetElement >> onCodeVisibilityChanged [
	self snippetViewModel shouldShowCode
		ifTrue: [ self showCoder ]
		ifFalse: [ self hideCoder ].
		
	showCoderToggle activated: self snippetViewModel shouldShowCode
]

{ #category : #'private - event handling' }
LeElementSnippetElement >> onHeightChanged [
	elementContainer vExact: self snippetViewModel elementHeight.
	self updateCoderHeight
]

{ #category : #'private - event handling' }
LeElementSnippetElement >> onPageChildEvaluated: aLeUIPageChildEvaluationAnnouncement [
	snippetViewModel ifNotNil: [ self snippetViewModel coderViewModel coder requestStyleSourceText ]
]

{ #category : #'api - snippet view model' }
LeElementSnippetElement >> onPostSnippetViewModelChanged [
	super onPostSnippetViewModelChanged.
	
	self snippetViewModel displayElement
		ifNotNil: [ :anElement | self setElement: [ anElement ] asStencil ]
		ifNil: [ self generateDisplayElement ]
]

{ #category : #'api - snippet view model' }
LeElementSnippetElement >> onSnippetViewModelChanged [
	super onSnippetViewModelChanged.

	self onCodeVisibilityChanged.
	self onHeightChanged.

	self updateCoderElementViewModel
]

{ #category : #'api - snippet view model' }
LeElementSnippetElement >> onSnippetViewModelFocused: aBoolean [
	"Override me to either request or lose focus when the focused state is changed in the UI Model"

	(aBoolean and: [ self snippetViewModel isCoderFocused not ])
		ifTrue: [ sceneContainer requestFocus ].

	aBoolean
		ifFalse: [ sceneContainer loseFocus ].

	aBoolean
		ifTrue: [ snippetResizer visibility: BlVisibility visible ]
		ifFalse: [ snippetResizer visibility: BlVisibility gone ].
		
	aBoolean
		ifTrue: [ showCoderToggle visibility: BlVisibility visible ]
		ifFalse: [ showCoderToggle visibility: BlVisibility gone ].
		
	aBoolean
		ifTrue: [ maximizerLook showMaximizeButton ]
		ifFalse: [ maximizerLook hideMaximizeButton ].
		
	self updateCoderWhenFocused: aBoolean
]

{ #category : #initialization }
LeElementSnippetElement >> registerEventsForCoder: aCoder [

	aCoder announcer weak
		when: GtCoderEvaluationAnnouncement
		send: #onCodeEvaluated:
		to: self
]

{ #category : #private }
LeElementSnippetElement >> setElement: anElementStencil [
	"Set the value of the supplied stencil as the receiver's display element"
	| displayElement |

	displayElement := [ anElementStencil value 
			ifNil: [ BlElement new ]
			ifNotNil: [ :element | element asElement ] ]
		on: Error 
		do: [ :ex | ^ self exception: ex ].
	
	elementContainer removeChildNamed: #displayElement.
	displayElement removeFromParent.
	elementContainer addChild: displayElement as: #displayElement.

	self snippetViewModel displayElement: displayElement
]

{ #category : #'private - coder' }
LeElementSnippetElement >> showCoder [		
	self ensureCoderCreated.
	
	(sceneContainer hasChild: coderContainer)
		ifTrue: [ ^ self ].
		
	sceneContainer addChild: coderContainer.
	
	elementContainer addChild: (coderResizer := self createVerticalResizer
		target: elementContainer;
		when: BlResizerResizedEvent do: [ :anEvent |
			self snippetViewModel resizeElementHeightTo: anEvent extent y ]).

	self updateCoderWhenFocused: self snippetViewModel focused.
	self updateCoderHeight.
	self updateCoderElementViewModel
]

{ #category : #'api - view' }
LeElementSnippetElement >> snippetContent [
	"Return an element that represents a content of the snippet.
	The embedder is responsible for placing #snippetContent in the right place within snippet element depending on the
	View Model properties and derived look"
	<return: #BlElement>

	^ sceneContainer
]

{ #category : #'api - view' }
LeElementSnippetElement >> snippetToolbar [
	"Return an element that represents a toolbar of the snippet. A toolbar usually appears below the snippet content.
	The embedder is responsible for placing #snippetToolbar in the right place within snippet element depending on the
	View Model properties and derived look.
	If returned #snippetToolbar is nil, no toolbar will be added"
	<return: #BlElement or: nil>

	^ nil
]

{ #category : #'api - snippet view model' }
LeElementSnippetElement >> subscribeToSnippetViewModel [
	super subscribeToSnippetViewModel.

	self snippet weak
		when: LeUIPageChildEvaluationAnnouncement
		send: #onPageChildEvaluated:
		to: self.

	self snippetViewModel weak
		when: LeElementSnippetViewModelHeightChanged
		send: #onHeightChanged
		to: self.
		
	self snippetViewModel weak
		when: LeElementSnippetViewModelCodeVisibilityChanged
		send: #onCodeVisibilityChanged
		to: self.
		
	self snippetViewModel coderViewModel coder weak
		when: GtCoderEvaluationAnnouncement
		send: #onCodeEvaluated:
		to: self
]

{ #category : #'api - snippet view model' }
LeElementSnippetElement >> unsubscribeFromSnippetViewModel [
	super unsubscribeFromSnippetViewModel.

	self snippet unsubscribe: self.
	self snippetViewModel unsubscribe: self.
	self snippetViewModel coderViewModel coder unsubscribe: self
]

{ #category : #'private - coder' }
LeElementSnippetElement >> updateCoderElementViewModel [
	self isCoderCreated
		ifFalse: [ ^ self ].

	coderElement textualCoderViewModel: self snippetViewModel coderViewModel.
	coderToolbar textualCoderViewModel: self snippetViewModel coderViewModel
]

{ #category : #'private - coder' }
LeElementSnippetElement >> updateCoderHeight [
	self isCoderCreated
		ifFalse: [ ^ self ].

	coderElement vExact: self snippetViewModel codeHeight
]

{ #category : #'private - coder' }
LeElementSnippetElement >> updateCoderWhenFocused: isFocused [
	self isCoderCreated
		ifFalse: [ ^ self ].

	isFocused
		ifTrue: [ coderResizer visibility: BlVisibility visible ]
		ifFalse: [ coderResizer visibility: BlVisibility gone ].

	isFocused
		ifTrue: [
			coderDecorationBar constraintsDo: [ :c | c grid vertical span: 2 ].
			coderDecorationBar background: (BrGlamorousColors primaryBorderColor alpha: 0.4) gtOpaqueColorOnWhite ]
		ifFalse: [
			coderDecorationBar constraintsDo: [ :c | c grid vertical span: 1 ].
			coderDecorationBar background: BrGlamorousColors lightBorderColor ].
			
	isFocused
		ifTrue: [
			coderToolbar constraintsDo: [ :c | c grid horizontal span: 1 ].
			coderToolbar visibility: BlVisibility visible ]
		ifFalse: [
			coderToolbar constraintsDo: [ :c | c grid horizontal span: 2 ].
			coderToolbar visibility: BlVisibility hidden ]
]

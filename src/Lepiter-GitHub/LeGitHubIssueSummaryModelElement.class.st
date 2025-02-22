Class {
	#name : #LeGitHubIssueSummaryModelElement,
	#superclass : #LeGitHubModelElement,
	#instVars : [
		'titleElement',
		'bodyElement'
	],
	#category : #'Lepiter-GitHub-UI Model Elements'
}

{ #category : #'private - accessing' }
LeGitHubIssueSummaryModelElement >> bodyElement [
	<return: #BrEditor>
	^ bodyElement
]

{ #category : #initialization }
LeGitHubIssueSummaryModelElement >> initialize [
	super initialize.
	self initializeTitleElement.
	self initializeBodyElement.
	
	self addChild: self titleElement as: #title.
	self addChild: self bodyElement as: #body.
	
	self addAptitude: (BrLayoutResizerAptitude inherit 
		anyToFitContent: self titleElement;
		hInherit: self bodyElement;
		vAnyToFitContent: self bodyElement).
]

{ #category : #initialization }
LeGitHubIssueSummaryModelElement >> initializeBodyElement [
	bodyElement := BrEditor new
		beReadOnlyWithSelection;
		aptitude: BrGlamorousRegularEditorAptitude;
		styler: LeSnippetStyler new;
		hMatchParent;
		vFitContentLimited.
]

{ #category : #initialization }
LeGitHubIssueSummaryModelElement >> initializeTitleElement [
	titleElement := BrLabel new
		text: '';
		beLargeSize;
		aptitude: (BrGlamorousLabelAptitude new bold);
		fitContent.
]

{ #category : #'private - accessing' }
LeGitHubIssueSummaryModelElement >> titleElement [
	<return: #BrLabel>
	^ titleElement
]

{ #category : #'private - updating' }
LeGitHubIssueSummaryModelElement >> updateElement [
	super updateElement.
	self titleElement text: self model title.
	self bodyElement text: self model body.
]

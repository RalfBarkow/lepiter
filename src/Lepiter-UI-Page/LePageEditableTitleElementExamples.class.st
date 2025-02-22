Class {
	#name : #LePageEditableTitleElementExamples,
	#superclass : #Object,
	#category : #'Lepiter-UI-Page-Examples'
}

{ #category : #'examples - page - editable title' }
LePageEditableTitleElementExamples >> basicPageEditableTitleElement [
	<gtExample>
	| anElement |
	anElement := LePageEditableTitleElement new.
	self assert: anElement hasPage not.
	^ anElement
]

{ #category : #'private - instance creation' }
LePageEditableTitleElementExamples >> database [
	<gtExample>
	| database folderReference localStore  |
	folderReference := FileSystem memory / 'storage-main'.
	folderReference ensureCreateDirectory.

	localStore := LeLocalStoreLoad current.
	localStore localRoot: folderReference.
	database := localStore loadAndMonitorFrom: folderReference.
	self assert: database explicitLinks size equals: 0.
	^ database
]

{ #category : #'private - instance creation' }
LePageEditableTitleElementExamples >> databaseWithPageAAndLinkToPageB [
	<gtExample>
	| aDatabase |
	aDatabase := self database.
	(aDatabase pageBuilder title: 'a'; add)
		snippetBuilder string: '[[b]]'; add.
	^ aDatabase	
]

{ #category : #'private - instance creation' }
LePageEditableTitleElementExamples >> databaseWithTwoPagesAndTwoDailyNotes [
	<gtExample>
	| aDatabase |
	aDatabase := self titledPageWithBlockHierachy database.
	aDatabase pageBuilder title: 'two'; add.
	aDatabase pageBuilder noteOf: Date today; add.
	aDatabase pageBuilder noteOf: Date yesterday; add.
	^ aDatabase
]

{ #category : #'examples - page - editable title' }
LePageEditableTitleElementExamples >> pageEditableTitleElement_ApprovedTitleRename [
	<gtExample>
	| anElement aPage aDatabase |
	anElement := self basicPageEditableTitleElement.
	aDatabase := self databaseWithTwoPagesAndTwoDailyNotes.
	aPage := aDatabase pageBuilder title: 'one'; ensure.
	anElement pageViewModel: (LePageViewModel new pageModel: aPage).
	anElement titleElement 
		switchToEditor;
		text: 'three';
		acceptEdition.
	self assert: anElement titleElement text asString equals: aPage title.
	self assert: anElement titleElement text asString equals: 'three'.
	^ anElement
]

{ #category : #'examples - page - editable title' }
LePageEditableTitleElementExamples >> pageEditableTitleElement_DisapprovedTitleRename [
	<gtExample>
	| anElement aPage aDatabase |
	anElement := self basicPageEditableTitleElement.
	aDatabase := self databaseWithTwoPagesAndTwoDailyNotes.
	aPage := aDatabase pageBuilder title: 'one'; ensure.
	anElement pageViewModel: (LePageViewModel new pageModel: aPage).
	anElement titleElement 
		switchToEditor;
		text: 'two';
		acceptEdition.
	self assert: anElement titleElement text asString equals: aPage title.
	self assert: anElement titleElement text asString equals: 'one'.
	^ anElement
]

{ #category : #'examples - page - editable title' }
LePageEditableTitleElementExamples >> pageEditableTitleElement_LongTitle [
	<gtExample>
	| anElement aPage |
	anElement := self basicPageEditableTitleElement.
	aPage := self titledPage.
	aPage updateTitle: (String loremIpsum: 108).

	anElement pageViewModel: (LePageViewModel new pageModel: aPage).
	
	self assert: anElement titleElement text asString equals: aPage title.
	^ anElement
]

{ #category : #'examples - page - editable title' }
LePageEditableTitleElementExamples >> pageEditableTitleElement_RenamePageBToC [
	<gtExample>
	| anElement aPage aDatabase |
	anElement := self basicPageEditableTitleElement.
	aDatabase := self databaseWithPageAAndLinkToPageB.
	aPage := aDatabase pageBuilder title: 'b'; add.

	anElement pageViewModel: (LePageViewModel new pageModel: aPage).
	anElement titleElement 
		switchToEditor;
		text: 'c';
		acceptEdition.
	self assert: aPage database equals: aDatabase.
	self assert: anElement titleElement text asString equals: aPage title.
	self assert: anElement titleElement text asString equals: 'c'.
	^ anElement
]

{ #category : #'examples - page - editable title' }
LePageEditableTitleElementExamples >> pageEditableTitleElement_TitledPage [
	<gtExample>
	| anElement aPage |
	anElement := self basicPageEditableTitleElement.
	aPage := self titledPage.
	anElement pageViewModel: (LePageViewModel new pageModel: aPage).
	self assert: anElement titleElement text asString equals: aPage title.
	^ anElement
]

{ #category : #'examples - page - editable title' }
LePageEditableTitleElementExamples >> pageEditableTitleElement_UntitledPage [
	<gtExample>
	| anElement aPage |
	anElement := self basicPageEditableTitleElement.
	aPage := self untitledPage.
	anElement pageViewModel: (LePageViewModel new pageModel: aPage).
	self assert: anElement titleElement text asString equals: aPage title.
	^ anElement
]

{ #category : #'private - instance creation' }
LePageEditableTitleElementExamples >> titledPage [
	<gtExample>

	^ self database pageBuilder title: 'one'; add
]

{ #category : #'private - instance creation' }
LePageEditableTitleElementExamples >> titledPageWithBlockHierachy [
	<gtExample>
	| aPage aSnippetOne aSnippetTwo |
	aPage := self database pageBuilder title: 'one'; add.
	aSnippetOne := aPage snippetBuilder string: 'block one > one'; add.
	aSnippetTwo := aPage snippetBuilder string: 'block one > two'; add.
	aSnippetOne snippetBuilder string: 'block one > one > one'; add.
	aSnippetOne snippetBuilder string: 'block one > one > two'; add.
	aSnippetTwo snippetBuilder string: 'block one > two > one'; add.
	aSnippetTwo snippetBuilder string: 'block one > two > two'; add.
	^ aPage
]

{ #category : #'private - instance creation' }
LePageEditableTitleElementExamples >> untitledPage [
	<gtExample>
	^ self database pageBuilder addOnlyAfterSettingTitle
]

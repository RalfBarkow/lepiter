"
LeWorldStatusDropdown provides a traffic light style button that provides a quick indication of the status of the (logical) database in LeWorld:

Red = something wrong - the monitor isn't running or there are corrupt files.
Yellow = there's unsaved pages (which is normal for a while)
Green = running and everything saved.

Pressing the button provides a detailed view of the cause of the current status.

LeWorldStatusDropdown listens directly to the database for page changes and to the monitor for page saves, rather than relying on the monitor for all information to help catch the case where the monitor may not be receiving announcements from the DB for whatever reason.

"
Class {
	#name : #LeWorldStatusDropdown,
	#superclass : #BlElement,
	#instVars : [
		'leWorldElement',
		'dropdownElement',
		'currentDropdownContent',
		'listElement',
		'pageChanged',
		'updateRequester'
	],
	#category : #'Lepiter-Tool-UI'
}

{ #category : #accessing }
LeWorldStatusDropdown >> databases [
	leWorldElement database ifNil: [ ^ #() ].
	^ leWorldElement database isLogicalDatabase
		ifTrue: [ leWorldElement database databases ]
		ifFalse: [ { leWorldElement database } ]
]

{ #category : #'building widgets' }
LeWorldStatusDropdown >> dropdownContent [
	^ currentDropdownContent ifNil: [ 
		currentDropdownContent := self newDropdownContent ].
]

{ #category : #'accessing - elements' }
LeWorldStatusDropdown >> dropdownElement [
	^ dropdownElement
]

{ #category : #testing }
LeWorldStatusDropdown >> hasPendingChanges [
	"Answer a boolean indicating whether any database has pending changes"

	^ leWorldElement database 
		ifNotNil: [ :aDatabase |
			aDatabase localSyncMonitorStatus hasPendingChanges ]
		ifNil: [ false ]
]

{ #category : #initialization }
LeWorldStatusDropdown >> initialize [
	super initialize.
	pageChanged := false.
	self layout: BlFrameLayout new.
	self constraintsDo: [ :c |
		c vertical fitContent.
		c horizontal fitContent ].
	 
	self addInteractiveModelState: BrLayoutHorizontalResizerModel fitContent.
	self addInteractiveModelState: BrLayoutVerticalResizerModel fitContent.
	
	self initializeDropdownElement.
	updateRequester := GtPhlowUpdateRequester new
		element: self selector: #updateContent.
	
	self addChild: self dropdownElement as: #dropdown.
	
	self addAptitude: (BrLayoutResizerAptitude new
		anyToFitContent: self).

]

{ #category : #initialization }
LeWorldStatusDropdown >> initializeDropdownElement [
	dropdownElement := self newButton
		label: self tooltip;
		addAptitude: (BrGlamorousWithDropdownAptitude
			handle: [ self newDropdownButton ]
			content: [ self reusedDropdownContent ])
]

{ #category : #accessing }
LeWorldStatusDropdown >> leWorldElement [
	^ leWorldElement
]

{ #category : #accessing }
LeWorldStatusDropdown >> leWorldElement: aLeWorld [

	leWorldElement ifNotNil: [ 
		leWorldElement announcer unsubscribe: self.
		leWorldElement database unsubscribe: self ].
	
	leWorldElement := aLeWorld.
	leWorldElement announcer
		when: LeWorldElementDatabaseChanged 
		send: #onDatabaseChanged
		to: self.
	leWorldElement announcer
		when: LeWorldElementDatabaseRemoved
		send: #onDatabaseRemoved:
		to: self
]

{ #category : #'building widgets' }
LeWorldStatusDropdown >> newButton [
	^ BrButton new
		icon: self statusIcon;
		aptitude: BrGlamorousButtonWithIconAptitude 
			- BrGlamorousButtonExteriorAptitude
]

{ #category : #'building widgets' }
LeWorldStatusDropdown >> newDropdownButton [
	^ BrButton new
		icon: self statusIcon;
		label: self tooltip;
		aptitude: BrGlamorousButtonWithIconAptitude 
			- BrGlamorousButtonWithLabelTooltipAptitude
			- BrGlamorousButtonExteriorAptitude 
]

{ #category : #'building widgets' }
LeWorldStatusDropdown >> newDropdownContent [
	| container |
	container := BrFrame new
		exact: 600@400.
	listElement := self newListElement.
	container addChild: listElement.
	^ container
]

{ #category : #'building widgets' }
LeWorldStatusDropdown >> newListElement [
	^ (self newListViewFor: GtPhlowEmptyView new)
		asElementDo: [ :e | e ]
]

{ #category : #'building widgets' }
LeWorldStatusDropdown >> newListViewFor: aView [
	^ aView columnedList
		title: 'Databases';
		items: [ self databases ];
		column: 'Database' 
			text: [ :aDatabase | 
				aDatabase databaseName ]
			width: 300;
		column: 'Local Sync'
			icon: [ :aDatabase | 
				aDatabase localSyncMonitorStatus statusWidget ]
			width: 200
]

{ #category : #callbacks }
LeWorldStatusDropdown >> onDatabaseChanged [

	self registerDatabaseEvents.
	self updateWidget
]

{ #category : #callbacks }
LeWorldStatusDropdown >> onDatabaseRemoved: anAnnouncement [ 
	anAnnouncement database ifNotNil: [ :aKnowledgeBase |
		aKnowledgeBase unsubscribe: self.
		aKnowledgeBase databases
			select: [ :db | db monitor isNotNil ]
			thenDo: [ :db |
				db monitor unsubscribe: self ] ]
]

{ #category : #callbacks }
LeWorldStatusDropdown >> onDbSaved [

	pageChanged := self hasPendingChanges.
	self updateWidget
]

{ #category : #callbacks }
LeWorldStatusDropdown >> onPageChanged: anAnnouncement [ 

	pageChanged ifTrue: 
		[ ^ self ].
	pageChanged := true.
	self updateWidget.
	StringSignal emit: 'set page changed'.
]

{ #category : #private }
LeWorldStatusDropdown >> registerDatabaseEvents [
	leWorldElement database ifNotNil: [ :database |
		database weak when: LeSnippetContentChanged send: #onPageChanged: to: self.
		database weak when: LeContentTreeChanged send: #onPageChanged: to: self.
		database weak when: LeDatabasePageAdded send: #onPageChanged: to: self.
		database weak when: LeDatabasePageRemoved send: #onPageChanged: to: self.
		database weak when: LePageTitleChanged send: #onPageChanged: to: self.
		self databases
			select: [ :db | db monitor isNotNil ]
			thenDo: [ :db |
				db monitor weak
					when: LeLocalStoreMonitorSaved 
					send: #onDbSaved 
					to: self ] ].
]

{ #category : #updating }
LeWorldStatusDropdown >> requestUpdate [
	self updateRequester ifNotNil: [ :anUpdateRequester | 
		anUpdateRequester requestUpdate ]
]

{ #category : #'building widgets' }
LeWorldStatusDropdown >> reusedDropdownContent [
	| dropdown |

	dropdown := self dropdownContent.
	^ dropdown removeFromParent
]

{ #category : #private }
LeWorldStatusDropdown >> statusIcon [
	"Answer the icon to display in the receiver's button"
	
	"Report an error in case we do not have a database."
	(leWorldElement isNil or: [ 
		leWorldElement database isNil ]) 
			ifTrue: [ ^ BrGlamorousIcons redcircle ].
	
	^ leWorldElement database localSyncMonitorStatus statusIcon
]

{ #category : #private }
LeWorldStatusDropdown >> tooltip [
	^ 'Lepiter KnowledgeBase Status'
]

{ #category : #updating }
LeWorldStatusDropdown >> updateContent [ 
	currentDropdownContent ifNil: [ ^ self ].
	currentDropdownContent removeChildren. 
	currentDropdownContent addChild: self newDropdownContent.
]

{ #category : #accessing }
LeWorldStatusDropdown >> updateRequester [
	^ updateRequester
]

{ #category : #updating }
LeWorldStatusDropdown >> updateStatus [

	dropdownElement enqueueTask: 
		(BlTaskAction new action: [ dropdownElement icon: self statusIcon ]).

]

{ #category : #updating }
LeWorldStatusDropdown >> updateWidget [
	self updateStatus.
	self requestUpdate.
]

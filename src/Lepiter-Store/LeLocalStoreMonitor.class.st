"
{{gtClass:LeLocalStoreMonitor}} listens to its {{gtClass:LeDatabase}} and saves pages back to disk whenever the page is updated (added, content modified, title changed, removed).

The monitor subscribes to announcements from the database and adds them to a queue of pages to be saved.   After each saveDelay has elapsed it saves all the pages back to the store.  See {{gtMethod:name=LeLocalStoreMonitor>>#defaultDelay}} for the default value.

The monitor can be in one of two states:

- running - it is listening to the database for changes and saving them.
- stopped - it isn't listening.

 
## Internal Representation and Key Implementation Points.

### Instance Variables
	saveDelay:		<Duration>
	state: 			<Symbol>


### Implementation Points

"
Class {
	#name : #LeLocalStoreMonitor,
	#superclass : #LeLocalStore,
	#traits : 'TGtAnnouncer',
	#classTraits : 'TGtAnnouncer classTrait',
	#instVars : [
		'saveDelay',
		'saveQueue',
		'removeQueue',
		'state',
		'corruptFiles',
		'announcer'
	],
	#classVars : [
		'NoStartup',
		'SessionAnnouncer'
	],
	#category : #'Lepiter-Store-LocalJSON-Store'
}

{ #category : #'system startup' }
LeLocalStoreMonitor class >> clearNoStartup [
	"Clear the flag to say that Lepiter startup actions should be ignored"

	NoStartup := false.
]

{ #category : #'api - accessing' }
LeLocalStoreMonitor class >> database: aLeDatabase root: aFileReference [

	^ self new 
		database: aLeDatabase;
		localRoot: aFileReference;
		yourself
]

{ #category : #'class initialization' }
LeLocalStoreMonitor class >> initialize [ 

	SessionManager default 
		registerUserClassNamed: self name.
	NoStartup := false.
]

{ #category : #accessing }
LeLocalStoreMonitor class >> sessionAnnouncer [

	^ SessionAnnouncer ifNil: [ SessionAnnouncer := Announcer new ]
]

{ #category : #'system startup' }
LeLocalStoreMonitor class >> setNoStartup [
	"Set the flag to say that Lepiter startup actions should be ignored"

	NoStartup := true.
]

{ #category : #'system startup' }
LeLocalStoreMonitor class >> shutDown: quitting [
	"Announce the shutdown, giving monitors a chance to flush their queues"

	self sessionAnnouncer announce: LeLocalJSONStoreShutdown new.
]

{ #category : #'system startup' }
LeLocalStoreMonitor class >> startUp: resuming [
	| noStartup |

	noStartup := (Smalltalk commandLine argumentsInclude: LeNoStartupCommandline commandName) | NoStartup.

	(resuming and: [ noStartup not ]) ifTrue: 
		[ self sessionAnnouncer announce: LeLocalJSONStoreStartup new ]
]

{ #category : #accessing }
LeLocalStoreMonitor >> announcer [ 

	^ announcer
]

{ #category : #accessing }
LeLocalStoreMonitor >> corruptFiles [
	"Answer the receiver's collection of corrupt files"

	^ corruptFiles
]

{ #category : #'private - accessing' }
LeLocalStoreMonitor >> defaultDelay [

	^ 30 seconds
]

{ #category : #'schema updating' }
LeLocalStoreMonitor >> forceSchemaUpgradeFrom: aString [ 
	"Run the receiver's db files through an update from the supplied version number, e.g. '3.0'"

	self dbSchema: (LeDbVersion fromString: aString).
	storage updateDbStore: self.
	self reload.
]

{ #category : #'gt-extensions' }
LeLocalStoreMonitor >> gtAttachmentsFor: aView [
	<gtView>
	self attachmentsDirectory ifNil: [ ^ aView empty ].
	
	^ aView columnedList
		title: 'Attachments';
		priority: 15;
		items: [ self attachmentsDirectory directories ];
		column: 'ID' item: #basename;
		column: 'Name' item: [ :aDirectory | 
			| allFiles |
			allFiles := aDirectory files select: [ :aFile | 
				aFile basename ~= LeAttachment basename ].
			allFiles size = 1
				ifTrue: [ allFiles first basename ]
				ifFalse: [ allFiles size asString, ' attachments' ] ]
	
]

{ #category : #'gt-extensions' }
LeLocalStoreMonitor >> gtViewCorruptFilesFor: aView [
	<gtView>
	^ aView list
		title: 'Corrupt files';
		items: [ self corruptFiles]
]

{ #category : #'gt-extensions' }
LeLocalStoreMonitor >> gtViewStatusDetailsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Details';
		priority: 10;
		items: [ {
			'Has pengind change' -> self isEmpty not.
			'Has corrupt files' -> (self corruptFiles size > 0) .
			'Is monitor stopped' -> self isRunning not}];
		column: 'Name' text: #key;
		column: 'Value' text: #value;
		send: #value
]

{ #category : #testing }
LeLocalStoreMonitor >> hasCorruptFiles [
	"Answer a boolean indicating whether the receiver is aware of any corrupt files"

	^ corruptFiles isNotEmpty 
]

{ #category : #initialization }
LeLocalStoreMonitor >> initialize [

	super initialize.
	announcer := Announcer new.
	state := #stopped.
	saveDelay := self defaultDelay.
	saveQueue := WaitfreeQueue new.
	removeQueue := WaitfreeQueue new.
	corruptFiles := #().
]

{ #category : #testing }
LeLocalStoreMonitor >> isEmpty [ 
	"Answer a boolean indicating if the receiver's queues are empty.
	This is approximate as it uses a non-locking test"
	
	^ saveQueue isEmpty and: [ removeQueue isEmpty ]
]

{ #category : #testing }
LeLocalStoreMonitor >> isRunning [ 
	"Answer a boolean indicating whether the receiver is running"

	^ state = #running
]

{ #category : #testing }
LeLocalStoreMonitor >> isRunningCleanly [
	"Answer a boolean indicating whether the receiver is running without any known issues"

	^ state = #running and: [ self hasCorruptFiles not ]
]

{ #category : #private }
LeLocalStoreMonitor >> loadCorruptFilenames [
	"Load the list of corrupt files (which should of course be empty)"

	corruptFiles := #('*.corrupt' '*.duplicate') flatCollect: [ :pattern |
		localRoot childrenMatching: pattern ]
]

{ #category : #'startup-shutdown' }
LeLocalStoreMonitor >> primitiveReload [
	"Reload the receiver's database."

	super primitiveReload.
	LeDatabaseReload new
		monitor: self;
		reload
]

{ #category : #'private - announcements' }
LeLocalStoreMonitor >> processContentTreeChanged: anAnnouncement [
	| page |

	page := anAnnouncement page.
	(page isNil or: [ page isPage not ]) ifTrue: [ ^ self ].

	"If empty pages should be saved, always save the page,
	otherwise save it if it has content."
	(page type saveEmptyPages or: [ page isNotEmpty ]) ifTrue: 
		[ ^ self savePage: page ].

	"If we got here, the page is empty and empty pages shouldn't be saved.
	Remove it from the DB if it exists."
	(self pageFileReference: page) exists ifTrue: 
		[ self removePage: page ].

]

{ #category : #'private - announcements' }
LeLocalStoreMonitor >> processExplicitLinksChanged: anAnnouncement [
	anAnnouncement requiresSavingOfLinks ifTrue: [
		self savePage: anAnnouncement explicitLinks copyForSavingOnlyWithAttachedLinks ]
]

{ #category : #'private - announcements' }
LeLocalStoreMonitor >> processPageAdded: anAnnouncement [
	"Save added pages that aren't empty"

	| page |
	page := anAnnouncement page.
	(page type saveEmptyPages or: [ page isNotEmpty ]) ifTrue: 
		[ self savePage: anAnnouncement page ]
]

{ #category : #'private - announcements' }
LeLocalStoreMonitor >> processPageRemoved: anAnnouncement [

	self removePage: anAnnouncement page.
]

{ #category : #'private - announcements' }
LeLocalStoreMonitor >> processPageTitleChanged: anAnnouncement [

	self savePage: anAnnouncement page.

]

{ #category : #'private - announcements' }
LeLocalStoreMonitor >> processSnippetContentChanged: anAnnouncement [
	self savePage: anAnnouncement snippet page
]

{ #category : #private }
LeLocalStoreMonitor >> queueRemove: aString [
	"Add the supplied page title to the queue of pages to be removed"

	removeQueue nextPut: aString.
	"LeLocalJSONStoreSignal new
		pageTitle: aString;
		operation: #queueRemove;
		emit."
]

{ #category : #private }
LeLocalStoreMonitor >> queueSave: aPage [
	"Add the supplied page to the queue of pages to be saved"

	saveQueue nextPut: aPage.
	"LeLocalJSONStoreSignal new
		pageTitle: aPage title;
		operation: #queueSave;
		emit."
]

{ #category : #'startup-shutdown' }
LeLocalStoreMonitor >> reload [
	"Reload the receiver's database.
	If the receiver is part of a logical database, defer to the logical database to coordinate reloads across all concrete databases."

	(database hasParentDatabase and: [ database parent hasProperties ]) ifTrue: 
		[ ^ database parent reloadRequestFrom: database ].
	self primitiveReload.
]

{ #category : #private }
LeLocalStoreMonitor >> removePage: aPage [
	"Remove the supplied page from the local store"

	self removePageFile: (self pageFilename: aPage)

]

{ #category : #private }
LeLocalStoreMonitor >> removePageFile: aString [
	"Remove the supplied page file named aString from the local store"

	saveDelay isZero
		ifTrue: [ self removePageNowNamed: aString ]
		ifFalse: [ self queueRemove: aString ]

]

{ #category : #private }
LeLocalStoreMonitor >> removePageNowNamed: aString [
	"Remove the supplied page file named aString from the local store"
	| pageFile |

	pageFile := localRoot / aString.
	pageFile ensureDelete.
	LeLocalStoreSignal new
		pageTitle: aString;
		operation: #remove;
		emit.
]

{ #category : #private }
LeLocalStoreMonitor >> runTimedUpdate [
	"Perform all the queued updates"

	[ [ self updateEntries ]
		on: UnhandledError fork: [ :ex | ex pass ] ]
			ensure: [ self scheduleNextUpdate ]
]

{ #category : #accessing }
LeLocalStoreMonitor >> saveDelay [
	^ saveDelay
]

{ #category : #accessing }
LeLocalStoreMonitor >> saveDelay: aDuration [
	"Set the duration to wait between updates.
	A duration of 0 means that updates are saved immediately and no further timed updates are scheduled.
	Note that the new duration only takes affect after the next update."

	saveDelay := aDuration
]

{ #category : #private }
LeLocalStoreMonitor >> savePage: aPage [
	"Write the supplied page back to the local store.
	If the saveDelay is 0, write the page immediately, otherwise queue for the next timed update."

	saveDelay isZero
		ifTrue: [ self savePageNow: aPage ]
		ifFalse: [ self queueSave: aPage ]

]

{ #category : #private }
LeLocalStoreMonitor >> scheduleNextUpdate [
	"Queue the next update to be run after the saveDelay duration"

	saveDelay isZero ifTrue: [ ^ self ].
	BlTaskAtQueue default
		schedule: 
			[ state = #running ifTrue:
				[ BlTktWorkerProvider highUICPUBoundPool schedule: 
					[ self runTimedUpdate ] asBlTktCommand ] ]
		at: DateAndTime now + saveDelay.
]

{ #category : #'startup-shutdown' }
LeLocalStoreMonitor >> startMonitoring [
	state = #running ifTrue: [ ^ self ].
	state := #running.
	
	database weak when: LeSnippetContentChanged send: #processSnippetContentChanged: to: self.
	database weak when: LeContentTreeChanged send: #processContentTreeChanged: to: self.
	database weak when: LeDatabasePageAdded send: #processPageAdded: to: self.
	database weak when: LeDatabasePageRemoved send: #processPageRemoved: to: self.
	database weak when: LePageTitleChanged send: #processPageTitleChanged: to: self.
	database weak when: LeExplicitLinksChange send: #processExplicitLinksChanged: to: self.
	
	self class sessionAnnouncer weak when: LeLocalJSONStoreShutdown send: #updateEntries to: self.
	self class sessionAnnouncer weak when: LeLocalJSONStoreStartup send: #startUp to: self.
	self scheduleNextUpdate.
	self loadCorruptFilenames.
]

{ #category : #'system startup' }
LeLocalStoreMonitor >> startUp [
	"The system is starting up, reload the databases"

	self submitReload.
]

{ #category : #'startup-shutdown' }
LeLocalStoreMonitor >> stopMonitoring [

	database unsubscribe: self.
	self class sessionAnnouncer unsubscribe: self.
	state := #stopped.
	self updateEntries.
]

{ #category : #private }
LeLocalStoreMonitor >> submitReload [

	[ self reload ] asBlTktCommand 
		name: 'Lepiter Database Reload';
		scheduleInPool: BlTktWorkerProvider highUIExternalResourceBoundPool
]

{ #category : #private }
LeLocalStoreMonitor >> updateEntries [
	"Perform all the queued updates"
	| oldSaveQueue oldRemoveQueue newSaveQueue newRemoveQueue savePages removePageFiles page |

	newSaveQueue := WaitfreeQueue new.
	newRemoveQueue := WaitfreeQueue new.

	"Save the old queues and insert the new queues.
	Assignment operations can't be interrupted, so this is atomic and thread safe"
	oldSaveQueue := saveQueue.
	oldRemoveQueue := removeQueue.
	saveQueue := newSaveQueue.
	removeQueue := newRemoveQueue.

	savePages := Set new.
	[ (page := oldSaveQueue nextOrNil) isNotNil ] whileTrue:
		[ savePages add: page ].
	savePages do: [ :each |
		self savePageNow: each ].

	removePageFiles := Set new.
	[ (page := oldRemoveQueue nextOrNil) isNotNil ] whileTrue:
		[ removePageFiles add: page ].
	removePageFiles do: [ :each |
		self removePageNowNamed: each ].

	self announce: (LeLocalStoreMonitorSaved new monitor: self)
]

{ #category : #accessing }
LeLocalStoreMonitor >> userEmail: aString [
	"Update the DB properties with the supplied user email.
	It is assumed that the value has already been validated by the database."

	self updateProperty: #userEmail value: aString
]

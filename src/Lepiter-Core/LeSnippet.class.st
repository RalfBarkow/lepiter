"
LeBlock is the common, abstract, superclass of all the content that can be added to a Lepiter Page.

 
## Internal Representation and Key Implementation Points.

### Instance Variables
	parent:		<LeContent>


### Implementation Points

"
Class {
	#name : #LeSnippet,
	#superclass : #LeContent,
	#instVars : [
		'parent',
		'uid'
	],
	#category : #'Lepiter-Core-Model'
}

{ #category : #visiting }
LeSnippet >> acceptVisitor: aVisitor [

	^ aVisitor visitSnippet: self
]

{ #category : #'api - editing' }
LeSnippet >> addChildOrSiblingSnippet: aNewSnippet [
	"Add a new snippet that is either:
	- a sibling of the receiver if there are no children.
	- the first child of the receiver."
	
	^ self hasChildren
		ifTrue: [ self addFirstSnippet: aNewSnippet ]
		ifFalse: [ self addSnippetAfterSelf: aNewSnippet ].
]

{ #category : #'api - editing' }
LeSnippet >> addChildOrSiblingSnippetOfClass: aNewSnippetClass [ 
	"Add a new snippet that is either:
	- a sibling of the receiver if there are no children.
	- the first child of the receiver."
	
	^ self hasChildren
		ifTrue: [ self addFirstSnippet: aNewSnippetClass empty ]
		ifFalse: [ self addSnippetAfterSelfOfClass: aNewSnippetClass ].
]

{ #category : #adding }
LeSnippet >> addExplicitLinkTo: aTargetReference [
	self assert: [ self database notNil ].
	self 
		assert: [ self database isDatabase ] 
		description: 'Explicit links shoud be attached this way only if the 
page is associated to a database. If not the link will be lost.'.
	
	self database addExplicitLink: (LeAttachedLink new
		originReference: (LeLinkSnippetUidReference forSnippet: self);
		targetReference: aTargetReference).
]

{ #category : #'api - editing' }
LeSnippet >> addFirstSnippet: aLeSnippet [
	"Add the supplied block as the first child of the receiver"

	self children addFirstChild: aLeSnippet.
	aLeSnippet addedToParent: self.
	self announceContentAdded: aLeSnippet.
	^ aLeSnippet
]

{ #category : #'api - editing' }
LeSnippet >> addSnippetAfterSelf [
	"Add a new snippet after the receiver. Answer the new snippet"
	^ self parent addSnippetAfter: self.
]

{ #category : #'api - editing' }
LeSnippet >> addSnippetAfterSelf: aNewSnippet [
	"Add a new snippet after the receiver having the given class. Answer the new snippet"
	^ self parent addSnippet: aNewSnippet after: self
]

{ #category : #'api - editing' }
LeSnippet >> addSnippetAfterSelfOfClass: aNewSnippetClass [ 
	"Add a new snippet after the receiver having the given class. Answer the new snippet"
	^ self parent addSnippetOfClass: aNewSnippetClass after: self
]

{ #category : #'api - editing' }
LeSnippet >> addSnippetBeforeSelf [
	"Add a new snippet before the receiver. Answer the new snippet"
	^ self parent addSnippetBefore: self.
]

{ #category : #'api - editing' }
LeSnippet >> addSnippetBeforeSelfOfClass: aNewSnippetClass [ 
	"Add a new snippet before the receiver having the given class. Answer the new snippet"
	^ self parent addSnippetOfClass: aNewSnippetClass before: self
]

{ #category : #'api - notifications' }
LeSnippet >> addedToParent: aParent [

	self aboutToAddToDatabase: aParent database.
	self parent: aParent.
	self addedToDatabase: aParent database.
]

{ #category : #'private - notifications' }
LeSnippet >> announceContentChanged [
	"Notify all dependents that the snippet's content (for example properties) has changed"

	self announceContentChangedBy: nil
]

{ #category : #'private - notifications' }
LeSnippet >> announceContentChangedBy: aSourceObject [
	"Notify all dependents that the snippet's content (for example properties) has changed"

	self notifyAnnouncement: (LeSnippetContentChanged new
		source: aSourceObject;
		snippet: self)
]

{ #category : #'api - attaching / detaching' }
LeSnippet >> attachChildSnippet: aNewSnippet [
	self assert: [ aNewSnippet notNil ].
	self assert: [ aNewSnippet parent isNil ].
	
	self children addChild: aNewSnippet.
	aNewSnippet attachToParent: self.
	^ aNewSnippet
]

{ #category : #'api - attaching / detaching' }
LeSnippet >> attachFirstChildSnippet: aNewSnippet [
	self assert: [ aNewSnippet notNil ].
	self assert: [ aNewSnippet parent isNil ].
	
	self children addFirstChild: aNewSnippet.
	aNewSnippet attachToParent: self.
	^ aNewSnippet
]

{ #category : #'api - attaching / detaching' }
LeSnippet >> attachToParent: aParentSnippet [
	self assert: [ aParentSnippet notNil ].
	self 
		assert: [ self parent isNil ] 
		description: 'To attach a snippet is must have been previously detached.'.
	
	self parent: aParentSnippet
]

{ #category : #'api - attaching / detaching' }
LeSnippet >> detachChildSnippet: aLeSnippet [
	self assert: [ aLeSnippet notNil ].
	self assert: [ aLeSnippet parent notNil ].
	
	self children removeSnippet: aLeSnippet.
]

{ #category : #'api - attaching / detaching' }
LeSnippet >> detachFromParent [
	self parent: nil
]

{ #category : #'api - testing' }
LeSnippet >> hasUid: aLeUID [

	^ uid = aLeUID
]

{ #category : #'t-rotating' }
LeSnippet >> heading [
	^ nil
]

{ #category : #'api - testing' }
LeSnippet >> includesSnippetUid: aLeUID [
	"Answer a boolean indicating whether the supplied uid is present"

	^ (uid = aLeUID) or: [ self children includesSnippetUid: aLeUID ]
]

{ #category : #'api - editing' }
LeSnippet >> indent [
	"Indent the receiver in the receiver's page, i.e. make it a child of the previous snippet.
	If this is the first snippet at the current level, do nothing"

	self parent indentSnippet: self.
]

{ #category : #'api - testing' }
LeSnippet >> isCodeSnippet [

	^ false
]

{ #category : #testing }
LeSnippet >> isSnippet [

	^ true
]

{ #category : #'api - testing' }
LeSnippet >> isTextSnippet [

	^ false
]

{ #category : #'api - editing' }
LeSnippet >> mergeWithNext [
	"Merge the contents of the receiver with the next block (the next sibling, or the parent's next).
	Answer the merged block."

	^ self 
		nextSnippetDo: [ :nextBlock | self requestMergeWithBlock: nextBlock ] 
		ifNone: [ self error: 'Can''t merge the last block with a following block' ].
]

{ #category : #'api - editing' }
LeSnippet >> mergeWithPrevious [
	"Merge the contents of the receiver with the previous block (the previous sibling, or the parent itself).
	Answer the merged block."

	^ self 
		previousSnippetDo: [ :previousBlock | previousBlock requestMergeWithBlock: self ] 
		ifNone: [ self error: 'Can''t merge the first block with a previous block' ].
]

{ #category : #'api - editing' }
LeSnippet >> moveDown [
	"Move the receiver down one snippet.
	If the receiver has a sibling below it, move there, if not and the receiver's parent has a sibling below, move there"

	self parent moveDownSnippet: self.
]

{ #category : #'api - editing' }
LeSnippet >> moveUp [
	"Move the receiver up one snippet.
	If the receiver has a sibling below it, move there, if not and the receiver's parent has a sibling below, move there"

	self parent moveUpSnippet: self.
]

{ #category : #'api - enumerating' }
LeSnippet >> nextBlockDo: aBlock ifNone: aNoneBlock [
	self
		deprecated: 'Use #nextSnippetDo:ifNone: instead'
		transformWith:
			'`@receiver nextBlockDo: `@arg1 ifNone: `@arg2'
			-> '`@receiver nextSnippetDo: `@arg1 ifNone: `@arg2'.

	^ self nextSnippetDo: aBlock ifNone: aNoneBlock
]

{ #category : #'api - enumerating' }
LeSnippet >> nextSibling [
	"Answer the next sibling"
	| myIndex |

	self parent
		ifNil: [ self error: 'No siblings' ].

	myIndex := self parent blocks indexOf: self.
	^ myIndex == self parent childrenCount
		ifTrue: [ self error: 'I am the last sibling' ]
		ifFalse: [ self parent blocks at: myIndex + 1 ]
]

{ #category : #'api - enumerating' }
LeSnippet >> nextSiblingDo: aBlock ifNone: aNoneBlock [
	"Find a next sibling block in the tree and evaluate aBlock if such block found, aNoneBlock otherwise.
	The next sibling is considered to be the first found from:
	- The next sibling
	- The parents next sibling"

	| myIndex |
	self parent ifNil: [ ^ aNoneBlock value ].
	myIndex := self parent children indexOf: self.
	^ myIndex == self parent childrenCount
		ifTrue: [ self parent isPage
				ifTrue: [ aNoneBlock value ]
				ifFalse: [ self parent nextSiblingDo: aBlock ifNone: aNoneBlock ] ]
		ifFalse: [ aBlock value: (self parent children at: myIndex + 1) ]
]

{ #category : #'api - enumerating' }
LeSnippet >> nextSnippetDo: aBlock ifNone: aNoneBlock [
	"Find a next snippet in the tree and evaluate aBlock if such snippet found, aNoneBlock otherwise.
	The next snippet is considered to be the first found from:
	- The receiver's first child
	- The next sibling
	- The parents next sibling"

	| myIndex |
	self hasChildren
		ifTrue: [ ^ aBlock value: children first ].
	self parent ifNil: [ ^ aNoneBlock value ].
	myIndex := self parent children indexOf: self.
	^ myIndex == self parent childrenCount
		ifTrue: [ self parent isPage
				ifTrue: [ aNoneBlock value ]
				ifFalse: [ self parent nextSiblingDo: aBlock ifNone: aNoneBlock ] ]
		ifFalse: [ aBlock value: (self parent children at: myIndex + 1) ]
]

{ #category : #'api - notifications' }
LeSnippet >> notifier [
	^ LeNotifier new
		content: self
]

{ #category : #'private - notifications' }
LeSnippet >> notifyAnnouncement: anAnnouncement [
	"Send anAnnouncement to all dependents of the snippet"

	self notifier 
		local; page; database;
		announce: anAnnouncement
]

{ #category : #'private - hooks' }
LeSnippet >> onAboutToAddToDatabase: aDatabase [ 
	"Ensure the receiver has a uid before it is added to a database"
	super onAboutToAddToDatabase: aDatabase .
	uid ifNil: [ uid := aDatabase newUID ].
	aDatabase registerSnippet: self.
]

{ #category : #'private - hooks' }
LeSnippet >> onRemovedFromDatabase: aDatabase [
	super onRemovedFromDatabase: aDatabase.
	aDatabase unregisterSnippet: self.
	
	aDatabase removeExplicitOutgoingLinksForContent: self.
	aDatabase removeIncomingExplicitLinksForContent: self.
]

{ #category : #'api - accessing' }
LeSnippet >> outgoingTextualLinks [
	^ LeExplicitLinks new
]

{ #category : #'api - accessing' }
LeSnippet >> page [
	^ self parent
		ifNil: [ nil ] 
		ifNotNil: [ self parent page ]
]

{ #category : #'api - accessing' }
LeSnippet >> parent [
	<return: #LeContent>
	^ parent
]

{ #category : #'private - accessing' }
LeSnippet >> parent: aParent [ 
	parent := aParent
]

{ #category : #'api - enumerating' }
LeSnippet >> previousBlockDo: aBlock ifNone: aNoneBlock [
	self
		deprecated: 'Use #previousSnippetDo:ifNone: instead'
		transformWith:
			'`@receiver previousBlockDo: `@arg1 ifNone: `@arg2'
			-> '`@receiver previousSnippetDo: `@arg1 ifNone: `@arg2'.

	^ self previousSnippetDo: aBlock ifNone: aNoneBlock
]

{ #category : #'api - enumerating' }
LeSnippet >> previousSibling [
	"Answer the previous sibling"

	| myIndex |
	self parent ifNil: [ self error: 'No siblings' ].
	myIndex := self parent children indexOf: self.
	^ myIndex == 1
		ifTrue: [ self error: 'I am the first sibling' ]
		ifFalse: [ self parent children at: myIndex - 1 ]
]

{ #category : #'api - enumerating' }
LeSnippet >> previousSnippetDo: aBlock ifNone: aNoneBlock [
	"Find a previous snippet in the tree and evaluate aBlock if such snippet found, aNoneBlock otherwise.
	The previous snippet is considered to be the first found from:
	- The last descended child from the receiver's previous sibling
	- The previous sibling
	- The parent"

	| myIndex |
	self parent ifNil: [ ^ aNoneBlock value ].
	myIndex := self parent children indexOf: self.
	^ myIndex == 1
		ifTrue: [ self parent isPage
				ifTrue: [ aNoneBlock value ]
				ifFalse: [ aBlock value: self parent ] ]
		ifFalse: [ aBlock value: (self parent children at: myIndex - 1) lastChildOrSelf ]
]

{ #category : #'private - updating' }
LeSnippet >> reloadAttributesFromContent: aSnippet [
	| attributesReloader |
	attributesReloader := LeContentAttributesReloader forContent: self.
	attributesReloader reloadFromContent: aSnippet.
	^ attributesReloader hasChanges
]

{ #category : #removing }
LeSnippet >> removeSelf [
	"Remove the receiver from its parent"
	
	self parent
		ifNil: [ ^ self ].
	self parent removeSnippet: self
]

{ #category : #'api - editing' }
LeSnippet >> requestMergeWithBlock: aBlock [
	"Request a merge between the receiver and the given block. 
	As a result of the request depending on the implementation:
	- nothing can happen if the merge is not accepted;
	- the receiver is deleted and its content is added to the given block
	- the given block is deleted amd its content is added to the receiver.
	
	One of the two blocks is returned to the caller."
	
	^ self subclassResponsibility
]

{ #category : #'api - accessing' }
LeSnippet >> topBlock [
	^ (self parent isNil or: [ self parent isPage ])
		ifTrue: [ self ] 
		ifFalse: [ self parent topBlock ]
]

{ #category : #'api - editing' }
LeSnippet >> transferChildrenTo: aSnippet [
	"Transfer the children of the receiver to the supplied snippet."

	children isEmpty
		ifTrue: [ ^ self ].
	children
		copyDo: [ :each | 
			self removeSnippet: each.
			aSnippet addSnippet: each ]
]

{ #category : #'api - accessing' }
LeSnippet >> uid [
	<return: #LeUID>
	^ uid
]

{ #category : #'api - accessing' }
LeSnippet >> uid: aLeUID [
	uid := aLeUID
]

{ #category : #'api - accessing' }
LeSnippet >> uidString [ 

	^ uid uidString
]

{ #category : #accessing }
LeSnippet >> uidString: aString64 [

	uid := LeUID new uidString: aString64
]

{ #category : #'api - editing' }
LeSnippet >> unindent [
	"Unindent the receiver in the receiver's page, i.e. make it follow its parent snippet.
	If this is a first level snippet, do nothing"

	self parent unindentSnippet: self.
]

{ #category : #installing }
LeSnippet >> unload [ 

	self notifier
		bubble; database;
		announce: (LeSnippetUnloadAnnouncement new content: self)
]

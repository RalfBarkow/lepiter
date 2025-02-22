"
Lepiter supports multiple types of databases:

- The 'normal' database is {{gtClass:LeDatabase}}, which represents a single instance of a database on-disk.
- {{gtClass:LeLogicalDatabase}} is a collection of databases that can be used in a single UI ({{gtClass:LeWorld}}).
- {{gtClass:LePharoClassDatabase}} acts as a view on to the class comments in a Pharo image.

"
Class {
	#name : #LeAbstractDatabase,
	#superclass : #LeModel,
	#traits : 'TGtAnnouncer + TLeSpotterChildrenEnumerationSearch + TLeSpotterPagesSearch',
	#classTraits : 'TGtAnnouncer classTrait + TLeSpotterChildrenEnumerationSearch classTrait + TLeSpotterPagesSearch classTrait',
	#instVars : [
		'announcer',
		'parent'
	],
	#category : #'Lepiter-Core-Model'
}

{ #category : #visiting }
LeAbstractDatabase >> acceptVisitor: aVisitor [

	^ aVisitor visitDatabase: self
]

{ #category : #announcer }
LeAbstractDatabase >> announcer [
	<return: #Announcer>
	^ announcer
]

{ #category : #initialization }
LeAbstractDatabase >> initialize [

	super initialize.
	announcer := Announcer new.

]

{ #category : #'api - accessing' }
LeAbstractDatabase >> logicalDatabase [
	"Answer the logical database for the receiver.
	This is either the receiver's parent, if it has one, or the receiver itself"

	^ parent ifNil: [ self ]
]

{ #category : #'api - accessing' }
LeAbstractDatabase >> pageNamed: aString [

	^ self subclassResponsibility 
]

{ #category : #'api - accessing' }
LeAbstractDatabase >> parent [ 
	"Answer the parent database of the receiver (a LeLogicalDatabase) or nil"
	<return: #LeLogicalDatabase>

	^ parent
]

{ #category : #'api - accessing' }
LeAbstractDatabase >> parent: aLeLogicalDatabase [
	"Set the parent database of the receiver (a LeLogicalDatabase)"

	parent := aLeLogicalDatabase
]

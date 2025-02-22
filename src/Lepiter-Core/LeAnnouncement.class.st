"
LeAnnouncement is an abstract, common, superclass for all announcements generated by Lepiter.

The source is an optional object that may be used to determine whether a change was generated by the receiver of the announcement or by an external source.  E.g. should the UI be updated again.  If the source was the UI, no update is required, if the source is external, update the UI to reflect the change.


## Internal Representation and Key Implementation Points.

### Instance Variables
	source:		<Object>	The source of the change that generated the announcement, see above.


### Implementation Points

"
Class {
	#name : #LeAnnouncement,
	#superclass : #Announcement,
	#instVars : [
		'source'
	],
	#category : #'Lepiter-Core-Announcements'
}

{ #category : #accessing }
LeAnnouncement >> source [
	^ source
]

{ #category : #accessing }
LeAnnouncement >> source: anObject [
	source := anObject
]

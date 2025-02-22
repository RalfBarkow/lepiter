Extension { #name : #LeLogicalDatabase }

{ #category : #'*Lepiter-UI' }
LeLogicalDatabase >> asContentUIModel [
	^ LeLogicalDatabaseViewModel new database: self
]

{ #category : #'*Lepiter-UI' }
LeLogicalDatabase >> gtDailyNotesFor: aView [
	<gtView>
	self pages ifNil: [ ^ aView empty ].
	^ aView columnedTree
		title: 'By Day';
		priority: 9;
		items: [ self dailyNotes ];
		children: [ :eachPage | eachPage children ];
		column: 'Title' item: #title;
		column: 'Time' item: #editTime;
		column: 'Author' item: #editEmail;
		send: [ :eachPageOrPart | 
			eachPageOrPart ]
]

{ #category : #'*Lepiter-UI' }
LeLogicalDatabase >> gtLiveFor: aView [
	<gtView>
	self pagesByName ifEmpty: [ ^ aView empty ].
	^ aView forward
		title: 'Live';
		priority: 1;
		object: [ self asContentUIModel ];
		view: #gtLiveFor:
]

"
Robin Hood hashing is a technique for implementing hash tables. It is based on open addressing with a simple but clever twist: as new keys are inserted, old keys are shifted around in such a way that all keys remain reasonably close to the slot to which they were originally hashed. In particular, the variance in the distance of keys from their ""home"" slots is minimized. The distance from the home slot to the actual slot of a key is called the ""probe sequence length"".
"
Class {
	#name : 'RHDictionary',
	#superclass : 'Dictionary',
	#instVars : [
		'probeSequenceLengths'
	],
	#category : 'Collections-RobinHood',
	#package : 'Collections-RobinHood'
}

{ #category : 'adding' }
RHDictionary >> add: anAssociation [
	"Add anAssociation to the dictionary. If the key is already in the dictionary then the value
	will overwrite the one currently present."

	| index element |
	index := self findElementOrNilForInsertion: anAssociation key.
	element := array at: index.
	element
		ifNil: [ self atNewIndex: index put: anAssociation ]
		ifNotNil: [ element value: anAssociation value ].
	^ anAssociation
]

{ #category : 'accessing' }
RHDictionary >> at: key put: anObject [
	"Set the value at key to be anObject.
	If key is not found, create a new entry for key and set its value to anObject.
	Answer anObject."

	| index assoc |
	index := self findElementOrNilForInsertion: key.
	assoc := array at: index.
	assoc
		ifNil: [
		self atNewIndex: index put: (Association key: key value: anObject) ]
		ifNotNil: [ assoc value: anObject ].
	^ anObject
]

{ #category : 'accessing' }
RHDictionary >> at: key update: updateBlock initial: initBlocktOrValue [
	"I am used to update the value at a given key. The updateBlock is passed
	the existing value, and the result of the block is stored back.
	If the key does not exist, store the value of the initBlocktOrValue.
	initBlocktOrValue can be a block in case the initial value is expensive to compute."

	| index |
	index := self findElementOrNilForInsertion: key.
	(array at: index)
		ifNil: [ self atNewIndex: index put: key -> initBlocktOrValue value ]
		ifNotNil: [ :assoc | assoc value: (updateBlock value: assoc value) ]
]

{ #category : 'private' }
RHDictionary >> findElementOrNilForInsertion: anObject [
	"Answer the index of a first slot containing either a nil (indicating an empty slot) or an element that matches the given object.
	This method is called for inserting a new element, so we take the opportunity to compute its probe sequence length.
	Answer the index of that slot or zero. Fail if neither a match nor an empty slot is found."

	| index |
	index := self scanForInsertion: anObject.
	index > 0 ifTrue: [ ^ index ].

	"Bad scene. Neither have we found a matching element nor even an empty slot.
	No hashed set is ever supposed to get completely full."
	self errorNoFreeSpace
]

{ #category : 'private' }
RHDictionary >> fixCollisionsFrom: start [
	"The element at start is to be removed.
	This method moves forward from there, shifting back any entry that were placed after it due to collisions with it."

	| element probeSequenceLength index previousIndex |
	previousIndex := index := start.
	[
	(element := array at: (index := index \\ array size + 1)) == nil or: [
		(probeSequenceLength := probeSequenceLengths at: index) == 0 ] ]
		whileFalse: [
			array at: previousIndex put: element.
			probeSequenceLengths at: previousIndex put: probeSequenceLength - 1.
			previousIndex := index ].

	"Clear the last position. If no element was shifted back then this clears where the element was removed."
	array at: previousIndex put: nil.
	probeSequenceLengths at: previousIndex put: nil
]

{ #category : 'private' }
RHDictionary >> grow [
	"Grow the elements array and reinsert the old elements"

	| oldElements newSize |
	oldElements := array.
	newSize := HashTableSizes atLeast: oldElements size * 2.
	array := Array new: newSize.
	probeSequenceLengths := Array new: newSize.
	tally := 0.
	oldElements do: [ :each | each ifNotNil: [ self noCheckAdd: each ] ]
]

{ #category : 'private' }
RHDictionary >> growTo: anInteger [
	"Grow the elements array and reinsert the old elements"

	| oldElements |
	oldElements := array.
	array := Array new: anInteger.
	probeSequenceLengths := Array new: anInteger.
	self noCheckNoGrowFillFrom: oldElements
]

{ #category : 'initialization' }
RHDictionary >> initialize: n [

	super initialize: n.
	probeSequenceLengths := Array new: n
]

{ #category : 'private' }
RHDictionary >> noCheckAdd: anObject [
	"Must be defined separately because (self findElementOrNilForInsertion:) expects a key, not an association."

	array
		at: (self findElementOrNilForInsertion: anObject key)
		put: anObject.
	tally := tally + 1
]

{ #category : 'copying' }
RHDictionary >> postCopy [

	super postCopy.
	probeSequenceLengths := probeSequenceLengths copy
]

{ #category : 'accessing' }
RHDictionary >> probeSequenceLengths [

	^ probeSequenceLengths
]

{ #category : 'private' }
RHDictionary >> rehash [

	| newSelf |
	newSelf := self species new: self size.
	self associationsDo: [ :each | newSelf noCheckAdd: each ].
	array := newSelf array.
	probeSequenceLengths := newSelf probeSequenceLengths
]

{ #category : 'removing' }
RHDictionary >> removeKey: key ifAbsent: aBlock [
	"Remove key (and its associated value) from the receiver. If key is not in
	the receiver, answer the result of evaluating aBlock. Otherwise, answer
	the value externally named by key."

	| index assoc |
	index := self scanFor: key.
	assoc := (array at: index) ifNil: [ ^ aBlock value ].
	tally := tally - 1.
	self fixCollisionsFrom: index.
	^ assoc value
]

{ #category : 'private' }
RHDictionary >> scanForEmptySlotFor: aKey [
	"Scan the key array for the first slot containing an empty slot (indicated by a nil).
	This method is called for inserting a new element, so we take the opportunity to compute its probe sequence length.
	Answer the index of that slot."

	| index start probeSequenceLength |
	index := start := aKey hash \\ array size + 1.
	probeSequenceLength := 0.
	[
	(array at: index) ifNil: [
		probeSequenceLengths at: index put: probeSequenceLength.
		^ index ].
	probeSequenceLength := probeSequenceLength + 1.
	(index := index \\ array size + 1) = start ] whileFalse.
	self errorNoFreeSpace
]

{ #category : 'private' }
RHDictionary >> scanForInsertion: anObject [
	"Scan the key array for the first slot containing either a nil (indicating an empty slot) or an element that matches anObject.
	This method is called for inserting a new element, so we take the opportunity to compute its probe sequence length.
	Answer the index of that slot or zero if no slot is found."

	| element start finish probeSequenceLength |
	finish := array size.
	start := anObject hash \\ finish + 1.
	probeSequenceLength := 0.

	"Search from (hash mod size) to the end."
	start to: finish do: [ :index |
		(element := array at: index) == nil ifTrue: [
			probeSequenceLengths at: index put: probeSequenceLength.
			^ index ].
		element key = anObject ifTrue: [ ^ index ].

		"If the element at the index has a smaller probe sequence length,
		steal its position to give it to the object to insert"
		(probeSequenceLengths at: index) < probeSequenceLength ifTrue: [
			self stealFrom: index.
			probeSequenceLengths at: index put: probeSequenceLength.
			^ index ].
		probeSequenceLength := probeSequenceLength + 1 ].

	"Search from 1 to where we started."
	1 to: start - 1 do: [ :index |
		(element := array at: index) == nil ifTrue: [
			probeSequenceLengths at: index put: probeSequenceLength.
			^ index ].
		element key = anObject ifTrue: [ ^ index ].

		(probeSequenceLengths at: index) < probeSequenceLength ifTrue: [
			self stealFrom: index.
			probeSequenceLengths at: index put: probeSequenceLength.
			^ index ].
		probeSequenceLength := probeSequenceLength + 1 ].

	^ 0 "No match AND no empty slot"
]

{ #category : 'private' }
RHDictionary >> stealFrom: richIndex [
	"Robin Hood steals from the rich and gives to the poor.
	The element at richIndex has a smaller probe sequence length than another element we wanted to insert, so its place is stolen by the inserted element.
	We look for a new place to put the rich element, thus increasing its probe sequence length and making it poorer the further we go.
	We can steal recursively from richer elements we encounter."

	| finish element probeSequenceLength |
	finish := array size.
	element := array at: richIndex.
	probeSequenceLength := (probeSequenceLengths at: richIndex) + 1.

	"Remove the element at the original index, otherwise insertion methods will think it's an update"
	array at: richIndex put: nil.

	"Search from the rich index to the end."
	richIndex + 1 to: finish do: [ :index |
		(array at: index) == nil ifTrue: [
			array at: index put: element.
			probeSequenceLengths at: index put: probeSequenceLength.
			^ index ].

		"If the element at the index has a smaller probe sequence length, recursively steal its position"
		(probeSequenceLengths at: index) < probeSequenceLength ifTrue: [
			self stealFrom: index.
			array at: index put: element.
			probeSequenceLengths at: index put: probeSequenceLength.
			^ index ].

		probeSequenceLength := probeSequenceLength + 1 ].

	"Search from 1 to where we started."
	1 to: richIndex - 1 do: [ :index |
		(array at: index) == nil ifTrue: [
			array at: index put: element.
			probeSequenceLengths at: index put: probeSequenceLength.
			^ index ].

		(probeSequenceLengths at: index) < probeSequenceLength ifTrue: [
			self stealFrom: index.
			array at: index put: element.
			probeSequenceLengths at: index put: probeSequenceLength.
			^ index ].

		probeSequenceLength := probeSequenceLength + 1 ].

	^ 0 "No match AND no empty slot"
]

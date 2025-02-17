Class {
	#name : 'BaselineOfRobinHoodCollections',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfRobinHoodCollections',
	#package : 'BaselineOfRobinHoodCollections'
}

{ #category : 'baselines' }
BaselineOfRobinHoodCollections >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			package: 'Collections-RobinHood';
			package: 'Collections-RobinHood-Tests'.
		spec
			group: 'default'
			with: #( 'Collections-RobinHood' 'Collections-RobinHood-Tests' ) ]
]

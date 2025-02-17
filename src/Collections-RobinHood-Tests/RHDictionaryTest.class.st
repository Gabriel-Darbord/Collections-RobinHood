Class {
	#name : 'RHDictionaryTest',
	#superclass : 'DictionaryTest',
	#category : 'Collections-RobinHood-Tests',
	#package : 'Collections-RobinHood-Tests'
}

{ #category : 'requirements' }
RHDictionaryTest >> canBeUnhealthy [

	^ false
]

{ #category : 'coverage' }
RHDictionaryTest >> classToBeTested [

	^ RHDictionary
]

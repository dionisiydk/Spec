Class {
	#name : #AbstractListPresenter,
	#superclass : #AbstractWidgetPresenter,
	#instVars : [
		'selectionMode',
		'multiSelectionHolder',
		'selectionHolder',
		'listHolder',
		'sortingBlockHolder',
		'filteringBlockHolder',
		'autoDeselect',
		'wrapBlockHolder',
		'listAnnouncer',
		'itemFilterBlockHolder',
		'menuHolder',
		'allowToSelect',
		'doubleClickActionHolder',
		'listItemsCache'
	],
	#category : #'Spec-Core-Widgets-Table'
}

{ #category : #api }
AbstractListPresenter >> beMultipleSelection [
	"Make list selection multiple"
	selectionMode := SpecMultipleSelectionMode on: self
]

{ #category : #api }
AbstractListPresenter >> beSingleSelection [
	
	selectionMode := SpecSingleSelectionMode on: self.
]

{ #category : #initialization }
AbstractListPresenter >> defaultFilteringBlock [ 
	^ [:col | col]
]

{ #category : #initialization }
AbstractListPresenter >> defaultSortingBlock [ 
	^ [:a :b | true]
]

{ #category : #api }
AbstractListPresenter >> displayBlock [
	"<api: #inspect>"
	"Return the one argument block used to wrap your domain specific items.
	The block should return something that can be displayed in a list - like a String or a Text"
	
	^ wrapBlockHolder value
]

{ #category : #api }
AbstractListPresenter >> displayBlock: aBlock [
	"<api: #block getter:#displayBlock registration: #whenDisplayBlockChanged:>"
	"Set the one argument block used to wrap your domain specific items.
	The block should return something that can be displayed in a list - like a String or a Text"
	
	wrapBlockHolder value: aBlock
]

{ #category : #'api-events' }
AbstractListPresenter >> doubleClickAction: aBlockClosure [ 
	
	doubleClickActionHolder value: aBlockClosure
]

{ #category : #simulation }
AbstractListPresenter >> doubleClickAtIndex: anInteger [
	self selectIndex: anInteger.
	doubleClickActionHolder value cull: anInteger
]

{ #category : #api }
AbstractListPresenter >> filteringBlock [
	"<api: #inspect>"
	"Return the filtering of the items"
	
	^ filteringBlockHolder value
]

{ #category : #api }
AbstractListPresenter >> filteringBlock: aBlock [
	"<api: #block getter: #filteringBlock registration: #whenFilteringBlockChanged:>"
	"To set the filtering of the items"
	
	filteringBlockHolder value: aBlock
]

{ #category : #api }
AbstractListPresenter >> getIndex [

	^ self selection selectedIndex
]

{ #category : #api }
AbstractListPresenter >> getList [

	^ listHolder value
]

{ #category : #private }
AbstractListPresenter >> getSelectionStateFor: anIndex [
	"Return the current state of the item -if selected or not - in a multiple selection list"
	"Answer true if the item at index _anIndex_ is selected"
	
	self flag: 'refactoring in progress'.

	^ multiSelectionHolder indexes
]

{ #category : #initialization }
AbstractListPresenter >> initialize [
	super initialize.
	self beSingleSelection.
	self initializeValueHolders.
	self registerEvents.

	self
		bindKeyCombination: Character space
		toAction: [ self clickOnSelectedItem ]
]

{ #category : #initialization }
AbstractListPresenter >> initializePorts [

	self addOutputPort: SelectionPresenterPort new.
	self addInputPort: ItemsPresenterPort new
]

{ #category : #initialization }
AbstractListPresenter >> initializeValueHolders [
	selectionHolder := SelectionValueHolder new.
	listHolder := Array new asValueHolder.
	sortingBlockHolder := self defaultSortingBlock asValueHolder.
	filteringBlockHolder := self defaultFilteringBlock asValueHolder.
	itemFilterBlockHolder := nil asValueHolder.
	doubleClickActionHolder := [  ] asValueHolder.
	wrapBlockHolder := [ :object | object asStringOrText ] asValueHolder.
	menuHolder := [ :menu :shifted | nil ] asValueHolder.
	allowToSelect := true asValueHolder.
	autoDeselect := true asValueHolder.
	listAnnouncer := Announcer new.

]

{ #category : #testing }
AbstractListPresenter >> isMultipleSelection [
	
	^ selectionMode isMultipleSelection
]

{ #category : #accessing }
AbstractListPresenter >> itemAt: anInteger [ 
	
	^ self model at: anInteger
]

{ #category : #api }
AbstractListPresenter >> itemBeginsWithFilter [
	self itemFilterBlock: [ :each :pattern | each asLowercase beginsWith: pattern asLowercase ]
]

{ #category : #api }
AbstractListPresenter >> itemFilterBlock [
	^ itemFilterBlockHolder value
]

{ #category : #api }
AbstractListPresenter >> itemFilterBlock: aBlock [
	itemFilterBlockHolder value: aBlock
]

{ #category : #api }
AbstractListPresenter >> itemSubstringFilter [
	self itemFilterBlock: [ :each :pattern | each asLowercase includesSubstring: pattern asLowercase ]
]

{ #category : #api }
AbstractListPresenter >> items: aList [
	"Set the items of the list.
	aList is a collection of your domain specific items.
	Use a two stages notification (issue 7420)."

	"<api: #st getter: #listItems registration: #whenListChanged:>"
	| oldContents |
	oldContents := listHolder value.
	listHolder value: (aList sorted: sortingBlockHolder value).
	listAnnouncer announce: (ValueChanged oldValue: oldContents newValue: listHolder value)
]

{ #category : #private }
AbstractListPresenter >> listElementAt: anIndex [
	"Return the item at index _anIndex_"
	
	^ self listItems at: anIndex ifAbsent: [ nil ]
]

{ #category : #private }
AbstractListPresenter >> listElementAt: anIndex ifAbsent: aBlock [	
	"Return the item at index _anIndex_"
	
	^ self listItems at: anIndex ifAbsent: aBlock
]

{ #category : #api }
AbstractListPresenter >> listItems [
	"<api: #inspect>"
	"Return the items of the list. They are your domain specific items"
	
	^ listItemsCache ifNil: [ listItemsCache :=  filteringBlockHolder value value: listHolder value ]
	
]

{ #category : #api }
AbstractListPresenter >> listSize [
	"<api: #inspect>"
	"Return the size of the list"
	
	^ self listItems size
]

{ #category : #api }
AbstractListPresenter >> menu [
	"<api: #inspect>"
	"Return the block used to defined the menu"
	
	^ menuHolder value
]

{ #category : #api }
AbstractListPresenter >> menu: aBlock [
	"<api: #block getter: #menu registration: #whenMenuChanged:>"
	"Set the block used to defined the menu"
	
	menuHolder value: aBlock
]

{ #category : #private }
AbstractListPresenter >> menu: aMenu shifted: aBoolean [
	"Build the menu when you right click on an item"

	"This does not work on multiple selection"
	self flag: #bug.
	self selectedItem ifNil: [ ^ nil ].

	^ menuHolder value cull: aMenu cull: aBoolean
]

{ #category : #accessing }
AbstractListPresenter >> model [
	
	^ listHolder value
]

{ #category : #private }
AbstractListPresenter >> refreshListItems [

	listItemsCache := nil.
	^ self changed: #listElementAt:
]

{ #category : #initialization }
AbstractListPresenter >> registerEvents [

	listHolder whenChangedDo: [ self refreshListItems ].
	filteringBlockHolder whenChangedDo: [ self refreshListItems ].
	selectionHolder index whenChangedDo: [ self changed: #getIndex ].
	wrapBlockHolder whenChangedDo:[ self changed: #listElementAt: ].
	autoDeselect whenChangedDo: [ :boolean | self changed: #autoDeselect: with: { boolean }].
	sortingBlockHolder
		whenChangedDo: [
			listHolder value: (listHolder value sorted: sortingBlockHolder value).
			self changed: #listElementAt: ].

]

{ #category : #api }
AbstractListPresenter >> resetSelection [
	"<api: #do>"
	"Unselect every items"

	selectionHolder reset.
	multiSelectionHolder reset
]

{ #category : #selection }
AbstractListPresenter >> selectIndex: anInteger [ 
	
	self selectionMode selectIndex: anInteger
]

{ #category : #selection }
AbstractListPresenter >> selectItem: anItem [ 
	
	self selectionMode selectItem: anItem
]

{ #category : #api }
AbstractListPresenter >> selectedIndex [
	"Return the index of the selected item
	In the case of a multiple selection list, it returns the last selected item"
	
	self
		deprecated: 'Use the #selection object instead. This method assumes single selection'
		transformWith: '`@receiver selectedIndex'
						-> '`@receiver selection selectedIndex'.
	
	^  self selection selectedIndex
]

{ #category : #api }
AbstractListPresenter >> selectedIndex: anIndex [

	"Set the index of the item you want to be selected"
	self
		deprecated: 'Use #selectIndex: instead'
		transformWith: '`@receiver selectedIndex: `@arg'
						-> '`@receiver selectIndex: `@arg'.
	
	self selectIndex: anIndex
]

{ #category : #api }
AbstractListPresenter >> selectedIndexes [
	self
		deprecated: 'Use the #selection object instead. This method assumes multiple selection'
		transformWith: '`@receiver selectedIndexes'
						-> '`@receiver selection selectedIndexes'.

	^  self selection selectedIndexes
]

{ #category : #api }
AbstractListPresenter >> selectedItem [
	"Return the selected item.
	In the case of a multiple selection list, it returns the last selected item"
	
	self
		deprecated: 'Use the #selection object instead. This method assumes single selection'
		transformWith: '`@receiver selectedItem'
						-> '`@receiver selection selectedItem'.
	
	^ self selection selectedItem
]

{ #category : #api }
AbstractListPresenter >> selectedItem: anItem [
	"Set the item you want to be selected"

	self
		deprecated: 'Use #selectItem: instead'
		transformWith: '`@receiver selectedItem: `@arg'
						-> '`@receiver selectItem: `@arg'.

	self selectItem: anItem
]

{ #category : #api }
AbstractListPresenter >> selectedItems [
	"<api: #inspect>"

	"Return all the selected items in the case of a multiple selection list"

	^ self selectedItemsAtIndexes: self selection selectedIndexes
]

{ #category : #private }
AbstractListPresenter >> selectedItemsAtIndexes: aCollectionOfIndex [
	^ aCollectionOfIndex collect: [ :anIndex | self listElementAt: anIndex ]
]

{ #category : #api }
AbstractListPresenter >> selectedItemsSorted [
	"return all the selected items sorted by their index"

	^ self selectedItemsAtIndexes: self selectedIndexes sort
]

{ #category : #accessing }
AbstractListPresenter >> selection [
	
	^ selectionMode
]

{ #category : #accessing }
AbstractListPresenter >> selectionMode [
	
	^ selectionMode
]

{ #category : #private }
AbstractListPresenter >> setIndex: anIndex [
	self
		deprecated: 'Use #selectIndex: instead'
		transformWith: '`@receiver setIndex: `@arg' -> '`@receiver selectIndex: `@arg'.
	self selectIndex: anIndex
]

{ #category : #private }
AbstractListPresenter >> setIndexes: aCollectionOfIndexes [
	"Set the indexexs of the selected items in case of multiple selection"
	self
		deprecated: 'Use the #selection object instead. This method assumes multiple selection'
		transformWith: '`@receiver setIndexes: `@arg'
						-> '`@receiver selection selectIndexes: `@arg'.

	self selection selectIndexes: aCollectionOfIndexes
]

{ #category : #api }
AbstractListPresenter >> setSelectedIndex: anIndex [
	self
		deprecated: 'Use #selectedIndex: instead'
		transformWith:
			'`@receiver setSelectedIndex: `@argument'
				-> '`@receiver selectedIndex: `@argument'.
	^ self selectIndex: anIndex
]

{ #category : #api }
AbstractListPresenter >> setSelectedItem: anIndex [
	self
		deprecated: 'Use #selectedItem: instead'
		transformWith:
			'`@receiver setSelectedItem: `@argument'
				-> '`@receiver selectedItem:`@argument'.
	^ self selectItem: anIndex
]

{ #category : #api }
AbstractListPresenter >> sortingBlock [
	"<api: #inspect>"
	"Return the ordering of the items"
	
	^ sortingBlockHolder value
]

{ #category : #api }
AbstractListPresenter >> sortingBlock: aBlock [
	"<api: #block getter: #sortingBlock registration: #whenSortingBlockChanged:>"
	"To set the ordering of the items"
	
	sortingBlockHolder value: aBlock
]

{ #category : #'api-events' }
AbstractListPresenter >> whenListChanged: aBlock [
	"Specify a block to value after the contents of the list has changed"
	"Basically when you set a new list of items"
	"<api: #event>"
	| block |
	block := [ :announcement :ann | 
	aBlock
		cull: announcement newValue
		cull: announcement oldValue
		cull: announcement
		cull: ann ].
	
	listAnnouncer
		when: ValueChanged
		do: block
]

{ #category : #'api-events' }
AbstractListPresenter >> whenMultiSelectionChanged: aBlock [
	"Set a block to value when the multiSelection value has changed"
	self deprecated: 'Should not use'
]

{ #category : #'api-events' }
AbstractListPresenter >> whenSelectedIndexChangedDo: aBlock [
	"Set a block to value when the selection index has changed"
	
	self
		deprecated: 'Use #selection whenChangedDo: instead'
		transformWith: '`@receiver whenSelectedIndexChangedDo: `@argument'
						-> '`@receiver selection whenChangedDo: [ :selection | `@argument value: selection selectedIndex ]'.

	^ self  selection whenChangedDo: [ :selection | aBlock value: selection selectedIndex ]
]

{ #category : #'api-events' }
AbstractListPresenter >> whenSelectedItemChanged: aBlock [
	
	self
		deprecated: 'Use #whenSelectedItemChangedDo: instead'
		transformWith: '`@receiver whenSelectedItemChanged: `@argument'
						-> '`@receiver whenSelectedItemChangedDo: `@argument'.
	^ self whenSelectedItemChangedDo: aBlock
]

{ #category : #'api-events' }
AbstractListPresenter >> whenSelectedItemChangedDo: aBlock [
	"Set a block to value when the select item is changed"
	
	self selection whenChangedDo: [ :selection | aBlock cull: selection selectedItem ]
]

{ #category : #'api-events' }
AbstractListPresenter >> whenSelectedItemsChanged: aBlock [
	"Set a block to value when the select item is changed"
	
	multiSelectionHolder selections whenChangedDo: aBlock
]

{ #category : #'api-events' }
AbstractListPresenter >> whenSelectionChanged: aBlock [
	
	self
		deprecated: 'Use #whenSelectionChangedDo: instead'
		transformWith: '`@receiver whenSelectionChanged: `@argument'
						-> '`@receiver whenSelectionChangedDo: `@argument'.
	^ self whenSelectionChangedDo: aBlock
]

{ #category : #'api-events' }
AbstractListPresenter >> whenSelectionChangedDo: aBlock [
	"Subscribe to changes in selection.
	This method works for all selection modes (single, multiple and no selection).
	The block used as argument will be sent an optional argument with the selection object."

	self selection whenChangedDo: aBlock
]

{ #category : #'api-events' }
AbstractListPresenter >> whenSelectionIndexChanged: aBlock [
	
	self
		deprecated: 'Use #selection whenChangedDo: instead'
		transformWith: '`@receiver whenSelectionIndexChanged: `@argument'
						-> '`@receiver selection whenChangedDo: [ :selection | `@argument value: selection selectedIndex ]'.
	^ self  selection whenChangedDo: [ :selection | aBlock value: selection selectedIndex ]
]

{ #category : #'api-events' }
AbstractListPresenter >> whenSelectionIndexesChanged: aBlock [
	"Set a block to value when the selection index has changed"
	
	self
		deprecated: 'Use #whenSelectionChangedDo: instead'
		transformWith: '`@receiver whenSelectionIndexesChanged: `@argument'
						-> '`@receiver whenSelectionChangedDo: [ :selection | `@argument value: selection selectedIndexes ]'.
	
	self whenSelectionChangedDo: [ :selection | aBlock value: selection selectedIndexes ].
]

{ #category : #private }
AbstractListPresenter >> wrapItem: anObject [ 
	"Return the item _anObject_ wrapped"

	^ wrapBlockHolder value cull: anObject 
]

{ #category : #private }
AbstractListPresenter >> wrapItem: anObject index: index [
	"Return the item _anObject_ wrapped"

	^ wrapBlockHolder value cull: anObject cull: index
]
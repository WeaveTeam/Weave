/*
Weave (Web-based Analysis and Visualization Environment)
Copyright (C) 2008-2011 University of Massachusetts Lowell

This file is a part of Weave.

Weave is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License, Version 3,
as published by the Free Software Foundation.

Weave is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/
package weave.ui
{
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.core.IUIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import spark.components.DataGrid;
	import spark.components.List;
	import spark.components.gridClasses.GridColumn;
	import spark.components.supportClasses.ListBase;
	import spark.components.supportClasses.SkinnableContainerBase;
	import spark.events.GridEvent;
	import spark.events.GridItemEditorEvent;
	import spark.layouts.VerticalLayout;
	import spark.layouts.supportClasses.LayoutBase;
	
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IColumnReference;
	import weave.core.LinkableWatcher;
	import weave.data.AttributeColumns.ReferencedColumn;
	
	/**
	 * Callbacks trigger when the list of objects changes.
	 */
	public class VariableSparkListController implements ILinkableObject
	{
		public function VariableSparkListController()
		{
		}
		
		public function dispose():void
		{
			view = null;
			hashMap = null;
			dynamicObject = null;
		}
		
		
		
		
		
		
		public function get view():SkinnableContainerBase
		{
			return _editor;
		}
		
		/**
		 * 
		 * @param editor This can be either a List or a DataGrid.
		 */
		public function set view(editor:SkinnableContainerBase):void
		{
			if (_editor == editor)
				return;
			
			if (_editor)
			{
				_editor.removeEventListener(DragEvent.DRAG_OVER, dragOverHandler);
				_editor.removeEventListener(DragEvent.DRAG_DROP, dragDropHandler);
				_editor.removeEventListener(DragEvent.DRAG_COMPLETE, dragCompleteHandler);
				_editor.removeEventListener(DragEvent.DRAG_ENTER, dragEnterCaptureHandler, true);
				if (_editor is DataGrid){
					_editor.removeEventListener(GridEvent.GRID_CLICK, handleItemClick);
					_editor.removeEventListener(GridItemEditorEvent.GRID_ITEM_EDITOR_SESSION_SAVE, handleGridItemEditEnd);
				}
				
			}
			
			_editor = editor;
			
			if (_editor)
			{
				if(editor is List){
					(_editor as List).dragEnabled = true;
					(_editor as List).dropEnabled = true;
					(_editor as List).dragMoveEnabled = true;
				}
				else if (editor is DataGrid){
					(_editor as DataGrid).dragEnabled = true;
					(_editor as DataGrid).dropEnabled = true;
					(_editor as DataGrid).dragMoveEnabled = true;
				}
				
				//_editor.allowMultipleSelection = _allowMultipleSelection;
				//_editor..layout.showDataTips = false;
				_editor.addEventListener(DragEvent.DRAG_OVER, dragOverHandler);
				_editor.addEventListener(DragEvent.DRAG_DROP, dragDropHandler);
				_editor.addEventListener(DragEvent.DRAG_COMPLETE, dragCompleteHandler);
				_editor.addEventListener(DragEvent.DRAG_ENTER, dragEnterCaptureHandler, true);
			}
			
			_nameColumn = null;
			_valueColumn = null;
			var dataGrid:DataGrid = _editor as DataGrid;
			if (dataGrid)
			{
				dataGrid.sortableColumns = false;
				// keep existing columns if there are any
				if (!dataGrid.columns.length)
				{
					dataGrid.editable = true;
					dataGrid.addEventListener(GridEvent.GRID_CLICK, handleItemClick);
					dataGrid.addEventListener(GridItemEditorEvent.GRID_ITEM_EDITOR_SESSION_SAVE, handleGridItemEditEnd);
					
					dataGrid.draggableColumns = false;
					
					_nameColumn = new GridColumn();
					_nameColumn.sortable = false;
					_nameColumn.editable = true;
					_nameColumn.labelFunction = getObjectName;
					_nameColumn.showDataTips = true;
					_nameColumn.dataTipFunction = nameColumnDataTip;
					setNameColumnHeader();
					
					_valueColumn = new GridColumn();
					_valueColumn.sortable = false;
					_valueColumn.editable = false;
					_valueColumn.headerText = lang("Value");
					_valueColumn.labelFunction = getItemLabel;
					
					dataGrid.columns = new ArrayCollection([_nameColumn, _valueColumn]);
				}
			}
			else if (_editor)
			{
				(_editor as ListBase).labelFunction = getItemLabel;
			}
			
			if (dynamicObject && _editor){
				setRowCount(1);
			}
			updateDataProvider();
		}
		
		private function get layout():LayoutBase
		{
			if(_editor is List){
				return (_editor as List).layout;
			}
			return null;
		}
		
		private function get dataprovider():IList
		{
			if(_editor is List)
				return (_editor as List).dataProvider;
			else if(_editor is DataGrid)
				return (_editor as DataGrid).dataProvider;
			return null;
		}
		
		private function set dataprovider(dp:IList):void
		{
			if(_editor is List)
				(_editor as List).dataProvider = dp;
			else if(_editor is DataGrid)
				(_editor as DataGrid).dataProvider = dp;
		}
		
		private function get selectedItems():Vector.<Object>{
			if(_editor is List)
				return (_editor as List).selectedItems;
			else if(_editor is DataGrid)
				return (_editor as DataGrid).selectedItems;
			return null;
		}
		
		private function set selectedItems(selItems:Vector.<Object>){
			if(_editor is List)
				(_editor as List).selectedItems = selItems;
			else if(_editor is DataGrid)
				(_editor as DataGrid).selectedItems = selItems;
			return null;
		}
		
		private function get selectedIndices():Vector.<int>{
			if(_editor is List)
				return (_editor as List).selectedIndices;
			else if(_editor is DataGrid)
				return (_editor as DataGrid).selectedIndices;
			return null;
		}
		
		private function setRowCount(value:int):void{
			if(_editor is List){
				if((_editor as List).layout is VerticalLayout){
					((_editor as List).layout as VerticalLayout).requestedRowCount = value
				}
			}else if(_editor is DataGrid){
				(_editor as DataGrid).requestedRowCount = value;
			}
		}
		
		private function maxVerticalScrollPosition():Number
		{
			if(_editor is List)
				return ((_editor as List).dataGroup.contentHeight) - ((_editor as List).dataGroup.height) ;
			/*if(_editor is DataGrid)
			return ((_editor as DataGrid). - ((_editor as DataGrid).dataGroup.height) ;*/
			return NaN;
		}
		
		private function setLabelFunction(labelFunc:Function):void{
			if(_editor is ListBase){
				(_editor as ListBase).labelFunction  = labelFunc
			}else if(_editor is DataGrid){
				var columns:IList = (_editor as DataGrid).columns;
				for(var i:int = 0 ; i < columns.length; i++){
					(columns[i] as GridColumn).labelFunction = labelFunc;
				}
			}
		}
		
		private function setNameColumnHeader():void
		{
			if (!_nameColumn)
				return;
			if (hashMap && hashMap.getNames().length)
				_nameColumn.headerText = lang("Name (Click below to edit)")
			else
				_nameColumn.headerText = lang("Name");
		}
		
		private function nameColumnDataTip(item:Object, ..._):String
		{
			return lang("{0} (Click to rename)", getObjectName(item));
		}
		
		private var _allowMultipleSelection:Boolean = true;
		
		public function set allowMultipleSelection(value:Boolean):void
		{
			_allowMultipleSelection = value;
			/*if (view)
			view.allowMultipleSelection = value;*/
		}
		
		private var _editor:SkinnableContainerBase;
		private var _layout:LayoutBase;
		private var _nameColumn:GridColumn;
		private var _valueColumn:GridColumn;
		private const _hashMapWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, refreshLabels, true);
		private const _dynamicObjectWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, updateDataProvider, true);
		private const _childListWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, updateDataProvider);
		private var _labelFunction:Function = null;
		private var _filterFunction:Function = null;
		private var _reverse:Boolean = false;
		
		public function get hashMap():ILinkableHashMap
		{
			return _hashMapWatcher.target as ILinkableHashMap;
		}
		public function set hashMap(value:ILinkableHashMap):void
		{
			if (value)
				dynamicObject = null;
			
			_hashMapWatcher.target = value;
			_childListWatcher.target = value && value.childListCallbacks;
		}
		
		public function get dynamicObject():ILinkableDynamicObject
		{
			return _dynamicObjectWatcher.target as ILinkableDynamicObject;
		}
		public function set dynamicObject(value:ILinkableDynamicObject):void
		{
			if (value)
			{
				hashMap = null;
				if (_editor)
					setRowCount(1);
			}
			
			_dynamicObjectWatcher.target = value;
		}
		
		private function refreshLabels():void
		{
			if (_editor is List)
				(_editor as List).labelFunction = (_editor as List).labelFunction; // this refreshes the labels
			else if(_editor is DataGrid){
				var columns:IList = (_editor as DataGrid).columns;
				for(var i:int = 0 ; i < columns.length; i++){
					(columns[i] as GridColumn).labelFunction = (columns[i] as GridColumn).labelFunction;
				}
			}
		}
		
		private function updateDataProvider():void
		{
			if (!_editor)
				return;
			
			var vsp:int = layout.verticalScrollPosition;
			var selItems:Vector.<Object> = selectedItems;
			
			if (dynamicObject)
			{
				dataprovider = dynamicObject.internalObject as IList;
			}
			else if (hashMap)
			{
				setNameColumnHeader();
				var objects:Array = hashMap.getObjects();
				if (_filterFunction != null)
					objects = objects.filter(_filterFunction);
				if (_reverse)
					objects = objects.reverse();
				dataprovider = new ArrayCollection(objects);
			}
			else
				dataprovider = null;
			
			if (!(_editor is DataGrid))
				setRowCount(1);
			
			var view:ICollectionView = dataprovider as ICollectionView;
			if (view)
				view.refresh();
			
			if (selItems && selItems.length)
			{
				_editor.validateProperties();
				/*if (vsp >= 0 && vsp <= _editor.maxVerticalScrollPosition)
				_editor.verticalScrollPosition = vsp;*/
				selectedItems = selItems;
			}
			
			getCallbackCollection(this).triggerCallbacks();
		}
		
		public function removeAllItems():void
		{
			if (hashMap)
				hashMap.removeAllObjects();
			else if (dynamicObject)
				dynamicObject.removeObject();
		}
		
		public function removeSelectedItems():void
		{
			if (hashMap && selectedIndex >= 0)
			{
				var names:Array = [];
				var selIndices:Vector.<int> = selectedIndices;
				for (var i:int = 0; i < selIndices.length; i++)
				{
					var selectedIndex:int = selIndices[i];
					
					names.push(hashMap.getName(dataprovider[selectedIndex] as ILinkableObject) );
				}	
				
				for each(var name:String in names)
				{
					hashMap.removeObject(name);
				}
			}
			else if (dynamicObject)
			{
				dynamicObject.removeObject();
			}
		}
		
		public function beginEditVariableName(object:ILinkableObject):void
		{
			var dg:DataGrid = _editor as DataGrid;
			if (dg && hashMap)
			{
				var rowIndex:int = hashMap.getObjects().indexOf(object);
				if (rowIndex >= 0)
					dg.startItemEditorSession(rowIndex, 0) ;
			}
		}
		
		/**
		 * @param item
		 * @return The name of the item in the ILinkableHashMap or the ILinkableDynamicObject internal object's global name
		 */		
		public function getItemName(item:Object):String
		{
			if (hashMap)
				return hashMap.getName(item as ILinkableObject);
			if (dynamicObject)
				return dynamicObject.globalName;
			return null;
		}
		
		private function getItemLabel(item:Object, ..._):String
		{
			if (_labelFunction != null)
				return _labelFunction(item);
			else
				return getObjectName(item) || String(item);
		}
		
		public function set labelFunction(value:Function):void
		{
			_labelFunction = value;
			refreshLabels();
		}
		
		public function set filterFunction(value:Function):void
		{
			if (value != null && value.length < 3)
				value = function(item:*, i:*, a:*):* { return value(item); }
			_filterFunction = value;
			updateDataProvider();
		}
		
		public function set reverse(value:Boolean):void
		{
			if (_reverse != value)
			{
				_reverse = value;
				updateDataProvider();
			}
		}
		
		private function updateHashMapNameOrder():void
		{
			if (!_editor)
				return;
			
			_editor.validateNow();
			
			if (hashMap)
			{
				// update object map name order based on what is in the data provider
				var newNameOrder:Array = [];
				var dp:ArrayCollection = dataprovider as ArrayCollection;
				for (var i:int = 0; i < dp.length; i++)
				{
					var object:ILinkableObject = dp[i] as ILinkableObject;
					if (object)
						newNameOrder[i] = hashMap.getName(object);
				}
				if (_reverse)
					newNameOrder.reverse();
				hashMap.setNameOrder(newNameOrder);
			}
		}
		
		private function removeObjectsMissingFromDataProvider():void
		{
			if (!_editor)
				return;
			
			if (hashMap)
			{
				var objects:Array = hashMap.getObjects();
				for each (var object:ILinkableObject in objects)
				{
					if(!(dataprovider as ArrayCollection).contains(object))
						hashMap.removeObject(hashMap.getName(object));
				}
			}
			else if(dynamicObject)
			{
				if(!(dataprovider as ArrayCollection).contains(dynamicObject.internalObject))
					dynamicObject.removeObject();
			}
		}
		
		// called when something is being dragged on top of this list
		private function dragOverHandler(event:DragEvent):void
		{
			if (dragSourceIsAcceptable(event))
				DragManager.showFeedback(DragManager.MOVE);
			else
				DragManager.showFeedback(DragManager.NONE);
		}
		
		// called when something is dropped into this list
		private function dragDropHandler(event:DragEvent):void
		{
			//hides the drop visual lines
			event.currentTarget.hideDropFeedback(event);
			//_editor.mx_internal::resetDragScrolling(); // if we don't do this, list will scroll when mouse moves even when not dragging something
			
			if (event.dragInitiator == _editor)
			{
				event.action = DragManager.MOVE;
				_editor.callLater(updateHashMapNameOrder);
			}
			else
			{
				event.preventDefault();
				
				var ref:IColumnReference;
				var refCol:ReferencedColumn;
				var meta:Object;
				var items:Array = event.dragSource.dataForFormat("items") as Array;
				if (hashMap)
				{
					var prevNames:Array = hashMap.getNames();
					var newNames:Array = [];
					
					var dropIndex:int = (layout.calculateDropLocation(event)).dropIndex;
					var newObject:ILinkableObject;
					
					// copy items in reverse order because selectedItems is already reversed
					for (var i:int = items.length - 1; i >= 0; i--)
					{
						var object:ILinkableObject = items[i] as ILinkableObject;
						if (object && hashMap.getName(object) == null)
						{
							newObject = hashMap.requestObjectCopy(null, object);
							newNames.push(hashMap.getName(newObject));
						}
						
						ref = items[i] as IColumnReference;
						if (ref)
						{
							meta = ref.getColumnMetadata();
							if (meta)
							{
								refCol = hashMap.requestObject(null, ReferencedColumn, false);
								refCol.setColumnReference(ref.getDataSource(), meta);
								newObject = refCol;
								newNames.push(hashMap.getName(newObject));
							}
						}
					}
					
					// insert new names inside prev names list and save the new name order
					var args:Array = newNames;
					newNames.unshift(dropIndex, 0);
					prevNames.splice.apply(null, args);
					hashMap.setNameOrder(prevNames);
					
					if (items.length == 1 && newObject)
						beginEditVariableName(newObject);
				}
				else if (dynamicObject && items.length > 0)
				{
					// only copy the first item in the list
					var item:Object = items[0];
					if (item is ILinkableObject)
						dynamicObject.requestLocalObjectCopy(item as ILinkableObject);
					
					ref = item as IColumnReference;
					if (ref)
					{
						meta = ref.getColumnMetadata();
						if (meta)
						{
							refCol = dynamicObject.requestLocalObject(ReferencedColumn, false);
							refCol.setColumnReference(ref.getDataSource(), meta);
						}
					}
				}
			}
		}
		
		private function dragSourceIsAcceptable(event:DragEvent):Boolean
		{
			if (event.dragSource.hasFormat("items"))
			{
				var items:Array = event.dragSource.dataForFormat("items") as Array;
				for each (var item:Object in items)
				{
					var ref:IColumnReference = item as IColumnReference;
					if (item is ILinkableObject || (ref && ref.getColumnMetadata() != null))
						return true;
				}
			}
			return false;
		}
		
		// called when something is dragged on top of this list
		private function dragEnterCaptureHandler(event:DragEvent):void
		{
			if (dragSourceIsAcceptable(event))
				DragManager.acceptDragDrop(event.currentTarget as IUIComponent);
			event.preventDefault();
		}
		
		public var defaultDragAction:String = DragManager.COPY;
		
		// called when something in this list is dragged and dropped somewhere else
		private function dragCompleteHandler(event:DragEvent):void
		{
			if (event.shiftKey)
				event.action = DragManager.MOVE;
			else if (event.ctrlKey)
				event.action = DragManager.COPY;
			else
				event.action = defaultDragAction;
			
			_editor.callLater(removeObjectsMissingFromDataProvider);
		}
		
		private function getObjectName(item:Object, ..._):String
		{
			if (hashMap)
				return hashMap.getName(item as ILinkableObject);
			if (dynamicObject)
				return dynamicObject.globalName;
			return null;
		}
		
		/*protected function handleItemEditEnd(event:GridEvent):void
		{
		var oldName:String = hashMap.getName(event.itemRenderer.data as ILinkableObject);
		var grid:DataGrid = event.target as DataGrid;
		
		if (grid)
		{
		var col:int = event.columnIndex;
		var field:String = (grid.columns[col] as GridColumn).editorDataField;
		var newValue:String = grid.itemEditorInstance[field];
		
		if (hashMap && newValue && hashMap.getNames().indexOf(newValue) < 0)
		hashMap.renameObject(oldName, newValue);
		
		if (dynamicObject && newValue != dynamicObject.globalName)
		dynamicObject.globalName = newValue;
		}
		}*/
		
		private var oldName:String;
		private function handleItemClick(event:GridEvent):void
		{
			var oldName:String = hashMap.getName(event.itemRenderer.data as ILinkableObject);			
		}
		
		private function handleGridItemEditEnd(event:GridItemEditorEvent):void
		{
			var newValue:String = (event.currentTarget as DataGrid).dataProvider[event.rowIndex][event.column.dataField];
			if (hashMap && newValue && hashMap.getNames().indexOf(newValue) < 0)
				hashMap.renameObject(oldName, newValue);
			if (dynamicObject && newValue != dynamicObject.globalName)
				dynamicObject.globalName = newValue;
		}
	}
}
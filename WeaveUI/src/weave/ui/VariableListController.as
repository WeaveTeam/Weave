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
	import mx.controls.DataGrid;
	import mx.controls.List;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.controls.listClasses.ListBase;
	import mx.core.IUIComponent;
	import mx.core.mx_internal;
	import mx.events.DataGridEvent;
	import mx.events.DragEvent;
	import mx.events.ListEvent;
	import mx.managers.DragManager;
	
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.core.CallbackJuggler;
	
	public class VariableListController implements ILinkableObject
	{
		public function VariableListController()
		{
		}
		
		public function dispose():void
		{
			view = null;
			hashMap = null;
			dynamicObject = null;
		}
		
		public function get view():ListBase
		{
			return _editor;
		}
		
		/**
		 * @param editor This can be either a List or a DataGrid.
		 */
		public function set view(editor:ListBase):void
		{
			if (_editor == editor)
				return;
			
			if (_editor)
			{
				_editor.removeEventListener(DragEvent.DRAG_OVER, dragOverHandler);
				_editor.removeEventListener(DragEvent.DRAG_DROP, dragDropHandler);
				_editor.removeEventListener(DragEvent.DRAG_COMPLETE, dragCompleteHandler);
				_editor.removeEventListener(DragEvent.DRAG_ENTER, dragEnterCaptureHandler, true);
				if (_editor is DataGrid)
					(_editor as DataGrid).removeEventListener(ListEvent.ITEM_EDIT_END, handleItemEditEnd);
			}
			
			_editor = editor;
			
			if (_editor)
			{
				_editor.dragEnabled = true;
				_editor.dropEnabled = true;
				_editor.dragMoveEnabled = true;
				_editor.allowMultipleSelection = _allowMultipleSelection;
				_editor.showDataTips = false;
				_editor.addEventListener(DragEvent.DRAG_OVER, dragOverHandler);
				_editor.addEventListener(DragEvent.DRAG_DROP, dragDropHandler);
				_editor.addEventListener(DragEvent.DRAG_COMPLETE, dragCompleteHandler);
				_editor.addEventListener(DragEvent.DRAG_ENTER, dragEnterCaptureHandler, true);
			}
			
			var dataGrid:DataGrid = _editor as DataGrid;
			if (dataGrid)
			{
				dataGrid.editable = true;
				dataGrid.addEventListener(ListEvent.ITEM_EDIT_END, handleItemEditEnd);
				
				var nameCol:DataGridColumn = new DataGridColumn();
				nameCol.sortable = false;
				nameCol.editable = true;
				nameCol.headerText = lang("Name");
				nameCol.labelFunction = getObjectName;
				
				var valueCol:DataGridColumn = new DataGridColumn();
				valueCol.sortable = false;
				valueCol.editable = false;
				valueCol.headerText = lang("Value");
				valueCol.labelFunction = getItemLabel;
				
				dataGrid.columns = [nameCol, valueCol];
			}
			else if (_editor)
			{
				_editor.labelFunction = getItemLabel;
			}
			
			if (dynamicObject && _editor)
				_editor.rowCount = 1;
			updateDataProvider();
		}
		
		private var _allowMultipleSelection:Boolean = true;
		
		public function set allowMultipleSelection(value:Boolean):void
		{
			_allowMultipleSelection = value;
			if (view)
				view.allowMultipleSelection = value;
		}
		
		private var _editor:ListBase;
		private const _hashMapJuggler:CallbackJuggler = new CallbackJuggler(this, refreshLabels, true);
		private const _dynamicObjectJuggler:CallbackJuggler = new CallbackJuggler(this, updateDataProvider, true);
		private const _childListJuggler:CallbackJuggler = new CallbackJuggler(this, updateDataProvider, false);
		private var _labelFunction:Function = null;
		
		public function get hashMap():ILinkableHashMap
		{
			return _hashMapJuggler.target as ILinkableHashMap;
		}
		public function set hashMap(value:ILinkableHashMap):void
		{
			if (value)
				dynamicObject = null;
			
			_hashMapJuggler.target = value;
			_childListJuggler.target = value && value.childListCallbacks;
		}
		
		public function get dynamicObject():ILinkableDynamicObject
		{
			return _dynamicObjectJuggler.target as ILinkableDynamicObject;
		}
		public function set dynamicObject(value:ILinkableDynamicObject):void
		{
			if (value)
			{
				hashMap = null;
				if (_editor)
					_editor.rowCount = 1;
			}
			
			_dynamicObjectJuggler.target = value;
		}
		
		private function refreshLabels():void
		{
			if (_editor)
				_editor.labelFunction = _editor.labelFunction; // this refreshes the labels
		}
		
		private function updateDataProvider():void
		{
			if (!_editor)
				return;
			
			if (dynamicObject)
			{
				_editor.dataProvider = dynamicObject.internalObject;
			}
			else if (hashMap)
			{
				_editor.dataProvider = hashMap.getObjects();
			}
			
			var view:ICollectionView = _editor.dataProvider as ICollectionView;
			if (view)
				view.refresh();
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
				for (var i:int = 0; i < _editor.selectedIndices.length; i++)
				{
					var selectedIndex:int = _editor.selectedIndices[i];
					
					names.push(hashMap.getName(_editor.dataProvider[selectedIndex] as ILinkableObject) );
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
				return getItemName(item);
		}
		
		public function set labelFunction(value:Function):void
		{
			_labelFunction = value;
			refreshLabels();
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
				for (var i:int = 0; i < _editor.dataProvider.length; i++)
				{
					var object:ILinkableObject = _editor.dataProvider[i] as ILinkableObject;
					if (object)
						newNameOrder[i] = hashMap.getName(object);
				}
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
					if(!(_editor.dataProvider as ArrayCollection).contains(object))
						hashMap.removeObject(hashMap.getName(object));
				}
			}
			else if(dynamicObject)
			{
				if(!(_editor.dataProvider as ArrayCollection).contains(dynamicObject.internalObject))
					dynamicObject.removeObject();
			}
		}
		
		// called when something is being dragged on top of this list
		private function dragOverHandler(event:DragEvent):void
		{
			DragManager.showFeedback(DragManager.MOVE);
		}
		
		// called when something is dropped into this list
		private function dragDropHandler(event:DragEvent):void
		{
			//need to add re-order functionality				
			//if(event.dragInitiator == _editor)
			//super.dragDropHandler(event);
			
			//hides the drop visual lines
			event.currentTarget.hideDropFeedback(event);
			_editor.mx_internal::resetDragScrolling(); // if we don't do this, list will scroll when mouse moves even when not dragging something
			
			if (event.dragInitiator == _editor)
			{
				event.action = DragManager.MOVE;
				_editor.callLater(updateHashMapNameOrder);
			}
			else
			{
				event.preventDefault();
				
				var object:ILinkableObject;
				var items:Array = event.dragSource.dataForFormat("items") as Array;
				if (hashMap)
				{
					var prevNames:Array = hashMap.getNames();
					var newNames:Array = [];
					var dropIndex:int = _editor.calculateDropIndex(event);
					
					// copy each item in the list, in order
					for (var i:int = 0; i < items.length; i++)
					{
						object = items[i] as ILinkableObject;
						if (hashMap.getName(object) == null)
						{
							var newObject:ILinkableObject = hashMap.requestObjectCopy(null, object);
							newNames.push(hashMap.getName(newObject));
						}
					}
					
					// insert new names inside prev names list and save the new name order
					var args:Array = newNames;
					newNames.unshift(dropIndex, 0);
					prevNames.splice.apply(null, args);
					hashMap.setNameOrder(prevNames);
				}
				else if (dynamicObject && items.length > 0)
				{
					// only copy the first item in the list
					dynamicObject.requestLocalObjectCopy(items[0]);
				}
			}
		}
		
		// called when something is dragged on top of this list
		private function dragEnterCaptureHandler(event:DragEvent):void
		{
			if (event.dragSource.hasFormat("items"))
			{
				var items:Array = event.dragSource.dataForFormat("items") as Array;
				if (items[0] is ILinkableObject)
					DragManager.acceptDragDrop(event.currentTarget as IUIComponent);
			}
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
		
		protected function handleItemEditEnd(event:DataGridEvent):void
		{
			var oldName:String = hashMap.getName(event.itemRenderer.data as ILinkableObject);
			var grid:DataGrid = event.target as DataGrid;
			
			if (grid)
			{
				var col:int = event.columnIndex;
				var field:String = (grid.columns[col] as DataGridColumn).editorDataField;
				var newValue:String = grid.itemEditorInstance[field];
				
				if (hashMap && newValue && hashMap.getNames().indexOf(newValue) < 0)
					hashMap.renameObject(oldName, newValue);
				
				if (dynamicObject && newValue != dynamicObject.globalName)
					dynamicObject.globalName = newValue;
			}
		}
	}
}
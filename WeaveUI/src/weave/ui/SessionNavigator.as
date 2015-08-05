/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.ui
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.CursorBookmark;
	import mx.collections.IViewCursor;
	import mx.events.ListEvent;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.ui.IObjectWithDescription;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.LinkableWatcher;
	import weave.core.SessionManager;
	import weave.primitives.WeaveTreeItem;
	import weave.utils.ColumnUtils;
			
	public class SessionNavigator extends CustomTree implements ILinkableObject
	{
			override protected function itemToUID(data:Object):String
			{
				if (data is WeaveTreeItem)
					data = (data as WeaveTreeItem).dependency;
				return super.itemToUID(data);
			}
			private function compareItems(a:WeaveTreeItem, b:WeaveTreeItem):Boolean
			{
				return (a && b) ? a.dependency === b.dependency : a === b;
			}
			override public function getItemIndex(item:Object):int
			{
				var cursor:IViewCursor = collection.createCursor();
				var i:int = 0;
				do
				{
					//if (selectedItemsCompareFunction(cursor.current, item))
					
					var a:WeaveTreeItem = cursor.current as WeaveTreeItem;
					var b:WeaveTreeItem = item as WeaveTreeItem;
					if ((a && b) ? a.dependency === b.dependency : a === b)
						break;
					i++;
				}
				while (cursor.moveNext());
				cursor.seek(CursorBookmark.FIRST, 0);
				return i;
			}
			
			private var _linkableObjectName:String;
			private var _linkableObjectTypeFilter:Class = null;
			private var _overrideSelectedItem:WeaveTreeItem;
			private var _treeChanged:Boolean;
			private const rootWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, invalidateList, true);
			
			override public function initialize():void
			{
				if (initialized)
					return;
				
				this.setStyle('openDuration', 0);
				this.percentWidth = 100;
				this.percentHeight = 100;
				this.doubleClickEnabled = true;
				this.labelFunction = nodeLabelFunction;
				this.selectedItemsCompareFunction = compareItems;
				this.addEventListener(ListEvent.CHANGE, handleItemSelect);
				this.addEventListener(MouseEvent.DOUBLE_CLICK, handleDoubleClick);
				
				super.initialize();
			}
			
			override protected function childrenCreated():void
			{
				super.childrenCreated();
				
				if (rootObject == null)
					rootObject = WeaveAPI.globalHashMap;
				getCallbackCollection(WeaveAPI.EditorManager).addGroupedCallback(this, invalidateList);
				(WeaveAPI.SessionManager as SessionManager).addTreeCallback(this, handleTreeChange);
			}
			
			private function handleTreeChange():void
			{
				_treeChanged = true;
				invalidateList();
			}
			
			override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
			{
				if (_treeChanged)
				{
					refreshDataProvider();
					_treeChanged = false;
				}
				super.updateDisplayList(unscaledWidth, unscaledHeight);
			}

			public function set rootObject(value:ILinkableObject):void
			{
				if (rootWatcher.target == value)
					return;
				
				rootWatcher.target = value;

				if (value == WeaveAPI.globalHashMap)
				{
					_linkableObjectName = "Weave";
				}
				else if (value)
				{
					var path:Array = (WeaveAPI.SessionManager as SessionManager).getPath(WeaveAPI.globalHashMap, value);
					_linkableObjectName = path ? path[path.length - 1] : null;
				}
				
				updateRootNode();
			}
			public function get rootObject():ILinkableObject
			{
				return rootWatcher.target;
			}
			
			private function updateRootNode():void
			{
				var rootNode:WeaveTreeItem = (WeaveAPI.SessionManager as SessionManager).getSessionStateTree(rootWatcher.target, _linkableObjectName, _linkableObjectTypeFilter);
				refreshDataProvider(rootNode);
				expandItem(rootNode, true);
			}
			
			private function nodeLabelFunction(item:WeaveTreeItem):String
			{
				// append class name to the label.
				var label:String = getQualifiedClassName(item.dependency).split("::").pop();
				if (item.label)
					label += ' ' + Compiler.encodeString(item.label);
				
				// get editor label
				var editorLabel:String = WeaveAPI.EditorManager.getLabel(item.dependency);
				// get description
				var description:String = null;
				var iowd:IObjectWithDescription = item.dependency as IObjectWithDescription
				if (iowd)
					description = iowd.getDescription();
				else if (item.dependency is IAttributeColumn)
					description = ColumnUtils.getTitle(item.dependency as IAttributeColumn);
				
				var inParens:String = editorLabel || description;
				if (editorLabel && description)
					inParens = editorLabel + ': ' + description;
				if (inParens)
					label += StandardLib.substitute(' ({0})', inParens);
				
				return label;
			}
			
			private function handleItemSelect(event:ListEvent):void
			{
				expandItem(selectedTreeItem, true);
			}
			
			private function handleDoubleClick(event:MouseEvent):void
			{
				ControlPanel.openEditor(getSelectedLinkableObject(), null, null, false);
			}
			
			public function set linkableObjectTypeFilter(className:Class):void
			{
				_linkableObjectTypeFilter = className;
				updateRootNode();
			}
			
			public function getSelectedPath(fromGlobalHashMap:Boolean = true):Array
			{
				var root:ILinkableObject = fromGlobalHashMap ? WeaveAPI.globalHashMap : rootObject;
				return WeaveAPI.SessionManager.getPath(root, getSelectedLinkableObject());
			}
			
			public function getSelectedLinkableObject():ILinkableObject
			{
				return selectedTreeItem ? selectedTreeItem.dependency : null;
			}
			
			[Bindable("change")]
			[Bindable("valueCommit")]
			override public function get selectedItem():Object
			{
				return _overrideSelectedItem || super.selectedItem;
			}
			override public function set selectedItem(data:Object):void
			{
				super.selectedItem = data;
			}
			
			public function get selectedTreeItem():WeaveTreeItem
			{
				return selectedItem as WeaveTreeItem;
			}
			
			override public function expandItem(item:Object, open:Boolean, animate:Boolean=false, dispatchEvent:Boolean=false, cause:Event=null):void
			{			
				super.expandItem(item, open, animate, dispatchEvent, cause);

				// keep expanding children while there is only one child
				var treeItem:WeaveTreeItem = item as WeaveTreeItem;
				if (open && treeItem && treeItem.children && treeItem.children.length == 1)
					expandItem(treeItem.children[0], open, animate, dispatchEvent, cause);
			}
}
}
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

package weave.core
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.core.UIComponent;
	import mx.events.IndexChangedEvent;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableDisplayObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;

	/**
	 * This is an all-static class containing functions related to UI and ILinkableObjects.
	 * 
	 * @author adufilie
	 */
	public class UIUtils
	{
		/**
		 * This function adds a callback to a LinkableHashMap to monitor any DisplayObjects contained in it.
		 * @TODO check if already linked
		 * @param uiParent A UIComponent to synchronize with the given hashMap.
		 * @param hashMap A LinkableHashMap containing DisplayObjects to synchronize with the given uiParent.
		 */
		public static function linkDisplayObjects(uiParent:UIComponent, hashMap:ILinkableHashMap, keepLinkableChildrenOnTop:Boolean = false):void
		{
			hashMap.childListCallbacks.addImmediateCallback(uiParent, handleHashMapChildListChange, [uiParent, hashMap, keepLinkableChildrenOnTop]);
			
			// add all existing sessioned DisplayObjects as children
			var names:Array = hashMap.getNames();
			for (var i:int = 0; i < names.length; i++)
				addChild(uiParent, hashMap, names[i], keepLinkableChildrenOnTop);
			
			// update hashMap name order when a child index changes
			var listener:Function = function (event:Event):void
			{
				if (parentToBusyFlagMap[uiParent])
					return;
				var newNameOrder:Array = [];
				var wrappers:Array = hashMap.getObjects(ILinkableDisplayObject);
				for (var i:int = 0; i < uiParent.numChildren; i++)
				{
					var name:String = null;
					// case 1: check if child is a registered linkable child of the hash map
					var child:DisplayObject = uiParent.getChildAt(i);
					if (child is ILinkableObject)
						name = hashMap.getName(child as ILinkableObject);
					if (name == null)
					{
						// case 2: check if child is the internal display object of an ILinkableDisplayObject
						for each (var wrapper:ILinkableDisplayObject in wrappers)
						{
							if (wrapper.getDisplayObject() == child)
							{
								name = hashMap.getName(wrapper);
								break;
							}
						}
					}
					if (name != null)
						newNameOrder.push(name);
				}
				parentToBusyFlagMap[uiParent] = true;
				hashMap.setNameOrder(newNameOrder);
				delete parentToBusyFlagMap[uiParent];
				
				// setting the name order on the hash map may not trigger callbacks, but
				// the child order with respect to non-linkable children may have changed,
				// so always update child order after an IndexChangedEvent.
				uiParent.callLater(updateChildOrder, [uiParent, hashMap, keepLinkableChildrenOnTop]);
			};
			parentToListenerMap[uiParent] = listener;
			uiParent.addEventListener(IndexChangedEvent.CHILD_INDEX_CHANGE, listener);
		}
		
		/**
		 * This function will undo the linking done by linkUIComponents(uiParent, hashMap).
		 * @param uiParent The uiParent parameter for a previous call to linkUIComponents().
		 * @param hashMap The hashMap parameter for a previous call to linkUIComponents().
		 */
		public static function unlinkDisplayObjects(uiParent:UIComponent, hashMap:ILinkableHashMap):void
		{
			if (parentToListenerMap[uiParent] != undefined)
			{
				hashMap.childListCallbacks.removeCallback(handleHashMapChildListChange);
				uiParent.removeEventListener(IndexChangedEvent.CHILD_INDEX_CHANGE, parentToListenerMap[uiParent]);
				
				var numChildren:int = uiParent.numChildren;
				for (var i:int = 0; i < numChildren; i++)
				{
					var uiChild:DisplayObject = uiParent.getChildAt(i);
					var listener:Function = childToEventListenerMap[uiChild] as Function;
					if (listener == null)
						continue;
					uiChild.removeEventListener(Event.ADDED, listener);
					uiChild.removeEventListener(Event.REMOVED, listener);
					delete childToEventListenerMap[uiChild];
				}
				for each (var child:ILinkableDisplayObject in hashMap.getObjects(ILinkableDisplayObject))
					getCallbackCollection(child).removeCallback(updateChildOrder);
			}
		}
		
		/**
		 * This maps a UIComponent to a listener function created by linkUIComponents().
		 */		
		private static const parentToListenerMap:Dictionary = new Dictionary(true); // weak links to be gc-friendly
		
		/**
		 * This maps a parent to a Boolean value which indicates whether
		 * or not UIUtils is busy processing some event for that parent.
		 */
		private static const parentToBusyFlagMap:Dictionary = new Dictionary(true); // weak links to be gc-friendly

		/**
		 * This maps a child UIComponent to a FlexEvent.REMOVE event listener.
		 */
		private static const childToEventListenerMap:Dictionary = new Dictionary(true); // weak links to be gc-friendly
		
		/**
		 * This function will add a sessioned UIComponent to a parent UIComponent.
		 * @param uiParent The parent UIComponent to add a child to.
		 * @param hashMap A LinkableHashMap containing a dynamically created UIComponent.
		 * @param childName The name of a child in the hashMap.
		 */
		private static function addChild(uiParent:UIComponent, hashMap:ILinkableHashMap, childName:String, keepLinkableChildrenOnTop:Boolean):void
		{
			if (!uiParent.initialized)
				return uiParent.callLater(addChild, arguments);
			
			var childObject:ILinkableObject = hashMap.getObject(childName);
			
			// special case: ILinkableDisplayObject
			if (childObject is ILinkableDisplayObject)
			{
				(childObject as ILinkableDisplayObject).setParentContainer(uiParent);
				var cc:ICallbackCollection = getCallbackCollection(childObject);
				cc.addImmediateCallback(uiParent, updateChildOrder, [uiParent, hashMap, keepLinkableChildrenOnTop], true);
				return;
			}
			
			var uiChild:DisplayObject = childObject as DisplayObject;
			// stop if the child was already removed from the hash map
			if (uiChild == null)
				return;

			// When the child is added to the parent, the child order should be updated.
			// When the child is removed from the parent with removeChild() or removeChildAt(), it should be disposed of.
			var listener:Function = function (event:Event):void
			{
				if (event.target == uiChild)
				{
					if (event.type == Event.ADDED)
						updateChildOrder(uiParent, hashMap, keepLinkableChildrenOnTop);
					else if (event.type == Event.REMOVED && !(childObject is ILinkableDisplayObject))
						hashMap.removeObject(childName);
				}
			};
			uiChild.addEventListener(Event.ADDED, listener);
			uiChild.addEventListener(Event.REMOVED, listener);
			childToEventListenerMap[uiChild] = listener; // save a pointer so the event listener can be removed later.
			
			if (uiParent == uiChild.parent)
				updateChildOrder(uiParent, hashMap, keepLinkableChildrenOnTop);
			else
				uiParent.addChild(uiChild);
		}
		
		/**
		 * This function gets called when a LinkableHashMap changes that was previously linked with a DisplayObjectContainer through linkUIComponents().
		 * Any sessioned DisplayObjects that were added/removed/reordered will be handled here.
		 * @param uiParent A DisplayObjectContainer to synchronize with the given hashMap.
		 * @param hashMap A LinkableHashMap containing sessioned DisplayObjects to synchronize with the given uiParent.
		 */
		private static function handleHashMapChildListChange(uiParent:UIComponent, hashMap:ILinkableHashMap, keepLinkableChildrenOnTop:Boolean):void
		{
			if (hashMap.childListCallbacks.lastObjectRemoved)
			{
				var removedChild:DisplayObject = hashMap.childListCallbacks.lastObjectRemoved as DisplayObject;
				if (!removedChild)
					return;
				var listener:Function = childToEventListenerMap[removedChild] as Function;
				if (listener != null)
				{
					removedChild.removeEventListener(Event.ADDED, listener);
					removedChild.removeEventListener(Event.REMOVED, listener);
					delete childToEventListenerMap[removedChild];
				}
				// removeChild() gives an error if called twice
				try {
					uiParent.removeChild(removedChild);
				} catch (e:Error) { } // behavior still seems ok after twice-called removeChild()
			}
			else if (hashMap.childListCallbacks.lastObjectAdded)
			{
				addChild(uiParent, hashMap, hashMap.childListCallbacks.lastNameAdded, keepLinkableChildrenOnTop);
			}
			else if (!parentToBusyFlagMap[uiParent])
			{
				// order changed, so set z-order of all sessioned UIComponents
				uiParent.callLater(updateChildOrder, [uiParent, hashMap, keepLinkableChildrenOnTop]);
			}
		}
		/**
		 * This function updates the order of the children in the uiParent based on the session state.
		 * @param uiParent
		 * @param hashMap
		 * @param keepLinkableChildrenOnTop
		 */		
		private static function updateChildOrder(uiParent:UIComponent, hashMap:ILinkableHashMap, keepLinkableChildrenOnTop:Boolean):void
		{
			if (!uiParent.initialized)
				return uiParent.callLater(updateChildOrder, arguments);
			
			var i:int;
			var uiChild:DisplayObject;
			// get all child DisplayObjects we are interested in
			var uiChildren:Array = hashMap.getObjects();
			for (i = uiChildren.length - 1; i >= 0; i--)
			{
				var wrapper:ILinkableDisplayObject = uiChildren[i] as ILinkableDisplayObject;
				if (wrapper)
					uiChildren[i] = wrapper.getDisplayObject();
				if (!(uiChildren[i] is DisplayObject))
					uiChildren.splice(i, 1);
			}
			// stop if there are sessioned UIComponents that are not contained by the parent.
			for each (uiChild in uiChildren)
				if (uiChild && uiParent != uiChild.parent)
					return;

			parentToBusyFlagMap[uiParent] = true; // prevent sessioned name order from being set
			if (keepLinkableChildrenOnTop)
			{
				// set child index values in reverse order so all the sessioned children will appear on top
				var indexOffset:int = uiParent.numChildren - uiChildren.length;
				for (i = uiChildren.length - 1; i >= 0; i--)
				{
					uiChild = uiChildren[i] as DisplayObject;
					if (uiChild && uiParent == uiChild.parent && uiParent.getChildIndex(uiChild) != indexOffset + i)
						uiParent.setChildIndex(uiChild, indexOffset + i);
				}
			}
			else
			{
				for (i = 0; i < uiChildren.length; i++)
				{
					uiChild = uiChildren[i] as DisplayObject;
					if (uiChild && uiParent == uiChild.parent && uiParent.getChildIndex(uiChild) != i)
						uiParent.setChildIndex(uiChild, i);
				}
			}
			delete parentToBusyFlagMap[uiParent];
		}
	}
}

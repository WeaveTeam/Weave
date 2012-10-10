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
	
	import mx.core.IUIComponent;
	import mx.core.IVisualElement;
	import mx.core.IVisualElementContainer;
	import mx.core.UIComponent;
	import mx.events.IndexChangedEvent;
	
	import weave.api.core.IChildListCallbackInterface;
	import weave.api.core.ILinkableDisplayObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableVariable;
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	import weave.api.ui.ILinkableLayoutManager;
	import weave.utils.Dictionary2D;

	/**
	 * This is an all-static class containing functions related to UI and ILinkableObjects.
	 * 
	 * @author adufilie
	 */
	public class UIUtils
	{
		/**
		 * This function determines if a particular component or one of its children has input focus.
		 * @param component The component to test.
		 * @return true if the component has focus.
		 */
		public static function hasFocus(component:UIComponent):Boolean
		{
			var focus:DisplayObject = component.getFocus();
			return focus && component.contains(focus);
		}
		
		/**
		 * This will add a callback to a linkable variable that will set a style property of a UIComponent.
		 * @param linkableVariable
		 * @param uiComponent
		 * @param stylePropertyName
		 */		
		public static function bindStyle(linkableVariable:ILinkableVariable, uiComponent:UIComponent, stylePropertyName:String, groupedCallback:Boolean = true):void
		{
			var callback:Function = function():void
			{
				if (!uiComponent.parent)
				{
					uiComponent.callLater(callback);
					return;
				}
				uiComponent.setStyle(stylePropertyName, linkableVariable.getSessionState());
			};
			
			if (groupedCallback)
				getCallbackCollection(linkableVariable).addGroupedCallback(null, callback, true);
			else
				getCallbackCollection(linkableVariable).addImmediateCallback(null, callback, true);
		}
		
		private static const linkFunctionCache:Dictionary2D = new Dictionary2D(true, true);
		
		/**
		 * This will set up a callback on a components hash map so they get added to an ILinkableLayoutManager. 
		 * @param layoutManager
		 * @param components
		 */
		public static function linkLayoutManager(layoutManager:ILinkableLayoutManager, components:ILinkableHashMap):void
		{
			// when the components list changes, we need to notify the layoutManager
			var clc:IChildListCallbackInterface = components.childListCallbacks;
			function componentListCallback():void
			{
				// add
				var newComponent:IVisualElement = clc.lastObjectAdded as IVisualElement;
				if (newComponent)
					layoutManager.addComponent(clc.lastNameAdded, newComponent);
				
				// remove
				var oldComponent:IVisualElement = clc.lastObjectRemoved as IVisualElement;
				if (oldComponent)
					layoutManager.removeComponent(clc.lastNameRemoved);
				
				// reorder
				if (!clc.lastObjectAdded && !clc.lastObjectRemoved)
					layoutManager.setComponentOrder(components.getNames());
			}
			components.childListCallbacks.addImmediateCallback(layoutManager, componentListCallback);
			
			// when layoutManager triggers callbacks, we need to synchronize the components list
			function layoutManagerCallback():void
			{
				getCallbackCollection(components).delayCallbacks();
				
				// for each component in the components list, if the layoutManager doesn't have that component, remove it from components list
				var names:Array = components.getNames(IUIComponent);
				for each (var name:String in names)
					if (!layoutManager.hasComponent(name))
						components.removeObject(name);
				// update order if necessary
				components.setNameOrder(layoutManager.getComponentOrder());
				
				getCallbackCollection(components).resumeCallbacks();
			}
			getCallbackCollection(layoutManager).addImmediateCallback(components, layoutManagerCallback);
			
			// add existing components
			var names:Array = components.getNames(IUIComponent);
			var objects:Array = components.getObjects(IUIComponent);
			
			getCallbackCollection(layoutManager).delayCallbacks();
			
			for (var i:int = 0; i < names.length; i++)
				layoutManager.addComponent(names[i] as String, objects[i] as IVisualElement);
			
			getCallbackCollection(layoutManager).resumeCallbacks();
		}
		
		/**
		 * This will set up a callback on a components hash map so they get added to an ILinkableLayoutManager. 
		 * @param layoutManager
		 * @param components
		 */
		public static function unlinkLayoutManager(layoutManager:ILinkableLayoutManager, components:ILinkableHashMap):void
		{
			//TODO
		}
		
		/**
		 * This function adds a callback to a LinkableHashMap to monitor any DisplayObjects contained in it.
		 * @param uiParent A UIComponent to synchronize with the given hashMap.
		 * @param hashMap A LinkableHashMap containing DisplayObjects to synchronize with the given uiParent.
		 * @param keepLinkableChildrenOnTop If set to true, children of the hashMap will be kept on top of all other UI children.
		 */
		public static function linkDisplayObjects(uiParent:UIComponent, hashMap:ILinkableHashMap, keepLinkableChildrenOnTop:Boolean = false):void
		{
			if (linkFunctionCache.get(uiParent, hashMap) is Function) // already linked?
				unlinkDisplayObjects(uiParent, hashMap);
			
			var callback:Function = function():void { handleHashMapChildListChange(uiParent, hashMap, keepLinkableChildrenOnTop); };
			linkFunctionCache.set(uiParent, hashMap, callback);
			
			hashMap.childListCallbacks.addImmediateCallback(uiParent, callback);
			
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
			if (parentToListenerMap[uiParent] !== undefined)
			{
				hashMap.childListCallbacks.removeCallback(linkFunctionCache.remove(uiParent, hashMap) as Function);
				for each (var child:ILinkableDisplayObject in hashMap.getObjects(ILinkableDisplayObject))
					getCallbackCollection(child).removeCallback(linkFunctionCache.remove(uiParent, child) as Function);
				
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
			// Children will not be displayed properly unless the parent is on the stage when the children are added.
			if (!uiParent.initialized || !uiParent.stage)
			{
				uiParent.callLater(addChild, arguments);
				return;
			}
			
			var childObject:ILinkableObject = hashMap.getObject(childName);
			
			// special case: ILinkableDisplayObject
			if (childObject is ILinkableDisplayObject)
			{
				(childObject as ILinkableDisplayObject).setParentContainer(uiParent);
				
				var callback:Function = function():void { updateChildOrder(uiParent, hashMap, keepLinkableChildrenOnTop); };
				linkFunctionCache.set(uiParent, childObject, callback);
				
				getCallbackCollection(childObject).addImmediateCallback(uiParent, callback, true);
				return;
			}
			
			var uiChild:DisplayObject = childObject as DisplayObject;
			// stop if the child was already removed from the hash map
			if (uiChild == null)
				return;

			// When the child is added to the parent, the child order should be updated.
			// When the child is removed from the parent with removeChild() or removeChildAt(), it should be disposed of.
			var listenLater:Function = function(event:Event):void
			{
				if (event.target == uiChild && !objectWasDisposed(uiChild))
				{
					if (event.type == Event.ADDED)
					{
						if (uiChild.parent == uiParent)
							updateChildOrder(uiParent, hashMap, keepLinkableChildrenOnTop);
					}
					else if (event.type == Event.REMOVED && !(childObject is ILinkableDisplayObject))
					{
						if (uiChild.parent != uiParent)
							hashMap.removeObject(childName);
					}
				}
			};
			var listener:Function = function (event:Event):void
			{
				// need to call later because Spark components use removeChild and addChildAt inside the setElementIndex function.
				uiParent.callLater(listenLater, arguments);
			};
			uiChild.addEventListener(Event.ADDED, listener);
			uiChild.addEventListener(Event.REMOVED, listener);
			childToEventListenerMap[uiChild] = listener; // save a pointer so the event listener can be removed later.
			
			if (uiParent == uiChild.parent)
				updateChildOrder(uiParent, hashMap, keepLinkableChildrenOnTop);
			else
				spark_addChild(uiParent, uiChild);
		}
		
		public static function spark_addChild(parent:UIComponent, child:DisplayObject):DisplayObject
		{
			if (parent is IVisualElementContainer)
			{
				if (child is IVisualElement)
					return (parent as IVisualElementContainer).addElement(child as IVisualElement) as DisplayObject;
				else
					throw new Error("parent is IVisualElementContainer, but child is not an IVisualElement");
			}
			else
				return parent.addChild(child);
		}
		
		public static function spark_setChildIndex(parent:UIComponent, child:DisplayObject, index:int):void
		{
			if (parent is IVisualElementContainer && child is IVisualElement)
			{
				if (child is IVisualElement)
					(parent as IVisualElementContainer).setElementIndex(child as IVisualElement, index);
				else
					throw new Error("parent is IVisualElementContainer, but child is not an IVisualElement");
			}
			else
				parent.setChildIndex(child, index);
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
			{
				uiParent.callLater(updateChildOrder, arguments);
				return;
			}
			
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
						spark_setChildIndex(uiParent, uiChild, indexOffset + i);
				}
			}
			else
			{
				for (i = 0; i < uiChildren.length; i++)
				{
					uiChild = uiChildren[i] as DisplayObject;
					if (uiChild && uiParent == uiChild.parent && uiParent.getChildIndex(uiChild) != i)
						spark_setChildIndex(uiParent, uiChild, i);
				}
			}
			delete parentToBusyFlagMap[uiParent];
		}
	}
}

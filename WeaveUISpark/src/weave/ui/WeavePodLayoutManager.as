/*
Weave (Web-based Analysis and Visualization Environment)
Copyright (C) 2008-2011 University of Massachusetts Lowell

This file is a part of Weave.

Weave is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License, Version 3,
as published by the Free Software Foundation.

Weave is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Weave. If not, see <http://www.gnu.org/licenses/>.
*/

package weave.ui
{
	import com.adobe.devnet.managers.PodLayoutManager;
	import com.adobe.devnet.view.Pod;
	
	import flash.utils.Dictionary;
	
	import mx.core.IVisualElement;
	
	import spark.components.Group;
	
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.linkBindableProperty;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ILinkableLayoutManager;
	import weave.core.LinkableNumber;
	
	/**
	 * @author sanbalag
	 */
	public class WeavePodLayoutManager extends Group implements ILinkableLayoutManager, IDisposableObject
	{
		public function WeavePodLayoutManager()
		{
			percentWidth = 100;
			percentHeight = 100;
			manager.container = this;
			linkBindableProperty(scale, this, 'scaleX');
			linkBindableProperty(scale, this, 'scaleY');
		}
		
		public const scale:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1));
		
		private var _idToComponent:Object = {}; // String -> IVisualElement
		private var _componentToId:Dictionary = new Dictionary(true); // IVisualElement -> String
		
		public var manager:PodLayoutManager = new PodLayoutManager();
		
		/**
		 * Adds a component to the layout.
		 * @param id A unique identifier for the component.
		 * @param component The component to add to the layout.
		 */		
		public function addComponent(id:String, component:IVisualElement):void
		{
			if (_idToComponent[id] != component)
			{
				_idToComponent[id] = component;
				_componentToId[component] = id;
				if (component.parent != this){
					var pod:Pod = new Pod();
					pod.addElement(component);
					pod.title = id;
					
					var busyIndicator:IVisualElement = new BusyIndicator(component as ILinkableObject) as IVisualElement;
					pod.addElement(busyIndicator);
					busyIndicator.includeInLayout = false;
					busyIndicator.x = 0;
					busyIndicator.y = 0;
					
					manager.addItem(pod, false);
					callLater(manager.updateLayout);
				}
					
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * Removes a component from the layout.
		 * @param id The id of the component to remove.
		 */
		public function removeComponent(id:String):void
		{
			var component:IVisualElement = _idToComponent[id] as IVisualElement;
			if (component)
			{
				delete _idToComponent[id];
				delete _componentToId[component];
				if (component.parent  is Pod){
					var pod:Pod = component.parent as Pod;
					pod.removeElement(component);
					manager.removeItem(pod);
					this.removeElement(pod);
				}
					
					
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * Reorders the components. 
		 * @param orderedIds An ordered list of ids.
		 */
		public function setComponentOrder(orderedIds:Array):void
		{
			getCallbackCollection(this).delayCallbacks();
			
			for (var index:int = 0; index < orderedIds.length; index++)
			{
				var id:String = orderedIds[index] as String;
				var component:IVisualElement = _idToComponent[id] as IVisualElement;
				if (component)
				{
					if (component.parent == this)
						this.setElementIndex(component, index);
					getCallbackCollection(this).triggerCallbacks();
				}
			}
			
			getCallbackCollection(this).resumeCallbacks();
		}
		
		/**
		 * This is an ordered list of ids in the layout.
		 */		
		public function getComponentOrder():Array
		{
			var result:Array = [];
			for (var index:int = 0; index < numElements; index++)
			{
				var component:IVisualElement = getElementAt(index);
				var id:String = _componentToId[component];
				if (id)
					result.push(id);
			}
			return result;
		}
		
		/**
		 * This function can be used to check if a component still exists in the layout.
		 */		
		public function hasComponent(id:String):Boolean
		{
			var component:IVisualElement = _idToComponent[id] as IVisualElement;
			return component != null;
		}
		
		/**
		 * This is called when the object is disposed.
		 */
		public function dispose():void
		{
			getCallbackCollection(this).delayCallbacks();
			
			for each (var id:String in getComponentOrder())
			removeComponent(id);
			
			getCallbackCollection(this).resumeCallbacks();
		}
	}
}
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
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.UIComponent;
	
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableDisplayObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObject;
	import weave.api.getLinkableOwner;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.ILinkableContainer;
	import weave.compiler.Compiler;

	/**
	 * This is an generic wrapper for a dynamically created DisplayObject.
	 * 
	 * @author adufilie
	 */	
	public class LinkableDisplayObject implements ILinkableDisplayObject, ILinkableContainer, IDisposableObject
	{
		public function LinkableDisplayObject()
		{
		}
		
		/**
		 * The qualified class name of a DisplayObject.
		 */
		public const className:LinkableString = newLinkableChild(this, LinkableString, handleClassDefChange);
		
		/**
		 * Session state containing an object mapping an event name to a script to be called when the event fires.
		 * The "this" context of the script will be the DisplayObject.
		 * The "event" variable will be set to the event object.
		 * The "owner" variable can be used inside the script to get a pointer to the LinkableDisplayObject.
		 */
		public const events:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable, updateEventListeners);
		
		/**
		 * Session state containing an object mapping the DisplayObject's property names to values.
		 */
		public const properties:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable, handlePropertiesChange, true);
		
		/**
		 * Child linkable objects.
		 */
		public const children:ILinkableHashMap = newLinkableChild(this, LinkableHashMap);
		
		private var _parent:DisplayObjectContainer = null; // The parent passed to setParentContainer()
		private var _displayObject:DisplayObject = null; // the internal DisplayObject
		private var _defaultProperties:Object = {}; // default values for the modified properties of the DisplayObject
		private var _eventListenerMap:Object = null; // hash map of event listeners that have been added to the DisplayObject
		
		/**
		 * Creates a child LinkableDisplayObject
		 */
		public function newChild(name:String, displayObjectClassName:String):LinkableDisplayObject
		{
			var ldo:LinkableDisplayObject = children.requestObject(name, LinkableDisplayObject, false);
			ldo.className.value = displayObjectClassName;
			return ldo;
		}
		
		/**
		 * Sets a value in the properties session state.
		 */
		public function setProperty(name:String, value:Object):void
		{
			var state:Object = Object(properties.value);
			state[name] = value;
			properties.value = state;
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			parent = null;
		}
		/**
		 * @inheritDoc
		 */
		public function getLinkableChildren():ILinkableHashMap
		{
			return children;
		}
		
		/**
		 * Returns the parent LinkableDisplayObject, if any.
		 */
		public function get parentLDO():LinkableDisplayObject
		{
			return getLinkableOwner(getLinkableOwner(this)) as LinkableDisplayObject;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set parent(parent:DisplayObjectContainer):void
		{
			if (_parent == parent)
				return;
			if (_parent && _displayObject && _parent == _displayObject.parent)
				_parent.removeChild(_displayObject);
			_parent = parent;
			if (_parent && _displayObject)
				_parent.addChild(_displayObject);
		}
		/**
		 * @inheritDoc
		 */
		public function get object():DisplayObject
		{
			return _displayObject;
		}
		
		/**
		 * This function updates the type of the internal DisplayObject.
		 */
		private function handleClassDefChange():void
		{
			// remove old component
			if (_displayObject)
			{
				if (_displayObject is UIComponent)
					UIUtils.unlinkDisplayObjects(_displayObject as UIComponent, children);
				if (_parent && _parent == _displayObject.parent)
					_parent.removeChild(_displayObject);
				removeEventListeners();
				disposeObject(_displayObject);
				_displayObject = null;
			}
			// create new component
			try
			{
				var classDef:Class = WeaveXMLDecoder.getClassDefinition(className.value)
				if (!classDef)
					return;
				var classQName:String = getQualifiedClassName(classDef);
				// stop if class doesn't extend DisplayObject
				if (!ClassUtils.classIs(classQName, getQualifiedClassName(DisplayObject)))
					return;
				if (ClassUtils.classIs(classQName, getQualifiedClassName(ILinkableObject)))
				{
					_displayObject = newLinkableChild(this, classDef);
					linkSessionState(properties, _displayObject as ILinkableObject);
				}
				else
				{
					_displayObject = newDisposableChild(this, classDef);
					addEventListeners();
					handlePropertiesChange();
				}
				if (_parent)
					_parent.addChild(_displayObject);
				if (_displayObject is UIComponent)
					UIUtils.linkDisplayObjects(_displayObject as UIComponent, children);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		/**
		 * This function updates the properties on the internal DisplayObject.
		 */		
		private function handlePropertiesChange():void
		{
			if (!_displayObject || _displayObject is ILinkableObject)
			{
				_defaultProperties = null;
				return;
			}
			
			if (_defaultProperties == null)
				_defaultProperties = {};
			
			var _newProperties:Object = properties.value;
			var name:String;
			for (name in _newProperties)
			{
				if (_displayObject.hasOwnProperty(name))
				{
					try
					{
						// save default value if not saved already
						if (!_defaultProperties.hasOwnProperty(name))
							_defaultProperties[name] = _displayObject[name];
						_displayObject[name] = _newProperties[name];
					}
					catch (e:Error)
					{
						reportError(e);
					}
				}
			}
			// for each name appearing in defaults but not in the new properties, restore default value
			for (name in _defaultProperties)
			{
				if (!_displayObject.hasOwnProperty(name))
					continue;
				if (!_newProperties || !_newProperties.hasOwnProperty(name))
				{
					try
					{
						_displayObject[name] = _defaultProperties[name];
					}
					catch (e:Error)
					{
						reportError(e);
					}
					delete _defaultProperties[name];
				}
			}
		}
		
		/**
		 * This function updates the event listeners on the internal DisplayObject.
		 */		
		private function updateEventListeners():void
		{
			removeEventListeners();
			addEventListeners();
		}
		
		/**
		 * This function removes the event listeners from the internal DisplayObject.
		 */		
		private function removeEventListeners():void
		{
			if (_displayObject != null)
				for (var name:String in _eventListenerMap)
					_displayObject.removeEventListener(name, _eventListenerMap[name]);
			_eventListenerMap = null;
		}
		
		/**
		 * This function adds the event listeners to the internal DisplayObject.
		 */		
		private function addEventListeners():void
		{
			removeEventListeners();
			if (_displayObject == null)
				return;
			_eventListenerMap = {};
			for (var name:String in events.value)
			{
				try
				{
					var script:String = events.value[name];
					var listener:Function = generateEventListener(script);
					_displayObject.addEventListener(name, listener, false, 0, true);
					_eventListenerMap[name] = listener;
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
		}
		
		private const symbolTable:Object = {owner: this};
		private const compiler:Compiler = new Compiler();
		
		/**
		 * This function generates an event listener that executes JavaScript code. 
		 * @param script The JavaScript code.
		 * @return An event listener that runs the JavaScript code.
		 */
		private function generateEventListener(script:String):Function
		{
			var compiledFunction:Function = compiler.compileToFunction(script, symbolTable, null, true, ['event']);
			return function(event:Event):void
			{
				symbolTable.event = event;
				try
				{
					compiledFunction.apply(_displayObject, [event]);
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
		}
	}
}

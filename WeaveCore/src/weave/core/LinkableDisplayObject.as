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
	import flash.external.ExternalInterface;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.UIComponent;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableContainer;
	import weave.api.core.ILinkableDisplayObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObjects;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
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
		
		public const qualifiedClassName:LinkableString = newLinkableChild(this, LinkableString, handleClassDefChange);
		public const eventListeners:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable, updateEventListeners);
		public const properties:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable, handlePropertiesChange);
		public const children:ILinkableHashMap = newLinkableChild(this, LinkableHashMap);
		
		private var _parent:DisplayObjectContainer = null; // The parent passed to setParentContainer()
		private var _displayObject:DisplayObject = null; // the internal DisplayObject
		private var _defaultProperties:Object = {}; // default values for the modified properties of the DisplayObject
		private var _eventListenerMap:Object = null; // hash map of event listeners that have been added to the DisplayObject
		
		// IDisposableObject interface
		public function dispose():void
		{
			setParentContainer(null);
		}
		// ILinkableContainer interface
		public function getLinkableChildren():ILinkableHashMap
		{
			return children;
		}
		// ILinkableDisplayObject interface
		public function setParentContainer(parent:DisplayObjectContainer):void
		{
			if (_parent == parent)
				return;
			if (_parent && _displayObject && _parent == _displayObject.parent)
				_parent.removeChild(_displayObject);
			_parent = parent;
			if (_parent && _displayObject)
				_parent.addChild(_displayObject);
		}
		// ILinkableDisplayObject interface
		public function getDisplayObject():DisplayObject
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
				disposeObjects(_displayObject);
				_displayObject = null;
			}
			// create new component
			try
			{
				var classDef:Class = WeaveXMLDecoder.getClassDefinition(qualifiedClassName.value)
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
				WeaveAPI.ErrorManager.reportError(e);
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
						WeaveAPI.ErrorManager.reportError(e);
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
						WeaveAPI.ErrorManager.reportError(e);
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
			for (var name:String in eventListeners.value)
			{
				try
				{
					var script:String = eventListeners.value[name];
					var listener:Function = generateEventListener(script);
					_displayObject.addEventListener(name, listener, false, 0, true);
					_eventListenerMap[name] = listener;
				}
				catch (e:Error)
				{
					WeaveAPI.ErrorManager.reportError(e);
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
			var compiledFunction:Function = compiler.compileToFunction(script, symbolTable, false, true, ['event']);
			return function(event:Event):void
			{
				symbolTable.event = event;
				try
				{
					compiledFunction.apply(_displayObject, [event]);
				}
				catch (e:Error)
				{
					WeaveAPI.ErrorManager.reportError(e);
				}
			}

			/*
			// create script to initialize the 'weave' variable
			var initScript:String = 'var weave = document.getElementById("' + ExternalInterface.objectID + '");';
			
			// attempt to delay alert boxes, without delaying other types of scripts
			if (script.search("(alert|confirm|prompt)[\\ \n\t]*\\(") >= 0)
				script = 'function(event){setTimeout(function(){' + initScript + script + '},0)}';
			else
				script = 'function(event){' + initScript + script + '}';
			
			return function (event:Event):void
			{
				var eventObj:Object = {};
				for each (var propertyName:String in ObjectUtil.getClassInfo(event).properties)
					eventObj[propertyName] = String(ObjectUtil.copy(event[propertyName]));
				
				ExternalInterface.call(script, eventObj);
			};
			*/
		}
	}
}

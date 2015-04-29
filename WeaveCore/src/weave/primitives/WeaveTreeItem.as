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

package weave.primitives
{
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableVariable;
	
	/**
	 * Facilitates the creation of dynamic trees.
	 */
	public class WeaveTreeItem
	{
		/**
		 * Initializes an Array of WeaveTreeItems using an Array of objects to pass to the constructor.
		 * Any Arrays passed in will be flattened.
		 * @param WeaveTreeItem_implementation The implementation of WeaveTreeItem to use.
		 * @param items Item descriptors.
		 */
		public static const createItems:Function = function(WeaveTreeItem_implementation:Class, items:Array):Array
		{
			// flatten
			var n:int = 0;
			while (n != items.length)
			{
				n = items.length;
				items = [].concat.apply(null, items);
			}
			
			return items.map(_mapItems, WeaveTreeItem_implementation).filter(_filterItemsRemoveNulls);
		};
		
		/**
		 * Used for mapping an Array of params objects to an Array of WeaveTreeItem objects.
		 * The "this" argument is used to specify a particular WeaveTreeItem implementation.
		 */
		protected static const _mapItems:Function = function(item:Object, i:int, a:Array):Object
		{
			// If the item is a Class definition, create an instance of that Class.
			if (item is Class)
				return new item();
			
			// If the item is a String or an Object, we can pass it to the constructor.
			if (item is String || (item != null && Object(item).constructor == Object))
			{
				var ItemClass:Class = this as Class || WeaveTreeItem;
				return new ItemClass(item);
			}
			
			// If the item is any other type, return the original item.
			return item;
		};
		
		/**
		 * Filters out null items.
		 */
		private static function _filterItemsRemoveNulls(item:Object, i:*, a:*):Boolean
		{
			return item != null;
		}
		
		//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----
		
		/**
		 * Constructs a new WeaveTreeItem.
		 * @param params An Object containing property values to set on the WeaveTreeItem.
		 *               If params is a String, both <code>label</code> and <code>data</code> will be set to that String.
		 */
		public function WeaveTreeItem(params:Object = null)
		{
			if (params is String)
			{
				this.label = params;
				this.data = params;
			}
			else
				for (var key:String in params)
					this[key] = params[key];
		}
		
		/**
		 * Set this to change the constructor used for initializing child items.
		 * This variable is intentionally uninitialized to avoid overwriting the value set by an extending class in its constructor.
		 */
		protected var childItemClass:Class; // IMPORTANT - no initial value
		protected var _recursion:Object = {}; // recursionName -> Boolean
		protected var _label:* = "";
		protected var _children:* = null;
		protected var _dependency:ILinkableObject = null;
		
		/**
		 * Cached values that get invalidated when the source triggers callbacks.
		 */
		protected var _cache:Object = {};
		
		/**
		 * Cached values of getCallbackCollection(source).triggerCounter.
		 */
		protected var _counter:Object = {};
		
		//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----
		
		/**
		 * Computes a Boolean value from various structures
		 * @param param Either a Boolean, and Object like {not: param}, a Function, an ILinkableVariable, or an Array of those objects.
		 * @param recursionName A name used to keep track of recursion.
		 * @return A Boolean value derived from the param, or the param itself if called recursively.
		 */
		protected function getBoolean(param:*, recursionName:String):*
		{
			if (!_recursion[recursionName])
			{
				try
				{
					_recursion[recursionName] = true;
					
					if (isSimpleObject(param, 'not'))
						param = !getBoolean(param['not'], "not_" + recursionName);
					if (isSimpleObject(param, 'or'))
						param = getBoolean(param['or'], "or_" + recursionName);
					if (param is Function)
						param = evalFunction(param as Function);
					if (param is ILinkableVariable)
						param = (param as ILinkableVariable).getSessionState();
					if (param is Array)
					{
						var breakValue:Boolean = recursionName.indexOf("or_") == 0;
						for each (param in param)
						{
							param = getBoolean(param, "item_" + recursionName);
							if (param ? breakValue : !breakValue)
								break;
						}
					}
					param = param ? true : false;
				}
				finally
				{
					_recursion[recursionName] = false;
				}
			}
			return param;
		}
		
		/**
		 * Checks if an object has a single specified property.
		 */
		protected function isSimpleObject(object:*, singlePropertyName:String):Boolean
		{
			var found:Boolean = false;
			for (var key:* in object)
			{
				if (found)
					return false; // two or more properties
				
				if (key !== singlePropertyName)
					return false; // not the desired property
				
				found = true; // found the desired property
			}
			return found;
		}
		
		/**
		 * Gets a String value from a String or Function.
		 * @param param Either a String or a Function.
		 * @param recursionName A name used to keep track of recursion.
		 * @return A String value derived from the param, or the param itself if called recursively.
		 */
		protected function getString(param:*, recursionName:String):*
		{
			if (!_recursion[recursionName])
			{
				try
				{
					_recursion[recursionName] = true;
					
					if (param is Function)
						param = evalFunction(param as Function);
					else
						param = param || '';
				}
				finally
				{
					_recursion[recursionName] = false;
				}
			}
			return param;
		}
		
		/**
		 * Evaluates a function to get an Object or just returns the non-Function Object passed in.
		 * @param param Either an Object or a Function.
		 * @param recursionName A name used to keep track of recursion.
		 * @return An Object derived from the param, or the param itself if called recursively.
		 */
		protected function getObject(param:*, recursionName:String):*
		{
			if (!_recursion[recursionName])
			{
				try
				{
					_recursion[recursionName] = true;
					
					if (param is Function)
						param = evalFunction(param as Function);
				}
				finally
				{
					_recursion[recursionName] = false;
				}
			}
			return param;
		}
		
		/**
		 * First tries calling a function with no parameters.
		 * If an ArgumentError is thrown, the function will called again, passing this WeaveTreeItem as the first parameter.
		 */
		protected function evalFunction(func:Function):*
		{
			try
			{
				try
				{
					// first try calling the function with no parameters
					return func.call(this);
				}
				catch (e:*)
				{
					if (!(e is ArgumentError))
					{
						if (e is Error)
							trace((e as Error).getStackTrace());
						throw e;
					}
				}
				
				// on ArgumentError, pass in this WeaveTreeItem as the first parameter
				return func.call(this, this);
			}
			catch (e:Error)
			{
				WeaveAPI.ErrorManager.reportError(e);
			}
		}
		
		//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----
		
		/**
		 * Checks if cached value is valid.
		 * Always returns false if the source property is not set.
		 * @param id A string identifying a property.
		 * @return true if the property value has been cached.
		 */
		protected function isCached(id:String):Boolean
		{
			if (_dependency && WeaveAPI.SessionManager.objectWasDisposed(_dependency))
				dependency = null;
			return _dependency && _counter[id] === WeaveAPI.SessionManager.getCallbackCollection(_dependency).triggerCounter;
		}
		
		/**
		 * Retrieves or updates a cached value for a property.
		 * Does not cache the value if the source property is not set.
		 * @param id A string identifying a property.
		 * @param newValue Optional new value to cache for the property.
		 * @return The new or existing value for the property.
		 */
		protected function cache(id:String, newValue:* = undefined):*
		{
			if (arguments.length == 1)
				return _cache[id];
			
			if (_dependency && WeaveAPI.SessionManager.objectWasDisposed(_dependency))
				dependency = null;
			if (_dependency)
			{
				_counter[id] = WeaveAPI.SessionManager.getCallbackCollection(_dependency).triggerCounter;
				_cache[id] = newValue;
			}
			return newValue;
		}
		
		//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----//----

		/**
		 * This can be set to either a String or a Function.
		 * This property is checked by Flex's default data descriptor.
		 * If this property is not set, the <code>data</code> property will be used as the label.
		 */
		public function get label():String
		{
			const id:String = 'label';
			if (isCached(id))
				return _cache[id];
			
			var str:String = getString(_label, id);
			if (!str && data is String)
				str = data as String;
			return cache(id, str);
		}
		public function set label(value:*):void
		{
			_counter['label'] = undefined;
			_label = value;
		}
		
		/**
		 * Gets the Array of child menu items and modifies it in place if necessary to create nodes from descriptors or remove null items.
		 * If this tree item specifies a dependency, the Array can be filled asynchronously.
		 * This property is checked by Flex's default data descriptor.
		 */
		public function get children():Array
		{
			const id:String = 'children';
			
			var items:Array;
			if (isCached(id))
				items = _cache[id];
			else
				items = getObject(_children, id) as Array;
			
			if (items)
			{
				// overwrite original array to support filling it asynchronously
				var iOut:int = 0;
				for (var i:int = 0; i < items.length; i++)
				{
					var item:Object = _mapItems.call(childItemClass, items[i], i, items);
					if (item != null)
						items[iOut++] = item;
				}
				items.length = iOut;
			}
			
			return cache(id, items);
		}
		
		/**
		 * This can be set to either an Array or a Function that returns an Array.
		 * The function can be like function():void or function(item:WeaveTreeItem):void.
		 * The Array can contain either WeaveTreeItems or Objects, each of which will be passed to the WeaveTreeItem constructor.
		 */
		public function set children(value:*):void
		{
			_counter['children'] = undefined;
			_children = value;
		}
		
		/**
		 * A pointer to the ILinkableObject that created this node.
		 * This is used to determine when to invalidate cached values.
		 */
		public function get dependency():ILinkableObject
		{
			if (_dependency && WeaveAPI.SessionManager.objectWasDisposed(_dependency))
				dependency = null;
			return _dependency;
		}
		public function set dependency(value:ILinkableObject):void
		{
			if (_dependency != value)
				_counter = {};
			_dependency = value;
		}
		
		/**
		 * This can be any data associated with this tree item.
		 * For example, it can be used to store state information if the tree is populated asynchronously.
		 */
		public var data:Object = null;
	}
}
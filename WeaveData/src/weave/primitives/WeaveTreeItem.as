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
package weave.primitives
{
	import weave.api.core.ILinkableVariable;
	
	/**
	 * Facilitates the creation of dynamic trees.
	 */
	public class WeaveTreeItem
	{
		/**
		 * Initializes an Array of WeaveTreeItems using an Array of objects to pass to the constructor.
		 * Any Arrays passed in will be flattened.
		 * @param params Item descriptors.
		 */
		public static function createItems(...params):Array
		{
			return _createItems(WeaveTreeItem, params);
		}
		
		/**
		 * Initializes an Array of WeaveTreeItems using an Array of objects to pass to the constructor.
		 * Any Arrays passed in will be flattened.
		 * @param WeaveTreeItem_implementation The implementation of WeaveTreeItem to use.
		 * @param items Item descriptors.
		 */
		protected static const _createItems:Function = function(WeaveTreeItem_implementation:Class, items:Array):Array
		{
			// flatten
			var n:int = 0;
			while (n != items.length)
			{
				n = items.length;
				items = [].concat.apply(null, items);
			}
			
			return items.map(_mapItems, WeaveTreeItem_implementation);
		};
		
		/**
		 * Used for mapping an Array of params objects to an Array of WeaveTreeItem objects.
		 * The "this" argument is used to specify a particular WeaveTreeItem implementation.
		 */
		protected static const _mapItems:Function = function(item:Object, i:int, a:Array):WeaveTreeItem
		{
			var ItemClass:Class = this as Class || WeaveTreeItem;
			if (item is Class)
				return new item();
			return item as WeaveTreeItem || new ItemClass(item) as WeaveTreeItem;
		};
		
		/**
		 * Constructs a new WeaveTreeItem.
		 * @param params An Object containing property values to set on the WeaveTreeItem.
		 *               If this is a String equal to "separator" (TYPE_SEPARATOR), a new separator will be created.
		 */
		public function WeaveTreeItem(params:Object = null)
		{
			if (params is String)
				this.label = params;
			else
				for (var key:String in params)
					this[key] = params[key];
		}
		
		/**
		 * Set this to change the constructor used for initializing child items.
		 * This variable is intentionally uninitialized to avoid overwriting the value set by an extending class in its constructor.
		 */
		protected var childItemClass:Class; // no initial value
		
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
				_recursion[recursionName] = true;
				
				if (param is Object && param.constructor == Object && param.hasOwnProperty('not'))
					param = !getBoolean(param['not'], "not_" + recursionName);
				if (param is Function)
					param = param.apply(this, param.length ? [this] : null);
				if (param is ILinkableVariable)
					param = (param as ILinkableVariable).getSessionState();
				if (param is Array)
					for each (param in param)
						if (!(param = getBoolean(param, recursionName + "_item")))
							break;
				param = param ? true : false;
				
				_recursion[recursionName] = false;
			}
			return param;
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
				_recursion[recursionName] = true;
				
				if (param is Function)
					param = param.apply(this, param.length ? [this] : null);
				else
					param = param || '';
				
				_recursion[recursionName] = false;
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
				_recursion[recursionName] = true;
				
				if (param is Function)
					param = param.apply(this, param.length ? [this] : null);
				
				_recursion[recursionName] = false;
			}
			return param;
		}
		
		protected var _recursion:Object = {}; // recursionName -> Boolean
		
		private var _label:* = "";
		private var _children:* = null;
		
		/**
		 * This can be set to either a String or a Function.
		 * This property is checked by Flex's default data descriptor.
		 */
		public function get label():String
		{
			return getString(_label, 'label');
		}
		public function set label(value:*):void
		{
			_label = value;
		}
		
		/**
		 * Gets a filtered copy of the child menu items.
		 * When this property is accessed, refresh() will be called except if refresh() is already being called.
		 * This property is checked by Flex's default data descriptor.
		 */
		public function get children():*
		{
			var items:Array = getObject(_children, 'children') as Array;
			if (!items)
				return null;
			
			return items.map(_mapItems, childItemClass);
		}
		
		/**
		 * This can be set to either an Array or a Function that returns an Array.
		 * The function can be like function():void or function(item:WeaveTreeItem):void.
		 * The Array can contain either WeaveTreeItems or Objects, each of which will be passed to the WeaveTreeItem constructor.
		 */
		public function set children(value:*):void
		{
			_children = value;
		}
		
		/**
		 * This can be any data associated with this tree item.
		 */
		public var data:Object = null;
	}
}
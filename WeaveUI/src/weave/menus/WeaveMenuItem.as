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
package weave.menus
{
	import weave.api.core.ILinkableVariable;
	import weave.core.LinkableBoolean;
	
	/**
	 * Dynamic menu item for use with a MenuBar.
	 * 
	 * Flex's DefaultDataDescriptor checks the following properties:
	 *     label, children, enabled, toggled, type, groupName
	 */
	public class WeaveMenuItem
	{
		public static const TYPE_SEPARATOR:String = "separator";
		public static const TYPE_CHECK:String = "check";
		public static const TYPE_RADIO:String = "radio";
		
		/**
		 * Initializes an Array of WeaveMenuItems using an Array of objects to pass to the constructor.
		 * Any Arrays passed in will be flattened.
		 */
		public static function createItems(...params):Array
		{
			// flatten
			var n:int = 0;
			while (n != params.length)
			{
				n = params.length;
				params = [].concat.apply(null, params);
			}
			
			return params.map(_mapItems);
		}
		private static function _mapItems(item:Object, i:int, a:Array):WeaveMenuItem
		{
			return item as WeaveMenuItem || new WeaveMenuItem(item);
		}
		private static function _filterItems(item:WeaveMenuItem, index:int, array:Array):Boolean
		{
			return item.shown;
		}
		
		/**
		 * Constructs a new WeaveMenuItem.
		 * @param params An Object containing property values to set on the WeaveMenuItem.
		 *               If this is a String equal to TYPE_SEPARATOR, a new separator will be created.
		 */
		public function WeaveMenuItem(params:Object)
		{
			if (params == TYPE_SEPARATOR)
				type = TYPE_SEPARATOR;
			else if (params is String)
				this.label = params;
			else
				for (var key:String in params)
					this[key] = params[key];
		}
		
		/**
		 * Computes a Boolean value from various structures
		 * @param param Either a Boolean, and Object like {not: param}, a Function, an ILinkableVariable, or an Array of those objects.
		 * @param recursionName A name used to keep track of recursion.
		 * @return A Boolean value derived from the param, or the param itself if called recursively.
		 */
		private function getBoolean(param:*, recursionName:String):*
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
		private function getString(param:*, recursionName:String):*
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
		 * Gets an Array value from an Array or Function.
		 * @param param Either an Array or a Function.
		 * @param recursionName A name used to keep track of recursion.
		 * @return An Array derived from the param, or the param itself if called recursively.
		 */
		private function getArray(param:*, recursionName:String):*
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
		
		private var _recursion:Object = {}; // recursionName -> Boolean
		
		/**
		 * This can be either a Function or a LinkableBoolean.
		 * The function can be like function():void or function(item:WeaveMenuItem):void.
		 * The function will be called like click.call(this) or click.call(this, this) if the former produces an ArgumentError.
		 */
		public var click:* = null;
		
		/**
		 * This property is checked by Flex's default data descriptor.
		 */
		public var type:String = null;
		
		/**
		 * This property is checked by Flex's default data descriptor.
		 */
		public var groupName:String = null;
		
		/**
		 * This can be any data associated with the menu item
		 */
		public var data:Object = null;
		
		private var _label:* = "";
		private var _enabled:* = true;
		private var _shown:* = true;
		private var _toggled:* = false;
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
		 * This property is checked by Flex's default data descriptor.
		 */
		public function get toggled():Boolean
		{
			return getBoolean(_toggled, 'toggled');
		}
		public function set toggled(value:*):void
		{
			_toggled = value;
		}
		
		/**
		 * This can be set to either a Boolean, a Function, or an ILinkableVariable.
		 * This property is checked by Flex's default data descriptor.
		 */
		public function get enabled():Boolean
		{
			// disable menu item if there is no clickFunction
			return getBoolean(_enabled, 'enabled');
		}
		public function set enabled(value:*):void
		{
			_enabled = value;
		}
		
		/**
		 * Specifies whether or not this item should be shown.
		 * This can be set to either a Boolean, a Function, an ILinkableVariable, or an Array of ILinkableVariables.
		 */
		public function get shown():Boolean
		{
			return getBoolean(_shown, 'shown');
		}
		public function set shown(value:*):void
		{
			_shown = value;
		}
		
		/**
		 * Gets a filtered copy of the child menu items.
		 * When this property is accessed, refresh() will be called except if refresh() is already being called.
		 * This property is checked by Flex's default data descriptor.
		 */
		public function get children():*
		{
			var items:Array = getArray(_children, 'children') as Array;
			if (!items)
				return null;
			
			// filter children based on "shown" status
			items = items.map(_mapItems).filter(_filterItems);
			// remove leading separators
			while (items.length && WeaveMenuItem(items[0]).type == TYPE_SEPARATOR)
				items.shift();
			// remove trailing separators
			while (items.length && WeaveMenuItem(items[items.length - 1]).type == TYPE_SEPARATOR)
				items.pop();
			// remove redundant separators
			for (var i:int = items.length - 1; i > 1; i--)
				if (WeaveMenuItem(items[i]).type == TYPE_SEPARATOR && WeaveMenuItem(items[i - 1]).type == TYPE_SEPARATOR)
					items.splice(i, 1);
			
			return items;
		}
		
		/**
		 * This can be set to either an Array or a Function that returns an Array.
		 * The function can be like function():void or function(item:WeaveMenuItem):void.
		 * The Array can contain either WeaveMenuItems or Objects, each of which will be passed to the WeaveMenuItem constructor.
		 */
		public function set children(value:*):void
		{
			_children = value;
		}
		
		/**
		 * If the click property is set to a Function, it will be called.
		 * If the click property is set to a LinkableBoolean, it will be toggled.
		 */
		public function runClickFunction():void
		{
			if (click is Function)
			{
				try
				{
					click.call(this);
				}
				catch (e:*)
				{
					if (e is ArgumentError)
						click.call(this, this);
				}
			}
			
			var lb:LinkableBoolean = click as LinkableBoolean;
			if (lb)
				lb.value = !lb.value;
		}
		
		// support for alternate spellings
		[Exclude(kind="property")] public function set enable(value:*):void { _enabled = value; }
		[Exclude(kind="property")] public function set show(value:*):void { _shown = value; }
	}
}
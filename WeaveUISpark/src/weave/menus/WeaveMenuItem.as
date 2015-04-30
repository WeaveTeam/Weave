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

package weave.menus
{
	import weave.api.core.ILinkableVariable;
	import weave.primitives.WeaveTreeItem;
	
	/**
	 * Dynamic menu item for use with Flex Menus.
	 * 
	 * Flex's DefaultDataDescriptor checks the following properties:
	 *     label, children, enabled, toggled, type, groupName
	 */
	public class WeaveMenuItem extends WeaveTreeItem
	{
		/**
		 * Initializes an Array of WeaveMenuItems using an Array of objects to pass to the constructor.
		 * Any Arrays passed in will be flattened and surrounded by separators.
		 * @param items An Array of item descriptors.
		 */
		public static function createItems(items:Array):Array
		{
			var flattened:Array = [];
			for each (var param:Object in items)
			{
				if (param is Array)
				{
					var groupedItems:Array = WeaveTreeItem.createItems(WeaveMenuItem, param as Array);
					_pushSeparator(flattened);
					flattened.push.apply(flattened, groupedItems);
					_pushSeparator(flattened);
				}
				else
				{
					flattened.push(param);
				}
			}
			
			// make sure the list of items does not end in a separator
			_pushSeparator(flattened);
			flattened.pop();
			
			return WeaveTreeItem.createItems(WeaveMenuItem, flattened);
		}
		
		/**
		 * Makes sure a non-empty output array ends in a non-redundant separator.
		 */
		private static function _pushSeparator(output:Array):void
		{
			if (!output.length)
				return;
			var last:Object = output[output.length - 1];
			if (last == TYPE_SEPARATOR)
				return;
			if (last is WeaveMenuItem && (last as WeaveMenuItem).type == TYPE_SEPARATOR)
				return;
			output.push(TYPE_SEPARATOR);
		}

		public static const TYPE_SEPARATOR:String = "separator";
		public static const TYPE_CHECK:String = "check";
		public static const TYPE_RADIO:String = "radio";
		
		/**
		 * Constructs a new WeaveMenuItem.
		 * @param params An Object containing property values to set on the WeaveMenuItem.
		 *               If this is a String equal to "separator" (TYPE_SEPARATOR), a new separator will be created.
		 */
		public function WeaveMenuItem(params:Object)
		{
			childItemClass = WeaveMenuItem;
			
			if (params == TYPE_SEPARATOR)
			{
				type = TYPE_SEPARATOR;
				params = null;
			}
			
			super(params);
		}
		
		/**
		 * This can be either a Function or an ILinkableVariable to be treated as a boolean setting.
		 * The Function signature can be like function():void or function(item:WeaveMenuItem):void.
		 * Instead of reading this property directly, call runClickFunction().
		 * @see #runClickFunction()
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
		
		private var _enabled:* = true;
		private var _shown:* = true;
		private var _toggled:* = false;
		
		/**
		 * This property is checked by Flex's default data descriptor.
		 */
		public function get toggled():Boolean
		{
			return getBoolean(_toggled, 'toggled');
		}
		public function set toggled(value:*):void
		{
			// Here we check if _toggled is a special value before setting it because
			// we don't want DefaultDataDescriptor.setToggled() to overwrite it.
			if (value is Boolean)
			{
				if (_toggled is ILinkableVariable)
				{
					(_toggled as ILinkableVariable).setSessionState(value);
					return;
				}
				if (_toggled is Function)
					return;
			}
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
		override public function get children():Array
		{
			var items:Array = super.children as Array;
			if (!items)
				return null;
			
			// filter children based on "shown" status (makes a copy)
			items = items.filter(_filterShown);
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
		
		private function _filterShown(item:WeaveMenuItem, index:int, array:Array):Boolean
		{
			return item.shown;
		}
		
		/**
		 * If the click property is set to a Function, it will be called like click.call(this)
		 *   or click.call(this, this) if the former produces an ArgumentError.
		 * If the click property is set to an ILinkableVariable, it will be toggled as a boolean.
		 */
		public function runClickFunction():void
		{
			if (click is Function)
				evalFunction(click as Function);
			
			var lv:ILinkableVariable = click as ILinkableVariable;
			if (lv)
				lv.setSessionState(!lv.getSessionState());
		}
	}
}
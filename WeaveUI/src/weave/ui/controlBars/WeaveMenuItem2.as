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
package weave.ui.controlBars
{
	import mx.collections.ArrayCollection;
	import mx.controls.menuClasses.MenuBarItem;
	
	import weave.api.core.ILinkableObject;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.primitives.LinkableFunction;
		
	public class WeaveMenuItem2 extends MenuBarItem implements ILinkableObject
	{	
		public function WeaveMenuItem2()
		{	
		}
		
		/**
		 * This is just a shorthand function.
		 * 
		 * @param labelFunctionString This is the function to give to the Weave Compiler to set the label. If you
		 * want to specify a constant string, you need to put double quotes around it.
		 * @param clickFunction This is the string for the Weave.compiler function to call.
		 * @param clickFunctionParameters These are the parameters to the clickFunction.
		 * @param enabledFunctionOrBoolean This is either a boolean or a string representation of a function.
		 */		
		public function init(labelFunctionString:* = null, clickFunction:String = null, clickFunctionParameters:Array = null, enabledFunctionOrBoolean:* = true):void
		{
			if (!labelFunctionString)
				labelFunctionString = 'unnamed menu item';
			
			this.labelMethod.value = labelFunctionString;
			this.weaveLabel = labelMethod.apply(this);
			
			if (clickFunction)
				this.clickMethod.value = clickFunction;
			this.functionParameters = clickFunctionParameters;
			
			if (enabledFunctionOrBoolean is String)
				this.enabledMethod.value = enabledFunctionOrBoolean as String;
			else
				this.enabledMethod.value = '"' + String(enabledFunctionOrBoolean) + '"';
			this.enabled = enabledMethod.apply(this);
			
			if (clickFunction == null)
				this.enabled = false;
		}
		
		public const enabledMethod:LinkableFunction = registerLinkableChild(this, new LinkableFunction());
		public const clickMethod:LinkableFunction = registerLinkableChild(this, new LinkableFunction());
		public const labelMethod:LinkableFunction = registerLinkableChild(this, new LinkableFunction());

		private var _functionParameters:Array = null;
		public function get functionParameters():Array
		{
			return _functionParameters;
		}
		public function set functionParameters(a:Array):void
		{
			_functionParameters = a;
		}
		/**
		 * Required, and meaningful, for radio type only) The identifier that associates radio button items in a radio group. 
		 * If you use the default data descriptor, data providers must use a groupName XML attribute or object field to specify this characteristic.
		 */		
		public var groupName:String = null;	

		/**
		 * Specifies the text that appears in the control. This item is used for all menu item types except separator.
		 * The menu's labelField or labelFunction property determines the name of the field in the data that specifies the label, 
		 * or a function for determining the labels. (If the data provider is in E4X XML format, you must specify one of these 
		 * properties to display a label.) If the data provider is an array of strings, Flex uses the string value as the label.
		 */		
		protected var _maxLabelLength:int = 75;
		protected var _label:String = "unnamed menu item";
		
		/**
		 * Specifies the type of menu item. Meaningful values are separator, check, or radio. Flex treats all other values, 
		 * or nodes with no type entry, as normal menu entries.
		 * If you use the default data descriptor, data providers must use a type XML attribute or object field to specify this characteristic.
		 */
		public var type:String = null;
		
		/**
		 * Gets an <code>ArrayCollection</code> representation of the objects in <code>this.childMenus</code>.
		 */		
		[Bindable("propertyChange")] public function get children():ArrayCollection
		{ 
			// get the objects from the actual children hash map
			var temp:Array = childMenus.getObjects();

			// if there are no objects, return 0 so we do not have sub-menus
			if (temp.length == 0)
				return null;
			
			// otherwise, return the result as an array collection (Flex doesn't want an Array?????)
			var result:ArrayCollection = new ArrayCollection(temp);
			return result;
		}
		
		/**
		 * This the hash map of the sessioned children. If you want to add a menu as a child to this menu, you 
		 * must use this.
		 */		
		public const childMenus:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(WeaveMenuItem2));

		/**
		 *  boolean used to indicate that this menu item should be refreshed any time the menu bar is opened so that the label, icon, etc
		 * can update to indicate the current state of the application
		 * TODO: THIS IS NOT USED FOR NOW -- what we would want is the children.refresh() to occur when this menu opens...I guess...
		 */
		public var isDynamic:Boolean = false;
		
		/**
		 *  generic pointer to any object that can be used for comparison on this object when clicked, when the menu is open, etc.
		 * An example would be the VisTool this menu item corresponds to so that the tool can be restored when the menu item is selected
		 */
		public var relevantItemPointer:* = null;
		
		public var toggledFunction:Function = null;
		
		public static const TYPE_SEPARATOR:String = "separator";
		public static const TYPE_CHECK:String = "check";
		public static const TYPE_RADIO:String = "radio";
		/** Custom variables for vis menu items **/
		
		/**
		 * Gets the label for this menu item. 
		 */		
		[Bindable] public function get weaveLabel():String 
		{ 
			if (labelMethod.compiledMethod != null)
			{
				_label = labelMethod.apply(this);
			}

			if(_label.length > _maxLabelLength)
				_label = _label.substr(0, _maxLabelLength).concat("...");

			return _label; 
		}
		/**
		 * Sets the label for this menu item. 
		 * @param value The new label.
		 */		
		public function set weaveLabel(value:String):void { _label = value; }	

		private var _toggled:Boolean = false;
		[Bindable] public function get toggled():Boolean
		{
			if(toggledFunction != null)
				_toggled = toggledFunction();
			
			return _toggled;
		}
		public function set toggled(value:Boolean):void { _toggled = value; }
		
		override public function set enabled(value:Boolean):void
		{
			super.enabled = value;
		}
		override public function get enabled():Boolean
		{
			if (enabledMethod.compiledMethod != null)
				super.enabled = enabledMethod.apply(this);
			
			return super.enabled;
		}
		
		/**
		 * Create a new WeaveMenuItem which is of type <code>TYPE_SEPARATOR</code>
		 * and has an empty label. 
		 * @return The newly created menu item.
		 */		
		public function makeNewSeparatorItem():WeaveMenuItem2
		{
			var separatorItem:WeaveMenuItem2 = childMenus.requestObject(childMenus.generateUniqueName('WeaveMenuItem2'), WeaveMenuItem2, false);
			separatorItem.labelMethod.value = '""';
			separatorItem.type = TYPE_SEPARATOR;
			
			return separatorItem;
		}

		/**
		 * Run the function for a click event.
		 */		
		public function runClickFunction():void
		{
			trace(functionParameters);
			if (clickMethod.compiledMethod!= null)
				clickMethod.apply(this, functionParameters);
		}
		
		public var debugName:String = 'EMPTY';
	}
}
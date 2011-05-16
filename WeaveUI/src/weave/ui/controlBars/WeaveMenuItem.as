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
		
	public class WeaveMenuItem extends MenuBarItem
	{	
		//(Required, and meaningful, for radio type only) The identifier that associates radio button items in a radio group. 
		//If you use the default data descriptor, data providers must use a groupName XML attribute or object field to specify this characteristic.
		public var groupName:String = null;	

		
		//Specifies the text that appears in the control. This item is used for all menu item types except separator.
		//The menu's labelField or labelFunction property determines the name of the field in the data that specifies the label, 
		//or a function for determining the labels. (If the data provider is in E4X XML format, you must specify one of these 
		//properties to display a label.) If the data provider is an array of strings, Flex uses the string value as the label.
		private var _maxLabelLength:int = 75;
		private var _label:String = "unnamed menu item";
		[Bindable]
		public function get weaveLabel():String 
		{ 
			if(labelFunction != null)
			{
				_label = labelFunction();
			}

			if(_label.length > _maxLabelLength)
				_label = _label.substr(0, _maxLabelLength).concat("...");

			return _label; 
		}
		public function set weaveLabel(value:String):void { _label = value; }	

		//Specifies whether a check or radio item is selected. If not specified, Flex treats the item as if the value were false 
		//and the item is not selected.  If you use the default data descriptor, data providers must use a toggled XML 
		//attribute or object field to specify this characteristic.
		private var _toggled:Boolean = false;
		[Bindable]
		public function get toggled():Boolean
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
			if(enabledFunction != null)
				super.enabled = enabledFunction();
			
			return super.enabled;
		}

		//Specifies the type of menu item. Meaningful values are separator, check, or radio. Flex treats all other values, 
		//or nodes with no type entry, as normal menu entries.
		//If you use the default data descriptor, data providers must use a type XML attribute or object field to specify this characteristic.
		public var type:String = null;
		
		[Bindable]
		public var children:ArrayCollection = null;
		
		
		public static const TYPE_SEPARATOR:String = "separator";
		public static const TYPE_CHECK:String = "check";
		public static const TYPE_RADIO:String = "radio";
		/** Custom variables for vis menu items **/
		
		
		// boolean used to indicate that this menu item should be refreshed any time the menu bar is opened so that the label, icon, etc
		// can update to indicate the current state of the application
		// TODO: THIS IS NOT USED FOR NOW -- what we would want is the children.refresh() to occur when this menu opens...I guess...
		public var isDynamic:Boolean = false;
		
		// generic pointer to any object that can be used for comparison on this object when clicked, when the menu is open, etc.
		// An example would be the VisTool this menu item corresponds to so that the tool can be restored when the menu item is selected
		public var relevantItemPointer:* = null;
		
		public var toggledFunction:Function = null;
		
		//public var iconURL:String = null;
		
		public function WeaveMenuItem(labelStringOrFunction:*, clickFunction:Function=null, clickFunctionParameters:Array = null, enabledBooleanOrFunction:*=true)
		{	
			this.weaveLabel = labelStringOrFunction is Function ? labelStringOrFunction() : labelStringOrFunction;
			
			this.clickFunction = clickFunction;
			this.functionParameters = clickFunctionParameters;
			this.labelFunction = labelStringOrFunction as Function;
		
			/*if(iconURL)
			{
				var iconImage:Image = new Image();
				iconImage.source = iconURL;
				
				this.icon = iconImage;
			}*/
			
			//this.iconURL = iconURL;
			
			this.enabled = enabledBooleanOrFunction is Function ? enabledBooleanOrFunction() : enabledBooleanOrFunction;
			this.enabledFunction = enabledBooleanOrFunction as Function;
			
			if(clickFunction == null)
				this.enabled = false;
		}
		
		public static function makeNewSeparatorItem():WeaveMenuItem
		{
			var separatorItem:WeaveMenuItem = new WeaveMenuItem("");
			separatorItem.type = TYPE_SEPARATOR;
			
			return separatorItem;
		}
		
		
		public var clickFunction:Function = null;
		public var labelFunction:Function = null;
		public var enabledFunction:Function = null;
		
		public var functionParameters:Array = null;

		public function runClickFunction():void
		{
			if(clickFunction != null)
				clickFunction.apply(this, functionParameters);
		}
	}
}
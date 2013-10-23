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
package weave.ui
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.CheckBox;
	import mx.core.mx_internal;
	
	import weave.core.UIUtils;
	import weave.utils.EventUtils;
	
	[DefaultProperty("children")]
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 * This class features a correctly behaving auto horizontal scroll policy.
	 */	
	public class CheckBoxWithNestedOptions extends VBox
	{
		public function CheckBoxWithNestedOptions()
		{
			selected = false;
			BindingUtils.bindProperty(this, 'selected', checkBox, 'selected');
			BindingUtils.bindProperty(innerVBox, 'visible', checkBox, 'selected');
			BindingUtils.bindProperty(innerVBox, 'includeInLayout', checkBox, 'selected');
			checkBox.addEventListener(Event.CHANGE, function(event:Event):void { dispatchEvent(event); });
		}
		
		public const indent:int = 20;
		public const checkBox:CheckBox = new CheckBox();
		public const topHBox:HBox = new HBox();
		public const innerVBox:VBox = new VBox();
		
		[Bindable] override public function get label():String
		{
			return super.label;
		}
		override public function set label(value:String):void
		{
			checkBox.label = value;
			super.label = value;
		}
		
		public function set children(array:Array):void
		{
			if (array[0] is HelpComponent)
				UIUtils.spark_addChild(topHBox, array.shift());
			for each (var child:DisplayObject in array)
				UIUtils.spark_addChild(innerVBox, child);
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			UIUtils.spark_addChild(this, topHBox);
			UIUtils.spark_addChildAt(topHBox, checkBox, 0);
			UIUtils.spark_addChild(this, innerVBox);
			this.percentWidth = 100;
			innerVBox.percentWidth = 100;
			innerVBox.setStyle('paddingLeft', indent);
		}
		
		[Bindable("change")] public function get selected():Boolean
		{
			return checkBox.selected;
		}
		public function set selected(value:Boolean):void
		{
			checkBox.mx_internal::setSelected(value);
		}
	}
}

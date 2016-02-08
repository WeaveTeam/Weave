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

package weave.ui
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.core.mx_internal;
	
	import weave.core.UIUtils;
	
	[DefaultProperty("children")]
	[Event(name="change", type="flash.events.Event")]
	
	/**
	 * This will display a checkbox in addition to the children you add.
	 * The children will be indented underneath the checkbox and show/hide depending on the state of the checkbox.
	 * If you add a HelpComponent as a child, it will be displayed to the right of the checkbox.
	 */
	public class CheckBoxWithNestedOptions extends VBox
	{
		public function CheckBoxWithNestedOptions()
		{
			selected = false;
			BindingUtils.bindProperty(this, 'selected', checkBox, 'selected');
			BindingUtils.bindProperty(innerVBox, 'visible', checkBox, 'selected');
			BindingUtils.bindProperty(innerVBox, 'includeInLayout', checkBox, 'selected');
			checkBox.addEventListener(Event.CHANGE, function(event:Event):void {
				dispatchEvent(event);
			});
			BindingUtils.bindSetter(setPaddingLeft, this, 'indent');
		}
		
		[Bindable] public var indent:Number = 20;
		public const checkBox:CustomCheckBox = new CustomCheckBox();
		public const topHBox:HBox = new HBox();
		public const innerVBox:VBox = new VBox();
		
		private function setPaddingLeft(value:Number):void
		{
			innerVBox.setStyle('paddingLeft', value);
		}
		
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
			topHBox.setStyle('verticalAlign', 'middle');
			innerVBox.percentWidth = 100;
			innerVBox.percentHeight = 100;
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

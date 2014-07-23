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
	import mx.controls.HSlider;
	import mx.controls.sliderClasses.Slider;
	import mx.controls.sliderClasses.SliderLabel;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	
	use namespace mx_internal;
	
	/**
	 * Adds labelPositions functionality.
	 */
	public class CustomHSlider extends HSlider
	{
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			setLabelPositions(this, _labelPositions);
		}
		
		private var _labelPositions:Array = [];
		
		/**
		 * Positions corresponding to the labels property.
		 * @see #labels
		 */
		[Bindable] public function get labelPositions():Array
		{
			return _labelPositions;
		}
		public function set labelPositions(value:Array):void
		{
			_labelPositions = value;
			invalidateDisplayList();
		}
		
		public static function getLabelObjects(slider:Slider):UIComponent
		{
			if (!slider.innerSlider || !slider.getTrackHitArea())
				return null;
			var i:int = slider.innerSlider.getChildIndex(slider.getTrackHitArea());
			if (i == 0)
				return null;
			var component:UIComponent = slider.innerSlider.getChildAt(i - 1) as UIComponent;
			if (component && component.numChildren > 0 && component.getChildAt(0) is SliderLabel)
				return component;
			return null;
		}
		public static function setLabelPositions(slider:Slider, positions:Array):void
		{
			var labelObjects:UIComponent = getLabelObjects(slider);
			if (positions && labelObjects)
			{
				for (var i:int = 0; i < labelObjects.numChildren; i++)
				{
					var sliderLabel:SliderLabel = labelObjects.getChildAt(i) as SliderLabel;
					if (sliderLabel)
						sliderLabel.x = slider.getXFromValue(positions[i]) - sliderLabel.width;
				}
			}
		}
	}
}
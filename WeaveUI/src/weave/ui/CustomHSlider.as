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
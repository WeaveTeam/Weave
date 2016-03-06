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

package weavejs.util
{
	import weavejs.WeaveAPI;
	import weavejs.core.LinkableVariable;
	import weavejs.util.StandardLib;
	
	/**
	 * @author adufilie
	 * @author abaumann
	 */
	public class ColorRamp extends LinkableVariable
	{
		public static const COLOR:String = 'color';
		public static const POSITION:String = 'position';
		
		public function ColorRamp(sessionState:Object = null)
		{
			super(null, verifyState, sessionState || getColorRampByName("Blues").colors);
		}
		private function verifyState(state:Object):Boolean
		{
			if (state is String)
			{
				var reversed:Boolean = false;
				
				// parse list of color values
				var colors:Array = WeaveAPI.CSVParser.parseCSVRow(state as String);
				if (reversed)
					colors.reverse();
				this.setSessionState(colors);
				return false;
			}
			
			var type:Class = StandardLib.getArrayType(state as Array);
			if (type == Number)
			{
				var array:Array = [];
				for each (var number:Number in state)
					array.push('0x' + StandardLib.numberToBase(number, 16, 6).toUpperCase());
				this.setSessionState(array);
				return false;
			}
			return type == String || type == Object;
		}
		
		private var _validateTriggerCount:uint = 0;
		
		private function validate():void
		{
			if (_validateTriggerCount == triggerCounter)
				return;
			
			_validateTriggerCount = triggerCounter;
			
			_colorNodes = [];
			for each (var item:Object in this.getSessionState())
			{
				if (typeof item == 'object')
					_colorNodes.push(new ColorNode(item[POSITION], item[COLOR]));
				else
					_colorNodes.push(new ColorNode(_colorNodes.length, StandardLib.asNumber(item)));
			}
			
			// if min,max positions are not 0,1, normalize all positions between 0 and 1
			var positions:Array = ArrayUtils.pluck(_colorNodes, POSITION);
			var minPos:Number = Math.min.apply(null, positions);
			var maxPos:Number = Math.max.apply(null, positions);
			for each (var node:ColorNode in _colorNodes)
				node.position = StandardLib.normalize(node.position, minPos, maxPos);
			
			StandardLib.sortOn(_colorNodes, "position");
		}
		
		public function reverse():void
		{
			var array:Array = this.getSessionState() as Array;
			if (array)
				this.setSessionState(array.reverse());
		}

		/**
		 * An array of ColorNode objects, each having "color" and "position" properties, sorted by position.
		 * This Array should be kept private.
		 */
		private var _colorNodes:Array = [];
		
		public function getColors():Array
		{
			validate();
			
			var colors:Array = [];
			
			for(var i:int = 0; i < _colorNodes.length; i++)
				colors.push((_colorNodes[i] as ColorNode).color);
			
			return colors;
		}
		
		/**
		 * @param normValue A value between 0 and 1.
		 * @return A color.
		 */
		public function getColorFromNorm(normValue:Number):Number
		{
			validate();
			
			if (isNaN(normValue) || normValue < 0 || normValue > 1 || _colorNodes.length == 0)
				return NaN;
			
			// find index to the right of normValue
			var rightIndex:int = 0;
			while (rightIndex < _colorNodes.length && normValue >= (_colorNodes[rightIndex] as ColorNode).position)
				rightIndex++;
			var leftIndex:int = Math.max(0, rightIndex - 1);
			var leftNode:ColorNode = _colorNodes[leftIndex] as ColorNode;
			var rightNode:ColorNode = _colorNodes[rightIndex] as ColorNode;

			// handle boundary conditions
			if (rightIndex == 0)
				return rightNode.color;
			if (rightIndex == _colorNodes.length)
				return leftNode.color;

			var interpolationValue:Number = (normValue - leftNode.position) / (rightNode.position - leftNode.position);
			return StandardLib.interpolateColor(interpolationValue, leftNode.color, rightNode.color);
		}
		
		/**
		 * Normalizes a value between min and max and returns an RGB hex color.
		 * @param value A numeric value
		 * @param min The min value used for normalization
		 * @param max The max value used for normalization
		 * @return A color represented as a Number between 0x000000 and 0xFFFFFF
		 */
		public function getColor(value:Number, min:Number = 0, max:Number = 1):Number
		{
			var normValue:Number = min == 0 && max == 1 ? value : StandardLib.normalize(value, min, max);
			return getColorFromNorm(normValue);
		}
		
		/**
		 * Normalizes a value between min and max and returns an RGB hex color.
		 * @param value A numeric value
		 * @param min The min value used for normalization
		 * @param max The max value used for normalization
		 * @return A 6-digit hex color String like #FFFFFF
		 */
		public function getHexColor(value:Number, min:Number = 0, max:Number = 1):String
		{
			var normValue:Number = min == 0 && max == 1 ? value : StandardLib.normalize(value, min, max);
			var color:Number = getColorFromNorm(normValue);
			if (!isFinite(color))
				return null;
			return '#' + StandardLib.numberToBase(color, 16, 6);
		}
		
		/* *
		 * This will draw the color ramp.
		 * @param destination The sprite where the ramp should be drawn.
		 * @param xDirection Either -1, 0, or 1. If xDirection is zero, yDirection must be non-zero, and vice versa.
		 * @param yDirection Either -1, 0, or 1. If xDirection is zero, yDirection must be non-zero, and vice versa.
		 * @param bounds Optional bounds for the ramp graphics.
		 */
		/*
		public function draw(destination:DisplayObject, xDirection:int, yDirection:int, bounds:IBounds2D = null):void
		{
			validate();
			
			var g:Graphics = destination['graphics'];
			var vertical:Boolean = yDirection != 0;
			var direction:int = StandardLib.sign(yDirection || xDirection || 1);
			var x:Number = bounds ? bounds.getXMin() : 0;
			var y:Number = bounds ? bounds.getYMin() : 0;
			var w:Number = bounds ? bounds.getWidth() : destination.width;
			var h:Number = bounds ? bounds.getHeight() : destination.height;
			var offset:Number = bounds ? (vertical ? bounds.getXDirection() : bounds.getYDirection()) : 1;
			
			g.clear();
			var n:int = Math.abs(vertical ? h : w);
			for (var i:int = 0; i < n; i++)
			{
				var norm:Number = i / (n - 1);
				if (direction < 0)
					norm = 1 - norm;
				var color:Number = getColorFromNorm(norm);
				if (isNaN(color))
					continue;
				g.lineStyle(1, color, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE); // pixelHinting = false or the endpoints will be blurry
				if (vertical)
				{
					g.moveTo(x, y + i);
					g.lineTo(x + w - offset + 1, y + i); // add 1 to the end point or it won't draw the last pixel
				}
				else
				{
					g.moveTo(x + i, y);
					g.lineTo(x + i, y + h - offset + 1); // add 1 to the end point or it won't draw the last pixel
				}
			}
		}
		*/

		/************************
		 * begin static section *
		 ************************/
		
		/**
		 * @return An Object with "name", "tags", and "colors" properties.
		 */
		public static function getColorRampByName(rampName:String):Object
		{
			for each (var ramp:Object in allColorRamps)
			if (ramp.name === rampName)
				return ramp;
			return null;
		}
		
		/**
		 * @return An Object with "name", "tags", and "colors" properties.
		 */
		public static function findMatchingColorRamp(ramp:ColorRamp):Object
		{
			var colors:Array = ramp.getColors();
			for each (var obj:Object in allColorRamps)
			if (StandardLib.compare(obj.colors, colors) == 0)
				return obj;
			return null;
		}
		
		public static const allColorRamps:Array = [
			{name: "Campfire", tags: "OIC,aesthetic", colors: [0x660000,0xFF0000,0xFFFF00]},
			{name: "Pink Rose", tags: "OIC,aesthetic", colors: [0xffc7fa,0xfa0094,0x660066]},
			{name: "Linear Gray", tags: "OIC,visualization,colorblind-safe,single-hue", colors: [0x000000,0xffffff]},
			{name: "Blue Green Red", tags: "OIC,visualization", colors: [0x0000ff,0x00ff00,0xff0000]},
			{name: "Red Scale", tags: "OIC,visualization,single-hue", colors: [0x000000,0xff0000,0xffcccc]},
			{name: "Blue To Cyan", tags: "OIC,visualization", colors: [0x000000,0x00b7f6,0x0bc4ff,0x68ffff,0xffffff]},
			{name: "Blue To Yellow", tags: "OIC,visualization", colors: [0x0000ff,0xffff00]},
			{name: "Heated", tags: "OIC,visualization,single-hue", colors: [0x130000,0x611501,0xb26b01,0xf0902e,0xfbbc06,0xfefefe]},
			{name: "MCH - Brown", tags: "OIC,visualization,single-hue", colors: [0x611501,0xb26b01,0xf0902e,0xfbbc06]},
			{name: "Jet", tags: "OIC,visualization,qualitative", colors: [0x000086,0x0000ff,0x00ffff,0xffff00,0xff0000,0x860000]},
			{name: "Linearized Optimal", tags: "OIC,visualization", colors: [0x000000,0x870000,0x87fe00,0x87ffff,0xffffff]},
			{name: "Rainbow", tags: "OIC,visualization", colors: [0x000000,0x470057,0x17458f,0x5fc046,0xa0c84c,0xffb38e,0xffffff]},
			{name: "Traffic Light", tags: "OIC,basic", colors: [0x00FF00,0xFFFF00,0xFF0000]},
			{name: "Arizona Skyline", tags: "OIC,aesthetic", colors: [0x5683B9,0xFFF0A1,0xE0991B,0xC23600,0x503000]},
			{name: "Watermelon", tags: "OIC,aesthetic", colors: [0x3E5B13,0x61B10D,0xCCCD06,0xFF8F88,0x630000]},
			{name: "Thunderstorm", tags: "OIC,aesthetic", colors: [0x585634,0x4781B5,0x6FBAFF,0xffff00]},
			{name: "Old Leather", tags: "OIC,aesthetic", colors: [0x404320,0x71550E,0x896731,0xDDD200,0x5C97BA,0x5C97BA]},
			{name: "Autumn", tags: "OIC,aesthetic", colors: [0x1A0000,0x712B00,0xFFBF88,0xFF6B00,0xFA0000]},
			{name: "Eggplant", tags: "OIC,aesthetic", colors: [0x040009,0x4E0075,0x7E00A5,0xE2A510,0xFFFF99]},
			{name: "Antique Flag", tags: "OIC,aesthetic", colors: [0x114B48,0x00AFF7,0xDBF9EF,0xABB869,0xFF0000]},
			{name: "Agate", tags: "OIC,aesthetic", colors: [0x6E4D58,0x9199A6,0xFFDCB7,0xFE7A1D,0xCB0000]},
			{name: "Bee", tags: "OIC,aesthetic,single-hue", colors: [0x000000,0xFFFF00]},
			{name: "Ornamental Cabbage", tags: "OIC,aesthetic", colors: [0x3E2A64,0x61B812,0xC4C74B,0xCCC59B,0xB4377A,0xB4377A]},
			{name: "Neon", tags: "OIC,aesthetic", colors: [0x334833,0xD75B8F,0xFF0080,0xFFFF00,0x00D100]},
			{name: "High Desert", tags: "OIC,aesthetic", colors: [0xB47046,0x72616A,0xD1C7C8,0xFFFFFF,0x0028AE]},
			{name: "Vermilion Cliffs", tags: "OIC,aesthetic", colors: [0x641300,0xD32500,0xFF7500,0xFFCA7D,0x0000D2,0x0000D2]},
			{name: "Papaya", tags: "OIC,aesthetic", colors: [0x101C01,0x3F8751,0x386C00,0xFD9E00,0xEF0000]},
			{name: "Van Gogh", tags: "OIC,aesthetic", colors: [0x31415A,0x609DCD,0xFFFF00,0xE9B400,0xBE2E00]},
			{name: "Outer Banks", tags: "OIC,aesthetic", colors: [0x674F38,0xD62A00,0xF7AD00,0xFAEABB,0x0096C4]},
			{name: "Desert Sands", tags: "OIC,aesthetic", colors: [0xF8E368,0xCEBA00,0x816B00,0xB55800,0x542000,0x242000]},
			{name: "Moonlight", tags: "OIC,aesthetic", colors: [0x040505,0x363635,0x0A0528,0xD1F0E4,0xDCC400,0xDCC400]},
			{name: "Twilight", tags: "OIC,aesthetic", colors: [0x2F2521,0xC8ACFE,0xFFFFFF,0xE4FF00]},
			{name: "Rosebud", tags: "OIC,aesthetic", colors: [0x69594E,0xADAF48,0xFEF0FE,0xF3008B,0xCD001E]},
			{name: "Morning Glory", tags: "OIC,aesthetic", colors: [0x590653,0xFFC1FF,0xFFFF00,0x5D00FF,0x3C00D9]},
			{name: "Cloudy Night", tags: "OIC,aesthetic", colors: [0x070411,0x6733AE,0xFFFFFF,0xFF6E00]},
			{name: "Vintage Map", tags: "OIC,aesthetic", colors: [0xFAF9E6,0xFBF672,0xFFD99F,0xB4C352,0x92E5CA,0xFD9DAB]},
			{name: "Doppler Radar", tags: "OIC,aesthetic,qualitative", colors: [0x04E9E7,0x009DF4,0x0201F4,0x01FC01,0x00C400,0x008C00,0x0FDF801,0xF99200,0xFD0000,0xBC0000,0xF800FD,0x9854C6]},
			{name: "Bu Gn", tags: "ColorBrewer,basic,sequential,colorblind-safe", colors: [0xEDF8FB,0xB2E2E2,0x66C2A4,0x2CA25F,0x006D2C]},
			{name: "Bu Pu", tags: "ColorBrewer,basic,sequential,colorblind-safe", colors: [0xEDF8FB,0xB3CDE3,0x8C96C6,0x8856A7,0x810F7C]},
			{name: "Gn Bu", tags: "ColorBrewer,basic,sequential,printer-friendly,colorblind-safe", colors: [0xF0F9E8,0xBAE4BC,0x7BCCC4,0x43A2CA,0x0868AC]},
			{name: "Or Rd", tags: "ColorBrewer,basic,sequential,colorblind-safe", colors: [0xFEF0D9,0xFDCC8A,0xFC8D59,0xE34A33,0xB30000]},
			{name: "Pu Bu", tags: "ColorBrewer,basic,sequential,colorblind-safe", colors: [0xF1EEF6,0xBDC9E1,0x74A9CF,0x2B8CBE,0x045A8D]},
			{name: "Pu Bu Gn", tags: "ColorBrewer,basic,sequential,colorblind-safe", colors: [0xF6EFF7,0xBDC9E1,0x67A9CF,0x1C9099,0x016C59]},
			{name: "Pu Rd", tags: "ColorBrewer,basic,sequential,printer-friendly,colorblind-safe", colors: [0xF1EEF6,0xD7B5D8,0xDF65B0,0xDD1C77,0x980043]},
			{name: "Rd Pu", tags: "ColorBrewer,basic,sequential,printer-friendly,colorblind-safe", colors: [0xFEEBE2,0xFBB4B9,0xF768A1,0xC51B8A,0x7A0177]},
			{name: "Yl Gn", tags: "ColorBrewer,basic,sequential,colorblind-safe", colors: [0xFFFFCC,0xC2E699,0x78C679,0x31A354,0x006837]},
			{name: "Yl Gn Bu", tags: "ColorBrewer,basic,sequential,printer-friendly,colorblind-safe", colors: [0xFFFFCC,0xA1DAB4,0x41B6C4,0x2C7FB8,0x253494]},
			{name: "Yl Or Br", tags: "ColorBrewer,basic,sequential,colorblind-safe", colors: [0xFFFFD4,0xFED98E,0xFE9929,0xD95F0E,0x993404]},
			{name: "Yl Or Rd", tags: "ColorBrewer,basic,sequential,colorblind-safe", colors: [0xFFFFB2,0xFECC5C,0xFD8D3C,0xF03B20,0xBD0026]},
			{name: "Blues", tags: "ColorBrewer,basic,sequential,single-hue,colorblind-safe", colors: [0xEFF3FF,0xBDD7E7,0x6BAED6,0x3182BD,0x08519C]},
			{name: "Greens", tags: "ColorBrewer,basic,sequential,single-hue,colorblind-safe", colors: [0xEDF8E9,0xBAE4B3,0x74C476,0x31A354,0x006D2C]},
			{name: "Greys", tags: "ColorBrewer,basic,sequential,single-hue,colorblind-safe", colors: [0xF7F7F7,0xCCCCCC,0x969696,0x636363,0x252525]},
			{name: "Oranges", tags: "ColorBrewer,basic,sequential,single-hue,colorblind-safe", colors: [0xFEEDDE,0xFDBE85,0xFD8D3C,0xE6550D,0xA63603]},
			{name: "Purples", tags: "ColorBrewer,basic,sequential,single-hue,colorblind-safe", colors: [0xF2F0F7,0xCBC9E2,0x9E9AC8,0x756BB1,0x54278F]},
			{name: "Reds", tags: "ColorBrewer,basic,sequential,single-hue,colorblind-safe", colors: [0xFEE5D9,0xFCAE91,0xFB6A4A,0xDE2D26,0xA50F15]},
			{name: "Br BG", tags: "ColorBrewer,basic,diverging,colorblind-safe,printer-friendly", colors: [0xA6611A,0xDFC27D,0xF5F5F5,0x80CDC1,0x018571]},
			{name: "Pi YG", tags: "ColorBrewer,basic,diverging,colorblind-safe", colors: [0xD01C8B,0xF1B6DA,0xF7F7F7,0xB8E186,0x4DAC26]},
			{name: "PR Gn", tags: "ColorBrewer,basic,diverging,colorblind-safe,printer-friendly", colors: [0x7B3294,0xC2A5CF,0xF7F7F7,0xA6DBA0,0x008837]},
			{name: "Pu Or", tags: "ColorBrewer,basic,diverging,colorblind-safe", colors: [0xE66101,0xFDB863,0xF7F7F7,0xB2ABD2,0x5E3C99]},
			{name: "Rd Bu", tags: "ColorBrewer,basic,diverging,colorblind-safe,printer-friendly", colors: [0xCA0020,0xF4A582,0xF7F7F7,0x92C5DE,0x0571B0]},
			{name: "Rd Gy", tags: "ColorBrewer,basic,diverging,printer-friendly", colors: [0xCA0020,0xF4A582,0xFFFFFF,0xBABABA,0x404040]},
			{name: "Rd Yl Bu", tags: "ColorBrewer,basic,diverging,colorblind-safe,printer-friendly", colors: [0xD7191C,0xFDAE61,0xFFFFBF,0xABD9E9,0x2C7BB6]},
			{name: "Rd Yl Gn", tags: "ColorBrewer,basic,diverging,printer-friendly", colors: [0xD7191C,0xFDAE61,0xFFFFBF,0xA6D96A,0x1A9641]},
			{name: "Spectral", tags: "ColorBrewer,basic,diverging,printer-friendly,photocopy-friendly", colors: [0xD7191C,0xFDAE61,0xFFFFBF,0xABDDA4,0x2B83BA]},
			{name: "Accent", tags: "ColorBrewer,basic,qualitative", colors: [0x7FC97F,0xBEAED4,0xFDC086,0xFFFF99,0x386CB0,0xF0027F,0xBF5B17,0x666666]},
			{name: "Dark2", tags: "ColorBrewer,basic,qualitative,printer-friendly", colors: [0x1B9E77,0xD95F02,0x7570B3,0xE7298A,0x66A61E,0xE6AB02,0xA6761D,0x666666]},
			{name: "Paired", tags: "ColorBrewer,basic,qualitative", colors: [0xA6CEE3,0x1F78B4,0xB2DF8A,0x33A02C,0xFB9A99,0xE31A1C,0xFDBF6F,0xFF7F00]},
			{name: "Pastel 1", tags: "ColorBrewer,basic,qualitative", colors: [0xFBB4AE,0xB3CDE3,0xCCEBC5,0xDECBE4,0xFED9A6,0xFFFFCC,0xE5D8BD,0xFDDAEC]},
			{name: "Pastel 2", tags: "ColorBrewer,basic,qualitative", colors: [0xB3E2CD,0xFDCDAC,0xCBD5E8,0xF4CAE4,0xE6F5C9,0xFFF2AE,0xF1E2CC,0xCCCCCC]},
			{name: "Set 1", tags: "ColorBrewer,basic,qualitative,printer-friendly", colors: [0xE41A1C,0x377EB8,0x4DAF4A,0x984EA3,0xFF7F00,0xFFFF33,0xA65628,0xF781BF]},
			{name: "Set 2", tags: "ColorBrewer,basic,qualitative", colors: [0x66C2A5,0xFC8D62,0x8DA0CB,0xE78AC3,0xA6D854,0xFFD92F,0xE5C494,0xB3B3B3]},
			{name: "Set 3", tags: "ColorBrewer,basic,qualitative,printer-friendly", colors: [0x8DD3C7,0xFFFFB3,0xBEBADA,0xFB8072,0x80B1D3,0xFDB462,0xB3DE69,0xFCCDE5]}
		];
	}
}

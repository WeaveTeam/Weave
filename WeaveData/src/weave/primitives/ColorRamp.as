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

package weave.primitives
{
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.utils.ByteArray;
	
	import weave.api.primitives.IBounds2D;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.utils.VectorUtils;
	
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
			super(null, verifyState, sessionState || getColorRampXMLByName("Blues").toString());
		}
		private function verifyState(state:Object):Boolean
		{
			if (state is XML)
				state = (state as XML).toXMLString();
			
			if (state is String)
			{
				var reversed:Boolean = false;
				
				// see if we should try parsing as xml
				if ((state as String).charAt(0) == '<' && (state as String).substr(-1) == '>')
				{
					try
					{
						var xml:XML = XML(state);
						var text:String = xml.text();
						reversed = String(xml.@reverse) == 'true';
						if (text)
						{
							state = text;
						}
						else
						{
							// handle a list of colorNode tags containing position and color attributes
							var objects:Array = [];
							var nodes:XMLList = xml.children();
							var n:int = nodes.length();
							for each (var node:XML in nodes)
							{
								var position:String = node.@[POSITION];
								var pos:Number = position == '' ? objects.length / (n - 1) : Number(position);
								var color:Number = Number(node.@[COLOR]);
								objects.push({"color": color, "position": pos});
							}
							if (reversed)
								objects.reverse();
							this.setSessionState(objects);
							return false;
						}
					}
					catch (e:Error) { } // not an XML
				}
				
				// parse list of color values
				var colors:Array = WeaveAPI.CSVParser.parseCSVRow(text || state as String);
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
			var positions:Array = VectorUtils.pluck(_colorNodes, POSITION);
			var minPos:Number = Math.min.apply(null, positions);
			var maxPos:Number = Math.max.apply(null, positions);
			for each (var node:ColorNode in _colorNodes)
				node.position = StandardLib.normalize(node.position, minPos, maxPos);
			
			_colorNodes.sortOn("position");
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
		 * This will draw the color ramp.
		 * @param destination The sprite where the ramp should be drawn.
		 * @param xDirection Either -1, 0, or 1. If xDirection is zero, yDirection must be non-zero, and vice versa.
		 * @param yDirection Either -1, 0, or 1. If xDirection is zero, yDirection must be non-zero, and vice versa.
		 * @param bounds Optional bounds for the ramp graphics.
		 */
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

		/************************
		 * begin static section *
		 ************************/
		
		[Embed(source="/weave/resources/ColorRampPresets.xml", mimeType="application/octet-stream")]
		private static const ColorRampPresetsXML:Class;
		private static var _allColorRamps:XML = null;
		public static function get allColorRamps():XML
		{
			if (_allColorRamps == null)
			{
				var ba:ByteArray = (new ColorRampPresetsXML()) as ByteArray;
				_allColorRamps = new XML( ba.readUTFBytes( ba.length ) );
				_allColorRamps.ignoreWhitespace = true;
			}
			return _allColorRamps;
		}
		public static function getColorRampXMLByName(rampName:String):XML
		{
			try
			{
				return (allColorRamps.colorRamp.(@name == rampName)[0] as XML).copy();
			}
			catch (e:Error) { }
			return null;
		}
		public static function findMatchingColorRampXML(ramp:ColorRamp):XML
		{
			var colors:Array = ramp.getColors();
			for (var i:int = 0; i < colors.length; i++)
				colors[i] = '0x' + StandardLib.numberToBase(colors[i], 16, 6);
			var str:String = colors.join(',').toUpperCase();
			for each (var xml:XML in allColorRamps.colorRamp)
			{
				var text:String = xml.toString().toUpperCase();
				if (text == str)
					return xml;
			}
			return null;
		}
	}
	
}

// for private use
internal class ColorNode
{
	public function ColorNode(position:Number, color:Number)
	{
		this.position = position;
		this.color = color;
	}
	
	public var position:Number;
	public var color:Number;
}

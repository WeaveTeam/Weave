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

package weave.primitives
{
	import flash.utils.ByteArray;
	
	import weave.compiler.MathLib;
	import weave.core.LinkableXML;
	import weave.utils.VectorUtils;
	
	/**
	 * ColorRamp
	 * Makes a colorRamp xml definition useful through a getColorFromNorm() function.
	 * 
	 * @author adufilie
	 * @author abaumann
	 */
	public class ColorRamp extends LinkableXML
	{		
		public function ColorRamp(rampXML:XML = null)
		{
			super();
			addImmediateCallback(this, firstCallback);
			if (rampXML == null)
				rampXML = <colorRamp name="Grayscale">
						<node color="0x000000" position="0.0"/>
						<node color="0xffffff" position="1.0"/>
					</colorRamp>;
			setSessionState(rampXML);
		}
		
		private function firstCallback():void
		{
			if (_sessionState is XML)
			{
				var xmlNodes:XMLList = _sessionState.children();
				
				_colorNodes.length = xmlNodes.length();
				var positions:Array = [];
				for (var i:int = 0; i < xmlNodes.length(); i++)
				{
					var pos:Number = Number(xmlNodes[i].@position);
					var color:Number = Number(xmlNodes[i].@color);
					//_colorNodes[i] = new ColorNode(pos, color);
					_colorNodes[i] = {position: pos, color: color};
					positions.push(pos);
				}
				// if min,max positions are not 0,1, normalize all positions between 0 and 1
				var minPos:Number = Math.min.apply(null, positions);
				var maxPos:Number = Math.max.apply(null, positions);
				if (minPos < 0 || maxPos > 1)
					for each (var node:Object in _colorNodes)
						node.position = MathLib.normalize(node.position, minPos, maxPos);
				
				_colorNodes.sortOn("position");
				
				_reversed = String((_sessionState as XML).@reverse) == 'true';
			}
			else
			{
				_colorNodes.length = 0;
				_reversed = false;
			}
		}
		
		private var _reversed:Boolean = false;
		public function get reversed():Boolean
		{
			return _reversed;
		}
		public function set reversed(value:Boolean):void
		{
			if (_sessionState == null)
				return;
			(_sessionState as XML).@reverse = value;
			detectChanges();
		}

		public function get name():String
		{
			if (_sessionState is XML)
				return (_sessionState as XML).@name;
			return null;
		}
		public function set name(value:String):void
		{
			if (_sessionState == null)
				return;
			(_sessionState as XML).@name = value;
			detectChanges();
		}
		
		/**
		 * An array of ColorNode objects, each having "color" and "position" properties, sorted by position.
		 * This Array should be kept private.
		 */
		private const _colorNodes:Array = [];

		/**
		 * getColorFromNorm
		 * @param normValue A value between 0 and 1.
		 * @return A color.
		 */
		public function getColorFromNorm(normValue:Number):Number
		{
			if (normValue < 0 || normValue > 1 || _colorNodes.length == 0)
				return NaN;
			
			if (_reversed)
				normValue = 1 - normValue;
			
			// find index to the right of normValue
			var rightIndex:int = 0;
//			while (rightIndex < _colorNodes.length && normValue >= (_colorNodes[rightIndex] as ColorNode).position)
//				rightIndex++;
			while (rightIndex < _colorNodes.length && normValue >= _colorNodes[rightIndex].position)
				rightIndex++;
			var leftIndex:int = Math.max(0, rightIndex - 1);
//			var leftNode:ColorNode = _colorNodes[leftIndex] as ColorNode;
//			var rightNode:ColorNode = _colorNodes[rightIndex] as ColorNode;
			var leftNode:Object = _colorNodes[leftIndex];
			var rightNode:Object = _colorNodes[rightIndex];

			// handle boundary conditions
			if (rightIndex == 0)
				return rightNode.color;
			if (rightIndex == _colorNodes.length)
				return leftNode.color;

			var interpolationValue:Number = (normValue - leftNode.position) / (rightNode.position - leftNode.position);
			return MathLib.interpolateColor(interpolationValue, leftNode.color, rightNode.color);
		}

		/************************
		 * begin static section *
		 ************************/
		
		[Embed("/weave/resources/ColorRampPresets.xml", mimeType="application/octet-stream")]
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

		private static var _allColorRampNames:Array = [];
		public static function get allColorRampNames():Array
		{
			if (_allColorRampNames.length == 0)
				VectorUtils.copyXMLListToVector(allColorRamps.colorRamp.@name, _allColorRampNames);
			return _allColorRampNames;
		}
		
		public static function getColorRampXMLByName(name:String):XML
		{
			return (allColorRamps.colorRamp.(@name == name)[0] as XML).copy();
		}
		
		private var ColorNode:Class = Object;
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

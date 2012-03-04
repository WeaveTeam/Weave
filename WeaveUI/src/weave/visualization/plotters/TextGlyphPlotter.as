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

package weave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	
	import mx.utils.ObjectUtil;
	
	import weave.WeaveProperties;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.LinkableTextFormat;
	import weave.utils.ObjectPool;
	import weave.utils.ProbeTextUtils;
	
	/**
	 * TextGlyphPlotter
	 * 
	 * @author adufilie
	 */
	public class TextGlyphPlotter extends AbstractGlyphPlotter
	{
		public function TextGlyphPlotter()
		{
			hideOverlappingText.value = false;
			xScreenOffset.value = 0;
			yScreenOffset.value = 0;
			setKeySource(text);
		}
		
		public function setBaseKeySource(source:IKeySet):void
		{
			setKeySource(source);
		}
		
		private const bitmapText:BitmapText = new BitmapText();
		private const matrix:Matrix = new Matrix();

		private static const tempPoint:Point = new Point(); // reusable object
		
		public const sortColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);

		public const text:DynamicColumn = newLinkableChild(this, DynamicColumn);
		
		public function setDefaultTextFormat(ltf:LinkableTextFormat):void
		{
			font.defaultValue.value = ltf.font.value;
			size.defaultValue.value = ltf.size.value;
			color.defaultValue.value = ltf.color.value;
			bold.defaultValue.value = ltf.bold.value;
			italic.defaultValue.value = ltf.italic.value;
			underline.defaultValue.value = ltf.underline.value;
		}
		public const font:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(LinkableTextFormat.DEFAULT_FONT));
		public const size:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(LinkableTextFormat.DEFAULT_SIZE));
		public const color:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(0x000000));
		public const bold:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(false));
		public const italic:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(false));
		public const underline:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(false));
		
		public const hAlign:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(BitmapText.HORIZONTAL_ALIGN_CENTER));
		public const vAlign:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(BitmapText.VERTICAL_ALIGN_MIDDLE));
		public const angle:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(0));
		public const hideOverlappingText:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		public const xScreenOffset:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const yScreenOffset:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const maxWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(80));

		/**
		 * This function is used with Array.sort to sort a list of record keys by the sortColumn values.
		 */
		private function compareRecords(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			var value1:Number = sortColumn.getValueFromKey(key1, Number);
			var value2:Number = sortColumn.getValueFromKey(key2, Number);
			return ObjectUtil.numericCompare(value1, value2)
				|| ObjectUtil.compare(key1, key2);
		}

		/**
		 * Draws the graphics onto BitmapData.
		 */
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (sortColumn.internalColumn != null)
				recordKeys.sort(compareRecords);

			var textWasDrawn:Array = [];
			var reusableBoundsObjects:Array = [];
			var bounds:IBounds2D;
			for (var i:int = 0; i < recordKeys.length; i++)
			{
				var recordKey:IQualifiedKey = recordKeys[i] as IQualifiedKey;
				
				// project data coordinates to screen coordinates and draw graphics onto tempShape
				tempPoint.x = dataX.getValueFromKey(recordKey, Number);
				tempPoint.y = dataY.getValueFromKey(recordKey, Number);
				dataBounds.projectPointTo(tempPoint, screenBounds);

				// round to nearest pixel to get clearer text
				bitmapText.x = Math.round(tempPoint.x + xScreenOffset.value);
				bitmapText.y = Math.round(tempPoint.y + yScreenOffset.value);
				bitmapText.text = text.getValueFromKey(recordKey, String) as String;
				bitmapText.verticalAlign = vAlign.getValueFromKey(recordKey, String) as String;
				bitmapText.horizontalAlign = hAlign.getValueFromKey(recordKey, String) as String;
				bitmapText.angle = angle.getValueFromKey(recordKey, Number);
				bitmapText.maxWidth = maxWidth.value - xScreenOffset.value;
				
				// init text format			
				var f:TextFormat = bitmapText.textFormat;
				f.font = font.getValueFromKey(recordKey, String) as String;
				f.size = size.getValueFromKey(recordKey, Number);
				f.color = color.getValueFromKey(recordKey, Number);
				f.bold = bold.getValueFromKey(recordKey, Boolean) as Boolean;
				f.italic = italic.getValueFromKey(recordKey, Boolean) as Boolean;
				f.underline = underline.getValueFromKey(recordKey, Boolean) as Boolean;

				if (hideOverlappingText.value)
				{
					// grab a bounds object to store the screen size of the bitmap text
					bounds = reusableBoundsObjects[i] = ObjectPool.borrowObject(Bounds2D);
					bitmapText.getUnrotatedBounds(bounds);
					
					// brute force check to see if this bounds overlaps with any previous bounds
					var overlaps:Boolean = false;
					for (var j:int = 0; j < i; j++)
					{
						if (textWasDrawn[j] && bounds.overlaps(reusableBoundsObjects[j] as IBounds2D))
						{
							overlaps = true;
							break;
						}
					}
					
					if (overlaps)
					{
						textWasDrawn[i] = false;
						continue;
					}
					else
					{
						textWasDrawn[i] = true;
					}
				}
				
				if (bitmapText.angle == 0)
				{
					// draw almost-invisible rectangle behind text
					bitmapText.getUnrotatedBounds(tempBounds);
					tempBounds.getRectangle(tempRectangle);
					
					var pixels:Vector.<uint> = destination.getVector(tempRectangle);
					for (var p:int = 0; p < pixels.length; p++)
					{
						var color:uint = pixels[p] as uint;
						if (!color)
							pixels[p] = color | 0x20808080;
					}
					destination.setVector(tempRectangle, pixels);
					
					//destination.fillRect(tempRectangle, 0x02808080);
				}
				
				bitmapText.draw(destination);
			}
			for each (bounds in reusableBoundsObjects)
				ObjectPool.returnObject(bounds);
		}

		private static const tempRectangle:Rectangle = new Rectangle(); // reusable temporary object
		private static const tempBounds:IBounds2D = new Bounds2D(); // reusable temporary object
	}
}

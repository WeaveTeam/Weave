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
	
	import weave.Weave;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ITextPlotter;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.LinkableTextFormat;
	import weave.utils.ObjectPool;
	import weave.visualization.layers.PlotTask;
	
	/**
	 * @author adufilie
	 */
	public class TextGlyphPlotter extends AbstractGlyphPlotter implements ITextPlotter
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, TextGlyphPlotter, "Labels");
		
		public function TextGlyphPlotter()
		{
			hideOverlappingText.value = false;
			xScreenOffset.value = 0;
			yScreenOffset.value = 0;
			setColumnKeySources([sortColumn, text]);
		}
		
		private const bitmapText:BitmapText = new BitmapText();
		private const matrix:Matrix = new Matrix();

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
		public const maxWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(100));

		/**
		 * Draws the graphics onto BitmapData.
		 */
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (!(task.asyncState is Function))
			{
				// these variables are used to save state between function calls
				const textWasDrawn:Array = [];
				const reusableBoundsObjects:Array = [];
				
				task.asyncState = function():Number
				{
					var bounds:IBounds2D;
					
					if (task.iteration == 0)
					{
						// cleanup
						for each (bounds in reusableBoundsObjects)
							ObjectPool.returnObject(bounds);
						reusableBoundsObjects.length = 0; // important so we don't return the same bounds later
					}
					
					if (task.iteration < task.recordKeys.length)
					{
						var recordKey:IQualifiedKey = task.recordKeys[task.iteration] as IQualifiedKey;
						
						// project data coordinates to screen coordinates and draw graphics onto tempShape
						getCoordsFromRecordKey(recordKey, tempPoint);
						task.dataBounds.projectPointTo(tempPoint, task.screenBounds);
		
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
						f.bold = StandardLib.asBoolean(bold.getValueFromKey(recordKey, Number));
						f.italic = StandardLib.asBoolean(italic.getValueFromKey(recordKey, Number));
						f.underline = StandardLib.asBoolean(underline.getValueFromKey(recordKey, Number));
		
						var shouldRender:Boolean = true;
						
						if (hideOverlappingText.value)
						{
							// grab a bounds object to store the screen size of the bitmap text
							bounds = reusableBoundsObjects[task.iteration] = ObjectPool.borrowObject(Bounds2D);
							bitmapText.getUnrotatedBounds(bounds);
							
							// brute force check to see if this bounds overlaps with any previous bounds
							for (var j:int = 0; j < task.iteration; j++)
							{
								if (textWasDrawn[j] && bounds.overlaps(reusableBoundsObjects[j] as IBounds2D))
								{
									shouldRender = false;
									break;
								}
							}
						}
							
						textWasDrawn[task.iteration] = shouldRender;
						
						if (shouldRender)
						{
							drawInvisibleHalo(bitmapText, task);
							
							bitmapText.draw(task.buffer);
						}
						
						return task.iteration / task.recordKeys.length;
					}

					for each (bounds in reusableBoundsObjects)
						ObjectPool.returnObject(bounds);
					reusableBoundsObjects.length = 0; // important so we don't return the same bounds later
					
					return 1; // avoids divide-by-zero when there are no record keys
				}; // end task function
			} // end if
			
			return (task.asyncState as Function).apply(this, arguments);
		}

		// reusable temporary objects
		private static const tempRectangle:Rectangle = new Rectangle();
		private static const tempBounds:IBounds2D = new Bounds2D();
		private static const tempMatrix:Matrix = new Matrix();
		private static const tempPoint:Point = new Point();
		
		/**
		 * Draws an invisible background for text that will be illuminated with bitmap filters,
		 * but only if bitmapText.angle is divisible by 90 and the task is for probing.
		 */
		public static function drawInvisibleHalo(bitmapText:BitmapText, task:IPlotTask):void
		{
			if (!(task is PlotTask) || (task as PlotTask).taskType != PlotTask.TASK_TYPE_PROBE)
				return;
			
			if (!Weave.properties.enableBitmapFilters.value)
				return;
			
			if (bitmapText.angle % 90)
				return;
			
			bitmapText.getUnrotatedBounds(tempBounds);
			if (bitmapText.angle % 360)
			{
				tempMatrix.identity();
				tempMatrix.translate(-bitmapText.x, -bitmapText.y);
				tempMatrix.rotate(bitmapText.angle * Math.PI / 180);
				tempMatrix.translate(bitmapText.x, bitmapText.y);
				tempBounds.getMinPoint(tempPoint);
				tempBounds.setMinPoint(tempMatrix.transformPoint(tempPoint));
				tempBounds.getMaxPoint(tempPoint);
				tempBounds.setMaxPoint(tempMatrix.transformPoint(tempPoint));
			}
			
			tempBounds.getRectangle(tempRectangle);
			// HACK -- check a pixel to decide how to draw the rectangular halo
			tempBounds.getCenterPoint(tempPoint);
			var pixel:uint = task.buffer.getPixel(tempPoint.x, tempPoint.y);
			var haloColor:uint = 0x20000000 | Weave.properties.probeInnerGlow.color.value;
			// Check all the pixels and only set the ones that aren't set yet.
			var pixels:Vector.<uint> = task.buffer.getVector(tempRectangle);
			for (var p:int = 0; p < pixels.length; p++)
			{
				pixel = pixels[p] as uint;
				if (!pixel)
					pixels[p] = haloColor;
			}
			task.buffer.setVector(tempRectangle, pixels);
			
			//buffer.fillRect(tempRectangle, 0x02808080); // alpha 0.008, invisible
		}
	}
}

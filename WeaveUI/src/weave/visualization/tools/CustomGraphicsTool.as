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

package weave.visualization.tools
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IVisTool;
	import weave.api.ui.IVisToolWithSelectableAttributes;
	import weave.core.LinkableFunction;
	import weave.core.LinkableHashMap;
	import weave.primitives.Bounds2D;
	import weave.ui.AttributeSelectorPanel;
	import weave.ui.DraggablePanel;
	import weave.utils.ColumnUtils;
	import weave.utils.GraphicsBuffer;
	import weave.utils.PlotterUtils;
	import weave.utils.TextGraphics;
	
	public class CustomGraphicsTool extends DraggablePanel implements IVisToolWithSelectableAttributes
	{
		WeaveAPI.registerImplementation(IVisTool, CustomGraphicsTool, "ActionScript Graphics Tool");
		
		public const vars:LinkableHashMap = newLinkableChild(this,LinkableHashMap);
		public const drawScript:LinkableFunction = registerLinkableChild(this, new LinkableFunction(defaultScript, false, true));
		public const locals:Object = {}; // for use inside scripts
		
		public const dataBounds:Bounds2D = new Bounds2D();
		public const screenBounds:Bounds2D = new Bounds2D();
		public const buffer:GraphicsBuffer = new GraphicsBuffer();
		public const point:Point = new Point();
		public const bitmap:Bitmap = new Bitmap();
		public function get bitmapData():BitmapData { return bitmap.bitmapData; }
		public const textGraphics:TextGraphics = new TextGraphics();
		public const canvas:Canvas = new Canvas();
		public var keys:Array;
		
		public function getSelectableAttributes():Array
		{
			return vars.getObjects(IAttributeColumn).concat(vars.getObjects(ILinkableHashMap));
		}
		public function getSelectableAttributeNames():Array
		{
			return vars.getNames(IAttributeColumn).concat(vars.getNames(ILinkableHashMap));
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			addChild(canvas);
			canvas.percentWidth = 100;
			canvas.percentHeight = 100;
			canvas.clipContent = true;
			canvas.rawChildren.addChild(bitmap);

			enableSubMenu.value = true;
			subMenu.addSubMenuItem("Edit session state", toggleControlPanel);
			subMenu.addSubMenuItem("Select attributes", selectAttributes);
			
			vars.childListCallbacks.addImmediateCallback(this, handleVarList);
		}
		
		private function selectAttributes():void
		{
			var attrs:Array = getSelectableAttributes();
			if (attrs.length)
				AttributeSelectorPanel.openToolSelector(this, attrs[0]);
			else
				reportError("No attributes to select.");
		}
		
		private function handleVarList():void
		{
			// When a new column is created, register the stats to trigger callbacks and affect busy status.
			// This will be cleaned up automatically when the column is disposed.
			var newColumn:IAttributeColumn = vars.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newColumn)
				registerLinkableChild(vars, WeaveAPI.StatisticsCache.getColumnStatistics(newColumn));
		}
		
		// remembers previous unscaled width,height
		private const _prevSize:Point = new Point();
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			// invalidate when session state changes
			getCallbackCollection(this).addImmediateCallback(this, invalidateDisplayList);
		}
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList.apply(this,arguments);
			
			var varsChanged:Boolean = detectLinkableObjectChange(updateDisplayList, vars);
			var scriptChanged:Boolean = detectLinkableObjectChange(updateDisplayList, drawScript)
				
			// do nothing if nothing changed (script, vars, size)
			if (!scriptChanged && !varsChanged && _prevSize.x == unscaledWidth && _prevSize.y == unscaledHeight)
				return;
			
			// remember current size for next time
			_prevSize.x = unscaledWidth;
			_prevSize.y = unscaledHeight;
			
			try
			{
				// resize the BitmapData if necessary
				if (PlotterUtils.setBitmapDataSize(bitmap, unscaledWidth, unscaledHeight))
				{
					// we have a new BitmapData, so set the destinations appropriately
					// reset the buffer so we don't keep drawing on top of old graphics
					buffer.destination(bitmapData).clear();
					textGraphics.destination(bitmapData);
				}
				else
				{
					// since we are re-using the same bitmap data, clear it
					PlotterUtils.clearBitmapData(bitmap);
				}
				
				// when the vars hash map changes, get the keys from all the columns in it
				if (varsChanged)
					keys = ColumnUtils.getAllKeys(vars.getObjects(IKeySet));
				
				// run the custom script
				drawScript.apply(this);
				
				// flush the buffer so the graphics appear on the panel
				buffer.flush(bitmapData);
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		public static const defaultScript:String = <![CDATA[
			import 'flash.utils.Dictionary';
			import 'weave.api.detectLinkableObjectChange';
			import 'weave.api.data.IAttributeColumn';
			import 'weave.compiler.GlobalLib';
			import 'weave.data.AttributeColumns.DynamicColumn';
			import 'weave.data.KeySets.SortedKeySet';
			
			var getStats = WeaveAPI.StatisticsCache.getColumnStatistics;
			var getColumn = locals.getColumn || (locals.getColumn = function(name) { return vars.requestObject(name, DynamicColumn, false); });
			var formatter = locals.formatter || (locals.formatter = function(n){ return formatNumber(n, 1); });
			
			var xcol = getColumn('x'),
				ycol = getColumn('y'),
				ccol = getColumn('c'),
				xstat = getStats(xcol),
				ystat = getStats(ycol),
				db = dataBounds,
				sb = screenBounds,
				margin = 40,
				key,
				d = locals.d || (locals.d = new Dictionary(true));
			
			ccol.globalName = 'defaultColorColumn';
			
			var varsChanged = detectLinkableObjectChange(this, vars);
			if (varsChanged)
			{
				// sort keys by the first column
				var compare = SortedKeySet.generateCompareFunction([xcol]);
				StandardLib.sort(keys, compare);
			}
			
			db.setBounds(xstat.getMin(), ystat.getMin(), xstat.getMax(), ystat.getMax());
			sb.setBounds(margin, canvas.height-margin, canvas.width-margin, margin); // bottom to top
			
			buffer.lineStyle(1, 0, 0.5)
				.moveTo(sb.xMin, sb.yMax)
				.lineTo(sb.xMin, sb.yMin)
				.lineTo(sb.xMax, sb.yMin);
			
			// min,max axis labels
			textGraphics.formatter(formatter)
				.angle(0).maxWidth(margin).maxHeight(margin)
				.before(sb.xMin)
				.below(sb.yMax).drawText(db.yMax)
				.above(sb.yMin).drawText(db.yMin)
				.below(sb.yMin)
				.after(sb.xMin).drawText(db.xMin)
				.before(sb.xMax).drawText(db.xMax);
			
			// x,y axis attribute labels
			textGraphics.formatter(null)
				.color(0x000080)
				.size(12).textFormat('bold',true)
				.center(sb.xMin).above(sb.getYCenter())
				.maxWidth(sb.getYCoverage() - 50)
				.angle(-90).drawText(ycol.getMetadata('title'))
				.center(sb.getXCenter()).below(sb.yMin)
				.maxWidth(sb.getXCoverage() - 50)
				.angle(0).drawText(xcol.getMetadata('title'));
			
			// set up textGraphics before loop
			textGraphics.color(0x808080)
				.maxWidth(NaN)
				.size(10).textFormat('bold',false)
				.angle(-90).middle().after();
			
			sb.getMinPoint(point);
			for each (key in keys)
			{
				buffer.moveTo(point.x, point.y);
				
				point.x = xcol.getValueFromKey(key, Number);
				point.y = ycol.getValueFromKey(key, Number);
				color = ccol.getValueFromKey(key, Number);
				
				textGraphics.text(point); // coordinates before projecting
				
				if (isNaN(point.x))
					point.x = db.xMax;
				if (isNaN(point.y))
					point.y = db.yMax;
				
				db.projectPointTo(point, sb);
				var x = point.x, y = point.y;
				
				/*
					We're using random size values here but they
					remain stable when redrawing because they are
					cached in a Dictionary, which is saved as a
					property of the 'locals' Object.
				*/
				rand = d[key];
				if (isNaN(d[key]))
					d[key] = rand = random();
				
				// size depends on width and height of panel
				size = 1 / 100 * rand * (width * height) ** .5;
				buffer.lineTo(x, y)
					.beginFill(color)
					.drawCircle(x, y, size);
				
				textGraphics.moveTo(x, y - 5).draw();
			}
		]]>;
	}
}
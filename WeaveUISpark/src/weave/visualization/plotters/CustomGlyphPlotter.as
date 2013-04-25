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
	
	import weave.Weave;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.ui.IPlotTask;
	import weave.compiler.ProxyObject;
	import weave.core.ClassUtils;
	import weave.core.LinkableFunction;
	import weave.core.LinkableHashMap;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;

	/**
	 * @author adufilie
	 */
	public class CustomGlyphPlotter extends AbstractGlyphPlotter
	{
		public function CustomGlyphPlotter()
		{
			fillStyle.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			setColumnKeySources([dataX, dataY]);
		}
		
		/**
		 * This is the line style used to draw the outline of the rectangle.
		 */
		public const lineStyle:SolidLineStyle = registerLinkableChild(this, new SolidLineStyle());
		/**
		 * This is the fill style used to fill the rectangle.
		 */
		public const fillStyle:SolidFillStyle = registerLinkableChild(this, new SolidFillStyle());
		
		/**
		 * This can hold any objects that should be stored in the session state.
		 */
		public const vars:ILinkableHashMap = newLinkableChild(this, LinkableHashMap);
		
		private const _thisProxy:ProxyObject = new ProxyObject(hasVar, getVar, setVar);
		private function hasVar(name:String):Boolean
		{
			return this.hasOwnProperty(name) || vars.getObject(name) != null;
		}
		private function getVar(name:String):*
		{
			return this.hasOwnProperty(name) ? this[name] : vars.getObject(name);
		}
		private function setVar(name:String, value:*):void
		{
			if (this.hasOwnProperty(name))
			{
				this[name] = value;
				return;
			}
			
			if (value is String)
				value = ClassUtils.getClassDefinition(value);
			vars.requestObject(name, value, false);
		}
		
		public const function_drawPlot:LinkableFunction = registerLinkableChild(this, new LinkableFunction(script_drawPlot, false, true, ['keys','dataBounds','screenBounds','destination']));
		public static const script_drawPlot:String = <![CDATA[
			// Parameter types: Array, IBounds2D, IBounds2D, BitmapData
			function(keys, dataBounds, screenBounds, destination)
			{
				var getStats = WeaveAPI.StatisticsCache.getColumnStatistics;
				var DynamicColumn = Class('weave.data.AttributeColumns.DynamicColumn');
				var screenSize = vars.requestObject('screenSize', DynamicColumn, false);
				var sizeStats = getStats(screenSize);
				var graphicsBuffer = new 'weave.utils.GraphicsBuffer'(destination);
				var key;
				for each (key in keys)
				{
					getCoordsFromRecordKey(key, tempPoint); // uses dataX,dataY
					var size = 20 * sizeStats.getNorm(key);
					
					if (isNaN(tempPoint.x) || isNaN(tempPoint.y) || isNaN(size))
						continue;
					
					// project x,y data coordinates to screen coordinates
					dataBounds.projectPointTo(tempPoint, screenBounds);
					
					// draw graphics
					lineStyle.beginLineStyle(key, graphicsBuffer.graphics());
					fillStyle.beginFillStyle(key, graphicsBuffer.graphics());
					
					graphicsBuffer.drawCircle(tempPoint.x, tempPoint.y, size)
						.endFill();
				}
				graphicsBuffer.flush();
			}
		]]>;
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			try
			{
				// BIG HACK to work properly as a symbolPlotter in GeometryPlotter
				if (task.iteration <= task.recordKeys.length)
					return 0;
				
				function_drawPlot.call(_thisProxy, task.recordKeys, task.dataBounds, task.screenBounds, task.buffer);
			}
			catch (e:*)
			{
				reportError(e);
			}
			return 1;
		}
		
		public const function_drawBackground:LinkableFunction = registerLinkableChild(this, new LinkableFunction(script_drawBackground, false, true, ['dataBounds', 'screenBounds', 'destination']));
		public static const script_drawBackground:String = <![CDATA[
			// Parameter types: IBounds2D, IBounds2D, BitmapData
			function(dataBounds, screenBounds, destination)
			{
				/*
				var graphicBuffer = new 'weave.utils.GraphicsBuffer'(destination);
			
				// draw background graphics here
			
				graphicsBuffer.flush();
				*/
			}
		]]>;
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			try
			{
				function_drawBackground.apply(_thisProxy, arguments);
			}
			catch (e:*)
			{
				reportError(e);
			}
		}
		
		public const function_getDataBoundsFromRecordKey:LinkableFunction = registerSpatialProperty(new LinkableFunction(script_getDataBoundsFromRecordKey, false, true, ['key', 'output']));
		public static const script_getDataBoundsFromRecordKey:String = <![CDATA[
			// Parameter types: IQualifiedKey, Array
			function(key, output)
			{
				getCoordsFromRecordKey(key, tempPoint); // uses dataX,dataY
				
				var bounds = initBoundsArray(output);
				bounds.includePoint(tempPoint);
				if (isNaN(tempPoint.x))
					bounds.setXRange(-Infinity, Infinity);
				if (isNaN(tempPoint.y))
					bounds.setYRange(-Infinity, Infinity);
			}
		]]>;
		override public function getDataBoundsFromRecordKey(key:IQualifiedKey, output:Array):void
		{
			try
			{
				function_getDataBoundsFromRecordKey.apply(_thisProxy, arguments);
			}
			catch (e:*)
			{
				reportError(e);
			}
		}
		
		public const function_getBackgroundDataBounds:LinkableFunction = registerSpatialProperty(new LinkableFunction(script_getBackgroundDataBounds, false, true, ['output']));
		public static const script_getBackgroundDataBounds:String = <![CDATA[
			// Parameter type: IBounds2D
			function (output)
			{
				if (zoomToSubset.value)
				{
					output.reset();
				}
				else
				{
					var getStats = WeaveAPI.StatisticsCache.getColumnStatistics;
					var statsX = getStats(dataX);
					var statsY = getStats(dataY);
			
					output.setBounds(
						statsX.getMin(),
						statsY.getMin(),
						statsX.getMax(),
						statsY.getMax()
					);
				}
			}
		]]>;
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			try
			{
				function_getBackgroundDataBounds.apply(_thisProxy, arguments);
			}
			catch (e:*)
			{
				reportError(e);
			}
		}
	}
}

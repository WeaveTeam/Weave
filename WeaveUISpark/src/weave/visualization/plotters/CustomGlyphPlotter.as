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
		
		public const function_drawPlotAsyncIteration:LinkableFunction = registerLinkableChild(this, new LinkableFunction(null, false, true, ['task']));
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			try
			{
				return function_drawPlotAsyncIteration.apply(_thisProxy, arguments);
			}
			catch (e:*)
			{
				reportError(e);
			}
			return 1;
		}
		
		public const function_drawBackground:LinkableFunction = registerLinkableChild(this, new LinkableFunction(null, false, true, ['dataBounds', 'screenBounds', 'destination']));
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
		
		public const function_getDataBoundsFromRecordKey:LinkableFunction = registerSpatialProperty(new LinkableFunction(null, false, true, ['key', 'output']));
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
		
		public const function_getBackgroundDataBounds:LinkableFunction = registerSpatialProperty(new LinkableFunction(null, false, true, ['output']));
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

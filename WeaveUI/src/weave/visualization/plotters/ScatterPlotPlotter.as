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
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.utils.ColumnUtils;
	import weave.visualization.plotters.styles.SolidFillStyle;
	
	/**
	 * ScatterPlotPlotter
	 * 
	 * @author adufilie
	 */
	public class ScatterPlotPlotter extends AbstractSimplifiedPlotter
	{
		public function ScatterPlotPlotter()
		{
			super(CircleGlyphPlotter);
			//circlePlotter.fillStyle.lock();
			setKeySource(_keySet);
			getCallbackCollection(this).addImmediateCallback(this, updateKeys);
			for each (var spatialProperty:ILinkableObject in [xColumn, yColumn, zoomToSubset])
				registerSpatialProperty(spatialProperty);
			for each (var child:ILinkableObject in [colorColumn, radiusColumn, minScreenRadius, maxScreenRadius, defaultScreenRadius, alphaColumn, enabledSizeBy])
				registerLinkableChild(this, child);
		}
		
		private var _keySet:KeySet = newDisposableChild(this,KeySet);
		
		public function setCustomKeySource(keys:Array):void
		{			
			getCallbackCollection(this).removeCallback(updateKeys);
			_keySet.replaceKeys(keys);
			setKeySource(_keySet);
			
		}		

		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (sortKeys == null)
				sortKeys = ColumnUtils.generateSortFunction([radiusColumn, colorColumn, xColumn, yColumn], [true, false, false, false]);
			recordKeys.sort(sortKeys);
			
			super.drawPlot(recordKeys, dataBounds, screenBounds, destination);
		}
		
		/**
		 * This function sorts record keys based on their radiusColumn values, then by their colorColumn values
		 * @param key1 First record key (a)
		 * @param key2 Second record key (b)
		 * @return Sort value: 0: (a == b), -1: (a < b), 1: (a > b)
		 */			
		private var sortKeys:Function = null;
		
		// the private plotter being simplified
		public function get circlePlotter():CircleGlyphPlotter { return internalPlotter as CircleGlyphPlotter; }
		
		public function get defaultScreenRadius():LinkableNumber {return circlePlotter.defaultScreenRadius;}
		public function get enabledSizeBy():LinkableBoolean {return circlePlotter.enabledSizeBy; }
		public function get minScreenRadius():LinkableNumber { return circlePlotter.minScreenRadius; }
		public function get maxScreenRadius():LinkableNumber { return circlePlotter.maxScreenRadius; }
		public function get xColumn():DynamicColumn { return circlePlotter.dataX; }
		public function get yColumn():DynamicColumn { return circlePlotter.dataY; }
		public function get alphaColumn():AlwaysDefinedColumn { return (circlePlotter.fillStyle.internalObject as SolidFillStyle).alpha; }
		public function get colorColumn():AlwaysDefinedColumn { return (circlePlotter.fillStyle.internalObject as SolidFillStyle).color; }
		public function get radiusColumn():DynamicColumn { return circlePlotter.screenRadius; }
		public function get zoomToSubset():LinkableBoolean { return circlePlotter.zoomToSubset; }
		
		private function getAllKeys(...inputKeySets):Array
		{
			var lookup:Dictionary = new Dictionary(true);
			var result:Array = [];
			for (var i:int = 0; i < inputKeySets.length; i++)
			{
				var keys:Array = (inputKeySets[i] as IKeySet).keys;
				for (var j:int = 0; j < keys.length; j++)
				{
					var key:IQualifiedKey = keys[j] as IQualifiedKey;
					if (lookup[key] === undefined)
					{
						lookup[key] = true;
						result.push(key);
					}
				}
			}
			return result;
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var x:Number = xColumn.getValueFromKey(recordKey, Number);
			var y:Number = yColumn.getValueFromKey(recordKey, Number);
			
			var bounds:IBounds2D = getReusableBounds();
			bounds.setCenteredRectangle(isNaN(x) ? 0 : x, isNaN(y) ? 0 : y, isNaN(x) ? Infinity:0, isNaN(y) ? Infinity : 0);
			return [bounds];
		}
				
		private function updateKeys():void
		{
			_keySet.replaceKeys(getAllKeys(xColumn, yColumn, radiusColumn, colorColumn));
		}
	}
}


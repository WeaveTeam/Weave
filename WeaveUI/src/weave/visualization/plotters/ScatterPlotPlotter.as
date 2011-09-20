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
	
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
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
			registerSpatialProperties(xColumn, yColumn, zoomToSubset);
			registerNonSpatialProperties(colorColumn, radiusColumn, minScreenRadius, maxScreenRadius, defaultScreenRadius, alphaColumn, enabledSizeBy);
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
			// sort by size, then color
			recordKeys.sort(sortKeys, Array.DESCENDING);
			super.drawPlot(recordKeys, dataBounds, screenBounds, destination );
		}
		
		/**
		 * This function sorts record keys based on their radiusColumn values, then by their colorColumn values
		 * @param key1 First record key (a)
		 * @param key2 Second record key (b)
		 * @return Sort value: 0: (a == b), -1: (a < b), 1: (a > b)
		 * 
		 */			
		private function sortKeys(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			// compare size
			var a:Number = radiusColumn.getValueFromKey(key1, Number);
			var b:Number = radiusColumn.getValueFromKey(key2, Number);
			// sort descending (high radius values and missing radius values drawn first)
			if(isNaN(a)) return -1;
			if(isNaN(b)) return 1;
			if( a < b )
				return -1;
			else if( a > b )
				return 1;
			
			// size equal.. compare color
			a = colorColumn.getValueFromKey(key1, Number);
			b = colorColumn.getValueFromKey(key2, Number);
			// sort ascending (high values drawn last)
			if( a < b ) return 1; 
			else if( a > b ) return -1 ;
			else return 0 ;
		}
		// the private plotter being simplified
		public function get defaultScreenRadius():LinkableNumber {return circlePlotter.defaultScreenRadius;}
		private function get circlePlotter():CircleGlyphPlotter { return internalPlotter as CircleGlyphPlotter; }
		public function get enabledSizeBy():LinkableBoolean {return circlePlotter.enabledSizeBy; }
		public function get minScreenRadius():LinkableNumber { return circlePlotter.minScreenRadius; }
		public function get maxScreenRadius():LinkableNumber { return circlePlotter.maxScreenRadius; }
		public function get xColumn():DynamicColumn { return circlePlotter.dataX; }
		public function get yColumn():DynamicColumn { return circlePlotter.dataY; }
		public function get alphaColumn():AlwaysDefinedColumn { return (circlePlotter.fillStyle.internalObject as SolidFillStyle).alpha; }
		public function get colorColumn():AlwaysDefinedColumn { return (circlePlotter.fillStyle.internalObject as SolidFillStyle).color; }
		public function get radiusColumn():DynamicColumn { return circlePlotter.screenRadius; }
		public function get zoomToSubset():LinkableBoolean { return circlePlotter.zoomToSubset; }
		
		private function getAllKeys(outputKeySet:KeySet, inputKeySets:Array):void
		{
			outputKeySet.delayCallbacks();
			if (inputKeySets.length > 0)
				outputKeySet.replaceKeys((inputKeySets[0] as IKeySet).keys);
			else
				outputKeySet.clearKeys();
			for (var i:int = 1; i < inputKeySets.length; i++)
			{
				outputKeySet.addKeys((inputKeySets[i] as IKeySet).keys);
			}
			outputKeySet.resumeCallbacks();			
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
			getAllKeys(_keySet,[xColumn,yColumn,radiusColumn,colorColumn]);
		}
	}
}


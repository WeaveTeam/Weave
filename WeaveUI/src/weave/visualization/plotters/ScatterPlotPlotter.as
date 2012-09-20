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
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotterWithKeyCompare;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.KeySetUnion;
	import weave.utils.ColumnUtils;
	
	/**
	 * @author adufilie
	 */
	public class ScatterPlotPlotter extends AbstractSimplifiedPlotter implements IPlotterWithKeyCompare
	{
		public function ScatterPlotPlotter()
		{
			super(CircleGlyphPlotter);
			//circlePlotter.fillStyle.lock();
			for each (var spatialProperty:ILinkableObject in [xColumn, yColumn, zoomToSubset])
				registerSpatialProperty(spatialProperty);
			for each (var child:ILinkableObject in [colorColumn, radiusColumn, minScreenRadius, maxScreenRadius, defaultScreenRadius, alphaColumn, enabledSizeBy])
				registerLinkableChild(this, child);
				
			_keySetUnion.addKeySetDependency(xColumn);
			_keySetUnion.addKeySetDependency(yColumn);
			_keySetUnion.addKeySetDependency(radiusColumn);
			_keySetUnion.addKeySetDependency(colorColumn);
			setKeySource(_keySetUnion);
			
//			function debugKeySets():void {
//				debugTrace(_keySetUnion,getKeyLocalNames(_keySetUnion.keys));
//				debugTrace(keySet,getKeyLocalNames(keySet.keys));
//				trace();
//			}
//			getCallbackCollection(_keySetUnion).addImmediateCallback(this, debugKeySets);
//			getCallbackCollection(keySet).addImmediateCallback(this, debugKeySets);
			
			_keyCompare = ColumnUtils.generateCompareFunction([radiusColumn, colorColumn, xColumn, yColumn], [true, false, false, false]);
		}
		
		private function getKeyLocalNames(keys:Array):String
		{
			keys = keys.concat();
			for (var i:int = 0; i < keys.length; i++)
				keys[i] = keys[i].localName;
			return keys.toString();
		}
		
		private var _keySetUnion:KeySetUnion = registerDisposableChild(this, new KeySetUnion(keyInclusionLogic));
		
		public var hack_keyInclusionLogic:Function = null;
		private function keyInclusionLogic(key:IQualifiedKey):Boolean
		{
			return hack_keyInclusionLogic == null ? true : hack_keyInclusionLogic(key);
		}
		
		public var hack_horizontalBackgroundLineStyle:Array;
		public var hack_verticalBackgroundLineStyle:Array;
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			if (!keySet.keys.length)
				return;
			if (hack_horizontalBackgroundLineStyle)
			{
				tempShape.graphics.clear();
				tempShape.graphics.lineStyle.apply(null, hack_horizontalBackgroundLineStyle);
				tempShape.graphics.moveTo(screenBounds.getXMin(), screenBounds.getYCenter());
				tempShape.graphics.lineTo(screenBounds.getXMax(), screenBounds.getYCenter());
			}
			if (hack_verticalBackgroundLineStyle)
			{
				tempShape.graphics.clear();
				tempShape.graphics.lineStyle.apply(null, hack_verticalBackgroundLineStyle);
				tempShape.graphics.moveTo(screenBounds.getXCenter(), screenBounds.getYMin());
				tempShape.graphics.lineTo(screenBounds.getXCenter(), screenBounds.getYMax());
			}
			destination.draw(tempShape);
		}
		
		private var _keyCompare:Function;
		/**
		 * This function compares record keys based on their radiusColumn values, then by their colorColumn values
		 * @param key1 First record key (a)
		 * @param key2 Second record key (b)
		 * @return Compare value: 0: (a == b), -1: (a < b), 1: (a > b)
		 */
		public function keyCompare(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			return _keyCompare(key1, key2);
		}
		
		/**
		 * @TODO This is not supposed to be public. Replace ScatterPlotPlotter with CircleGlyphPlotter and add the necessary backwards compatibility code.
		 */		
		public function get circlePlotter():CircleGlyphPlotter { return internalPlotter as CircleGlyphPlotter; }
		
		// the private plotter being simplified
		private function get _internalCirclePlotter():CircleGlyphPlotter { return internalPlotter as CircleGlyphPlotter; }
		
		public function get defaultScreenRadius():LinkableNumber {return _internalCirclePlotter.defaultScreenRadius;}
		public function get enabledSizeBy():LinkableBoolean {return _internalCirclePlotter.enabledSizeBy; }
		public function get minScreenRadius():LinkableNumber { return _internalCirclePlotter.minScreenRadius; }
		public function get maxScreenRadius():LinkableNumber { return _internalCirclePlotter.maxScreenRadius; }
		public function get xColumn():DynamicColumn { return _internalCirclePlotter.dataX; }
		public function get yColumn():DynamicColumn { return _internalCirclePlotter.dataY; }
		public function get alphaColumn():AlwaysDefinedColumn { return _internalCirclePlotter.fill.alpha; }
		public function get colorColumn():AlwaysDefinedColumn { return _internalCirclePlotter.fill.color; }
		public function get radiusColumn():DynamicColumn { return _internalCirclePlotter.screenRadius; }
		public function get zoomToSubset():LinkableBoolean { return _internalCirclePlotter.zoomToSubset; }
	}
}


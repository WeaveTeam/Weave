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

package weave.visualization.layers
{
	import flash.display.Bitmap;
	import flash.display.PixelSnapping;
	import flash.events.Event;
	
	import mx.core.UIComponent;
	import mx.utils.NameUtil;
	
	import weave.Weave;
	import weave.api.core.IDisposableObject;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObjects;
	import weave.api.getCallbackCollection;
	import weave.api.linkBindableProperty;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotLayer;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISpatialIndex;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.SessionManager;
	import weave.core.StageUtils;
	import weave.data.KeySets.FilteredKeySet;
	import weave.primitives.Bounds2D;
	import weave.utils.DebugUtils;
	import weave.utils.PlotterUtils;
	import weave.utils.SpatialIndex;
	import weave.utils.ZoomUtils;
	import weave.visualization.plotters.DynamicPlotter;
	
	/**
	 * A PlotLayer is a UIComponent that has a Bitmap child.
	 * The Bitmap child contains the graphics of an IPlotter.
	 * 
	 * @author adufilie
	 */
	public class PlotLayer extends UIComponent implements IPlotLayer, IDisposableObject
	{
		public function PlotLayer(externalPlotter:DynamicPlotter = null, externalSpatialIndex:SpatialIndex = null)
		{
			super();
			if (externalPlotter && externalSpatialIndex)
			{
				_dynamicPlotter = registerLinkableChild(this, externalPlotter);
				_spatialIndex = externalSpatialIndex;
				usingExternalSpatialIndex = true;
			}
			else
			{
				_dynamicPlotter = newLinkableChild(this, DynamicPlotter);
				_spatialIndex = newLinkableChild(this, SpatialIndex);
				usingExternalSpatialIndex = false;
				_dynamicPlotter.spatialCallbacks.addImmediateCallback(this, _spatialIndex.clear);
			}
			// default size = 100%,100%
			percentWidth = 100;
			percentHeight = 100;
			
			this.addChild(_plotBitmap);
			
			// make selectionFilter appear in session state.
			registerLinkableChild(this, selectionFilter);
			
			//_filteredKeys.keyFilter.globalName = Weave.DEFAULT_SUBSET_KEYFILTER;
			_dynamicPlotter.keySet.keyFilter.globalName = Weave.DEFAULT_SUBSET_KEYFILTER;
			
			_filteredKeys.setBaseKeySet(_dynamicPlotter.keySet);
			
			linkBindableProperty(layerIsVisible, this, 'visible');
			
			getCallbackCollection(this).addImmediateCallback(this, invalidateDisplayList);
		}
		
		/**
		 * This is called by SessionManager.dispose().
		 */
		public function dispose():void
		{
			// clean up everything that does not get cleaned up automatically.
			disposeObjects(
				_plotBitmap.bitmapData
			);
			if (!usingExternalSpatialIndex)
				disposeObjects(spatialIndex);
		}
		
		private var usingExternalSpatialIndex:Boolean;
		private var _dynamicPlotter:DynamicPlotter = null;
		private var _spatialIndex:SpatialIndex = null;
		private var _spatialIndexDirty:Boolean = true;
		
		
		/**
		 * The IPlotter object used to draw shapes on this PlotLayer.
		 */
		public function getDynamicPlotter():DynamicPlotter { return _dynamicPlotter; }
		
		/**
		 * IPlotLayer interface
		 */
		
		public function get plotter():IPlotter { return _dynamicPlotter; }
		
		/**
		 * This key set allows you to filter the records before they are used to calculate the graphics.
		 */  
		public function get subsetFilter():IDynamicKeyFilter { return plotter.keySet.keyFilter; }
		
		public function getDataBounds(destination:IBounds2D):void
		{
			destination.copyFrom(_dataBounds);
		}
		public function getScreenBounds(destination:IBounds2D):void
		{
			destination.copyFrom(_screenBounds);
		}
		
		public function setDataBounds(source:IBounds2D):void
		{
			if (!_dataBounds.equals(source))
			{
				_dataBounds.copyFrom(source);
				invalidateDisplayList();
			}
		}
		public function setScreenBounds(source:IBounds2D):void
		{
			if (!_screenBounds.equals(source))
			{
				_screenBounds.copyFrom(source);
				invalidateDisplayList();
			}
		}
		
		// end IPlotter interface
		
		private const _dataBounds:IBounds2D = new Bounds2D(); // this is set by the public setDataBounds() interface
		private const _screenBounds:IBounds2D = new Bounds2D(); // this is set by the public setScreenBounds() interface
		
		/**
		 * When this is true, the plot won't be drawn if there is no selection and the background will never be drawn.
		 * This variable says whether or not this is an overlay on top of another layer with the same plotter.
		 */
		public const isOverlay:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		// This is the key set of the plotter with a filter applied to it.
		private const _filteredKeys:FilteredKeySet = newDisposableChild(this, FilteredKeySet);
		
		/**
		 * Sets the visibility of the layer
		 */
		public const layerIsVisible:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * Sets the minimum scale at which the layer should be rendered. Scale is defined by pixels per data unit.
		 */
		public const minVisibleScale:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0, verifyVisibleScaleValue));
		
		/**
		 * Sets the maximum scale at which the layer should be rendered. Scale is defined by pixels per data unit.
		 */
		public const maxVisibleScale:LinkableNumber = registerLinkableChild(this, new LinkableNumber(Infinity, verifyVisibleScaleValue));
		
		/**
		 * @private
		 */		
		private function verifyVisibleScaleValue(value:Number):Boolean
		{
			return value >= 0;
		}
		
		/**
		 * This returns true if the layer should be rendered and selectable/probeable
		 * @return true if the layer should be rendered and selectable/probeable
		 */		
		public function shouldBeRendered():Boolean
		{
			if (!layerIsVisible.value)
				return false;
			
			// 
			if (_dataBounds.isUndefined())
				return true;
			
			var min:Number = minVisibleScale.value;
			var max:Number = maxVisibleScale.value;
			var xScale:Number = _screenBounds.getXCoverage() / _dataBounds.getXCoverage();
			var yScale:Number = _screenBounds.getYCoverage() / _dataBounds.getYCoverage();
			return min <= xScale && xScale <= max
				&& min <= yScale && yScale <= max;
		}
		
		/**
		 * This will be used to filter the graphics that are drawn, but not the records that were used to calculate the graphics.
		 */
		public function get selectionFilter():IDynamicKeyFilter { return _filteredKeys.keyFilter; }
		
		/**
		 * This is used to index the keys in the plotter by dataBounds.
		 */
		public function get spatialIndex():ISpatialIndex { return _spatialIndex; }
		public var showMissingRecords:Boolean = false;
		
		// these bitmaps will be added as a children
		private const _plotBitmap:Bitmap = new Bitmap(null, PixelSnapping.ALWAYS, false);
		
		/**
		 * @private
		 */		
		internal function validateSpatialIndex():void
		{
			// spatial index becomes invalid when spatial callbacks are triggered
			if (detectLinkableObjectChange(validateSpatialIndex, _dynamicPlotter.spatialCallbacks))
				_spatialIndex.createIndex(plotter, showMissingRecords);
		}
		public function getSelectedKeys():Array
		{
			//validate spatial index if necessary
			validateSpatialIndex();
			
			var keys:Array;
			
			// if a global filter is referenced and the keyType matches, use the keys from the global filter
			// otherwise, use the keys from the plotter
			
			//selectionFilter.keyType == plotter.keySet.keyType && 
			if (selectionFilter.internalObject != null)
			{
				keys = [];
				var selectedKeys:Array = _filteredKeys.keys;
				for (var i:int = 0; i < selectedKeys.length; i++)
				{
					var key:IQualifiedKey = selectedKeys[i] as IQualifiedKey;
					for each (var keyBounds:IBounds2D in _spatialIndex.getBoundsFromKey(key))
					{
						if (keyBounds.overlaps(_dataBounds))
						{
							if(!keyBounds.isUndefined() || showMissingRecords)
								keys.push(key);
							break;
						}
					}
				}
			}
			else if (isOverlay.value)
			{
				keys = null;
			}
			else
			{
				keys = _spatialIndex.getKeysBoundingBoxOverlap(_dataBounds); // all keys within visible data bounds
				//keys = plotter.keySet.keys;
			}
			
			return keys;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//trace("updateDisplayList",arguments);
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			// resize bitmap if necessary, and clear graphics
			PlotterUtils.setBitmapDataSize(_plotBitmap, unscaledWidth, unscaledHeight);
			
			//trace(name,'begin updateDisplayList', _dataBounds);
			var shouldDraw:Boolean = (unscaledWidth * unscaledHeight > 0) && shouldBeRendered();
			//validate spatial index if necessary
			if (shouldDraw)
				validateSpatialIndex();
			
			// draw plot
			if (!PlotterUtils.bitmapDataIsEmpty(_plotBitmap))
			{
				// get keys for plot, then draw the records
				if (shouldDraw)
				{
					if (!isOverlay.value)
						plotter.drawBackground(_dataBounds, _screenBounds, _plotBitmap.bitmapData);
					
					var keys:Array = getSelectedKeys() || []; // use empty Array if keys are null
					plotter.drawPlot(keys, _dataBounds, _screenBounds, _plotBitmap.bitmapData);
				}
			}
			//trace(name,'end updateDisplayList', _dataBounds);
		}
	}
}

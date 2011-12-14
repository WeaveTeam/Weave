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
			
			this.addChild(backgroundBitmap);
			this.addChild(plotBitmap);
			
			// make selectionFilter appear in session state.
			registerLinkableChild(this, selectionFilter);

			//_filteredKeys.keyFilter.globalName = Weave.DEFAULT_SUBSET_KEYFILTER;
			_dynamicPlotter.keySet.keyFilter.globalName = Weave.DEFAULT_SUBSET_KEYFILTER;
			
			_filteredKeys.setBaseKeySet(_dynamicPlotter.keySet);
			isOverlay.value = false;
			
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
				backgroundBitmap.bitmapData,
				plotBitmap.bitmapData
			);
			if (!usingExternalSpatialIndex)
				disposeObjects(spatialIndex);
		}
		
		private var usingExternalSpatialIndex:Boolean;
		private var _dynamicPlotter:DynamicPlotter = null;
		private var _spatialIndex:SpatialIndex = null;
		private var _spatialIndexDirty:Boolean = true;
		
		
		/**
		 * Sets the minimum visible zoom level for the layer
		 */
		public const minVisibleZoomLevel:LinkableNumber = registerLinkableChild(this, new LinkableNumber(-5));
		
		/**
		 * Sets the maximum visible zoom level for the layer
		 */
		public const maxVisibleZoomLevel:LinkableNumber = registerLinkableChild(this, new LinkableNumber(20));
		
		/**
		 * A flag which is true when the zoom level of the PlotLayerContainer containing
		 * this SelectablePlotLayer is between minVisibleZoomLevel and maxVisibleZoomLevel.
		 * Set by PlotLayerContainer.updateZoom().
		 */
		public var withinVisibleZoomLevels:Boolean = true;
		
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
		
//		public function getZoomLevel():Number
//		{
//			return ZoomUtils.getZoomLevel(_dataBounds, _screenBounds, _fullDataBounds, _minScreenSize);
//		}
		
		// end IPlotter interface

		private const _dataBounds:IBounds2D = new Bounds2D(); // this is set by the public setDataBounds() interface
		private const _screenBounds:IBounds2D = new Bounds2D(); // this is set by the public setScreenBounds() interface
//		internal const _fullDataBounds:IBounds2D = new Bounds2D(); // this is set by other classes
//		internal var _minScreenSize:int = 128; // this is set by other classes

		/**
		 * When this is true, the plot won't be drawn if there is no selection and the background will never be drawn.
		 * This variable says whether or not this is an overlay on top of another layer with the same plotter.
		 */
		public const isOverlay:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
		
		// This is the key set of the plotter with a filter applied to it.
		private const _filteredKeys:FilteredKeySet = newDisposableChild(this, FilteredKeySet);

		/**
		 * Sets the visibility of the layer
		 */
		public const layerIsVisible:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));

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
 		protected const backgroundBitmap:Bitmap = new Bitmap(null, PixelSnapping.AUTO, true);
		protected const plotBitmap:Bitmap = new Bitmap(null, PixelSnapping.AUTO, true);

		public function getPlotBitmap():Bitmap { return plotBitmap; }
		public function getBackgroundBitmap():Bitmap { return backgroundBitmap; }
		
		// access the filters of the background layer only
		public function get backgroundFilters():Array 			 { return backgroundBitmap.filters;  }
		public function set backgroundFilters(value:Array):void  { backgroundBitmap.filters = value; }
		
		// access the filters of the plot layer only
		public function get plotFilters():Array      			 { return plotBitmap.filters;        }
		
		// value can be null for no style
		// Array is of type BitmapFilter
		public function set plotFilters(value:Array):void        { plotBitmap.filters = value;       }

		public function validateSpatialIndex():void
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
		 * This function gets called when the unscaled width or height changes.
		 * This function will resize the BitmapData to the new unscaled width and height.
		 */
		private function handleSizeChange():void
		{
			//trace("sizeChanged",unscaledWidth,unscaledHeight);
			
			var bitmapChanged:Boolean = PlotterUtils.setBitmapDataSize(plotBitmap, unscaledWidth, unscaledHeight);
			if (bitmapChanged)
				invalidateDisplayList();
			
			if (!isOverlay.value)
			{
				var bgChanged:Boolean = PlotterUtils.setBitmapDataSize(backgroundBitmap, unscaledWidth, unscaledHeight);
				if (bgChanged)
					invalidateDisplayList();
			}
			else if (backgroundBitmap.bitmapData != null)
			{
				backgroundBitmap.bitmapData.dispose();
				backgroundBitmap.bitmapData = null;
			}
		}

		// these variables are used to detect a change in size
		private var _prevUnscaledWidth:Number = NaN;
		private var _prevUnscaledHeight:Number = NaN;

		/**
		 * @inheritDoc
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//trace("updateDisplayList",arguments);
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			// do nothing if not visible
			if (!layerIsVisible.value)
				return;

			// detect size change
			var sizeChanged:Boolean = _prevUnscaledWidth != unscaledWidth || _prevUnscaledHeight != unscaledHeight;
			_prevUnscaledWidth = unscaledWidth;
			_prevUnscaledHeight = unscaledHeight;
			if (sizeChanged)
				handleSizeChange();

			//trace(name,'begin updateDisplayList', _dataBounds);
			var shouldDraw:Boolean = (unscaledWidth * unscaledHeight > 0) && withinVisibleZoomLevels;
			//validate spatial index if necessary
			if (shouldDraw)
				validateSpatialIndex();
			
			// draw background if this is not an overlay
			if (!isOverlay.value && !PlotterUtils.bitmapDataIsEmpty(backgroundBitmap))
			{
				PlotterUtils.clear(backgroundBitmap.bitmapData);
				if (shouldDraw)
				{
					plotter.drawBackground(_dataBounds, _screenBounds, backgroundBitmap.bitmapData);
				}
			}
			
			// draw plot
			if (!PlotterUtils.bitmapDataIsEmpty(plotBitmap))
			{
				PlotterUtils.clear(plotBitmap.bitmapData);
				// get keys for plot, then draw the records
				
				if (shouldDraw)
				{
					var keys:Array = getSelectedKeys() || []; // use empty Array if keys are null
					plotter.drawPlot(keys, _dataBounds, _screenBounds, plotBitmap.bitmapData);
				}
			}
			//trace(name,'end updateDisplayList', _dataBounds);
		}
	}
}

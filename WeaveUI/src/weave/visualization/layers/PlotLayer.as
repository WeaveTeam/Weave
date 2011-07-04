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
	
	import mx.core.UIComponent;
	import mx.utils.NameUtil;
	
	import weave.api.core.IDisposableObject;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObjects;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotLayer;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISpatialIndex;
	import weave.core.LinkableBoolean;
	import weave.data.KeySets.FilteredKeySet;
	import weave.primitives.Bounds2D;
	import weave.utils.DebugUtils;
	import weave.utils.PlotterUtils;
	import weave.utils.SpatialIndex;
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
				_dynamicPlotter = registerLinkableChild(this, externalPlotter, invalidateGraphics);
				_spatialIndex = externalSpatialIndex;
				usingExternalSpatialIndex = true;
			}
			else
			{
				_dynamicPlotter = newLinkableChild(this, DynamicPlotter, invalidateGraphics);
				_spatialIndex = new SpatialIndex();
				usingExternalSpatialIndex = false;
			}
			init();
		}
		
		/**
		 * This function gets called by the constructor.
		 * This code is in its own function because constructors do not get compiled.
		 */
		private function init():void
		{
			// generate a name for debugging
			name = NameUtil.createUniqueName(this);
			// default size = 100%,100%
			percentWidth = 100;
			percentHeight = 100;
			
			this.addChild(backgroundBitmap);
			this.addChild(plotBitmap);
			
			// make selectionFilter appear in session state.
			registerLinkableChild(this, selectionFilter);

			if (!usingExternalSpatialIndex)
				_dynamicPlotter.spatialCallbacks.addImmediateCallback(this, spatialCallback);
			
			//_filteredKeys.keyFilter.globalName = Weave.DEFAULT_SUBSET_KEYFILTER;
			
			_filteredKeys.setBaseKeySet(_dynamicPlotter.keySet);
			isOverlay.value = false;
			
			layerIsVisible.value = true;

			_filteredKeys.addImmediateCallback(this, invalidateGraphics);
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
				invalidateGraphics();
			}
		}
		public function setScreenBounds(source:IBounds2D):void
		{
			if (!_screenBounds.equals(source))
			{
				_screenBounds.copyFrom(source);
				invalidateGraphics();
			}
		}
		
		// end IPlotter interface

		private const _dataBounds:IBounds2D = new Bounds2D(); // this is set by the public setDataBounds() interface
		private const _screenBounds:IBounds2D = new Bounds2D(); // this is set by the public setScreenBounds() interface

		/**
		 * When this is true, the plot won't be drawn if there is no selection and the background will never be drawn.
		 * This variable says whether or not this is an overlay on top of another layer with the same plotter.
		 */
		public const isOverlay:LinkableBoolean = newLinkableChild(this, LinkableBoolean, invalidateGraphics);
		
		// This is the key set of the plotter with a filter applied to it.
		private const _filteredKeys:FilteredKeySet = newDisposableChild(this, FilteredKeySet);
		
		/**
		 * This will be used to filter the graphics that are drawn, but not the records that were used to calculate the graphics.
		 */
		public function get selectionFilter():IDynamicKeyFilter { return _filteredKeys.keyFilter; }

		/**
		 * This is used to index the keys in the plotter by dataBounds.
		 */
		public function get spatialIndex():ISpatialIndex { return _spatialIndex; }

		// these bitmaps will be added as a children
 		protected const backgroundBitmap:Bitmap = new Bitmap(null, PixelSnapping.AUTO, true);
		protected const plotBitmap:Bitmap = new Bitmap(null, PixelSnapping.AUTO, true);

		// access the filters of the background layer only
		public function get backgroundFilters():Array 			 { return backgroundBitmap.filters;  }
		public function set backgroundFilters(value:Array):void  { backgroundBitmap.filters = value; }
		
		// access the filters of the plot layer only
		public function get plotFilters():Array      			 { return plotBitmap.filters;        }
		
		// value can be null for no style
		// Array is of type BitmapFilter
		public function set plotFilters(value:Array):void        { plotBitmap.filters = value;       }

		/**
		 * This function should be used instead of validateGraphics(), which should never be called directly.
		 * This will invalidate the graphics and cause validateGraphics() to be called at the appropriate time.
		 */
		public function invalidateGraphics():void
		{
			//trace("invalidateGraphics");
			_graphicsAreValid = false;
			invalidateDisplayList();
		}
		
		private function spatialCallback():void
		{
			_spatialIndex.clear();
		}

		/**
		 *Sets the visibility of the layer 
		 * 
		*/
		public const layerIsVisible:LinkableBoolean = newLinkableChild(this, LinkableBoolean, toggleLayer);
		private function toggleLayer():void
		{
			this.visible = layerIsVisible.value;
			invalidateGraphics();
		}
		private var _graphicsAreValid:Boolean = false; // used as a flag to remember if the graphics need to be updated

		/**
		 * @return true if the graphics are valid.
		 */
		public function get graphicsAreValid():Boolean
		{
			return _graphicsAreValid;
		}

		public function getSelectedKeys():Array
		{
			//validate spatial index if necessary
			if (_spatialIndex.recordCount == 0)
			{
				//trace(this,"updating spatial index", CallbackCollection.getStackTrace());
				_spatialIndex.createIndex(plotter);
				//trace(this,"updated spatial index",spatialIndex.collectiveBounds);
			}

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
				keys = _spatialIndex.getKeysOverlappingBounds(_dataBounds, 0);
				//keys = plotter.keySet.keys;
			}
			
			return keys;
		}

		/**
		 * This function should be defined with override by classes that extend AbstractVisLayer.
		 * This function should never be called directly except by the protected updateDisplayList() function defined here.
		 */
		protected function validateGraphics(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var shouldDraw:Boolean = (unscaledWidth * unscaledHeight > 0);
			//validate spatial index if necessary
			if (shouldDraw && _spatialIndex.recordCount == 0)
				_spatialIndex.createIndex(plotter);

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
		}
		
		/**
		 * This function gets called when the unscaled width or height changes.
		 * This function will resize the BitmapData to the new unscaled width and height.
		 * Classes that extend PlotLayer can override this function for different behavior.
		 */
		protected function handleSizeChange():void
		{
			//trace("sizeChanged",unscaledWidth,unscaledHeight);
			var bitmapChanged:Boolean = PlotterUtils.setBitmapDataSize(plotBitmap, unscaledWidth, unscaledHeight);
			if (bitmapChanged)
				invalidateGraphics();

			if (!isOverlay.value)
			{
				var bgChanged:Boolean = PlotterUtils.setBitmapDataSize(backgroundBitmap, unscaledWidth, unscaledHeight);
				if (bgChanged)
					invalidateGraphics();
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
		 * This function checks if the unscaled size of the UIComponent changed.
		 * If so, the graphics are invalidated.
		 * If the graphics are invalid, this function will call validateGraphics().
		 * This is the only function that should call validateGraphics() directly.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			//trace("updateDisplayList",arguments);
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			// detect size change
			var sizeChanged:Boolean = _prevUnscaledWidth != unscaledWidth || _prevUnscaledHeight != unscaledHeight;
			_prevUnscaledWidth = unscaledWidth;
			_prevUnscaledHeight = unscaledHeight;
			if (sizeChanged)
				handleSizeChange();

			// validate graphics if necessary
			if (!_graphicsAreValid && layerIsVisible.value)
			{
				//trace("validating graphics...");
				validateGraphics(unscaledWidth, unscaledHeight);
				_graphicsAreValid = true;
			}
		}

		private function trace(...args):void
		{
			DebugUtils.debug_trace(this, selectionFilter.globalName, args);
		}
	}
}

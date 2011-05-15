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

package org.oicweave.visualization.layers
{
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	
	import org.oicweave.api.core.ILinkableObject;
	import org.oicweave.api.newLinkableChild;
	import org.oicweave.api.primitives.IBounds2D;
	import org.oicweave.api.registerLinkableChild;
	import org.oicweave.api.ui.IPlotLayer;
	import org.oicweave.compiler.MathLib;
	import org.oicweave.core.LinkableBoolean;
	import org.oicweave.core.LinkableHashMap;
	import org.oicweave.core.LinkableNumber;
	import org.oicweave.core.UIUtils;
	import org.oicweave.primitives.Bounds2D;
	import org.oicweave.primitives.LinkableBounds2D;
	import org.oicweave.utils.SpatialIndex;
	import org.oicweave.utils.ZoomUtils;

	/**
	 * This is a container for a list of PlotLayers
	 * 
	 * @author adufilie
	 */
	public class PlotLayerContainer extends Canvas implements ILinkableObject
	{
		public function PlotLayerContainer()
		{
			super();
			init();
		}
		private function init():void
		{
			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";

			autoLayout = true;
			percentHeight = 100;
			percentWidth = 100;
			
			UIUtils.linkDisplayObjects(this, layers);
			
			layers.childListCallbacks.addImmediateCallback(this, handleLayersListChange);
		}
		
		public const layers:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IPlotLayer));
		public const dataBounds:LinkableBounds2D = newLinkableChild(this, LinkableBounds2D, updateDataBounds, false);
		public const marginRight:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateScreenAndDataBounds, true);
		public const marginLeft:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateScreenAndDataBounds, true);
		public const marginTop:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateScreenAndDataBounds, true);
		public const marginBottom:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateScreenAndDataBounds, true);
		public const minScreenSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(128), updateDataBounds, true);
		public const minZoomLevel:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateDataBounds, true);
		public const maxZoomLevel:LinkableNumber = registerLinkableChild(this, new LinkableNumber(16), updateDataBounds, true);
		public const enableFixedAspectRatio:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), handleZoomSettingsChange, true);
		public const enableAutoZoomToExtent:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true), handleZoomSettingsChange, true);
		public const includeNonSelectableLayersInAutoZoom:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), handleZoomSettingsChange, true);

		protected function handleLayersListChange():void
		{
			var oldLayer:IPlotLayer = layers.childListCallbacks.lastObjectRemoved as IPlotLayer;
			if (oldLayer)
			{
				(oldLayer.spatialIndex as SpatialIndex).removeCallback(spatialCallback);
				oldLayer.plotter.spatialCallbacks.removeCallback(spatialCallback);
			}
			var newLayer:IPlotLayer = layers.childListCallbacks.lastObjectAdded as IPlotLayer;
			if (newLayer)
			{
				(newLayer.spatialIndex as SpatialIndex).addImmediateCallback(this, spatialCallback);
				newLayer.plotter.spatialCallbacks.addImmediateCallback(this, spatialCallback);
			}
			if (!oldLayer && !newLayer)
				return;
			
			if (oldLayer || newLayer)
				spatialCallback();
			
			// make sure new layer has correct screenBounds
			// and make sure dataBounds is updated to include new layer
			updateScreenAndDataBounds();
		}
		
		private function spatialCallback():void
		{
			updateFullDataBounds();

			// since fullDataBounds (may have) changed, there are new constraints on the dataBounds
			updateDataBounds();
		}
		
		protected function handleZoomSettingsChange():void
		{
			if (enableFixedAspectRatio.value || enableAutoZoomToExtent.value)
				updateDataBounds();
		}
		
		private function updateScreenAndDataBounds():void
		{
			// copy old screen bounds
			tempScreenBounds.copyFrom(_currentScreenBounds);
			// get new screen bounds
			getScreenBounds(_currentScreenBounds);
			// set new screen bounds for each layer
			for each (var plotLayer:IPlotLayer in layers.getObjects(IPlotLayer))
				plotLayer.setScreenBounds(_currentScreenBounds);

			// if screen bounds changed, need to make sure data bounds is still within desired constraints.
			if (!_currentScreenBounds.equals(tempScreenBounds))
			{
				if (_currentScreenBounds.isEmpty() || tempScreenBounds.isEmpty())
				{
					updateDataBounds();
				}
				else if (enableFixedAspectRatio.value)
				{
					// get the old data bounds
					dataBounds.copyTo(tempDataBounds);
					// center the old screen bounds in the new screen bounds
					tempScreenBounds.setCenter(_currentScreenBounds.getXCenter(), _currentScreenBounds.getYCenter());
					
					// get data bounds corresponding to new screen bounds, then set as new data bounds
					tempBounds.copyFrom(_currentScreenBounds);
					tempScreenBounds.projectCoordsTo(tempBounds, tempDataBounds);
					
					// save the new data bounds
					if (!tempBounds.isEmpty())
						dataBounds.copyFrom(tempBounds);
					else
						updateDataBounds();
				}
			}
		}
		
		protected function getScreenBounds(outputScreenBounds:IBounds2D):void
		{
			// default behaviour is to set screenBounds beginning from lower-left corner and ending at upper-right corner
			var left:Number = marginLeft.value;
			var top:Number = marginTop.value;
			var right:Number = unscaledWidth - marginRight.value;
			var bottom:Number = unscaledHeight - marginBottom.value;
			// set screenBounds beginning from lower-left corner and ending at upper-right corner
			//TODO: is other behavior required?
			outputScreenBounds.setBounds(left, bottom, right, top);
			if (left > right)
				outputScreenBounds.setWidth(0);
			if (top > bottom)
				outputScreenBounds.setHeight(0);
		}

		protected function updateFullDataBounds():void
		{
			fullDataBounds.reset();
			var _layers:Array;
			if (includeNonSelectableLayersInAutoZoom.value)
				_layers = layers.getObjects(IPlotLayer);
			else
				_layers = layers.getObjects(SelectablePlotLayer); // only consider SelectablePlotLayers
			for each (var plotLayer:IPlotLayer in _layers)
			{
				var spl:SelectablePlotLayer = plotLayer as SelectablePlotLayer;
				if (spl && !spl.layerIsVisible.value)
					continue;
				var pl:PlotLayer = plotLayer as PlotLayer;
				if (pl && !pl.layerIsVisible.value)
					continue;
				
				//trace(layers.getName(plotLayer), plotLayer.spatialIndex.collectiveBounds);
				fullDataBounds.includeBounds((plotLayer.spatialIndex as SpatialIndex).collectiveBounds);
				var bg:IBounds2D = plotLayer.plotter.getBackgroundDataBounds();
				fullDataBounds.includeBounds(bg);
			}
		}
		
		/**
		 * This is the collective data bounds of all the selectable plot layers.
		 */
		public const fullDataBounds:IBounds2D = new Bounds2D();
		
		protected function updateDataBounds():void
		{
			dataBounds.copyTo(tempBounds);
			if (enableAutoZoomToExtent.value || tempBounds.isUndefined())
			{
				if (!fullDataBounds.isEmpty())
				{
					dataBounds.copyFrom(fullDataBounds);
				}
			}

			// read data and screen bounds to temp bounds objects
			dataBounds.copyTo(tempDataBounds);
			getScreenBounds(tempScreenBounds);
			
			if (!tempScreenBounds.isEmpty())
			{
				var minSize:Number = Math.min(minScreenSize.value, tempScreenBounds.getXCoverage(), tempScreenBounds.getYCoverage());
				
				// enforce fixed aspect ratio on tempDataBounds
				if (enableFixedAspectRatio.value)
				{
					if (enableAutoZoomToExtent.value)
					{
						// Zoom to full extent now before fixing the aspect ratio.
						// This lets you see the full extent scaled to the entire screen bounds at a 1:1 aspect ratio.
						tempDataBounds.copyFrom(fullDataBounds);
					}
					// make xDataPerPixel ratio match yDataPerPixel ratio by expanding the data bounds width or height
					var xDataPerPixel:Number = Math.abs(tempDataBounds.getWidth() / tempScreenBounds.getWidth());
					var yDataPerPixel:Number = Math.abs(tempDataBounds.getHeight() / tempScreenBounds.getHeight());
					var desiredDataPerPixel:Number;
					// if screen too small, prefer smaller data per pixel so enlarging the screen zooms in
					if (minSize < minScreenSize.value && !enableAutoZoomToExtent.value)
						desiredDataPerPixel = Math.min(xDataPerPixel, yDataPerPixel);
					else // otherwise, prefer larger data per pixel so expanding the window will not change zoom level
						desiredDataPerPixel = Math.max(xDataPerPixel, yDataPerPixel);
					
					if (xDataPerPixel != desiredDataPerPixel)
						tempDataBounds.setWidth( tempDataBounds.getXDirection() * tempScreenBounds.getXCoverage() * desiredDataPerPixel );
					else if (yDataPerPixel != desiredDataPerPixel)
						tempDataBounds.setHeight( tempDataBounds.getYDirection() * tempScreenBounds.getYCoverage() * desiredDataPerPixel );
				}
				
				// Enforce min,max zoom level on tempDataBounds.
				if (!tempDataBounds.isUndefined() && !fullDataBounds.isUndefined())
				{
					var useXCoordinates:Boolean = (fullDataBounds.getXCoverage() > fullDataBounds.getYCoverage()); // fit full extent inside min screen size
					var currentZoomLevel:Number = ZoomUtils.getZoomLevel(tempDataBounds, tempScreenBounds, fullDataBounds, minSize, useXCoordinates);
					var newZoomLevel:Number = MathLib.constrain(currentZoomLevel, minZoomLevel.value, maxZoomLevel.value);
					if (newZoomLevel != currentZoomLevel)
					{
						var scale:Number = 1 / Math.pow(2, newZoomLevel - currentZoomLevel);
						if (!isNaN(scale) && scale != 0)
						{
							tempDataBounds.setWidth(tempDataBounds.getWidth() * scale);
							tempDataBounds.setHeight(tempDataBounds.getHeight() * scale);
						}
					}
					// Enforce pan restrictions on tempDataBounds.
					// Center of visible dataBounds should be a point inside fullDataBounds.
					fullDataBounds.constrainBoundsCenterPoint(tempDataBounds);
				}
			}
			
			// set new data bounds on each layer
			for each (var plotLayer:IPlotLayer in layers.getObjects(IPlotLayer))
			{
				plotLayer.setDataBounds(tempDataBounds);
			}
			
			// TODO: determine if this currentlyUpdatingDataBounds 
			
			// save new data bounds
			dataBounds.copyFrom(tempDataBounds);
		}
		
		public function getZoomLevel():Number
		{
			dataBounds.copyTo(tempDataBounds);
			getScreenBounds(tempScreenBounds);
			var useXCoordinates:Boolean = (fullDataBounds.getXCoverage() > fullDataBounds.getYCoverage()); // fit full extent inside min screen size
			var minSize:Number = Math.min(minScreenSize.value, tempScreenBounds.getXCoverage(), tempScreenBounds.getYCoverage());
			var zoomLevel:Number = ZoomUtils.getZoomLevel(tempDataBounds, tempScreenBounds, fullDataBounds, minSize, useXCoordinates);
			return zoomLevel;
		}
		
		public function setZoomLevel(newZoomLevel:Number):void
		{
			var currentZoomLevel:Number = getZoomLevel();
			var newConstrainedZoomLevel:Number = MathLib.constrain(newZoomLevel, minZoomLevel.value, maxZoomLevel.value);
			if (newConstrainedZoomLevel != currentZoomLevel)
			{
				var scale:Number = 1 / Math.pow(2, newConstrainedZoomLevel - currentZoomLevel);
				if (!isNaN(scale) && scale != 0)
				{
					dataBounds.copyTo(tempDataBounds);
					tempDataBounds.setWidth(tempDataBounds.getWidth() * scale);
					tempDataBounds.setHeight(tempDataBounds.getHeight() * scale);
					dataBounds.copyFrom(tempDataBounds);
				}
			}
		}
		
		public function invalidateGraphics():void
		{
			for each (var plotLayer:IPlotLayer in layers.getObjects(IPlotLayer))
			{
				plotLayer.invalidateGraphics();
			}
		}
		
		/**
		 * This function checks if the unscaled size of the UIComponent changed.
		 * If so, the graphics are invalidated.
		 * If the graphics are invalid, this function will call validateGraphics().
		 * This is the only function that should call validateGraphics() directly.
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// detect size change
			var sizeChanged:Boolean = _prevUnscaledWidth != unscaledWidth || _prevUnscaledHeight != unscaledHeight;
			_prevUnscaledWidth = unscaledWidth;
			_prevUnscaledHeight = unscaledHeight;
			if (sizeChanged)
				updateScreenAndDataBounds();
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		// these variables are used to detect a change in size
		private var _prevUnscaledWidth:Number = 0;
		private var _prevUnscaledHeight:Number = 0;
		
		private const tempPoint:Point = new Point();
		private const tempBounds:IBounds2D = new Bounds2D();
		private const tempScreenBounds:IBounds2D = new Bounds2D();
		private const tempDataBounds:IBounds2D = new Bounds2D();
		private const _currentScreenBounds:IBounds2D = new Bounds2D();
	}
}

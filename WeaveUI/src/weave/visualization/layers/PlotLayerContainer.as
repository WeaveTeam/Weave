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
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import mx.containers.Canvas;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.ISimpleGeometry;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotLayer;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.core.UIUtils;
	import weave.primitives.Bounds2D;
	import weave.primitives.ZoomBounds;
	import weave.utils.NumberUtils;
	import weave.utils.SpatialIndex;
	import weave.utils.ZoomUtils;

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
			
			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";

			autoLayout = true;
			percentHeight = 100;
			percentWidth = 100;
			
			UIUtils.linkDisplayObjects(this, layers);
			
			layers.addImmediateCallback(this, updateZoom);
			
			(WeaveAPI.SessionManager as SessionManager).removeLinkableChildFromSessionState(this, marginBottomNumber);
			(WeaveAPI.SessionManager as SessionManager).removeLinkableChildFromSessionState(this, marginTopNumber);
			(WeaveAPI.SessionManager as SessionManager).removeLinkableChildFromSessionState(this, marginLeftNumber);
			(WeaveAPI.SessionManager as SessionManager).removeLinkableChildFromSessionState(this, marginRightNumber);
		}
		
		public const layers:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IPlotLayer));
		public const zoomBounds:ZoomBounds = newLinkableChild(this, ZoomBounds, updateZoom, false); // must be immediate callback to avoid displaying a stretched map, for example
		
		//These variables hold the numeric values of the margins. They are removed from the session state after the values are set
		//This was done to support percent values
		public const marginRightNumber:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateZoom, true);
		public const marginLeftNumber:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateZoom, true);
		public const marginTopNumber:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateZoom, true);
		public const marginBottomNumber:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateZoom, true);
		
		//These values take a string which could be a number value or a percentage value. The string is evaluated and 
		//the above set of margin values (marginTopNumber, margingBottomNumber...) are set with the correct numeric value
		public const marginRight:LinkableString = registerLinkableChild(this, new LinkableString('0', NumberUtils.verifyNumberOrPercentage), updateZoom, true);
		public const marginLeft:LinkableString = registerLinkableChild(this, new LinkableString('0', NumberUtils.verifyNumberOrPercentage), updateZoom, true);
		public const marginTop:LinkableString = registerLinkableChild(this, new LinkableString('0', NumberUtils.verifyNumberOrPercentage), updateZoom, true);
		public const marginBottom:LinkableString = registerLinkableChild(this, new LinkableString('0', NumberUtils.verifyNumberOrPercentage), updateZoom, true);
		
		public const minScreenSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(128), updateZoom, true);
		public const minZoomLevel:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0), updateZoom, true);
		public const maxZoomLevel:LinkableNumber = registerLinkableChild(this, new LinkableNumber(16), updateZoom, true);
		public const enableFixedAspectRatio:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), updateZoom, true);
		public const enableAutoZoomToExtent:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true), updateZoom, true);
		public const enableAutoZoomToSelection:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), updateZoom, true);
		public const includeNonSelectableLayersInAutoZoom:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), updateZoom, true);

		public const overrideXMin:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN), updateZoom, true);
		public const overrideYMin:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN), updateZoom, true);
		public const overrideXMax:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN), updateZoom, true);
		public const overrideYMax:LinkableNumber = registerLinkableChild(this, new LinkableNumber(NaN), updateZoom, true);
		
		/**
		 * This is the collective data bounds of all the selectable plot layers.
		 */
		public const fullDataBounds:IBounds2D = new Bounds2D();

		/**
		 * This function gets called by updateZoom and updates fullDataBounds.
		 */
		protected function updateFullDataBounds():void
		{
			//trace('begin updateFullDataBounds ',ObjectUtil.toString(fullDataBounds));
			var layer:IPlotLayer;
			var plotLayer:PlotLayer;
			var selectablePlotLayer:SelectablePlotLayer;
			
			tempBounds.copyFrom(fullDataBounds);
			fullDataBounds.reset();

			var _layers:Array;
			if (includeNonSelectableLayersInAutoZoom.value)
				_layers = layers.getObjects(IPlotLayer);
			else
				_layers = layers.getObjects(SelectablePlotLayer); // only consider SelectablePlotLayers
			
			for each (layer in _layers)
			{
				selectablePlotLayer = layer as SelectablePlotLayer;
				if (selectablePlotLayer && !selectablePlotLayer.layerIsVisible.value)
					continue;
				plotLayer = layer as PlotLayer;
				if (plotLayer && !plotLayer.layerIsVisible.value)
					continue;
				
				//trace(layers.getName(layer), (layer.spatialIndex as SpatialIndex).collectiveBounds, selectablePlotLayer && selectablePlotLayer.plotLayer._spatialIndexDirty);
				// BEGIN HACK
				if (selectablePlotLayer)
					selectablePlotLayer.validateSpatialIndex();
				if (plotLayer)
					plotLayer.validateSpatialIndex();
				// END HACK
				fullDataBounds.includeBounds((layer.spatialIndex as SpatialIndex).collectiveBounds);
			}
			if (!tempBounds.equals(fullDataBounds))
			{
				//trace('fullDataBounds changed',ObjectUtil.toString(fullDataBounds));
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/**
		 * This function will update the fullDataBounds and zoomBounds based on the current state of the layers.
		 */
		protected function updateZoom():void
		{
			// make sure callbacks only trigger once
			getCallbackCollection(this).delayCallbacks();
			getCallbackCollection(zoomBounds).delayCallbacks();
			//trace('begin updateZoom',ObjectUtil.toString(getSessionState(zoomBounds)));
			
			// make sure numeric margin values are correct
			marginBottomNumber.value = Math.round(NumberUtils.getNumberFromNumberOrPercent(marginBottom.value, unscaledHeight));
			marginTopNumber.value = Math.round(NumberUtils.getNumberFromNumberOrPercent(marginTop.value, unscaledHeight));
			marginLeftNumber.value = Math.round(NumberUtils.getNumberFromNumberOrPercent(marginLeft.value, unscaledWidth));
			marginRightNumber.value = Math.round(NumberUtils.getNumberFromNumberOrPercent(marginRight.value, unscaledWidth));
			
			var layer:IPlotLayer;
			var plotLayer:PlotLayer;
			var selectablePlotLayer:SelectablePlotLayer;
			
			updateFullDataBounds();
			
			// calculate new screen bounds in temp variable
			// default behaviour is to set screenBounds beginning from lower-left corner and ending at upper-right corner
			var left:Number = marginLeftNumber.value;
			var top:Number = marginTopNumber.value;
			var right:Number = unscaledWidth - marginRightNumber.value;
			var bottom:Number = unscaledHeight - marginBottomNumber.value;
			// set screenBounds beginning from lower-left corner and ending at upper-right corner
			//TODO: is other behavior required?
			tempScreenBounds.setBounds(left, bottom, right, top);
			if (left > right)
				tempScreenBounds.setWidth(0);
			if (top > bottom)
				tempScreenBounds.setHeight(0);
			// copy current dataBounds to temp variable
			zoomBounds.getDataBounds(tempDataBounds);
			
			// determine if dataBounds should be zoomed to fullDataBounds
			if (enableAutoZoomToExtent.value || tempDataBounds.isUndefined())
			{
				if (!fullDataBounds.isEmpty())
				{
					tempDataBounds.copyFrom(fullDataBounds);
					if (isFinite(overrideXMin.value))
						tempDataBounds.setXMin(overrideXMin.value);
					if (isFinite(overrideXMax.value))
						tempDataBounds.setXMax(overrideXMax.value);
					if (isFinite(overrideYMin.value))
						tempDataBounds.setYMin(overrideYMin.value);
					if (isFinite(overrideYMax.value))
						tempDataBounds.setYMax(overrideYMax.value);
					if (enableFixedAspectRatio.value)
					{
						var xScale:Number = tempDataBounds.getWidth() / tempScreenBounds.getXCoverage();
						var yScale:Number = tempDataBounds.getHeight() / tempScreenBounds.getYCoverage();
						// keep greater data-to-pixel ratio because we want to zoom out if necessary
						if (xScale > yScale)
							tempDataBounds.setHeight(tempScreenBounds.getYCoverage() * xScale);
						if (yScale > xScale)
							tempDataBounds.setWidth(tempScreenBounds.getXCoverage() * yScale);
					}
				}
			}
			
			var overrideBounds:Boolean = isFinite(overrideXMin.value) || isFinite(overrideXMax.value)
										|| isFinite(overrideYMin.value) || isFinite(overrideYMax.value);
			if (!tempScreenBounds.isEmpty() && !overrideBounds)
			{
				//var minSize:Number = Math.min(minScreenSize.value, tempScreenBounds.getXCoverage(), tempScreenBounds.getYCoverage());
				
				if (!tempDataBounds.isUndefined() && !fullDataBounds.isUndefined())
				{
					// Enforce pan restrictions on tempDataBounds.
					// Center of visible dataBounds should be a point inside fullDataBounds.
					fullDataBounds.constrainBoundsCenterPoint(tempDataBounds);
				}
			}
			
			// save new bounds
			zoomBounds.setBounds(tempDataBounds, tempScreenBounds, enableFixedAspectRatio.value);
			if (enableAutoZoomToSelection.value)
				zoomToSelection();
			
			// set new bounds for each layer
			for each (layer in layers.getObjects(IPlotLayer))
			{
				layer.setDataBounds(tempDataBounds);
				
				plotLayer = layer as PlotLayer;
				if (plotLayer)
					plotLayer.setScreenBounds(tempScreenBounds);
				
				selectablePlotLayer = layer as SelectablePlotLayer;
				if (selectablePlotLayer)
					selectablePlotLayer.setScreenBounds(tempScreenBounds);
			}
			//trace('end updateZoom',ObjectUtil.toString(getSessionState(zoomBounds)));
			
			getCallbackCollection(zoomBounds).resumeCallbacks();
			getCallbackCollection(this).resumeCallbacks();
		}
		
		/**
		 * This function will zoom the visualization to the bounds corresponding to a list of keys.
		 * @param keys An Array of IQualifiedKey objects, or null to get them from the current selection.
		 * @param zoomMarginPercent The percent of width and height to reserve for space around the zoomed area.
		 */
		public function zoomToSelection(keys:Array = null, zoomMarginPercent:Number = 0.2):void
		{
			if (!keys)
			{
				var selection:IKeySet = Weave.defaultSelectionKeySet;
				var probe:IKeySet = Weave.defaultProbeKeySet;
				var alwaysHighlight:IKeySet = Weave.alwaysHighlightKeySet;
				keys = selection.keys;
				if (keys.length == 0)
					keys = probe.keys;
				if (keys.length == 0)
					keys = alwaysHighlight.keys;
			}
			
			// get the bounds containing all the records on all the layers
			tempBounds.reset();
			var layers:Array = layers.getObjects(IPlotLayer);
			for each (var key:* in keys)
			{
				// support for generic objects coming from JavaScript
				if (!(key is IQualifiedKey))
					key = WeaveAPI.QKeyManager.getQKey(key.keyType, key.localName);
				
				for each (var layer:IPlotLayer in layers)
				{
					var boundsArray:Array = (layer.spatialIndex as SpatialIndex).getBoundsFromKey(key);
					for each (var bounds:IBounds2D in boundsArray)
						tempBounds.includeBounds(bounds);
				}
			}
			
			// make sure callbacks only trigger once.
			getCallbackCollection(zoomBounds).delayCallbacks();
			
			// zoom to that bounds, expanding the area to keep the fixed aspect ratio
			// if tempBounds is undefined and enableAutoZoomToExtent is enabled, this will zoom to the full extent.
			zoomBounds.setDataBounds(tempBounds, true);
			
			// zoom out to include the specified margin
			zoomBounds.getDataBounds(tempBounds);
			var scale:Number = 1 / (1 - zoomMarginPercent);
			tempBounds.setWidth(tempBounds.getWidth() * scale);
			tempBounds.setHeight(tempBounds.getHeight() * scale);
			zoomBounds.setDataBounds(tempBounds);
			
			getCallbackCollection(zoomBounds).resumeCallbacks();
		}

		/**
		 * This function gets the current zoom level as defined in ZoomUtils.
		 * @return The current zoom level.
		 * @see weave.utils.ZoomUtils#getZoomLevel
		 */
		public function getZoomLevel():Number
		{
			zoomBounds.getDataBounds(tempDataBounds);
			zoomBounds.getScreenBounds(tempScreenBounds);
			var minSize:Number = Math.min(minScreenSize.value, tempScreenBounds.getXCoverage(), tempScreenBounds.getYCoverage());
			var zoomLevel:Number = ZoomUtils.getZoomLevel(tempDataBounds, tempScreenBounds, fullDataBounds, minSize);
			return zoomLevel;
		}
		
		/**
		 * This function sets the zoom level as defined in ZoomUtils.
		 * @param newZoomLevel The new zoom level.
		 * @see weave.utils.ZoomUtils#getZoomLevel
		 */
		public function setZoomLevel(newZoomLevel:Number):void
		{
			var currentZoomLevel:Number = getZoomLevel();
			var newConstrainedZoomLevel:Number = StandardLib.constrain(newZoomLevel, minZoomLevel.value, maxZoomLevel.value);
			if (newConstrainedZoomLevel != currentZoomLevel)
			{
				var scale:Number = 1 / Math.pow(2, newConstrainedZoomLevel - currentZoomLevel);
				if (!isNaN(scale) && scale != 0)
				{
					zoomBounds.getDataBounds(tempDataBounds);
					tempDataBounds.setWidth(tempDataBounds.getWidth() * scale);
					tempDataBounds.setHeight(tempDataBounds.getHeight() * scale);
					zoomBounds.setDataBounds(tempDataBounds);
				}
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// detect size change
			var sizeChanged:Boolean = _prevUnscaledWidth != unscaledWidth || _prevUnscaledHeight != unscaledHeight;
			_prevUnscaledWidth = unscaledWidth;
			_prevUnscaledHeight = unscaledHeight;
			if (sizeChanged)
				updateZoom();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		/**
		 * This function will get all the unique keys that overlap each geometry specified by
		 * simpleGeometries. 
		 * @param simpleGeometries
		 * @return An array of keys.
		 */		
		public function getKeysOverlappingGeometry(simpleGeometries:Array):Array
		{
			var key:IQualifiedKey;
			var keys:Dictionary = new Dictionary();
			var _layers:Array = layers.getObjects();
			var simpleGeometry:ISimpleGeometry;
			var layer:IPlotLayer;
			
			// Go through the layers and make a query for each layer
			for each (layer in _layers)
			{
				var spatialIndex:SpatialIndex = layer.spatialIndex as SpatialIndex; 
				for each (simpleGeometry in simpleGeometries)
				{
					var queriedKeys:Array = spatialIndex.getKeysGeometryOverlapGeometry(simpleGeometry);
					// use the dictionary to handle duplicates
					for each (key in queriedKeys)
					{
						keys[key] = true;
					}
				}
			}
			
			var result:Array = [];
			for (var keyObj:* in keys)
				result.push(keyObj as IQualifiedKey);
			
			return result;
		}
		
		/**
		 * This function projects data coordinates to stage coordinates.
		 * @return The point containing the stageX and stageY.
		 */		
		public function getStageCoordinates(dataX:Number, dataY:Number):Point
		{
			tempPoint.x = dataX;
			tempPoint.y = dataY;
			zoomBounds.getScreenBounds(tempScreenBounds);
			zoomBounds.getDataBounds(tempDataBounds);
			tempDataBounds.projectPointTo(tempPoint, tempScreenBounds);
			
			return localToGlobal(tempPoint);
		}

		/**
		 * Get the <code>mouseX</code> and <code>mouseY</code> properties of the container
		 * projected into data coordinates for the container. 
		 * @return The point containing the projected mouseX and mouseY.
		 */
		public function getMouseDataCoordinates():Point
		{
			tempPoint.x = mouseX;
			tempPoint.y = mouseY;
			zoomBounds.getScreenBounds(tempScreenBounds);
			zoomBounds.getDataBounds(tempDataBounds);
			tempScreenBounds.projectPointTo(tempPoint, tempDataBounds);
			
			return tempPoint;
		}
		
		// these variables are used to detect a change in size
		private var _prevUnscaledWidth:Number = 0;
		private var _prevUnscaledHeight:Number = 0;
		
		private const tempPoint:Point = new Point();
		private const tempBounds:IBounds2D = new Bounds2D();
		private const tempScreenBounds:IBounds2D = new Bounds2D();
		private const tempDataBounds:IBounds2D = new Bounds2D();
		
		// backwards compatibility
		[Deprecated(replacement="zoomBounds")] public function set dataBounds(value:Object):void
		{
			setSessionState(zoomBounds, value);
		}
	}
}

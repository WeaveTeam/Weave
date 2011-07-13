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
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	import mx.containers.Canvas;
	import mx.controls.Label;
	
	import weave.Weave;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IKeySet;
	import weave.api.disposeObjects;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotLayer;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISpatialIndex;
	import weave.core.LinkableBoolean;
	import weave.core.StageUtils;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.utils.SpatialIndex;
	import weave.visualization.plotters.DynamicPlotter;
	
	/**
	 * 
	 * @author adufilie
	 */
	public class SelectablePlotLayer extends Canvas implements IPlotLayer
	{
		public function SelectablePlotLayer()
		{
			super();
			init();
		}
		
		private function addGroupedCallbacks(callback:Function, property:ILinkableObject, ...moreProperties):void
		{
			moreProperties.unshift(property);
			for each (property in moreProperties)
				getCallbackCollection(property).addGroupedCallback(this, callback, true);
		}
		private function init():void
		{
			addGroupedCallbacks(handleProbeInnerGlowFilterChange,
					Weave.properties.probeInnerGlowColor,
					Weave.properties.probeInnerGlowAlpha,
					Weave.properties.probeInnerGlowBlur,
					Weave.properties.probeInnerGlowStrength
				);
			addGroupedCallbacks(handleProbeOuterGlowFilterChange,
					Weave.properties.probeOuterGlowColor,
					Weave.properties.probeOuterGlowAlpha,
					Weave.properties.probeOuterGlowBlur,
					Weave.properties.probeOuterGlowStrength
				);
			addGroupedCallbacks(handleShadowFilterChange,
					Weave.properties.shadowDistance,
					Weave.properties.shadowAngle,
					Weave.properties.shadowColor,
					Weave.properties.shadowAlpha,
					Weave.properties.shadowBlur
				);
			addGroupedCallbacks(handleBlurringFilterChange,
					Weave.properties.selectionBlurringAmount,
					Weave.properties.selectionAlphaAmount
				);

			percentWidth = 100;
			percentHeight = 100;
			
			// all three layers will use the same plotter and spatial index
			_plotLayer = new PlotLayer();
			_selectionLayer = new PlotLayer(_plotLayer.getDynamicPlotter(), _plotLayer.spatialIndex as SpatialIndex);
			_probeLayer = new PlotLayer(_plotLayer.getDynamicPlotter(), _plotLayer.spatialIndex as SpatialIndex);
			registerDisposableChild(this, _plotLayer);
			registerDisposableChild(this, _selectionLayer);
			registerDisposableChild(this, _probeLayer);
			
			// plotLayer should not have a filter because plotLayer is meant to show everything (filter is applied after plot graphics are generated).
			// apply a key filter to selection and probe layers so they only show the selected & probed shapes.

			_plotLayer.isOverlay.value = false;
			_selectionLayer.isOverlay.value = true;
			_probeLayer.isOverlay.value = true;
			
			subsetFilter.globalName = Weave.DEFAULT_SUBSET_KEYFILTER;
			selectionFilter.globalName = Weave.DEFAULT_SELECTION_KEYSET;
			probeFilter.globalName = Weave.DEFAULT_PROBE_KEYSET;
			
			layerIsVisible.value = true;
			layerIsSelectable.value = true;
			backgroundIsVisible.value = true;
			
			// initialize label that says there is no selection
			emptySelectionText.text = "No records are selected";
			emptySelectionText.setStyle("fontWeight", "bold");
			
			getCallbackCollection(selectionFilter).addGroupedCallback(this, showOrHideEmptySelectionText);
			getCallbackCollection(probeFilter).addGroupedCallback(this, showOrHideEmptySelectionText);
			getCallbackCollection(selectionFilter).addImmediateCallback(this, handleSelectionChange, null, true);

			registerLinkableChild(this, plotter);
			registerLinkableChild(this, subsetFilter);
			registerLinkableChild(this, selectionFilter);
			registerLinkableChild(this, probeFilter);
			
			addEventListener(Event.ENTER_FRAME, handleFrameEnter);
			getCallbackCollection(probeFilter).addGroupedCallback(this, resetAnimator);
		}
		
		private static var _frameTimeCurrent:int = 0;
		private static var _frameTimeTotal:int = 0;
		private static var _frameTimeBeforeUpdate:int = 50;
		private static var _alphaAnimValue:Number = 0;
		private static var _reset:Boolean = false;
		private static var _timeConstant:int = 7;
		private static var _minAlpha:Number = 0.3;
		private static var _delayAnimatorTime:int = 3000;
		
		private function resetAnimator():void
		{
			// set the reset varible to true so it delays the start of the animation in handleFrameEnter
			_reset = true;
			// reset the timer used to generate the sinusoidal alpha animation
			_frameTimeTotal = 0;
			
			// reset the alpha value to 1.0
			_probeLayer.alpha = 1.0;
		}
		
		{ /** begin static code block **/
			StageUtils.addEventCallback(Event.ENTER_FRAME, null, probeAnimator);
		} /** end static code block **/
		private static function probeAnimator():void
		{
			// only do animation if it is enabled
			if(!Weave.properties.enableProbeAnimation.value)
				return;

			// don't animate if nothing is probed
			if((Weave.root.getObject(Weave.DEFAULT_PROBE_KEYSET) as KeySet).keys.length == 0)
			{
				_frameTimeTotal = 0;
				return;
			}

			// if the animation is reset by changing what is being probed
			if(_reset) 
			{
				// set the alpha to 1
				_alphaAnimValue = 1.0;
				
				// and if the delay time has been elapsed, reset the frame total counter (used to get sine values) and set reset flag to false to cause 
				// animation to occur again
				if( _frameTimeCurrent > _delayAnimatorTime )
				{
					_frameTimeTotal = 0;
					_reset = false;
				}
			}
			// reset delay time has elapsed
			else if(_frameTimeCurrent > _frameTimeBeforeUpdate) // if the current time has surpassed the time needed to reset
			{	
				// set the reset variable to false, it will be set again when the probing changes
				_reset = false;
					
				// make the alpha range from 0.15 to 1 going in a (positive only) sine pattern.  The sine change time is slowed
				// down by multiplying 	_frameTimeBeforeReset by the _timeConstant
				_alphaAnimValue = _minAlpha + (1.0 + Math.sin(Math.PI/2 + _frameTimeTotal / (_frameTimeBeforeUpdate*_timeConstant) )) / (2.0 - _minAlpha);

				// reset the current frame time to 0, it will be used to determine when to update the animation
				_frameTimeCurrent = 0;
				return;
			}
			
			// update the current and total time counters
			_frameTimeCurrent += StageUtils.previousFrameElapsedTime;
			_frameTimeTotal   += StageUtils.previousFrameElapsedTime;
		}

		private function handleFrameEnter(e:Event):void
		{
			// only do animation if it is enabled
			if(!Weave.properties.enableProbeAnimation.value)
				return;
				
			if (_probeLayer.alpha != _alphaAnimValue)
				_probeLayer.alpha = _alphaAnimValue;
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			// center this text
			_plotLayer.getScreenBounds(tempBounds);
			emptySelectionText.x = tempBounds.getXCenter() - emptySelectionText.width / 2;
			emptySelectionText.y = tempBounds.getYCenter() - emptySelectionText.height / 2;
		}
		
		private const tempBounds:IBounds2D = new Bounds2D();

		private const emptySelectionText:Label = new Label();
		
		private function showOrHideEmptySelectionText():void
		{
			if (!backgroundIsVisible.value && !selectionExists && !probeExists)
			{
				if (!contains(emptySelectionText))
					addChild(emptySelectionText);
			}
			else
			{
				if (contains(emptySelectionText))
					removeChild(emptySelectionText);
			}	
		}
		
		
		public function invalidateGraphics():void
		{
			// invalidate the graphics of all the layers in SelectablePlotLayer
			_plotLayer.invalidateGraphics();
			_selectionLayer.invalidateGraphics();
			_probeLayer.invalidateGraphics();
		}
		
		private function get probeExists():Boolean
		{
			return (
				//probeFilter.keyType == plotter.keySet.keyType &&
				probeFilter.internalObject is IKeySet &&
				(probeFilter.internalObject as IKeySet).keys.length > 0
			);
		}
		
		private function get selectionExists():Boolean
		{
			return (
				//selectionFilter.keyType == plotter.keySet.keyType &&
				selectionFilter.internalObject is IKeySet &&
				(selectionFilter.internalObject as IKeySet).keys.length > 0
			);
		}

		//public const testFilter:LinkableWrapper = registerLinkableChild(this, new LinkableWrapper(BitmapFilter), handleSelectionChange);
		
		private function handleSelectionChange():void
		{
			if (selectionExists)
			{
				_plotLayer.alpha = Weave.properties.selectionAlphaAmount.value;
				
				if (enableBitmapFilters.value)
				{
					_plotLayer.plotFilters = [selectionBlur];
					//selectionLayer.plotFilters = testFilter.generatedObject ? [testFilter.generatedObject] : null;
					_selectionLayer.plotFilters = [shadow];
				}
				else
				{
					_plotLayer.plotFilters = null;
				}
			}
			else
			{
				_plotLayer.alpha = 1.0;
				_plotLayer.plotFilters = null;
			}	
		}

		public const enableBitmapFilters:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true), handleToggleBitmapFilters, true);
		private function handleToggleBitmapFilters():void
		{
			handleSelectionChange();
			if (enableBitmapFilters.value)
			{
				_selectionLayer.plotFilters = [shadow];
				_probeLayer.plotFilters = [probeGlowInner, probeGlowOuter];
			}
			else
			{
				_selectionLayer.plotFilters = null;
				_probeLayer.plotFilters = [shadow]; // still need one filter on probe layer to make it stand out
			}
		}
		
		private var _plotLayer:PlotLayer;
		private var _selectionLayer:PlotLayer;
		private var _probeLayer:PlotLayer;
		
		public function get plotLayer():PlotLayer { return _plotLayer; }
		public function get selectionLayer():PlotLayer { return _selectionLayer; }
		public function get probeLayer():PlotLayer { return _probeLayer; }
		
		public function getDynamicPlotter():DynamicPlotter { return _plotLayer.getDynamicPlotter(); }
		
		/**
		 * IPlotLayer interface
		 */
		
		public function get plotter():IPlotter { return _plotLayer.plotter; }
		public function get spatialIndex():ISpatialIndex { return _plotLayer.spatialIndex; }
		
		public function get subsetFilter():IDynamicKeyFilter { return _plotLayer.plotter.keySet.keyFilter; }
		public function get selectionFilter():IDynamicKeyFilter { return _selectionLayer.selectionFilter; }
		public function get probeFilter():IDynamicKeyFilter { return _probeLayer.selectionFilter; }

		public function getDataBounds(destination:IBounds2D):void
		{
			_plotLayer.getDataBounds(destination);
		}
		public function getScreenBounds(destination:IBounds2D):void
		{
			_plotLayer.getScreenBounds(destination);
		}
		public function setDataBounds(source:IBounds2D):void
		{
			for each (var layer:IPlotLayer in [_plotLayer, _selectionLayer, _probeLayer])
				layer.setDataBounds(source);
		}
		public function setScreenBounds(source:IBounds2D):void
		{
			for each (var layer:IPlotLayer in [_plotLayer, _selectionLayer, _probeLayer])
				layer.setScreenBounds(source);
		}

		private function handleBlurringFilterChange():void
		{
			selectionBlur.blurX = Weave.properties.selectionBlurringAmount.value;
			selectionBlur.blurY = Weave.properties.selectionBlurringAmount.value;
			handleToggleBitmapFilters();
		}
		
		public const useTextBitmapFilters:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), handleToggleTextFilters);
		private function handleToggleTextFilters():void
		{
			handleProbeInnerGlowFilterChange();
			//handleProbeOuterGlowFilterChange();
		}
		
		// TODO: make sessioned filters that do all this linkable properties for each filter property
		// made the list of filters each layer uses a linkableHashMap
		private var selectionBlur:BlurFilter 	= new BlurFilter(Weave.properties.selectionBlurringAmount.value,Weave.properties.selectionBlurringAmount.value);
		
		private var probeGlowInner:GlowFilter = new GlowFilter(0xff0000, 0.9, 5,5,10);
		
		private function handleProbeInnerGlowFilterChange():void
		{
			var blur:Number = useTextBitmapFilters.value ? 2 : Weave.properties.probeInnerGlowBlur.value;
			var strength:Number = useTextBitmapFilters.value ? 255 : Weave.properties.probeInnerGlowStrength.value;
			probeGlowInner.color 	= Weave.properties.probeInnerGlowColor.value;
			probeGlowInner.alpha 	= Weave.properties.probeInnerGlowAlpha.value;
			probeGlowInner.blurX	= blur;
			probeGlowInner.blurY	= blur;
			probeGlowInner.strength = strength;
			handleToggleBitmapFilters();
		}
		
		private var probeGlowOuter:GlowFilter = new GlowFilter(0xff0000, 0.7, 3,3,10);		
		private function handleProbeOuterGlowFilterChange():void
		{
			probeGlowOuter.color 	= Weave.properties.probeOuterGlowColor.value;
			probeGlowOuter.alpha 	= Weave.properties.probeOuterGlowAlpha.value;
			probeGlowOuter.blurX	= Weave.properties.probeOuterGlowBlur.value;
			probeGlowOuter.blurY	= Weave.properties.probeOuterGlowBlur.value;
			probeGlowOuter.strength = Weave.properties.probeOuterGlowStrength.value;
			handleToggleBitmapFilters();
		}
		
		private function handleShadowFilterChange():void
		{
			shadow.distance = Weave.properties.shadowDistance.value;
			shadow.angle 	= Weave.properties.shadowAngle.value;
			shadow.color	= Weave.properties.shadowColor.value;
			shadow.alpha	= Weave.properties.shadowAlpha.value;
			shadow.blurX	= Weave.properties.shadowBlur.value;
			shadow.blurY	= Weave.properties.shadowBlur.value;
			handleToggleBitmapFilters();
		}
		private var shadow:DropShadowFilter 	= new DropShadowFilter(2, 45, 0, 0.5, 4, 4, 2);
		
		
		public const backgroundIsVisible:LinkableBoolean =  newLinkableChild(this, LinkableBoolean, handleBackgroundLayerVisibleChange);
		private function handleBackgroundLayerVisibleChange():void
		{
			_plotLayer.visible = backgroundIsVisible.value;
			showOrHideEmptySelectionText();
		}
		
		public const layerIsVisible:LinkableBoolean =  newLinkableChild(this, LinkableBoolean, handleLayerIsVisibleChange);
		public const layerIsSelectable:LinkableBoolean =  newLinkableChild(this, LinkableBoolean);
		
		/**
		 * Sets the visibility of the layer 
		 */
		private function handleLayerIsVisibleChange():void
		{
			this.visible = layerIsVisible.value;
			for each (var layer:PlotLayer in [_plotLayer, _selectionLayer, _probeLayer])
			{
				try
				{
					if (layerIsVisible.value)
						addChild(layer);
					else
						removeChild(layer);
				}
				catch (e:Error)
				{
					// this error may occur if the children are already added or removed.
				}
				layer.layerIsVisible.value = layerIsVisible.value;
			}
		}
	}
}

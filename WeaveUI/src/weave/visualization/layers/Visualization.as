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
	import flash.utils.getDefinitionByName;
	
	import mx.containers.Canvas;
	
	import spark.components.Group;
	import spark.core.SpriteVisualElement;
	
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotter;
	import weave.core.ClassUtils;
	import weave.core.SessionManager;

	/**
	 * This is a container for a list of PlotLayers
	 * 
	 * @author adufilie
	 */
	public class Visualization extends Group implements ILinkableObject
	{
		public function Visualization()
		{
			super();
			
			/*this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";*/

			autoLayout = true;
			percentHeight = 100;
			percentWidth = 100;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			var sprCont:SpriteVisualElement = new SpriteVisualElement();
			sprCont.addChild(plotManager.bitmap);
			addElement(sprCont);
			//rawChildren.addChild(plotManager.bitmap);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList.apply(this, arguments);
			plotManager.setBitmapDataSize.apply(null, arguments);
		}
		
		public const plotManager:PlotManager = newLinkableChild(this, PlotManager);

		
		/*******************************
		 **  backwards compatibility  **
		 *******************************/
		
		[Deprecated] public function set layers(array:Array):void
		{
			plotManager.plotters.delayCallbacks();
			plotManager.layerSettings.delayCallbacks();
			
			var dynamicState:Object;
			var removeMissingDynamicObjects:Boolean = true;
			for each (dynamicState in array)
				if (dynamicState is String || !dynamicState.className || dynamicState.className == SessionManager.DIFF_DELETE)
					removeMissingDynamicObjects = false;
			
			if (removeMissingDynamicObjects)
				plotManager.plotters.removeAllObjects();
			
			for each (dynamicState in array)
			{
				if (dynamicState is String)
					continue;
				if (deprecatedLayerNames.indexOf(dynamicState.objectName) >= 0)
					continue;
				
				var layerState:Object = dynamicState.sessionState;
				var plotterState:Object = null;
				if (layerState && layerState.plotter is Array && layerState.plotter.length)
				{
					plotterState = layerState.plotter[0];
					var className:String = plotterState.className;
					var plotterClass:Class = ClassUtils.getClassDefinition(className);
					if (plotterClass)
						plotManager.plotters.requestObject(dynamicState.objectName, plotterClass, false);
					
					var plotter:ILinkableObject = plotManager.plotters.getObject(dynamicState.objectName);
					var settings:ILinkableObject = plotManager.getLayerSettings(dynamicState.objectName);
					if (plotter && plotterState)
						setSessionState(plotter, plotterState.sessionState, removeMissingDynamicObjects);
					if (settings)
						setSessionState(settings, layerState, removeMissingDynamicObjects);
				}
			}
			
			plotManager.plotters.resumeCallbacks();
			plotManager.layerSettings.resumeCallbacks();
		}
		
		private static const deprecatedLayerNames:Array = ["undefinedX", "undefinedY", "undefinedXY"];
		
		[Deprecated] public function set zoomBounds(value:Object):void { plotManager.zoomBounds.setSessionState(value); }
		
		[Deprecated] public function set marginRight(value:String):void { plotManager.marginRight.value = value; }
		[Deprecated] public function set marginLeft(value:String):void { plotManager.marginLeft.value = value; }
		[Deprecated] public function set marginTop(value:String):void { plotManager.marginTop.value = value; }
		[Deprecated] public function set marginBottom(value:String):void { plotManager.marginBottom.value = value; }
		
		[Deprecated] public function set minScreenSize(value:Number):void { plotManager.minScreenSize.value = value; }
		[Deprecated] public function set minZoomLevel(value:Number):void { plotManager.minZoomLevel.value = value; }
		[Deprecated] public function set maxZoomLevel(value:Number):void { plotManager.maxZoomLevel.value = value; }
		[Deprecated] public function set enableFixedAspectRatio(value:Boolean):void { plotManager.enableFixedAspectRatio.value = value; }
		[Deprecated] public function set enableAutoZoomToExtent(value:Boolean):void { plotManager.enableAutoZoomToExtent.value = value; }
		[Deprecated] public function set enableAutoZoomToSelection(value:Boolean):void { plotManager.enableAutoZoomToSelection.value = value; }
		[Deprecated] public function set includeNonSelectableLayersInAutoZoom(value:Boolean):void { plotManager.includeNonSelectableLayersInAutoZoom.value = value; }
		[Deprecated] public function set overrideXMin(value:Number):void { plotManager.overrideXMin.value = value; }
		[Deprecated] public function set overrideYMin(value:Number):void { plotManager.overrideYMin.value = value; }
		[Deprecated] public function set overrideXMax(value:Number):void { plotManager.overrideXMax.value = value; }
		[Deprecated] public function set overrideYMax(value:Number):void { plotManager.overrideYMax.value = value; }
		
		[Deprecated] public function get fullDataBounds():IBounds2D { return plotManager.fullDataBounds; }
		[Deprecated] public function get zoomToSelection():Function { return plotManager.zoomToSelection; }
		[Deprecated] public function get getZoomLevel():Function { return plotManager.getZoomLevel; }
		[Deprecated] public function get setZoomLevel():Function { return plotManager.setZoomLevel; }
		[Deprecated] public function get getKeysOverlappingGeometry():Function { return plotManager.getKeysOverlappingGeometry; }
		
		[Deprecated] public function set dataBounds(value:Object):void { plotManager.zoomBounds.setSessionState(value); }
	}
}

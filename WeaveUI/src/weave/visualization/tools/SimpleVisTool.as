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

package weave.visualization.tools
{
	import flash.events.Event;
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Label;
	import mx.core.UIComponent;
	
	import weave.Weave;
	import weave.api.copySessionState;
	import weave.api.core.ILinkableContainer;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.disposeObjects;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.core.UIUtils;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.ui.DraggablePanel;
	import weave.ui.LayerListComponent;
	import weave.ui.editors.WindowSettingsEditor;
	import weave.utils.ColumnUtils;
	import weave.utils.ProbeTextUtils;
	import weave.visualization.layers.AxisLayer;
	import weave.visualization.layers.SelectablePlotLayer;
	import weave.visualization.layers.SimpleInteractiveVisualization;

	/**
	 * A simple visualization is one with a single SelectablePlotLayer
	 * 
	 * @author adufilie
	 */
	public class SimpleVisTool extends DraggablePanel implements ILinkableContainer
	{
		public function SimpleVisTool()
		{
			// Actual constructors are interpreted, not compiled.
			// Don't put any code here.
			// Put code in the constructor() function instead.
		}

		override protected function constructor():void
		{
			super.constructor();
			
			// lock an InteractiveVisualization onto the panel
			_visualization = children.requestObject("visualization", SimpleInteractiveVisualization, true);
			
			_visualization.addEventListener(Event.RESIZE, handleVisualizationResize);
			function handleVisualizationResize(event:Event):void
			{
				invalidateDisplayList();
			}
			Weave.properties.axisFontSize.addGroupedCallback(this, updateTitleLabel);
			Weave.properties.axisFontColor.addGroupedCallback(this, updateTitleLabel);
		}
		
		/**
		 * container for Flex components
		 */
		private const toolVBox:VBox = new VBox(); // simpleVisToolVBox contains titleLabel and visCanvas
		protected const visCanvas:Canvas = new Canvas(); // For linkDisplayObjects
		private const titleLabel:Label = new Label(); // For display of title inside the window area
		
		private var createdChildren:Boolean = false;
		override protected function createChildren():void
		{
			super.createChildren();
			
			if (createdChildren)
				return;
			
			toolVBox.percentHeight = 100;
			toolVBox.percentWidth = 100;
			toolVBox.setStyle("horizontalAlign", "center");
			visCanvas.percentHeight = 100;
			visCanvas.percentWidth = 100;
			toolVBox.addChild(visCanvas);
			
			updateTitleLabel();
			
			UIUtils.linkDisplayObjects(visCanvas, children);
			
			var flexChildren:Array = getChildren();
			removeAllChildren();
			
			for ( var i:int = 0; i < flexChildren.length; i++ )
				visCanvas.addChild(flexChildren[i]);
			
			this.addChild(toolVBox);
			
			_userWindowSettings.targetTool = this;
			
			createdChildren = true;
		}
		
		private function updateTitleLabel():void
		{
			if (!parent)
				return callLater(updateTitleLabel);
			
			titleLabel.setStyle("fontSize", Weave.properties.axisFontSize.value);
			titleLabel.setStyle("color", Weave.properties.axisFontColor.value);
		}
		
		protected var _userWindowSettings:WindowSettingsEditor = new WindowSettingsEditor();
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			var layerSettings:VBox = new VBox();
			layerSettings.creationPolicy = "all";
			layerSettings.percentHeight = layerSettings.percentWidth = 100;
			
			var layersList:LayerListComponent = new LayerListComponent();
			layersList.visTool = this;
			layersList.hashMap = visualization.layers;
			
			layerSettings.addChild(layersList);
			
			if (controlPanel)
			{
				controlPanel.children = [layersList, _userWindowSettings];
			}
			
			BindingUtils.bindSetter(handleBindableTitle, this, 'title');
		}
		private function handleBindableTitle(value:String):void
		{
			titleLabel.text = title;
		}
		
		/**
		 * This function should be defined with override by subclasses.
		 * @return An Array of names corresponding to the objects returned by getSelectableAttributes().
		 */		
		public function getSelectableAttributeNames():Array
		{
			return [];
		}

		/**
		 * This function should be defined with override by subclasses.
		 * @return An Array of DynamicColumn and/or ILinkableHashMap objects that an AttributeSelectorPanel can link to.
		 */		
		public function getSelectableAttributes():Array
		{
			return [];
		}

		private function updateToolWindowSettings():void
		{
			creationPolicy = "all"; // this prevents ui components from being null in childrenCreated()
			horizontalScrollPolicy = "off";
			verticalScrollPolicy = "off";
		}
		
		public const enableTitle:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false), handleTitleToggleChange);
		private function handleTitleToggleChange():void
		{
			if (!enableTitle.value)
			{
				if (toolVBox == titleLabel.parent)
					toolVBox.removeChild(titleLabel);
			}
			else
			{
				if (toolVBox != titleLabel.parent)
					toolVBox.addChildAt(titleLabel,0);
			}
			invalidateDisplayList();
		}
		
		private const MIN_TOOL_WIDTH:int  = 250;
		private const MIN_TOOL_HEIGHT:int = 250;
		
		// NOT WORKING YET -- the intention is to scale the things inside a tool if the size is below a certain value
		// this would scale the UI and vis
		override public function set width(value:Number):void
		{
			/*var scale:Number = calculateScale();
			
			if(scale < 1)
			{
				for each(var child:UIComponent in getChildren())
				{
					child.scaleX = scale;
					child.scaleY = scale;
				}
			}
			else
			{*/
				super.width = value;
			//}
		}
		override public function set height(value:Number):void
		{
			/*var scale:Number = calculateScale();
			
			if(scale < 1)
			{
				for each(var child:UIComponent in getChildren())
				{
					child.scaleX = scale;
					child.scaleY = scale;
				}
			}
			else
			{*/
				super.height = value;
			//}
		}
		private function calculateScale():Number
		{
			var childScale:Number = 1;
			for each(var child:UIComponent in getChildren())
			{
				var widthScale:Number  = Math.min(1, (child.width  / child.scaleX) / MIN_TOOL_WIDTH);
				var heightScale:Number = Math.min(1, (child.height / child.scaleY) / MIN_TOOL_HEIGHT);
				
				// if the width scale is the smallest so far, set the returned value to this
				if(widthScale < childScale)
					childScale = widthScale;
				// if the height scale is the smallest so far, set the returned value to this
				if(heightScale < childScale)
					childScale = heightScale;
			}
			
			return childScale;
		}
		
		public static function getDefaultColumnsOfMostCommonKeyType():Array
		{
			var probedColumns:Array = ProbeTextUtils.probedColumns.getObjects(IAttributeColumn);
			if (probedColumns.length == 0)
				probedColumns = ProbeTextUtils.probeHeaderColumns.getObjects(IAttributeColumn);
			
			var keyTypeCounts:Object = new Object();
			for each (var column:IAttributeColumn in probedColumns)
				keyTypeCounts[ColumnUtils.getKeyType(column)] = int(keyTypeCounts[ColumnUtils.getKeyType(column)]) + 1;
			var selectedKeyType:String = null;
			var count:int = 0;
			for (var keyType:String in keyTypeCounts)
				if (keyTypeCounts[keyType] > count)
					count = keyTypeCounts[selectedKeyType = keyType];
			
			// remove columns not of the selected key type
			var i:int = probedColumns.length;
			while (--i > -1)
				if (ColumnUtils.getKeyType(probedColumns[i]) != selectedKeyType)
					probedColumns.splice(i, 1);
			
			if (probedColumns.length == 0)
			{
				var filteredColumn:FilteredColumn = Weave.root.getObject(Weave.DEFAULT_COLOR_DATA_COLUMN) as FilteredColumn;
				if (filteredColumn.internalColumn)
					probedColumns.push(filteredColumn.internalColumn);
			}
			
			return probedColumns;
		}
		
		/**
		 * This function takes a list of dynamic column objects and
		 * initializes the internal columns to default ones.
		 */
		public static function initColumnDefaults(dynamicColumn:DynamicColumn, ... moreDynamicColumns):void
		{
			moreDynamicColumns.unshift(dynamicColumn);
			
			var probedColumns:Array = getDefaultColumnsOfMostCommonKeyType();
			for (var i:int = 0; i < moreDynamicColumns.length; i++)
			{
				var selectedColumn:ILinkableObject = probedColumns[i % probedColumns.length] as ILinkableObject;
				var columnToInit:DynamicColumn = moreDynamicColumns[i] as DynamicColumn;
				if (columnToInit.internalColumn == null)
				{
					if (selectedColumn is DynamicColumn)
						copySessionState(selectedColumn, columnToInit);
					else
						columnToInit.copyLocalObject(selectedColumn);
				}
			}
		}
		
		[Inspectable]
		public function set xAxisEnabled(value:Boolean):void
		{
			visualization.xAxisEnabled = value;
		}
		[Inspectable]
		public function set yAxisEnabled(value:Boolean):void
		{
			visualization.yAxisEnabled = value;
		}
		
		[Inspectable]
		public function set plotterClass(classDef:Class):void
		{
			visualization.plotterClass = classDef;
		}
		
		protected function initDefaultPlotter(classDef:Class):*
		{
			visualization.plotterClass = classDef;
			return visualization.getDefaultPlotter();
		}

		protected function get plotLayer():SelectablePlotLayer
		{
			return visualization.getPlotLayer();
		}
		protected function get xAxisLayer():AxisLayer
		{
			return visualization.getXAxisLayer();
		}
		protected function get yAxisLayer():AxisLayer
		{
			return visualization.getYAxisLayer();
		}
		
		// returns the interactive visualization
		public function get visualization():SimpleInteractiveVisualization
		{
			return _visualization;
		}
		private var _visualization:SimpleInteractiveVisualization;
		
		// UI children
		public const children:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
		public function getLinkableChildren():ILinkableHashMap { return children; }
		
		override public function dispose():void
		{
			super.dispose();
		}
		
		// backwards compatibility 0.9.6
		[Deprecated(replacement="enableBorders")] public function set hideBorders(value:Boolean):void
		{
			enableBorders.value = !value;
		}
	}
}

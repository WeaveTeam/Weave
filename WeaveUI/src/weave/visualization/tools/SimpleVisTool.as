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
	import mx.core.UIComponent;
	
	import weave.Weave;
	import weave.api.copySessionState;
	import weave.api.core.ILinkableContainer;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.disposeObjects;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.core.UIUtils;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.ui.DraggablePanel;
	import weave.ui.UserWindowSettings;
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
			super();
			// Actual constructors are interpreted, not compiled.
			// Don't put any code here.
			// Put code in the constructor() function instead.
		}
		
		override protected function constructor():void
		{
			super.constructor();
			
			UIUtils.linkDisplayObjects(this, children);
			
			// lock an InteractiveVisualization onto the panel
			_visualization = children.requestObject("visualization", SimpleInteractiveVisualization, true);
		}
		
		protected var _userWindowSettings:UserWindowSettings = new UserWindowSettings();
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			
			if (controlPanel)
			{
				_userWindowSettings.targetTool = this;
				controlPanel.children = [_userWindowSettings];
			}
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
		
		
		public const linkColormap:LinkableBoolean  = registerLinkableChild(this, new LinkableBoolean(true));
		public const linkSelection:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const linkSubset:LinkableBoolean    = registerLinkableChild(this, new LinkableBoolean(true));
		public const linkProbing:LinkableBoolean   = registerLinkableChild(this, new LinkableBoolean(true));
		
		public const toolTitle:LinkableString = newLinkableChild(this, LinkableString, handleToolTitleChange);
		
		private function handleToolTitleChange():void
		{
			if (toolTitle.value == '')
				toolTitle.value = null;
			if (toolTitle.value != null)
				title = toolTitle.value;
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
		[Deprecated(replacement="enableBorders")] public function get hideBorders():LinkableBoolean
		{
			var hide:LinkableBoolean = new LinkableBoolean(!enableBorders.value);
			var callback:Function = function():void
			{
				enableBorders.value = !hide.value;
				disposeObjects(hide);
			};
			return registerLinkableChild(this, hide, callback);
		}
	}
}

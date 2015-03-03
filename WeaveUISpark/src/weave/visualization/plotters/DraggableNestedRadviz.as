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
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISelectableAttributes;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableVariable;
	import weave.core.LinkableWatcher;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.utils.ColumnUtils;
	import weave.visualization.layers.PlotTask;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * @author adufilie
	 */
	public class DraggableNestedRadviz extends AbstractPlotter implements ISelectableAttributes
	{
		public var probedKey:IQualifiedKey = null;
		
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, DraggableScatterPlotPlotter, "Draggable Nested Radviz");
		
		public function DraggableNestedRadviz()
		{
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
		}
		
		public function getSelectableAttributeNames():Array
		{
			return ["Topic Weights", "Color", "Radius", "Thumbnails", "Links"];
		}
		public function getSelectableAttributes():Array
		{
			return [topicColumns, fill.color, docRadius, thumbnails, docLinks];
		}
		
		public const topicColumns:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
		public const docRadius:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const docLinks:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const thumbnails:DynamicColumn = newLinkableChild(this, DynamicColumn);
		
		public const topicPlotRadius:LinkableNumber = registerLinkableChild(this, new LinkableNumber(50, isFinite));
		public const thresholdNumber:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.25, isFinite)); // for probe lines
		
		public const line:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fill:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		
		private const nestedPlotters:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(RadVizPlotter));
		private const rankedTopics:RankedTopicColumn = newLinkableChild(this, RankedTopicColumn);
		private const tempPoint:Point = new Point();
		
		private const RECORD_INDEX:String = 'recordIndex';
		private const MIN_IMPORTANCE:String = 'minImportance';
		private const D_PROGRESS:String = 'd_progress';
		private const D_ASYNCSTATE:String = 'd_asyncState';
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (task.iteration == 0)
			{
				task.asyncState[RECORD_INDEX] = 0;
				task.asyncState[D_PROGRESS] = new Dictionary(true);
				task.asyncState[D_ASYNCSTATE] = new Dictionary(true);
			}
			
			var recordIndex:Number = task.asyncState[RECORD_INDEX];
			var minImportance:Number = task.asyncState[MIN_IMPORTANCE];
			var d_progress:Dictionary = task.asyncState[D_PROGRESS];
			var d_asyncState:Dictionary = task.asyncState[D_ASYNCSTATE];
			var progress:Number = 1; // set to 1 in case loop is not entered
			while (recordIndex < task.recordKeys.length)
			{
				var recordKey:IQualifiedKey = task.recordKeys[recordIndex] as IQualifiedKey;
				
				if( probedKey != null && (task as PlotTask).taskType == PlotTask.TASK_TYPE_PROBE )
					for each (var topicColumn:IAttributeColumn in topicColumns.getObjects())
					{
						var tempColumnValue:Number = topicColumn.getValueFromKey(probedKey, Number);
						if( tempColumnValue > thresholdNumber.value )
						{
							var topicIDs:Array = rankedTopics.getValueFromKey(recordKey, Array);
							if (!topicIDs || !topicIDs.length)
								continue;
							
							var p0:Point = getTopicPoint(topicIDs[0]);
							task.dataBounds.projectPointTo(p0, task.screenBounds);
							
							for (var i:int = 0; i < topicIDs.length; i++)
							{
								var p1:Point = getTopicPoint(topicIDs[i]);
								task.dataBounds.projectPointTo(p1, task.screenBounds);
								tempShape.graphics.moveTo(p0.x, p0.y);
								tempShape.graphics.lineTo(p1.x, p1.y);
							}
						}
					}
					
				// this progress value will be less than 1
				progress = recordIndex / task.recordKeys.length;
				task.asyncState[RECORD_INDEX] = ++recordIndex;
				
				// avoid doing too little or too much work per iteration 
				if (getTimer() > task.iterationStopTime)
					break; // not done yet
			}
			
			// hack for symbol plotters
			var nestedPlottersArray:Array = nestedPlotters.getObjects();
			var ourAsyncState:Object = task.asyncState;
			for each (var plotter:RadVizPlotter in nestedPlottersArray)
			{
				if (task.iteration == 0)
				{
					d_asyncState[plotter] = {};
					d_progress[plotter] = 0;
				}
				if (d_progress[plotter] != 1)
				{
					task.asyncState = d_asyncState[plotter];
					d_progress[plotter] = plotter.drawPlotAsyncIteration(task);
				}
				progress += d_progress[plotter];
			}
			task.asyncState = ourAsyncState;
			
			return progress / (1 + nestedPlottersArray.length);
		}
		
		private var keyBeingDragged:IQualifiedKey;
		public var isDragging:Boolean = false;
		
		public function startPointDrag(key:IQualifiedKey):void
		{
			if (!topicColumns.getNames().indexOf(key.localName) >= 0)
				return;
			keyBeingDragged = key;
			//trace("Dragging Started  " + keyBeingDragged.localName);
			isDragging = true;
		}
		
		public function updatePointDrag(tempDragPoint:Point):void
		{
			if (keyBeingDragged != null)
				moveTopicPoint(keyBeingDragged, tempDragPoint);
		}
		
		public function stopPointDrag(endPoint:Point):void
		{
			//trace("Dragging End  " + keyBeingDragged.localName);
			isDragging = false;
			if (keyBeingDragged != null)
				moveTopicPoint(keyBeingDragged, endPoint);
			keyBeingDragged = null;
			
			//Insert send points to R code here.
		}
		
		public const topicPositions:LinkableVariable = newSpatialProperty(LinkableVariable);
		
		public function resetTopicPoints():void
		{
			topicPositions.setSessionState(null);
		}
		
		private function getTopicPoint(topicID:String):Point
		{
			var ss:Object = topicPositions.getSessionState();
			var p:Object = ss && ss[topicID];
			if (p && typeof p == 'object')
				return new Point(p.x, p.y);
			return null;
		}
		
		private function moveTopicPoint(key:IQualifiedKey, point:Point):void
		{
			var ss:Object = topicPositions.getSessionState() || {};
			ss[key.localName] = {x: point.x, y: point.y};
			topicPositions.setSessionState(ss);
		}
	}
}

import flash.display.BitmapData;

import weave.api.data.ColumnMetadata;
import weave.api.data.IAttributeColumn;
import weave.api.data.IQualifiedKey;
import weave.api.detectLinkableObjectChange;
import weave.api.primitives.IBounds2D;
import weave.api.registerDisposableChild;
import weave.api.registerLinkableChild;
import weave.compiler.StandardLib;
import weave.data.AttributeColumns.AbstractAttributeColumn;
import weave.visualization.plotters.DraggableNestedRadviz;

internal class NestedPlotTask
{
	/**
	 * This is the off-screen buffer, which may change
	 */
	public var buffer:BitmapData;
	
	/**
	 * This specifies the range of data to be rendered
	 */
	public var dataBounds:IBounds2D;
	
	/**
	 * This specifies the pixel range where the graphics should be rendered
	 */
	public var screenBounds:IBounds2D;
	
	/**
	 * These are the IQualifiedKey objects identifying which records should be rendered
	 */
	public var recordKeys:Array;
	
	/**
	 * This counter is incremented after each iteration.  When the task parameters change, this counter is reset to zero.
	 */
	public var iteration:uint;
	
	/**
	 * This is the time at which the current iteration should be stopped, if possible.  This value can be compared to getTimer().
	 * Ignore this value if an iteration cannot be ended prematurely.
	 */
	public var iterationStopTime:int;
	
	/**
	 * This object can be used to optionally store additional state variables for resuming an asynchronous task where it previously left off.
	 * Setting this will not reset the iteration counter.
	 */
	public var asyncState:Object;
}

internal class RankedTopicColumn extends AbstractAttributeColumn
{
	public function RankedTopicColumn(plotter:DraggableNestedRadviz):void
	{
		var meta:Object = {};
		meta[ColumnMetadata.TITLE] = lang('Primary Topic');
		super(meta);
		
		this.plotter = plotter;
		registerDisposableChild(plotter, this);
		registerLinkableChild(this, plotter.topicColumns);
		registerLinkableChild(this, plotter.thresholdNumber);
	}
	
	private var plotter:DraggableNestedRadviz;
	private var columns:Array;
	private var names:Array;
	
	override protected function generateValue(key:IQualifiedKey, dataType:Class):Object
	{
		if (detectLinkableObjectChange(this, plotter.topicColumns.childListCallbacks))
		{
			columns = plotter.topicColumns.getObjects();
			names = plotter.topicColumns.getNames();
		}
		
		//TODO - sort topicIDs by weight and filter by threshold value
		var maxValue:Number = NaN;
		var maxIndex:Number = NaN;
		var keyType:String = '';
		for (var i:int = 0; i < columns.length; i++)
		{
			var column:IAttributeColumn = columns[i] as IAttributeColumn;
			var value:Number = column.getValueFromKey(key, Number);
			if (isNaN(maxValue) || value > maxValue)
			{
				maxValue = value;
				maxIndex = i;
				keyType = column.getMetadata(ColumnMetadata.KEY_TYPE);
			}
		}
		
		if (dataType == Number)
			return maxIndex;
		
		var name:String = StandardLib.asString(names[i]);
		
		if (dataType == String)
			return name;
		
		if (dataType == IQualifiedKey)
			return WeaveAPI.QKeyManager.getQKey(keyType, name);
		
		if (dataType == IAttributeColumn)
			return columns[i] as IAttributeColumn;
		
		return undefined;
	}
}

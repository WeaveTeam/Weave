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
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.Weave;
	import weave.api.core.IChildListCallbackInterface;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISelectableAttributes;
	import weave.compiler.StandardLib;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.visualization.layers.PlotTask;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * @author adufilie
	 */
	public class DraggableNestedRadvizPlotter extends AbstractPlotter implements ISelectableAttributes
	{
		public var probedKey:IQualifiedKey = null;
		
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, DraggableScatterPlotPlotter, "Draggable Nested RadViz");
		
		public function DraggableNestedRadvizPlotter()
		{
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			
			var columnList:IChildListCallbackInterface = topicColumns.childListCallbacks;
			columnList.addImmediateCallback(this, function():void {
				if (columnList.lastNameAdded)
					topicPlotters.requestObject(columnList.lastNameAdded, RadVizPlotter, false);
				if (columnList.lastNameRemoved)
					topicPlotters.removeObject(columnList.lastNameRemoved);
			});
			
			var plotterList:IChildListCallbackInterface = topicPlotters.childListCallbacks;
			plotterList.addImmediateCallback(this, function():void {
				if (plotterList.lastObjectAdded)
					linkSessionState(topicColumns, (plotterList.lastObjectAdded as RadVizPlotter).columns);
				if (plotterList.lastNameRemoved)
					topicColumns.removeObject(plotterList.lastNameRemoved);
			});
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
		
		private const topicPlotters:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(RadVizPlotter));
		private const rankedTopics:RankedTopicColumn = newLinkableChild(this, RankedTopicColumn);
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			var topicIDs:Array = rankedTopics.getValueFromKey(recordKey, Array);
		}
		
		
		private const tempPoint:Point = new Point();
		
		private const RECORD_INDEX:String = 'recordIndex';
		private const D_TASKS:String = 'tasks';
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			var name:String;
			var radviz:RadVizPlotter;
			var names:Array = topicColumns.getNames();
			var subtask:CustomPlotTask;
			
			if (task.iteration == 0)
			{
				task.asyncState[RECORD_INDEX] = 0;
				task.asyncState[D_TASKS] = {};
				for each (name in names)
				{
					subtask = task.asyncState[D_TASKS][name] = new CustomPlotTask(task);
					radviz = topicPlotters.requestObject(name, RadVizPlotter, false);
					//TODO
					radviz.anchors;
					subtask.dataBounds;
					subtask.screenBounds;
				}
			}
			
			var recordIndex:Number = task.asyncState[RECORD_INDEX];
			var progress:Number = 1; // set to 1 in case loop is not entered
			while (recordIndex < task.recordKeys.length)
			{
				var recordKey:IQualifiedKey = task.recordKeys[recordIndex] as IQualifiedKey;
				
				//TODO - partition the recordKeys into subtasks
				
				// this progress value will be less than 1
				progress = recordIndex / task.recordKeys.length;
				task.asyncState[RECORD_INDEX] = ++recordIndex;
				
				// avoid doing too little or too much work per iteration 
				if (getTimer() > task.iterationStopTime)
					break; // not done yet
			}
			
			// render subtasks
			for each (name in names)
			{
				subtask = task.asyncState[D_TASKS][name] as CustomPlotTask;
				if (subtask.progress != 1)
				{
					subtask.iteration++;
					subtask.iterationStopTime = task.iterationStopTime;
					radviz = topicPlotters.getObject(name) as RadVizPlotter;
					subtask.progress = radviz.drawPlotAsyncIteration(subtask);
				}
				progress += subtask.progress;
			}
			
			progress = progress / (1 + names.length);
			
			// draw probe lines linking document to related topics
			if (progress == 1 && probedKey != null && (task as PlotTask).taskType == PlotTask.TASK_TYPE_PROBE )
			{
				tempShape.graphics.clear();
				var rankedNames:Array = rankedTopics.getValueFromKey(probedKey, Array);
				for each (name in rankedNames)
				{
					var p0:Point = getTopicPoint(name);
					task.dataBounds.projectPointTo(p0, task.screenBounds);
					
					for (var i:int = 0; i < rankedNames.length; i++)
					{
						var p1:Point = getTopicPoint(rankedNames[i]);
						task.dataBounds.projectPointTo(p1, task.screenBounds);

						line.beginLineStyle(probedKey, tempShape.graphics);
						tempShape.graphics.moveTo(p0.x, p0.y);
						tempShape.graphics.lineTo(p1.x, p1.y);
					}
				}
				task.buffer.draw(tempShape);
			}
			
			return progress;
		}
		
		private var keyBeingDragged:IQualifiedKey;
		public var isDragging:Boolean = false;
		
		public function startPointDrag(key:IQualifiedKey):void
		{
			if (!topicColumns.getNames().indexOf(key.localName) >= 0)
				return;
			keyBeingDragged = key;
			isDragging = true;
		}
		
		public function updatePointDrag(tempDragPoint:Point):void
		{
			if (keyBeingDragged != null)
				moveTopicPoint(keyBeingDragged, tempDragPoint);
		}
		
		public function stopPointDrag(endPoint:Point):void
		{
			isDragging = false;
			if (keyBeingDragged != null)
				moveTopicPoint(keyBeingDragged, endPoint);
			keyBeingDragged = null;
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
import weave.api.ui.IPlotTask;
import weave.compiler.StandardLib;
import weave.data.AttributeColumns.AbstractAttributeColumn;
import weave.visualization.plotters.DraggableNestedRadvizPlotter;

internal class CustomPlotTask implements IPlotTask
{
	public function CustomPlotTask(parentTask:IPlotTask)
	{
		this.buffer = parentTask.buffer;
		this.dataBounds = parentTask.dataBounds.cloneBounds();
		this.screenBounds = parentTask.screenBounds.cloneBounds();
	}
	
	public var progress:Number = 0;
	
	public var _buffer:BitmapData;
	public var _dataBounds:IBounds2D;
	public var _screenBounds:IBounds2D;
	public var _recordKeys:Array = [];
	public var _iteration:uint = 0;
	public var _iterationStopTime:int;
	public var _asyncState:Object = {};
	
	public function get buffer():BitmapData { return _buffer; }
	public function set buffer(v:BitmapData):void { _buffer = v; }
	public function get dataBounds():IBounds2D { return _dataBounds; }
	public function set dataBounds(v:IBounds2D):void { _dataBounds = v; }
	public function get screenBounds():IBounds2D { return _screenBounds; }
	public function set screenBounds(v:IBounds2D):void { _screenBounds = v; }
	public function get recordKeys():Array { return _recordKeys; }
	public function set recordKeys(v:Array):void { _recordKeys = v; }
	public function get iteration():uint { return _iteration; }
	public function set iteration(v:uint):void { _iteration = v; }
	public function get iterationStopTime():int { return _iterationStopTime; }
	public function set iterationStopTime(v:int):void { _iterationStopTime = v; }
	public function get asyncState():Object { return _asyncState; }
	public function set asyncState(v:Object):void { _asyncState = v; }
}

internal class RankedTopicColumn extends AbstractAttributeColumn
{
	public function RankedTopicColumn(plotter:DraggableNestedRadvizPlotter):void
	{
		var meta:Object = {};
		meta[ColumnMetadata.TITLE] = lang('Ranked Topics');
		super(meta);
		
		this.plotter = plotter;
		registerDisposableChild(plotter, this);
		registerLinkableChild(this, plotter.topicColumns);
		registerLinkableChild(this, plotter.thresholdNumber);
	}
	
	private var plotter:DraggableNestedRadvizPlotter;
	private var columnNames:Array;
	
	private var tempDocKey:IQualifiedKey; // used in getTopicWeight
	
	private function getTopicWeight(name:String):Number
	{
		var column:IAttributeColumn = plotter.topicColumns.getObject(name) as IAttributeColumn;
		return column.getValueFromKey(tempDocKey, Number);
	}
	
	override protected function generateValue(key:IQualifiedKey, dataType:Class):Object
	{
		if (detectLinkableObjectChange(this, plotter.topicColumns.childListCallbacks))
			columnNames = plotter.topicColumns.getNames();
		
		// set tempDocKey for getTopicWeight()
		tempDocKey = key;
		// filter topic columns by threshold value
		var sortedColumnNames:Array = columnNames.filter(function(columnName:String, i:int, a:Array):Boolean {
			return getTopicWeight(columnName) >= plotter.thresholdNumber.value;
		});
		// sort topic column names by topic weight
		StandardLib.sortOn(sortedColumnNames, getTopicWeight, -1);
		
		if (!dataType)
			dataType = Array;
		
		if (dataType == Array)
			return sortedColumnNames; // sorted, filtered topic column names
		
		if (dataType == String)
			return StandardLib.asString(sortedColumnNames[0]); // primary topic column name
		
		if (dataType == Number)
			return columnNames.indexOf(sortedColumnNames[0]); // index of primary topic
		
		return undefined;
	}
}

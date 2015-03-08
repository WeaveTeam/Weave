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
	import avmplus.getQualifiedClassName;
	
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.Weave;
	import weave.api.copySessionState;
	import weave.api.core.IChildListCallbackInterface;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkBindableProperty;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.api.ui.ISelectableAttributes;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.ClassUtils;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.utils.VectorUtils;
	import weave.visualization.layers.PlotTask;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * @author adufilie
	 */
	public class DraggableNestedRadvizPlotter extends AbstractPlotter implements ISelectableAttributes, IDraggablePlotter, IDocumentPlotter
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, DraggableNestedRadvizPlotter, "Draggable Nested RadViz");
		
		public function DraggableNestedRadvizPlotter()
		{
			fill.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			
			var columnList:IChildListCallbackInterface = topicColumns.childListCallbacks;
			columnList.addImmediateCallback(this, function():void {
				topicColumnNames = topicColumns.getNames();
				if (columnList.lastNameAdded)
				{
					var radviz:RadVizPlotter = topicPlotters.requestObject(columnList.lastNameAdded, RadVizPlotter, false);
					registerSpatialProperty(radviz.spatialCallbacks);
					linkSessionState(line, radviz.lineStyle);
					linkSessionState(fill, radviz.fillStyle);
					linkSessionState(docRadius, radviz.radiusColumn);
					
					// this hack is so the call to requestLocalObject() succeeds
					ClassUtils.registerDeprecatedClass(getQualifiedClassName(KeyFilterByTopic), KeyFilterByTopic);
					var kf:KeyFilterByTopic = radviz.filteredKeySet.keyFilter.requestLocalObject(KeyFilterByTopic, true);
					kf.baseKeyFilter = registerLinkableChild(kf, filteredKeySet);
					kf.rankedTopics = registerLinkableChild(kf, rankedTopics);
					kf.filterString = columnList.lastNameAdded;
				}
				if (columnList.lastNameRemoved)
				{
					topicPlotters.removeObject(columnList.lastNameRemoved);
				}
				topicKeySet.replaceKeys(WeaveAPI.QKeyManager.getQKeys(TOPIC_KEY_TYPE, topicColumnNames));
				setColumnKeySources(topicColumns.getObjects().concat(topicKeySet));
			}, true);
			
			var plotterList:IChildListCallbackInterface = topicPlotters.childListCallbacks;
			plotterList.addImmediateCallback(this, function():void {
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
		public function getThumbnailURL(key:IQualifiedKey):String
		{
			return thumbnails.getValueFromKey(key, String);
		}
		public function getDocumentURL(key:IQualifiedKey):String
		{
			return docLinks.getValueFromKey(key, String);
		}
		
		public static const TOPIC_KEY_TYPE:String = 'DraggableNestedRadVizPlotter_topic';
		
		private var topicColumnNames:Array;
		
		private const topicKeySet:KeySet = newLinkableChild(this, KeySet);
		
		public const topicColumns:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(IAttributeColumn));
		public const docRadius:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const docLinks:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const thumbnails:DynamicColumn = newLinkableChild(this, DynamicColumn);
		
		public const numProbeTopicLines:LinkableNumber = registerLinkableChild(this, new LinkableNumber(3));
		public const thresholdNumber:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.25, isFinite)); // for probe lines
		
		public const line:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fill:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		public const labelSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(11));
		public const gridSnap:LinkableNumber = registerLinkableChild(this, new LinkableNumber(.5));
		public const textVerticalPos_1_to_4:LinkableNumber = registerLinkableChild(this, new LinkableNumber(2, function(value:Number):Boolean { return [1,2,3,4].indexOf(value) >= 0; }));
		public const topicColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000080));
		public const topicBackgroundAlpha:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.05));
		public const topicPointSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5));
		public const topicPositions:LinkableVariable = newSpatialProperty(LinkableVariable);
		
		private const topicPlotters:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(RadVizPlotter));
		private const rankedTopics:RankedTopicColumn = registerLinkableChild(this, new RankedTopicColumn(this as DraggableNestedRadvizPlotter));
		
		private const tempBounds:Bounds2D = new Bounds2D();
		private const bitmapText:BitmapText = new BitmapText();
		private const tempRect:Rectangle = new Rectangle();
		private const tempBoundsArray:Array = [];
		
		override public function getBackgroundDataBounds(output:IBounds2D):void
		{
			output.reset();
			for each (var name:String in topicColumnNames)
			{
				var radviz:RadVizPlotter = topicPlotters.getObject(name) as RadVizPlotter;
				radviz.getBackgroundDataBounds(tempBounds);
				var p:Point = getTopicPoint(name);
				tempBounds.offset(p.x, p.y);
				output.includeBounds(tempBounds);
			}
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			initBoundsArray(output);
			
			var primaryTopic:String;
			if (recordKey.keyType == TOPIC_KEY_TYPE)
				primaryTopic = recordKey.localName;
			else
				primaryTopic = rankedTopics.getValueFromKey(recordKey, String);
			
			var radviz:RadVizPlotter = topicPlotters.getObject(primaryTopic) as RadVizPlotter;
			if (radviz)
			{
				if (recordKey.keyType == TOPIC_KEY_TYPE)
				{
					radviz.getBackgroundDataBounds(output[0]);
					// hack to get upper-left corner
					var b:IBounds2D = output[0];
					//b.setCenteredRectangle(b.getXMin(), b.getYMax(), 0, 0);
					b.setWidth(0);
					b.setHeight(0);
				}
				else
					radviz.getDataBoundsFromRecordKey(recordKey, output);
			}
			
			var p:Point = getTopicPoint(primaryTopic);
			(output[0] as IBounds2D).offset(p.x, p.y);
		}
		
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			for each (var name:String in topicColumnNames)
			{
				var radviz:RadVizPlotter = topicPlotters.getObject(name) as RadVizPlotter;
				radviz.getBackgroundDataBounds(tempBounds);
				var topicPoint:Point = getTopicPoint(name);
				tempBounds.offset(topicPoint.x, topicPoint.y);
				if (!tempBounds.overlaps(dataBounds))
					continue;
				
				dataBounds.projectCoordsTo(tempBounds, screenBounds);
				tempBounds.centeredResize(tempBounds.getXCoverage() - 2, tempBounds.getYCoverage() - 2);
				screenBounds.constrainBounds(tempBounds, false);
				tempBounds.getRectangle(tempRect);
				
				// draw box around nested plotter
				tempShape.graphics.clear();
				tempShape.graphics.beginFill(topicColor.value, topicBackgroundAlpha.value);
				tempShape.graphics.drawRect(tempRect.x, tempRect.y, tempRect.width, tempRect.height);
				tempShape.graphics.endFill();
				destination.draw(tempShape);
				
				//AnchorPlotter.static_drawConvexHull(radviz.anchors, line, null, subtask.dataBounds, subtask.screenBounds, subtask.buffer);
				
				var topicColumn:IAttributeColumn = topicColumns.getObject(name) as IAttributeColumn;
				bitmapText.text = topicColumn.getMetadata(ColumnMetadata.TITLE);
				switch (textVerticalPos_1_to_4.value)
				{
					case 1:
						bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_TOP;
						bitmapText.y = tempBounds.getYNumericMin();
						bitmapText.height = tempRect.height;
					break;
					case 2:
						bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_BOTTOM;
						bitmapText.y = tempBounds.getYCenter();
						bitmapText.height = tempRect.height / 2;
					break;
					case 3:
						bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_TOP;
						bitmapText.y = tempBounds.getYCenter();
						bitmapText.height = tempRect.height / 2;
					break;
					case 4:
						bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_BOTTOM;
						bitmapText.y = tempBounds.getYNumericMax();
						bitmapText.height = tempRect.height;
					break;
				}
				bitmapText.x = tempRect.x;
				bitmapText.width = tempRect.width;
				bitmapText.textFormat.size = labelSize.value;
				bitmapText.draw(destination);
			}
		}
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			var name:String;
			var radviz:RadVizPlotter;
			var names:Array = topicColumnNames;
			var subtask:CustomPlotTask;
			
			if (task.iteration == 0)
			{
				task.asyncState = {};
				for each (name in names)
				{
					subtask = task.asyncState[name] = new CustomPlotTask(task);
					subtask.screenBounds.copyFrom(task.screenBounds);
					
					var topicPoint:Point = getTopicPoint(name);
					subtask.dataBounds.copyFrom(task.dataBounds);
					subtask.dataBounds.offset(-topicPoint.x, -topicPoint.y);
					
					var otherName:String;
					// remove columns that are no longer relevant
					radviz = topicPlotters.getObject(name) as RadVizPlotter;
					for each (otherName in VectorUtils.subtract(radviz.columns.getNames(), names))
						radviz.columns.removeObject(otherName);
					
					for each (otherName in names)
					{
						if (name == otherName)
							continue;
						radviz.columns.requestObjectCopy(otherName, topicColumns.getObject(otherName));
						var anchor:AnchorPoint = radviz.anchors.getObject(otherName) as AnchorPoint;
						var otherPoint:Point = getTopicPoint(otherName).subtract(topicPoint);
						otherPoint.normalize(1);
						anchor.x.value = otherPoint.x;
						anchor.y.value = otherPoint.y;
					}
				}
			}
			
			// render subtasks
			var progress:Number = 0;
			for each (name in names)
			{
				subtask = task.asyncState[name] as CustomPlotTask;
				if (subtask.progress != 1)
				{
					subtask.iteration = task.iteration;
					subtask.iterationStopTime = task.iterationStopTime;
					radviz = topicPlotters.getObject(name) as RadVizPlotter;
					subtask.progress = radviz.drawPlotAsyncIteration(subtask);
				}
				progress += subtask.progress;
			}
			
			progress = progress / names.length;
			
			if (progress < 1)
				return progress;
			
			for each (name in names)
			{
				if (task.recordKeys.indexOf(WeaveAPI.QKeyManager.getQKey(TOPIC_KEY_TYPE, name)) < 0)
					continue;
				
				// draw a small square in the middle of the topic plotter
				var center:Point = getTopicPoint(name);
				task.dataBounds.projectPointTo(center, task.screenBounds);
				
				tempShape.graphics.clear();
				tempShape.graphics.lineStyle(1, topicColor.value, 1.0);
				tempShape.graphics.drawRect(center.x, center.y, topicPointSize.value, topicPointSize.value);
				tempShape.graphics.endFill();
				task.buffer.draw(tempShape);
			}
			
			// draw probe lines linking document to related topics
			if ((task as PlotTask).taskType == PlotTask.TASK_TYPE_PROBE && task.recordKeys.length)
			{
				tempShape.graphics.clear();
				var probedKey:IQualifiedKey = task.recordKeys[0];
				
				var p0:Point = new Point();
				getDataBoundsFromRecordKey(probedKey, tempBoundsArray);
				(tempBoundsArray[0] as IBounds2D).getCenterPoint(p0);
				task.dataBounds.projectPointTo(p0, task.screenBounds);
				
				var rankedNames:Array = rankedTopics.getValueFromKey(probedKey, Array);
				var n:int = Math.min(numProbeTopicLines.value, rankedNames.length);
				for (var i:int = 0; i < n; i++)
				{
					name = rankedNames[i];
					var p1:Point = getTopicPoint(name);
					task.dataBounds.projectPointTo(p1, task.screenBounds);

					line.beginLineStyle(probedKey, tempShape.graphics);
					tempShape.graphics.moveTo(p0.x, p0.y);
					tempShape.graphics.lineTo(p1.x, p1.y);
				}
				task.buffer.draw(tempShape);
			}
			
			return 1;
		}
		
		private var keyBeingDragged:IQualifiedKey;
		public function get isDragging():Boolean { return _isDragging; }
		private var _isDragging:Boolean = false;
		
		public function startPointDrag(key:IQualifiedKey):void
		{
			if (key.keyType == TOPIC_KEY_TYPE && topicColumnNames.indexOf(key.localName) >= 0)
			{
				keyBeingDragged = key;
				_isDragging = true;
			}
		}
		
		public function updatePointDrag(tempDragPoint:Point):void
		{
			if (keyBeingDragged != null)
				moveTopicPoint(keyBeingDragged.localName, tempDragPoint);
		}
		
		public function stopPointDrag(endPoint:Point):void
		{
			_isDragging = false;
			if (keyBeingDragged != null)
				moveTopicPoint(keyBeingDragged.localName, endPoint);
			keyBeingDragged = null;
		}
		
		public function resetMovedDataPoints():void
		{
			topicPositions.setSessionState(null);
		}
		
		private function getTopicPoint(name:String):Point
		{
			var ss:Object = topicPositions.getSessionState();
			var p:Object = ss && ss[name];
			if (p && typeof p == 'object')
				return new Point(p.x, p.y);
			var names:Array = topicColumnNames;
			var index:int = names.indexOf(name);
			var point:Point = Point.polar(names.length/2, 2 * Math.PI * index / names.length);
			if (index >= 0)
				moveTopicPoint(name, point);
			return point;
		}
		
		private function moveTopicPoint(topicID:String, point:Point):void
		{
			var x:Number = point.x;
			var y:Number = point.y;
			if (gridSnap.value > 0)
			{
				x = Math.round(x / gridSnap.value) * gridSnap.value;
				y = Math.round(y / gridSnap.value) * gridSnap.value;
			}
			
			var ss:Object = topicPositions.getSessionState() || {};
			ss[topicID] = {x: x, y: y};
			topicPositions.setSessionState(ss);
		}
	}
}

import flash.display.BitmapData;
import flash.utils.Dictionary;

import weave.api.core.ILinkableObject;
import weave.api.data.ColumnMetadata;
import weave.api.data.IAttributeColumn;
import weave.api.data.IKeyFilter;
import weave.api.data.IQualifiedKey;
import weave.api.detectLinkableObjectChange;
import weave.api.primitives.IBounds2D;
import weave.api.registerDisposableChild;
import weave.api.registerLinkableChild;
import weave.api.ui.IPlotTask;
import weave.compiler.StandardLib;
import weave.data.AttributeColumns.AbstractAttributeColumn;
import weave.data.AttributeColumns.ColumnDataTask;
import weave.primitives.Bounds2D;
import weave.primitives.Dictionary2D;
import weave.visualization.plotters.DraggableNestedRadvizPlotter;

internal class CustomPlotTask implements IPlotTask
{
	public function CustomPlotTask(parentTask:IPlotTask)
	{
		this._recordKeys = parentTask.recordKeys;
		this.buffer = parentTask.buffer;
	}
	
	public var progress:Number = 0;
	
	public var _recordKeys:Array;
	public var _buffer:BitmapData;
	public var _dataBounds:IBounds2D = new Bounds2D();
	public var _screenBounds:IBounds2D = new Bounds2D();
	public var _iteration:uint;
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

internal class KeyFilterByTopic implements IKeyFilter
{
	public var baseKeyFilter:IKeyFilter;
	public var rankedTopics:RankedTopicColumn;
	public var filterString:String;
	public function containsKey(key:IQualifiedKey):Boolean
	{
		return baseKeyFilter
			&& baseKeyFilter.containsKey(key)
			&& rankedTopics
			&& rankedTopics.getValueFromKey(key, String) == filterString;
	}
}

internal class RankedTopicColumn extends AbstractAttributeColumn implements ILinkableObject
{
	public function RankedTopicColumn(plotter:DraggableNestedRadvizPlotter):void
	{
		dataCache = new Dictionary2D();
		
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
	
	override public function get keys():Array
	{
		return plotter.filteredKeySet.keys;
	}
	
	override public function containsKey(key:IQualifiedKey):Boolean
	{
		return plotter.filteredKeySet.containsKey(key);
	}
	
	override public function getValueFromKey(key:IQualifiedKey, dataType:Class=null):*
	{
		var cache:Dictionary = dataCache.dictionary[dataType] as Dictionary;
		if (!cache)
			dataCache.dictionary[dataType] = cache = new Dictionary();
		var value:* = cache[key];
		if (value === undefined)
			cache[key] = value = generateValue(key, dataType);
		return value;
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
		
		return null;
	}
}

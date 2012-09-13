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
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.radviz.ILayoutAlgorithm;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
	import weave.radviz.BruteForceLayoutAlgorithm;
	import weave.radviz.GreedyLayoutAlgorithm;
	import weave.radviz.IncrementalLayoutAlgorithm;
	import weave.radviz.NearestNeighborLayoutAlgorithm;
	import weave.radviz.RandomLayoutAlgorithm;
	import weave.utils.ColumnUtils;
	import weave.utils.DrawUtils;
	import weave.utils.RadVizUtils;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * CompoundRadVizPlotter
	 * 
	 * @author kmanohar
	 */
	public class CompoundRadVizPlotter extends AbstractPlotter
	{
		public function CompoundRadVizPlotter()
		{
			fillStyle.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			setNewRandomJitterColumn();		
			iterations.value = 50;
			
			algorithms[RANDOM_LAYOUT] = RandomLayoutAlgorithm;
			algorithms[GREEDY_LAYOUT] = GreedyLayoutAlgorithm;
			algorithms[NEAREST_NEIGHBOR] = NearestNeighborLayoutAlgorithm;
			algorithms[INCREMENTAL_LAYOUT] = IncrementalLayoutAlgorithm;
			algorithms[BRUTE_FORCE] = BruteForceLayoutAlgorithm;
			
			handleColumnsChange();
			
			columns.childListCallbacks.addImmediateCallback(this, handleColumnsListChange);
		}
		private function handleColumnsListChange():void
		{
			// When a new column is created, register the stats to trigger callbacks and affect busy status.
			// This will be cleaned up automatically when the column is disposed.
			var newColumn:IAttributeColumn = columns.childListCallbacks.lastObjectAdded as IAttributeColumn;
			if (newColumn)
				registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(newColumn), handleColumnsChange);
		}
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn), handleColumnsChange);
		public const localNormalization:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(true));
		
		/**
		 * LinkableHashMap of RadViz dimension locations: 
		 * <br/>contains the location of each column as an AnchorPoint object
		 */		
		public const anchors:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(AnchorPoint));
		private var coordinate:Point = new Point();//reusable object
		private const tempPoint:Point = new Point();//reusable object
				
		public const jitterLevel:LinkableNumber = 			registerSpatialProperty(new LinkableNumber(-19));	
		public const enableWedgeColoring:LinkableBoolean = 	registerLinkableChild(this, new LinkableBoolean(false));
		public const enableJitter:LinkableBoolean = 		registerSpatialProperty(new LinkableBoolean(false));
		public const iterations:LinkableNumber = 			newLinkableChild(this,LinkableNumber);
		
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fillStyle:SolidFillStyle = newLinkableChild(this,SolidFillStyle,handleColorColumnChange);		
		public function get alphaColumn():AlwaysDefinedColumn { return fillStyle.alpha; }
		public const colorMap:ColorRamp = registerLinkableChild(this, new ColorRamp(ColorRamp.getColorRampXMLByName("Doppler Radar")),fillColorMap);
		public var anchorColorMap:Dictionary;
		
		/**
		 * This is the radius of the circle, in screen coordinates.
		 */
		public const radiusColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		private const radiusColumnStats:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(radiusColumn));
		public const radiusConstant:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5));
		
		private static var randomValueArray:Array = new Array();		
		private static var randomArrayIndexMap:Dictionary;
		private var keyNumberMap:Dictionary;		
		private var keyColorMap:Dictionary;
		private var keyNormMap:Dictionary;
		private var keyGlobalNormMap:Dictionary;
		private var keyMaxMap:Dictionary;
		private var keyMinMap:Dictionary;
		private var columnTitleMap:Dictionary;
		
		private const _currentScreenBounds:Bounds2D = new Bounds2D();
		
		private function handleColumnsChange():void
		{			
			var i:int = 0;
			var keyNormArray:Array;
			var columnNormArray:Array;
			var columnNumberMap:Dictionary;
			var columnNumberArray:Array;
			_columns = columns.getObjects(IAttributeColumn);
			var sum:Number = 0;
			
			randomArrayIndexMap = 	new Dictionary(true);				
			keyMaxMap = 			new Dictionary(true);
			keyMinMap = 			new Dictionary(true);
			keyNormMap = 			new Dictionary(true);
			keyGlobalNormMap = 		new Dictionary(true);
			keyNumberMap = 			new Dictionary(true);
			columnTitleMap = 		new Dictionary(true);
			
			if (_columns.length > 0) 
			{
				setKeySource(_columns[0]);
			
				for each( var key:IQualifiedKey in keySet.keys)
				{					
					randomArrayIndexMap[key] = i ;										
					var magnitude:Number = 0;
					columnNormArray = [];
					columnNumberArray = [];
					columnNumberMap = new Dictionary(true);
					sum = 0;
					for each( var column:IAttributeColumn in _columns)
					{
						var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
						if(i == 0)
							columnTitleMap[column] = columns.getName(column);
						columnNormArray.push(stats.getNorm(key));
						columnNumberMap[column] = column.getValueFromKey(key, Number);
						columnNumberArray.push(columnNumberMap[column]);
					}
					for each(var x:Number in columnNumberMap)
					{
						magnitude += (x*x);
					}					
					keyMaxMap[key] = Math.sqrt(magnitude);
					keyMinMap[key] = Math.min.apply(null, columnNumberArray);
					
					keyNumberMap[key] = columnNumberMap ;	
					keyNormMap[key] = columnNormArray ;
					i++
				}
				
				for each( var k:IQualifiedKey in keySet.keys)
				{
					keyNormArray = [];
					i = 0;
					for each( var col:IAttributeColumn in _columns)
					{
						keyNormArray.push((keyNumberMap[k][col] - keyMinMap[k])/(keyMaxMap[k] - keyMinMap[k]));
						i++;
					}					
					keyGlobalNormMap[k] = keyNormArray;
				}
			}
			else
				setKeySource(null);
			
			setAnchorLocations();
			fillColorMap();
		}
		
		private function handleColorColumnChange():void
		{			
			keyColorMap = 			new Dictionary(true);
			for each(var key:IQualifiedKey in keySet.keys)
			{
				keyColorMap[key] = fillStyle.color.internalDynamicColumn.getValueFromKey(key, Number);
			}
		}
		
		public function setAnchorLocations():void
		{			
			_columns = columns.getObjects(IAttributeColumn);
			var theta:Number = (2*Math.PI)/_columns.length;
			var anchor:AnchorPoint;
			anchors.delayCallbacks();
			anchors.removeAllObjects();
			for( var i:int = 0; i < _columns.length; i++ )
			{
				anchor = anchors.requestObject(columns.getName(_columns[i]), AnchorPoint, false) as AnchorPoint ;								
				anchor.x.value = Math.cos(theta*i);
				anchor.y.value = Math.sin(theta*i);		
				anchor.title.value = ColumnUtils.getTitle(_columns[i]);
			}
			anchors.resumeCallbacks();
		}			
				
		private function fillColorMap():void
		{
			var i:int = 0;
			anchorColorMap = new Dictionary(true);
			var _anchors:Array = anchors.getObjects(AnchorPoint);
			
			for each( var anchor:AnchorPoint in anchors.getObjects())
			{
				anchorColorMap[anchors.getName(anchor)] = colorMap.getColorFromNorm(i / (_anchors.length - 1)); 
				i++;
			}
		}
		
		/**
		 * Applies the RadViz algorithm to a record specified by a recordKey
		 */
		private function getXYcoordinates(recordKey:IQualifiedKey):Number
		{
			//implements RadViz algorithm for x and y coordinates of a record
			var numeratorX:Number = 0;
			var numeratorY:Number = 0;
			var denominator:Number = 0;
			
			var anchorArray:Array = anchors.getObjects();			
			
			var sum:Number = 0;			
			var value:Number = 0;			
			var name:String;
			var keyMapExists:Boolean = true;
			var anchor:AnchorPoint;
			var array:Array = (localNormalization.value) ? keyNormMap[recordKey] : keyGlobalNormMap[recordKey];
			if(!array) keyMapExists = false;
			var array2:Dictionary = keyNumberMap[recordKey];
			var i:int = 0;
			for each( var column:IAttributeColumn in _columns)
			{				
				var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(column);
				value = (keyMapExists) ? array[i] : stats.getNorm(recordKey);
				name = (keyMapExists) ? columnTitleMap[column] : columns.getName(column);	
				sum += (keyMapExists) ? array2[column] : column.getValueFromKey(recordKey, Number);
				anchor = anchors.getObject(name) as AnchorPoint;
				numeratorX += value * anchor.x.value;
				numeratorY += value * anchor.y.value;						
				denominator += value;
				i++ ;
			}
			if(denominator==0) 
			{
				denominator = .00001;
			}
			coordinate.x = (numeratorX/denominator);
			coordinate.y = (numeratorY/denominator);
			if( enableJitter.value )
				jitterRecords(recordKey);			
			return sum;
		}
		
		private function jitterRecords(recordKey:IQualifiedKey):void
		{
			var index:Number = randomArrayIndexMap[recordKey];
			var jitter:Number = Math.abs(StandardLib.asNumber(jitterLevel.value));
			var xJitter:Number = (randomValueArray[index])/(jitter);
			if(randomValueArray[index+1] % 2) xJitter *= -1;
			var yJitter:Number = (randomValueArray[index+2])/(jitter);
			if(randomValueArray[index+3])yJitter *= -1;
			if(!isNaN(xJitter))coordinate.x += xJitter ;
			if(!isNaN(yJitter))coordinate.y += yJitter ;
		}
		
		public function drawWedge(destination:Graphics, beginRadians:Number, spanRadians:Number, projectedPoint:Point, radius:Number = 1):void
		{
			// move to center point
			destination.moveTo(projectedPoint.x, projectedPoint.y);
			// line to beginning of arc, draw arc
			DrawUtils.arcTo(destination, true, projectedPoint.x, projectedPoint.y, beginRadians, beginRadians + spanRadians, radius);
			// line back to center point
			destination.lineTo(projectedPoint.x, projectedPoint.y);
		}
		
		/**
		 * Repopulates the static randomValueArray with new random values to be used for jittering
		 */
		public function setNewRandomJitterColumn():void
		{
			randomValueArray = [] ;
			if( randomValueArray.length == 0 )
				for( var i:int = 0; i < 5000 ;i++ )
				{
					randomValueArray.push( Math.random() % 10) ;
					randomValueArray.push( -(Math.random() % 10)) ;
				}
			spatialCallbacks.triggerCallbacks();
		}
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			if (task.iteration == 0)
			{
				if (!keyNumberMap || keyNumberMap[task.recordKeys[0]] == null)
					return 1;
				task.recordKeys.sort(sortKeys, Array.DESCENDING);
			}
			return super.drawPlotAsyncIteration(task);
		}
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{						
			var graphics:Graphics = tempShape.graphics;
			var radius:Number = (radiusColumn.getInternalColumn()) ? radiusColumnStats.getNorm(recordKey) : radiusConstant.value;
			
			// Get coordinates of record and add jitter (if specified)
			var sum:Number= getXYcoordinates(recordKey);

			// missing values skipped
			if(isNaN(coordinate.x) || isNaN(coordinate.y)) return;
				
			if(isNaN(radius) && (radiusColumn.getInternalColumn() != null))
			{			
				radius = radiusConstant.value;
				
				lineStyle.beginLineStyle(recordKey, graphics);
				fillStyle.beginFillStyle(recordKey, graphics);
				dataBounds.projectPointTo(coordinate, screenBounds);
				
				// draw a square of fixed size for missing size values				
				graphics.drawRect(coordinate.x - radius/2, coordinate.y - radius/2, radius, radius);		
				graphics.endFill();
				return ;
			}
			if(radius <= Infinity) radius = 2 + (radius *(10-2));
						
			sum = (1/sum) *2 * Math.PI ;
			
			// Plot pie charts of each record
			var beginRadians:Number = 0;
			var spanRadians:Number = 0;
			var value:Number = 0;
			var numberMap:Dictionary = keyNumberMap[recordKey];
			
			var defaultAlpha:Number = StandardLib.asNumber(alphaColumn.defaultValue.value);
			
			dataBounds.projectPointTo(coordinate,screenBounds);						
			
			for each(var column:IAttributeColumn in _columns)
			{
				value = numberMap[column];
				beginRadians += spanRadians;
				spanRadians = value * sum;
				
				lineStyle.beginLineStyle(recordKey, graphics);
				if(enableWedgeColoring.value && anchorColorMap)
					graphics.beginFill(anchorColorMap[columnTitleMap[column]], alphaColumn.defaultValue.value as Number);
				else
					fillStyle.beginFillStyle(recordKey, graphics);

				if (radiusColumn.getInternalColumn())
				{
					drawWedge(graphics, beginRadians, spanRadians, coordinate, radius*radiusConstant.value/3);
				}
				else
				{					
					drawWedge(graphics, beginRadians, spanRadians, coordinate,radiusConstant.value);
				}
				graphics.endFill();
			}
		}
		
		/**
		 * This function draws the background graphics for this plotter, if applicable.
		 * An example background would be the origin lines of an axis.
		 * @param dataBounds The data coordinates that correspond to the given screenBounds.
		 * @param screenBounds The coordinates on the given sprite that correspond to the given dataBounds.
		 * @param destination The sprite to draw the graphics onto.
		 */
		override public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var g:Graphics = tempShape.graphics;
			g.clear();

			coordinate.x = -1;
			coordinate.y = -1;
			dataBounds.projectPointTo(coordinate, screenBounds);
			var x:Number = coordinate.x;
			var y:Number = coordinate.y;
			coordinate.x = 1;
			coordinate.y = 1;
			dataBounds.projectPointTo(coordinate, screenBounds);
			
			// draw RadViz circle
			try {
				g.lineStyle(2, 0, .2);
				g.drawEllipse(x, y, coordinate.x - x, coordinate.y - y);
			} catch (e:Error) { }
			
			destination.draw(tempShape);
			_destination = destination;
			
			_currentScreenBounds.copyFrom(screenBounds);
		}
			
		/**
		 * This function sorts record keys based on their radiusColumn values, then by their colorColumn values
		 * @param key1 First record key (a)
		 * @param key2 Second record key (b)
		 * @return Sort value: 0: (a == b), -1: (a < b), 1: (a > b)
		 * 
		 */			
		private function sortKeys(key1:IQualifiedKey, key2:IQualifiedKey):int
		{			
			// sort descending (high radius values drawn first)
			if (radiusColumn.getInternalColumn())
			{				
				// compare size
				var a:Number = radiusColumn.getValueFromKey(key1, Number);
				var b:Number = radiusColumn.getValueFromKey(key2, Number);
				
				if (isNaN(a) || a < b)
					return -1;
				else if (isNaN(b) || a > b)
					return 1;
			}
			// size equal.. compare color (if global colorColumn is used)
			if (!enableWedgeColoring.value)
			{
				a = keyColorMap[key1];
				b = keyColorMap[key2];
				// sort ascending (high values drawn last)
				if( a < b ) return 1;
				else if (a > b) return -1 ;
			}
			
			return 0 ;
		}			
		
		/**
		 * This function must be implemented by classes that extend AbstractPlotter.
		 * 
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 * @return An Array of Bounds2D objects that make up the bounds for the record.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			_columns = columns.getObjects(IAttributeColumn);
			//if(!unorderedColumns.length) handleColumnsChange();
			getXYcoordinates(recordKey);
			
			var bounds:IBounds2D = getReusableBounds();
			bounds.includePoint(coordinate);
			return [bounds];
		}
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @return A Bounds2D object specifying the background data bounds.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds(-1, -1.1, 1, 1.1);
		}		
		
		public var drawProbe:Boolean = false;
		public var probedKeys:Array = null;
		private var _destination:BitmapData = null;
		
		public function drawProbeLines(dataBounds:Bounds2D, screenBounds:Bounds2D, destination:Graphics):void
		{						
			if(!drawProbe) return;
			if(!probedKeys) return;
			try {
				//PlotterUtils.clear(destination);
			} catch(e:Error) {return;}
			var graphics:Graphics = destination;
			graphics.clear();
			if(probedKeys.length)
				if(probedKeys[0].keyType != keySet.keys[0].keyType) return;
			
			for each( var key:IQualifiedKey in probedKeys)
			{
				getXYcoordinates(key);
				dataBounds.projectPointTo(coordinate, screenBounds);
				
				for each( var anchor:AnchorPoint in anchors.getObjects(AnchorPoint))
				{
					tempPoint.x = anchor.x.value;
					tempPoint.y = anchor.y.value;
					dataBounds.projectPointTo(tempPoint, screenBounds);
					graphics.lineStyle(.5, 0xff0000);
					graphics.moveTo(coordinate.x, coordinate.y);
					graphics.lineTo(tempPoint.x, tempPoint.y);					
				}
			}
		}
						
		private var _columns:Array = null;		
	
		private function changeAlgorithm():void
		{
			if(_currentScreenBounds.isEmpty()) return;
			
			var newAlgorithm:Class = algorithms[currentAlgorithm.value];
			if (newAlgorithm == null) 
				return;
			
			_algorithm = newSpatialProperty(newAlgorithm);
			var array:Array = _algorithm.run(columns.getObjects(IAttributeColumn), keyNumberMap);
			
			RadVizUtils.reorderColumns(columns, array);
		}
		
		private var _algorithm:ILayoutAlgorithm = newSpatialProperty(GreedyLayoutAlgorithm);
		
		// algorithms
		[Bindable] public var algorithms:Array = [RANDOM_LAYOUT, GREEDY_LAYOUT, NEAREST_NEIGHBOR, INCREMENTAL_LAYOUT, BRUTE_FORCE];
		public const currentAlgorithm:LinkableString = registerLinkableChild(this, new LinkableString(GREEDY_LAYOUT), changeAlgorithm);
		public static const RANDOM_LAYOUT:String = "Random layout";
		public static const GREEDY_LAYOUT:String = "Greedy layout";
		public static const NEAREST_NEIGHBOR:String = "Nearest neighbor";
		public static const INCREMENTAL_LAYOUT:String = "Incremental layout";
		public static const BRUTE_FORCE:String = "Brute force";
	}
}

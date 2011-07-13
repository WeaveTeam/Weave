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
	import flash.utils.describeType;
	
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.compiler.MathLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.FilteredKeySet;
	import weave.data.KeySets.KeySet;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.utils.DebugTimer;
	import weave.utils.DrawUtils;
	import weave.utils.PlotterUtils;
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
			registerNonSpatialProperty(radiusColumn);
			setNewRandomJitterColumn();		
			iterations.value = 50;
		}		
		
		public const columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn), handleColumnsChange);		
		
		/**
		 * LinkableHashMap of RadViz dimension locations: 
		 * <br/>contains the location of each column as an AnchorPoint object
		 */		
		public const anchors:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(AnchorPoint));
		private const coordinate:Point = new Point();//reusable object
		private const tempPoint:Point = new Point();//reusable object
				
		public const jitterLevel:LinkableNumber = 			registerSpatialProperty(new LinkableNumber(-19));	
		public const enableWedgeColoring:LinkableBoolean = 	registerSpatialProperty(new LinkableBoolean(false));
		public const enableJitter:LinkableBoolean = 		registerSpatialProperty(new LinkableBoolean(false));
		public const iterations:LinkableNumber = 			newLinkableChild(this,LinkableNumber);
		
		public const lineStyle:SolidLineStyle = newNonSpatialProperty(SolidLineStyle);
		public const fillStyle:SolidFillStyle = newNonSpatialProperty(SolidFillStyle);		
		public function get alphaColumn():AlwaysDefinedColumn { return fillStyle.alpha; }
		public var colorMap:ColorRamp = registerNonSpatialProperty(new ColorRamp(ColorRamp.getColorRampXMLByName("Doppler Radar"))) ;		

		/**
		 * This is the radius of the circle, in screen coordinates.
		 */
		private const screenRadius:DynamicColumn = new DynamicColumn();
		public function get radiusColumn():DynamicColumn { return screenRadius; }
		public const radiusConstant:LinkableNumber = registerNonSpatialProperty(new LinkableNumber(5));
		
		private static var randomValueArray:Array = new Array();		
		private static var randomArrayIndexMap:Dictionary;
		private var keyNumberMap:Dictionary;		
		private var keyRadiusMap:Dictionary;
		private var keyNormedRadiusMap:Dictionary;
		private var keyColorMap:Dictionary;
		private var keyNormMap:Dictionary;
		private var columnTitleMap:Dictionary;
		
		private function handleColumnsChange():void
		{
			var i:int = 0;
			var columnNormArray:Array;
			var columnNumberArray:Array;
			unorderedColumns = columns.getObjects(IAttributeColumn);
			var sum:Number = 0;
			
			if (unorderedColumns.length > 0) 
			{
				setKeySource(unorderedColumns[0]);
			
				randomArrayIndexMap = 	new Dictionary(true);				
				keyRadiusMap = 			new Dictionary(true);
				keyNormedRadiusMap = 	new Dictionary(true);
				keyColorMap = 			new Dictionary(true);
				keyNormMap = 			new Dictionary(true);
				keyNumberMap = 			new Dictionary(true);
				columnTitleMap = 		new Dictionary(true);
				
				for each( var key:IQualifiedKey in keySet.keys)
				{					
					randomArrayIndexMap[key] = i ;
					keyNormedRadiusMap[key] = ColumnUtils.getNorm(screenRadius,key);
					keyRadiusMap[key] = screenRadius.getValueFromKey(key, Number);
					keyColorMap[key] = fillStyle.color.internalDynamicColumn.getValueFromKey(key, Number);

					columnNormArray = [];
					columnNumberArray = [];
					sum = 0;
					for each( var column:IAttributeColumn in unorderedColumns)
					{
						if(i == 0)
							columnTitleMap[column] = ColumnUtils.getTitle(column);
						columnNormArray.push(ColumnUtils.getNorm(column, key));	
						columnNumberArray.push(column.getValueFromKey(key, Number));
					}
					keyNumberMap[key] = columnNumberArray ;
					keyNormMap[key] = columnNormArray ;					
					i++
				}
			}
			else
				setKeySource(null);
			
			setAnchorLocations();
		}
		
		public function setAnchorLocations():void
		{			
			unorderedColumns = columns.getObjects(IAttributeColumn);
			var theta:Number = (2*Math.PI)/unorderedColumns.length;
			var anchor:AnchorPoint;
			anchors.removeAllObjects();
			for( var i:int = 0; i < unorderedColumns.length; i++ )
			{
				anchor = anchors.copyObject(ColumnUtils.getTitle(unorderedColumns[i]),new AnchorPoint()) as AnchorPoint ;								
				anchor.x.value = Math.cos(theta*i);
				anchor.y.value = Math.sin(theta*i);				
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
			var anchor:AnchorPoint;
			var array:Array = keyNormMap[recordKey];
			var array2:Array = keyNumberMap[recordKey];
			for (var i:int=0; i<unorderedColumns.length; i++) {
				
				value = array[i];
				name = columnTitleMap[unorderedColumns[i]];	
				sum += array2[i];
				anchor = anchors.getObject(name) as AnchorPoint;
				numeratorX += value * anchor.x.value;
				numeratorY += value * anchor.y.value;						
				denominator += value;
			}
			if(denominator) {
				coordinate.x = (numeratorX/denominator);
				coordinate.y = (numeratorY/denominator);
			}
			else {
				coordinate.x = 0;
				coordinate.y = 0;
			}
			if( enableJitter.value )
				jitterRecords(recordKey);			
			return sum;
		}
		
		private function jitterRecords(recordKey:IQualifiedKey):void
		{
			var index:Number = randomArrayIndexMap[recordKey];
			var jitter:Number = Math.abs(MathLib.toNumber(jitterLevel.value));
			var xJitter:Number = (randomValueArray[index])/(jitter);
			if(randomValueArray[index+1] % 2) xJitter *= -1;
			var yJitter:Number = (randomValueArray[index+2])/(jitter);
			if(randomValueArray[index+3])yJitter *= -1;
			if(!isNaN(xJitter))coordinate.x += xJitter ;
			if(!isNaN(yJitter))coordinate.y += yJitter ;
		}
		
		public function drawWedge(destination:Graphics, dataBounds:IBounds2D, screenBounds:IBounds2D, beginRadians:Number, spanRadians:Number, xDataCenter:Number = 0, yDataCenter:Number = 0, radius:Number = 1):void
		{
			tempPoint.x = xDataCenter;
			tempPoint.y = yDataCenter;
			dataBounds.projectPointTo(tempPoint, screenBounds);
			// move to center point
			destination.moveTo(tempPoint.x, tempPoint.y);
			// line to beginning of arc, draw arc
			DrawUtils.arcTo(destination, true, tempPoint.x, tempPoint.y, beginRadians, beginRadians + spanRadians, radius);
			// line back to center point
			destination.lineTo(tempPoint.x, tempPoint.y);
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
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{			
			var graphics:Graphics = tempShape.graphics;
			var radius:Number = keyNormedRadiusMap[recordKey];
			if(!isNaN(radius)) radius = 2 + (radius *(10-2));
			if(isNaN(radius)) radius = 5 ;
						
			// Get coordinates of record and add jitter (if specified)
			var sum:Number= getXYcoordinates(recordKey);
						
			sum = (1/sum) *2 * Math.PI ;
			
			// Plot pie charts of each record
			var beginRadians:Number = 0;
			var spanRadians:Number = 0;
			var value:Number = 0;
			var numArray:Array = keyNumberMap[recordKey];
			
			var defaultAlpha:Number = MathLib.toNumber(alphaColumn.defaultValue.value);
			for( var i:int = 0; i < unorderedColumns.length; i++ )
			{
				value = numArray[i];
				beginRadians += spanRadians;
				spanRadians = value * sum;
				
				lineStyle.beginLineStyle(recordKey, graphics);
				if(enableWedgeColoring.value)
					graphics.beginFill(colorMap.getColorFromNorm(i / (unorderedColumns.length - 1)), alphaColumn.defaultValue.value as Number);
				else
					fillStyle.beginFillStyle(recordKey, graphics);

				if( screenRadius.internalColumn ) {
					if(!isNaN(spanRadians)) //missing values skipped
						drawWedge(graphics, dataBounds, screenBounds, beginRadians, spanRadians, coordinate.x, coordinate.y, radius*radiusConstant.value/3);
				}
				else
				{
					if(!isNaN(spanRadians)) //missing values skipped
						drawWedge(graphics, dataBounds, screenBounds, beginRadians, spanRadians, coordinate.x, coordinate.y,radiusConstant.value);
				}
				graphics.endFill();
			}
		}
		
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
			// compare size
			var a:Number = keyRadiusMap[key1];
			var b:Number = keyRadiusMap[key2];
			// sort descending (high radius values drawn first)
			if( radiusColumn.internalColumn )
			{
				if( a < b )	return -1;
				else if( a > b ) return 1;
			}
			// size equal.. compare color (if global colorColumn is used)
			if( !enableWedgeColoring.value)
			{
				a = keyColorMap[key1];
				b = keyColorMap[key2];
				// sort ascending (high values drawn last)
				if( a < b ) return 1;
				else if (a > b) return -1 ;
			}
			
			return 0 ;
		}			
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			//timer1.start();
			recordKeys.sort(sortKeys, Array.DESCENDING);			
			super.drawPlot(recordKeys, dataBounds, screenBounds, destination );
			/*timer1.debug("endplot");
			timer1.stop();*/
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			unorderedColumns = columns.getObjects(IAttributeColumn);
			getXYcoordinates(recordKey);
			
			var bounds:IBounds2D = getReusableBounds();
			bounds.includePoint(coordinate);
			return [bounds];
		}
		
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
		
		private var timer1:DebugTimer = new DebugTimer(false);
		private var S:Array ; // global similarity matrix 
		private var N:Array ; // neighborhood matrix
		private var orderedColumns:Array = null;
		private var unorderedColumns:Array = null;
		private var dimensionReorderLabels:Array ; // stores the list of reordered dimensions to apply to the columns LinkableHashMap
				
		private function isAdjacent(dim1:IAttributeColumn, dim2:IAttributeColumn, array:Array):Boolean
		{
			if(array[0] == dim1 && array[array.length-1] == dim2) return true;
			if(array[0] == dim2 && array[array.length-1] == dim1) return true;
			
			for( var i:int = 0; i < array.length-1; i++ )
			{
				if(array[i] == dim1 && array[i+1] == dim2) return true ;
				if(array[i] == dim2 && array[i+1] == dim1) return true ;
			}
			
			return false ;
		}		
		private function getCosineDistance( recordKeys:Array, column1:IAttributeColumn, column2:IAttributeColumn):Number
		{
			var dist:Number = 0 ;
			var sum:Number = 0;
			var recordKeyslength:uint = recordKeys.length ;
			var dist1:Number = 0; var dist2:Number = 0;
			for( var i:int = 0; i < recordKeyslength; i++ )
			{
				var value1:Number = ColumnUtils.getNumber(column1, recordKeys[i] as IQualifiedKey);
				var value2:Number = ColumnUtils.getNumber(column2, recordKeys[i] as IQualifiedKey);
				
				if( !isNaN(value1) && !isNaN(value2))
				{
					sum += Math.abs(value1 * value2);
					dist1 += (value1 * value1);
					dist2 += (value2 * value2);
				}
			}
			dist = sum/Math.sqrt(dist1*dist2);			
			return dist;
		}		
		/** 
		 * Creates a new dxd global similarity matrix (where d is the number of dimensions) 
		 * everytime the DA ordering algorithm is run
		 */
		private function getGlobalSimilarityMatrix():void
		{			
			var length:uint = unorderedColumns.length ;
			S = [];
			for( var i:int = 0; i < length; i++ )
			{
				var tempRowArray:Array = []; 
				for( var j:int = 0; j < length; j++ )
				{
					tempRowArray.push(getCosineDistance( keySet.keys, unorderedColumns[i], unorderedColumns[j] ));
				}
				S.push(tempRowArray) ;
				tempRowArray = null ;
			}				
		}
		
		private function getNeighborhoodMatrix(array:Array):void
		{			
			var length:uint = unorderedColumns.length ;
			N = [];
			for( var i:int = 0; i < length; i++ )
			{
				var tempArray:Array = [] ;
				
				for( var j:int = 0; j < length; j++)
				{
					if( isAdjacent(unorderedColumns[i], unorderedColumns[j], array))
						tempArray.push(1);
					else tempArray.push(0);
				}
				N.push( tempArray );
				tempArray = null;
			}
		}		
		
		/** 
		 * Creates a dxd global similarity matrix (where d is the number of dimensions) 
		 * everytime the DA ordering algorithm is run
		 */
		private function getSortedSimilarityMatrix():void
		{
			var column:IAttributeColumn = unorderedColumns[0];
			var length:uint = unorderedColumns.length ;
			S = [];
			for( var i:int = 0; i < length ;i++ )
			{				
				for( var j:int = 0; j < i; j++ )
				{					
					var entry:MatrixEntry = new MatrixEntry();
					entry.similarity = getCosineDistance( column.keys, unorderedColumns[i], unorderedColumns[j] );
					entry.dimension1 = unorderedColumns[i];
					entry.dimension2 = unorderedColumns[j];
					S.push(entry);
				}
			}	
			// sort by increasing similarity values 
			// we want the least similar dimensions at index 0
			S.sort(sortEntries);
		}
		
		/**
		 * This function sorts matrix entries based on their similarity values 
		 * @param entry1 First MatrixEntry (a)
		 * @param entry2 Second MatrixEntry (b)
		 * @return Sort value: 0: (a==b); -1:(a < b); 1:(a > b)
		 * 
		 */		
		private function sortEntries( entry1:MatrixEntry, entry2:MatrixEntry):int
		{
			if( entry1.similarity > entry2.similarity) return 1;
			if( entry1.similarity < entry2.similarity) return -1;
			return 0;
		}
		
		/**
		 * Stores the DA ordering with the max similarity so far 
		 * into private array DimensionReorderLabels
		 */
		private function storeDimensionReorder(array:Array):void
		{
			dimensionReorderLabels = [];
			for( var i:int = 0; i < array.length; i++ )
				dimensionReorderLabels.push(columns.getName(array[i])) ;
		}
		
		/**
		 * Calculates and returns the similarity measure for each reordering 
		 * of the DAs in the algorithm
		 */
		private function getSimilarityMeasure():Number
		{
			var sim:Number = 0 ; var Nlength:uint = N.length ;
			for( var i:int = 0; i < Nlength; i++ )
				for( var j:int = 0; j < Nlength; j++ )
					sim+=(S[i][j] * N[i][j]);
			return sim; 
		}
		
		/**
		 * Searches for parameter IAttributeColumn inside the array parameter 
		 * @param column column to search for
		 * @param orderedColumns array of IAttributeColumns to search for column parameter
		 * @return true: column is found
		 * 
		 */		
		private function searchForColumn(column:IAttributeColumn, orderedColumns:Array ):IAttributeColumn
		{
			for each (var col:IAttributeColumn in orderedColumns ) {
				if( col == column ) return col;
			}
			return null;
		}
		
		private function searchForAnchorMatch(matchTo:IAttributeColumn, ignore:IAttributeColumn, orderedColumns:Array):IAttributeColumn
		{
			loop:for( var i:int = 0; i < S.length; i++ )
			{
				if(S[i].dimension1 == matchTo || S[i].dimension2 == matchTo)
					if(S[i].dimension1 != ignore && S[i].dimension2 != ignore)
					{
						var matched:IAttributeColumn = (S[i].dimension1 == matchTo) ? S[i].dimension2 : S[i].dimension1;
						for each( var column:IAttributeColumn in orderedColumns)
						{
							if( column == matched ) continue loop; 
						}
						return matched;
					}
			}
			return null;
		}
		
		/**
		 * Reorder the private columns LinkableHashMap 
		 * using the result from the DA ordering algorithm
		 */
		private function reorderColumnsHashMap():void
		{
			timer1.debug("end");
			timer1.stop();
			columns.setNameOrder(dimensionReorderLabels);
		}		
		
		/**
		 * Randomly swaps dimensions for a specified number of iterations,
		 *  keeping track of reorderings with the max similarity so far
		 */
		private function applyRandomReorder():void
		{
			getGlobalSimilarityMatrix();
			
			var r1:Number; var r2:Number;
			getNeighborhoodMatrix(unorderedColumns);
			var min:Number = getSimilarityMeasure();
			var sim:Number = 0 ;			

			for( var i:int = 0; i < iterations.value; i++ )
			{
				// get 2 random column numbers
				do{
					r1=Math.floor(Math.random()*100) % unorderedColumns.length;	
					r2=Math.floor(Math.random()*100) % unorderedColumns.length;	
				} while(r1 == r2);
				
				// swap columns r2 and r1
				var temp1:IAttributeColumn = new DynamicColumn() ; 
				var temp2:IAttributeColumn = new DynamicColumn() ;
				temp1 = unorderedColumns[r1];
				unorderedColumns.splice(r1, 1, unorderedColumns[r2] );
				unorderedColumns.splice(r2, 1, temp1);
				
				getNeighborhoodMatrix(unorderedColumns);
				if((sim = getSimilarityMeasure()) <= min) 
				{	
					min = sim ;
					storeDimensionReorder(unorderedColumns);
				}
			}
			trace( "random swap ", min );
			reorderColumnsHashMap();
		}
		
		private function performGreedyLayout():void
		{
			var i:int = 0; 
			orderedColumns.push(S[0].dimension1, S[0].dimension2);
			var columnBegin:IAttributeColumn = orderedColumns[0];
			var columnEnd:IAttributeColumn = orderedColumns[1];
			var column1:IAttributeColumn; 
			var column2:IAttributeColumn ;
			while( orderedColumns.length < unorderedColumns.length )
			{
				column1 = searchForColumn( S[i].dimension1, orderedColumns );
				column2 = searchForColumn( S[i].dimension2, orderedColumns );
				
				if(column1 && column2) {i++; continue;} 
				else if( column1 ) {					
					if( columnEnd == column1 ) {
						orderedColumns.push(column2);
						columnEnd = column2;
					} else if( columnBegin == column1 )
					{
						orderedColumns.unshift(column2);
						columnBegin = column2;
					} else {i++; continue;}
				} else if( column2 ) {
					if( columnEnd == column2 ) {
						orderedColumns.push(column1);
						columnEnd = column1 ;
					} else if (columnBegin == column2 ) {
						orderedColumns.unshift(column1);
						columnBegin = column1 ;
					} else {i++; continue ;}
				} else {
					orderedColumns.push(S[i].dimension1, S[i].dimension2 );
					columnEnd = S[i].dimension2 ;
				}
				i++;
			}
			storeDimensionReorder(orderedColumns);
			columns.setNameOrder(dimensionReorderLabels);
			
			// debugging
			getGlobalSimilarityMatrix();
			getNeighborhoodMatrix(orderedColumns);
			trace( "greedy ",getSimilarityMeasure());
		}
		
		private function performNearestNeighborSearch():void
		{			
			// push the two columns that are least similar into new column order
			orderedColumns.push(S[0].dimension1,S[0].dimension2);
			while( orderedColumns.length < unorderedColumns.length)
			{
				var column:IAttributeColumn = searchForAnchorMatch( orderedColumns[orderedColumns.length-1], 
					orderedColumns[orderedColumns.length-2], orderedColumns);				
				orderedColumns.push(column);
			}
			storeDimensionReorder(orderedColumns);
			columns.setNameOrder(dimensionReorderLabels);
			
			// debugging
			getGlobalSimilarityMatrix();
			getNeighborhoodMatrix(orderedColumns);
			trace( "nearest neighbor ", getSimilarityMeasure());
		}
		
		public function applyRandomAnchorLayout():void
		{
			unorderedColumns = columns.getObjects(IAttributeColumn);
			if(!unorderedColumns.length) return;
			orderedColumns = [];
			trace(timer1.start());
			timer1.debug("start");
			applyRandomReorder();
			orderedColumns = null;
		}		
		public function applyNearestNeighborAlgorithm():void
		{
			unorderedColumns = columns.getObjects(IAttributeColumn);
			if(!unorderedColumns.length) return;
			orderedColumns = [];
			getSortedSimilarityMatrix();
			performNearestNeighborSearch();
			orderedColumns = null;
		}				
		public function applyGreedyLayoutAlgorithm():void
		{
			unorderedColumns = columns.getObjects(IAttributeColumn);
			if(!unorderedColumns.length) return;
			orderedColumns = [];
			getSortedSimilarityMatrix();
			performGreedyLayout();
			orderedColumns = null;
		}			
	}
}

import weave.api.data.IAttributeColumn;

class MatrixEntry
{
	public function MatrixEntry() {}
	public var similarity:Number;
	public var dimension1:IAttributeColumn;
	public var dimension2:IAttributeColumn;
}

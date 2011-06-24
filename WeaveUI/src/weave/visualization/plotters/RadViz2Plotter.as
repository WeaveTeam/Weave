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
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.compiler.MathLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.primitives.ColorRamp;
	import weave.utils.BitmapText;
	import weave.utils.ColumnUtils;
	import weave.utils.DebugTimer;
	import weave.utils.DrawUtils;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * RadViz2Plotter
	 * 
	 * @author kmanohar
	 */
	public class RadViz2Plotter extends AbstractPlotter
	{
		public function RadViz2Plotter()
		{
			fillStyle.color.internalDynamicColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
			registerNonSpatialProperty(radiusColumn);
			setNewRandomJitterColumn();
		}		
		
		public var columns:LinkableHashMap = registerSpatialProperty(new LinkableHashMap(IAttributeColumn), handleColumnsChange);
		private const coordinate:Point = new Point();//reusable object
		private const tempPoint:Point = new Point();//reusable object
		
		private const _currentDataBounds:IBounds2D = new Bounds2D(); // reusable temporary object
		private const _currentScreenBounds:IBounds2D = new Bounds2D(); // reusable temporary object		
		
		public const jitterLevel:LinkableNumber = registerSpatialProperty(new LinkableNumber(-19));	
		public const enableWedgeColoring:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		public const enableJitter:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		
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
		
		private static var randomValueArray:Array = new Array() ;		
		private static var hashMap:Dictionary = new Dictionary( true ) ;
		
		private function handleColumnsChange():void
		{
			var i:int ;
			var array:Array = columns.getObjects();
			if (array.length > 0) 
			{
				setKeySource(array[0]);
				hashMap = null ;
				hashMap = new Dictionary( true ) ;
				for (var j:int = 0; j < keySet.keys.length; j++)
				{
					var string:String = (keySet.keys[j] as IQualifiedKey).localName;
					hashMap[string] = j ;
				}
			}
			else
				setKeySource(null);
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
		 * Applies the RadViz algorithm to a record specified by a recordKey
		 */
		private function getXYcoordinates(recordKey:IQualifiedKey):void
		{
			//implements RadViz algorithm for x and y coordinates of a record
			var numeratorX:Number = 0;
			var denominatorX:Number = 0;
			var numeratorY:Number = 0;
			var denominatorY:Number = 0;
			
			var columnArray:Array = columns.getObjects();
			var columnArrayLength:int = columnArray.length;
			//CORRECT this function so the coordinate is accurate
			var j:int;
			var value:Number = 0;
			var theta:Number = (2 * Math.PI) / columnArrayLength; 
			for (j=0; j<columnArrayLength; j++) {
				
				value = ColumnUtils.getNorm(columnArray[j], recordKey);
				
				numeratorX += value * Math.cos(theta * j);
				denominatorX += value;
				numeratorY += value * Math.sin(theta * j);
				denominatorY += value;
				//trace(numeratorX, numeratorY, denominatorX, denominatorY);
				
			}
			if(denominatorX) coordinate.x = (numeratorX/denominatorX);
			else coordinate.x = 0;
			if(denominatorY) coordinate.y = (numeratorY/denominatorY);
			else coordinate.y = 0;
			if( enableJitter.value )
				jitterRecords(recordKey);
		}
		
		private function jitterRecords(recordKey:IQualifiedKey):void
		{
			var index:Number = hashMap[recordKey.localName];
			var jitter:Number = Math.abs(MathLib.toNumber(jitterLevel.value));
			var xJitter:Number = (randomValueArray[index])/(jitter);
			if(randomValueArray[index+1] % 2) xJitter *= -1;
			var yJitter:Number = (randomValueArray[index+2])/(jitter);
			if(randomValueArray[index+3])yJitter *= -1;
			if(!isNaN(xJitter))coordinate.x += xJitter ;
			if(!isNaN(yJitter))coordinate.y += yJitter ;
		}
		
		/**
		 * This function may be defined by a class that extends AbstractPlotter to use the basic template code in AbstractPlotter.drawPlot().
		 */
		override protected function addRecordGraphicsToTempShape(recordKey:IQualifiedKey, dataBounds:IBounds2D, screenBounds:IBounds2D, tempShape:Shape):void
		{
			var graphics:Graphics = tempShape.graphics;
			var radius:Number = ColumnUtils.getNorm(screenRadius, recordKey );
			if(!isNaN(radius)) radius = 2 + (radius *(10-2));
			if(isNaN(radius)) radius = 5 ;
			
			_currentDataBounds.copyFrom(dataBounds);
			_currentScreenBounds.copyFrom(screenBounds);
			
			// Get coordinates of record and add jitter (if specified)
			getXYcoordinates(recordKey);
			
			// Plot pie charts of each record
			var beginRadians:Number = 0;
			var spanRadians:Number = 0;
			var sum:Number = 0; var value:Number = 0;
			var columnArray:Array = columns.getObjects();
			
			for( var i:int = 0; i < columnArray.length; i++ )
				sum += ColumnUtils.getNumber(columnArray[i], recordKey);
			
			var defaultAlpha:Number = MathLib.toNumber(alphaColumn.defaultValue.value);
			for( var j:int = 0; j < columnArray.length; j++ )
			{
				var norm:Number = ColumnUtils.getNorm(columnArray[j], recordKey );
				value = ColumnUtils.getNumber( columnArray[j], recordKey );
				beginRadians += spanRadians;
				spanRadians = (value/sum) * 2 * Math.PI;
				
				lineStyle.beginLineStyle(recordKey, graphics);
				if(enableWedgeColoring.value)
					graphics.beginFill(colorMap.getColorFromNorm(j / (columnArray.length - 1)), alphaColumn.defaultValue.value as Number);
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
			
			// Project coordinate to screen
			dataBounds.projectPointTo(coordinate, screenBounds);			
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
			
			try {
				g.lineStyle(2, 0, .2);
				g.drawEllipse(x, y, coordinate.x - x, coordinate.y - y);
			} catch (e:Error) { }
			
			destination.draw(tempShape);
			var i:int = 0;
			var column1:Array = columns.getObjects(IAttributeColumn);
			for each( var column:IAttributeColumn in column1 )
			{
				i++ ;
			}
			
			var theta:Number = ( 2 * Math.PI )/column1.length ;
			for( i = 0 ; i < column1.length ; i++ )
			{
				coordinate.x = Math.cos( theta * i ) ;
				coordinate.y = Math.sin( theta * i ) ;
				dataBounds.projectPointTo(coordinate, screenBounds);
				var graphics1:Graphics = tempShape.graphics;
				var labelText:BitmapText = new BitmapText();
				labelText.text =("  " + ColumnUtils.getTitle(column1[i]) + "  ");
				if(((theta*i) < (Math.PI/2)) || ((theta*i) > ((3*Math.PI)/2)))
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_LEFT ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER ;
				}
					//else if( theta <= ((55*Math.PI)/36) && theta >= ((53*Math.PI)/36))
				else if ((theta*i) == ((3*Math.PI)/2) )
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER ;
				}
				else if((theta*i) == (Math.PI/2))
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_BOTTOM ;
				}
				else
				{
					labelText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_RIGHT ;
					labelText.verticalAlign = BitmapText.VERTICAL_ALIGN_CENTER ;
				}
				labelText.x = coordinate.x ;
				labelText.y = coordinate.y ;
				labelText.draw(destination) ;
				graphics1.clear();
				graphics1.lineStyle(3);
				graphics1.drawCircle(coordinate.x, coordinate.y, 1) ;
				destination.draw(tempShape);
			}
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
			var a:Number = radiusColumn.getValueFromKey(key1, Number);
			var b:Number = radiusColumn.getValueFromKey(key2, Number);
			// sort descending (high radius values drawn first)
			if( radiusColumn.internalColumn )
			{
				if( a < b )	return -1;
				else if( a > b ) return 1;
			}
			// size equal.. compare color (if global colorColumn is used)
			if( !enableWedgeColoring.value)
			{
				a = fillStyle.color.internalDynamicColumn.getValueFromKey(key1, Number);
				b = fillStyle.color.internalDynamicColumn.getValueFromKey(key2, Number);
				// sort ascending (high values drawn last)
				if( a < b ) return 1;
				else if (a > b) return -1 ;
			}
			
			return 0 ;
		}
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			recordKeys.sort(sortKeys, Array.DESCENDING);
			super.drawPlot(recordKeys, dataBounds, screenBounds, destination );
		}
		
		/**
		 * The data bounds for a glyph has width and height equal to zero.
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			getXYcoordinates(recordKey);
			
			var bounds:IBounds2D = getReusableBounds();
			bounds.includePoint(coordinate);
			return [bounds];
		}
		
		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			return getReusableBounds(-1, -1.1, 1, 1.1);
		}		
		
		private var S:Array ; // global similarity matrix 
		private var N:Array ; // neighborhood matrix
		private var dimensionReorderLabels:Array ; // stores the list of reordered dimensions to apply to the columns LinkableHashMap
		
		/** 
		 * Creates a new global similarity matrix (private var) dxd matrix (where d is the number of dimensions) 
		 * everytime the DA ordering algorithm is run
		 */
		private function getGlobalSimilarityMatrix(column:IAttributeColumn):void
		{
			var colArray:Array  = columns.getObjects(IAttributeColumn) ;
			var colArraylength:uint = colArray.length ;
			S = null;
			S = new Array();
			for( var i:int = 0; i < colArraylength ;i++ )
			{
				var tempRowArray:Array = []; 
				for( var j:int = 0; j < colArraylength; j++ )
				{
					tempRowArray.push(getCosineDistance( column.keys, colArray[i], colArray[j] ));
				}
				S.push(tempRowArray) ;
				tempRowArray = null ;
			}				
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
			if( !isNaN(sum) && !isNaN(dist1) && !isNaN(dist2))
				dist = 1-(sum/((Math.sqrt(dist1)*Math.sqrt(dist2))));
			return ((isNaN(dist))?0:dist);
		}
		
		private function getNeighborhoodMatrix(array:Array):void
		{
			var columns1:Array = columns.getObjects(IAttributeColumn);
			var columns1length:uint = columns1.length ;
			N = [];
			for( var i:int = 0; i < columns1length; i++ )
			{
				var tempArray:Array = [] ;
				
				for( var j:int = 0; j < columns1length; j++)
				{
					var s1:String = ColumnUtils.getTitle(columns1[i]);
					var s2:String = ColumnUtils.getTitle(columns1[j]);
					if( isAdjacent(s1, s2, array))
						tempArray.push(1);
					else tempArray.push(0);
				}
				N.push( tempArray );
				tempArray = null;
			}
		}
		
		private function isAdjacent(dim1:String, dim2:String, array:Array):Boolean
		{
			if(ColumnUtils.getTitle(array[0]) == dim1 && ColumnUtils.getTitle(array[array.length-1]) == dim2)
				return true;
			if(ColumnUtils.getTitle(array[0]) == dim2 && ColumnUtils.getTitle(array[array.length-1]) == dim1)
				return true;
			for( var i:int = 0; i < array.length-1; i++ )
			{
				if(ColumnUtils.getTitle(array[i]) == dim1 && ColumnUtils.getTitle(array[i+1]) == dim2)
					return true ;
				if(ColumnUtils.getTitle(array[i]) == dim2 && ColumnUtils.getTitle(array[i+1]) == dim1)
					return true ;
			}
			return false ;
		}
		
		public function applyDimensionReordering():void
		{
			trace(this, timer1.start());
			timer1.debug("start");
			applyRandomReorder();
		}
		private var timer1:DebugTimer = new DebugTimer(false);
		
		/**
		 * Randomly swaps dimensions for a specified number of iterations,
		 *  keeping track of reorderings with the max similarity so far
		 */
		private function applyRandomReorder():void
		{
			getGlobalSimilarityMatrix( columns.getObjects()[0] );
			var columns1:Array = columns.getObjects(IAttributeColumn);
			var r1:Number; var r2:Number;
			getNeighborhoodMatrix(columns1);
			var min:Number = getSimilarityMeasure();
			var sim:Number = 0 ;
			var iterations:int ;
			trace(this, "change" );
			if( columns1.length <= 6 ) iterations = 50;
			else if (columns1.length > 6 && columns1.length < 11) iterations = 500 ;
			else iterations = 1000;
			for( var i:int = 0; i < iterations; i++ )
			{
				// get 2 random column numbers
				do{
					r1=Math.floor(Math.random()*100) % columns1.length;	
					r2=Math.floor(Math.random()*100) % columns1.length;	
				} while(r1 == r2);
				
				// swap columns r2 and r1
				var temp1:IAttributeColumn = new DynamicColumn() ; 
				var temp2:IAttributeColumn = new DynamicColumn() ;
				temp1 = columns1[r1];
				columns1.splice(r1, 1, columns1[r2] );
				columns1.splice(r2, 1, temp1);
				
				getNeighborhoodMatrix(columns1);
				if((sim = getSimilarityMeasure()) <= min) 
				{	
					min = sim ;
					storeDimensionReorder( columns1 );
				}
			}
			reorderColumnsHashMap(columns1);
		}
		
		/**
		 * Stores the DA ordering with the max similarity so far 
		 * into private array DimensionReorderLabels
		 */
		private function storeDimensionReorder( columns1:Array ):void
		{
			dimensionReorderLabels = [];
			for( var i:int = 0; i < columns1.length; i++ )
				dimensionReorderLabels.push(columns.getName(columns1[i])) ;
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
		 * Reorder the private columns LinkableHashMap 
		 * using the result from the DA ordering algorithm
		 */
		private function reorderColumnsHashMap(array:Array):void
		{
			columns.setNameOrder(dimensionReorderLabels);
			timer1.debug("end");
			timer1.stop();
			//trace( columns.getNames() );
		}
	}
}
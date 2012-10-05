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
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;
	import weave.visualization.plotters.styles.SolidFillStyle;
	import weave.visualization.plotters.styles.SolidLineStyle;
	
	/**
	 * WeaveWorldePlotter
	 * 
	 * @author jfallon
	 */
	public class WeaveWordlePlotter extends AbstractPlotter
	{
		
		public function WeaveWordlePlotter()
		{
			
			// default fill color
			fillStyle.color.defaultValue.setSessionState(0x808080);
			
			// set up session state
			setColumnKeySources([wordColumn], [true]);
			
			registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(wordColumn));
		}	
		
		public const wordColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const lineStyle:SolidLineStyle = newLinkableChild(this, SolidLineStyle);
		public const fillStyle:SolidFillStyle = newLinkableChild(this, SolidFillStyle);
		
		override public function getBackgroundDataBounds():IBounds2D
		{
			var words:Array = wordColumn.keys;
			var i:int;
			var bounds:Bounds2D = getReusableBounds();
			for( i = 0; i < words.length; i++ ){
				//This sets the intial points of every word.
				if( randPoints[words[i]] == undefined ){
					randPoints[words[i]] = [ Math.random(), Math.random() ];
				}
				else if( randPoints[words[i]] != undefined ) {
					if( i == 0 ){
						bounds.xMin = randPoints[words[i]][0];
						bounds.xMax = randPoints[words[i]][0];
						bounds.yMin = randPoints[words[i]][1];
						bounds.yMax = randPoints[words[i]][1];					
					}
					if( bounds.xMin > randPoints[words[i]][0] )
						bounds.xMin = randPoints[words[i]][0];
					if( bounds.xMax < randPoints[words[i]][0] )
						bounds.xMax = randPoints[words[i]][0];
					if( bounds.yMin > randPoints[words[i]][1] )
						bounds.yMin = randPoints[words[i]][1];
					if( bounds.yMax < randPoints[words[i]][1] )
						bounds.yMax = randPoints[words[i]][1];				
				}
			}
			return bounds;
		}
		
		/**
		 * This gets the data bounds of the histogram bin that a record key falls into.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var bounds:IBounds2D = getReusableBounds();
			if( randPoints[recordKey] != undefined ){
				bounds.setCenteredRectangle(
						0,
						0,
						1,
						1
				);
			}
			return [bounds];
		}
		/**
		 * This function retrieves a max and min value from the keys to later be used for sizing purposes.
		 */
		
		/**
		 * This draws the words to the screen and sized based on count.
		 */
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			drawAll(task.recordKeys, task.dataBounds, task.screenBounds, task.buffer);
			return 1;
		}
		private function drawAll(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			var normalized:Number;
			var j:int;
			var maxDisplay:uint;
			screenBoundaries = screenBounds;
			var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(wordColumn);
			var lowest:Number = stats.getMin();
			var highest:Number = stats.getMax();
			if( highest == lowest )
				highest = highest + 1;
			//maxDisplay is used for putting a word limit if necessary, 200 seems to fill the screen.
			maxDisplay = recordKeys.length;
			
			if( maxDisplay > 200 )
				maxDisplay = 200;
			
			for (var i:int = 0; i < maxDisplay; i++)
			{
				
				var recordKey:IQualifiedKey = recordKeys[i] as IQualifiedKey;
				
				normalized = wordColumn.getValueFromKey( recordKey );
				
				tempPoint.x = randPoints[recordKey][0] * screenBounds.getWidth() + screenBounds.getXMin();
				tempPoint.y = randPoints[recordKey][1] * screenBounds.getHeight() + screenBounds.getYMin();
				
				var tf:TextFormat = new TextFormat("Arial", null ,Math.random() * uint.MAX_VALUE );
				tf.size = ( 50 * ( ( normalized - lowest ) / ( highest - lowest ) ) ) + 20;
				bitMapper.textFormat = tf;
				bitMapper.text = recordKey.localName;
				bitMapper.x = tempPoint.x;
				bitMapper.y = tempPoint.y;
				bitMapper.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
				bitMapper.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
				bitMapper.getUnrotatedBounds( tempBounds );
				//findOpeningLeft will check to make sure there is no overlapping, and adjust as necessary.
				findOpeningLeft();
				increment = 4;
				orientation = 0;
				count = 1;
				flag = false;
				if( tooLong == false ) {
					boundaries[added++] = getReusableBounds( tempBounds.xMin, tempBounds.yMin, tempBounds.xMax, tempBounds.yMax );
					//destination.fillRect( new Rectangle( tempBounds.xMin, tempBounds.yMin, tempBounds.width, tempBounds.height ), 0x80ff0000 );
					bitMapper.draw(destination);
				}
				else
					tooLong = false;
			}
			added = 0;
			boundaries.length = 0;
		}
		/**
		 * This function will look for an possible overlapping and adjust as necessary.
		 */
		
		private function findOpeningLeft():void
		{
			var i:int;
			var j:int;
			
			for( i = 0; i < boundaries.length; i++ ){
				if( tempBounds.overlaps( boundaries[i] ) ){
					while( flag == false ) {
						for( j = 0; j < count; j++ ){
							if( orientation == 0 )
								bitMapper.x = bitMapper.x - increment;
							if( orientation == 1 )
								bitMapper.y = bitMapper.y - increment;
							if( orientation == 2 )
								bitMapper.x = bitMapper.x + increment;
							if( orientation == 3 )
								bitMapper.y = bitMapper.y + increment;
							bitMapper.getUnrotatedBounds( tempBounds );
							checkBounds();
							if( flag == true )
								return;
							if( tooLong == true )
								return;
						}
						orientation++;
						if( orientation > 3 )
							orientation = 0;
						count++;
					}
				}
			}
		}
		/*
		These are all the functions from a previous recursive attempt at plotting.
		
		private function findOpeningDown():void
		{
			var i:int;
			var j:int;
			
			for( i = 0; i < boundaries.length; i++ ){
				if( tempBounds.overlaps( boundaries[i] ) ){
					for( j = 0; j < count; j++ ){
						bitMapper.y = bitMapper.y - 4;
						bitMapper.getBounds( tempBounds );
						checkBounds();
						if( flag == true )
							return;
					}
					if( flag == true )
						return;
					count++;
					findOpeningRight();
					if( flag == true )
						return;
				}
			}
			checkBounds();
			if( flag == false ){
				for( j = 0; j < count; j++ ){
					bitMapper.y = bitMapper.y - 4;
					bitMapper.getBounds( tempBounds );
					checkBounds();
					if( flag == true )
						return;
				}
				count++;
				findOpeningRight();
				return;
			}
			else
				return;
		}
		
		private function findOpeningRight():void
		{
			var i:int;
			var j:int;
			
			for( i = 0; i < boundaries.length; i++ ){
				if( tempBounds.overlaps( boundaries[i] ) ){
					for( j = 0; j < count; j++ ){
						bitMapper.x = bitMapper.x + 4;
						bitMapper.getBounds( tempBounds );
						checkBounds();
						if( flag == true )
							return;
					}
					if( flag == true )
						return;
					count++;
					findOpeningUp();
					if( flag == true )
						return;
				}
			}
			checkBounds();
			if( flag == false ){
				for( j = 0; j < count; j++ ){
					bitMapper.x = bitMapper.x + 4;
					bitMapper.getBounds( tempBounds );
					checkBounds();
					if( flag == true )
						return;
				}
				count++;
				findOpeningUp();
				return;
			}
			else
				return;
		}
		
		private function findOpeningUp():void
		{
			var i:int;
			var j:int;
			
			for( i = 0; i < boundaries.length; i++ ){
				if( tempBounds.overlaps( boundaries[i] ) ){
					for( j = 0; j < count; j++ ){
						bitMapper.y = bitMapper.y + 4;
						bitMapper.getBounds( tempBounds );
						checkBounds();
						if( flag == true )
							return;
					}
					if( flag == true )
						return;
					count++;
					findOpeningLeft();
					if( flag == true )
						return;
				}
			}
			checkBounds();
			if( flag == false ){
				for( j = 0; j < count; j++ ){
					bitMapper.y = bitMapper.y + 4;
					bitMapper.getBounds( tempBounds );
					checkBounds();
					if( flag == true )
						return;
				}
				count++;
				findOpeningLeft();
				return;
			}
			else
				return;
		}
		
		*/
		/**
		 * This function preforms a brute force approach to checking if the current bounds intersect any previously placed bounds. 
		 */
		private function checkBounds():void
		{
			var i:int;
			
			/*
			if( count > 150 )
				increment = 15;
			else if( count > 100 )
				increment = 12;
			else if( count > 50 )
				increment = 8;
			*/
			if( count > 150 ){
				tooLong = true;
				flag = true;
				return;
			}
			/*
			if( !( screenBoundaries.containsBounds( tempBounds ) ) ){
				flag = false;
				return;
			}
			
			if( screenBoundaries.equals( tempBounds ) ){
				flag = false;
				return;
			}
			*/
			for( i = 0; i < boundaries.length; i++ )
				if( tempBounds.overlaps( boundaries[i] ) ){
					flag = false;
					return;
				}
	
			flag = true;						
		}
		
		private var count:Number = 1;
		private var flag:Boolean = false;
		private const bitMapper:BitmapText = new BitmapText();
		private const tempPoint:Point = new Point();
		private const tempBounds:Bounds2D = new Bounds2D(); // reusable temporary object	
		private static const randPoints:Object = new Object();
		private var boundaries:Array = new Array();
		private var screenBoundaries:IBounds2D = new Bounds2D();
		private var tooLong:Boolean = false;
		private var added:int = 0;
		private var orientation:int = 0;
		private var increment:int = 4;
	}
}
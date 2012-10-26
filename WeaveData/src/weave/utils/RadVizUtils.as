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

package weave.utils
{
	import flash.utils.Dictionary;
	
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IQualifiedKey;
	import weave.core.LinkableHashMap;
	import weave.radviz.MatrixEntry;

	public class RadVizUtils
	{
		/**
		 * Reorders columns in a LinkableHashMap using the ordered layout 
		 * @param columns A LinkableHashMap containing IAttributeColumns
		 * @param array An array of IAttributeColumns that are contained in columns
		 */		
		public static function reorderColumns(columns:LinkableHashMap, array:Array):void
		{
			var columnNames:Array = [];
			for each(var column:IAttributeColumn in array)
			{
				columnNames.push(columns.getName(column));
			}
			columns.setNameOrder(columnNames);
		}
				
		/**
		 * Checks for adjacency, assuming the columns in the array are placed in order around a circle
		 * @param column1 An IAttributeColumn in the circle
		 * @param column2 An IAttributeColumn in the circle
		 * @param array An array of IAttributeColumns
		 * @return true if the column parameters are adjacent in the circle 
		 */		
		public static function isAdjacent(column1:IAttributeColumn, column2:IAttributeColumn, array:Array):Boolean
		{
			if(array[0] == column1 && array[array.length-1] == column2) return true;
			if(array[0] == column2 && array[array.length-1] == column1) return true;
			
			for( var i:int = 0; i < array.length-1; i++ )
			{
				if(array[i] == column1 && array[i+1] == column2) return true ;
				if(array[i] == column2 && array[i+1] == column1) return true ;
			}
			
			return false ;
		}
		
		/**
		 * Calculates circular distance, assuming the indices in the array are placed in order around a circle
		 * @param index1 An array index
		 * @param index2 An array index
		 * @param length the length of the array
		 * @return Number of indices between two indices in an array
		 */		
		public static function getCircularDistance( index1:int, index2:int, length:int):Number
		{			
			var upper:int = Math.max(index1, index2);
			var lower:int = Math.min(index1, index2);
			var forward:int = upper - lower;
			var backward:int = length - upper + lower ;			
			return Math.min(forward, backward);
		}
		
		/** 
		 * @param recordKeys an array of IQualifiedKeys
		 * @param column1 first IAttributeColumn
		 * @param column2 second IAttributeColumn
		 * @param keyNumberMap key->column->value mapping to speed up computation
		 * @return The euclidean distance between the two column parameters 
		 */		
		public static function getEuclideanDistance( recordKeys:Array, column1:IAttributeColumn, column2:IAttributeColumn, keyNumberMap:Dictionary):Number
		{						
			var sum:Number = 0;
			var temp:Number = 0;
			for each( var key:IQualifiedKey in recordKeys)
			{
				if(!keyNumberMap[key])
					continue;
				temp = keyNumberMap[key][column1] - keyNumberMap[key][column2];
				if(temp <= Infinity)
					sum += temp * temp;				 
			}
			return Math.sqrt(sum); 
		}
		
		/** 
		 * @param recordKeys an array of IQualifiedKeys
		 * @param column1 first IAttributeColumn
		 * @param column2 second IAttributeColumn
		 * @param keyNumberMap recordKey->column->value mapping to speed up computation
		 * @return The cosine similarity between two parameter columns
		 */		
		public static function getCosineSimilarity( recordKeys:Array, column1:IAttributeColumn, column2:IAttributeColumn, keyNumberMap:Dictionary):Number
		{
			var dist:Number = 0 ;
			var sum:Number = 0;
			var recordKeyslength:uint = recordKeys.length ;
			var dist1:Number = 0; var dist2:Number = 0;
			for each( var key:IQualifiedKey in recordKeys)
			{		
				//this key is not in the column's keys but it exists in the plotter's keySet
				if(!keyNumberMap[key]) 
					continue;
				var value1:Number = keyNumberMap[key][column1];
				var value2:Number = keyNumberMap[key][column2];
				
				if( (value1 <= Infinity) && (value2 <= Infinity)) // alternative to !isNaN()
				{
					sum += Math.abs(value1 * value2);
					dist1 += (value1 * value1);
					dist2 += (value2 * value2);
				}
			}
			dist = 1 - sum/Math.sqrt(dist1*dist2);			
			return dist;
		}		
		
		/**
		 * Creates a dxd similarity matrix (where d is the length of the parameter array)
		 * @param array An array of IAttributeColumns
		 * @param keyNumberMap recordKey->column->value mapping to speed up computation
		 * @return A 2D Array representing a similarity matrix 		
		 */		
		public static function getGlobalSimilarityMatrix(array:Array, keyNumberMap:Dictionary):Array
		{			
			var similarityMatrix:Array = [];
			var length:uint = array.length ;
			
			if(!length) 
				return similarityMatrix;
			
			var keys:Array = (array[0] as IAttributeColumn).keys;
			
			for( var i:int = 0; i < length; i++ )
			{
				var tempRowArray:Array = []; 
				for( var j:int = 0; j < length; j++ )
				{
					// augmented similarity measure
					tempRowArray.push(getCosineSimilarity(keys, array[i], array[j], keyNumberMap));
				}
				similarityMatrix.push(tempRowArray) ;
				tempRowArray = null ;
			}				
			return similarityMatrix;
		}
		
		/**
		 * Creates a neighborhood matrix (where d is the length of the parameter array)
		 * @param array An array of IAttributeColumns
		 * @return A 2D Array representing a neighborhood matrix 		
		 */		
		public static function getNeighborhoodMatrix(array:Array):Array
		{			
			var length:uint = array.length ;
			var neighborhoodMatrix:Array = [];
			
			for( var i:int = 0; i < length; i++ )
			{
				var tempArray:Array = [] ;
				
				for( var j:int = 0; j < length; j++)
				{
					tempArray.push(1-(getCircularDistance(i,j,length)/(length/2)));
				}
				neighborhoodMatrix.push( tempArray );
				tempArray = null;			
			}
			return neighborhoodMatrix;
		}		
		
		/**
		 * Creates a sorted similarity matrix consisting of MatrixEntry objects,
		 * with the columns with the highest similarity first 
		 * @param array An array of IAttributeColumns
		 * @param keyNumberMap recordKey->column->value mapping to speed up computation
		 * @return A 1D array consisting of MatrixEntry objects
		 */		
		public static function getSortedSimilarityMatrix(array:Array, keyNumberMap:Dictionary):Array
		{
			var column:IAttributeColumn = array[0];
			var length:uint = array.length ;
			var similarityMatrix:Array = [];
			
			for( var i:int = 0; i < length ;i++ )
			{				
				for( var j:int = 0; j < i; j++ )
				{					
					var entry:MatrixEntry = new MatrixEntry();
					entry.similarity = getCosineSimilarity( column.keys, array[i], array[j], keyNumberMap );
					entry.dimension1 = array[i];
					entry.dimension2 = array[j];
					similarityMatrix.push(entry);
				}
			}	
			// sort by increasing similarity values 
			// we want the least similar dimensions at index 0
			AsyncSort.sortImmediately(similarityMatrix, sortEntries);
			
			return similarityMatrix;
		}
		
		/**
		 * This function sorts matrix entries based on their similarity values 
		 * @param entry1 First MatrixEntry (a)
		 * @param entry2 Second MatrixEntry (b)
		 * @return Sort value: 0: (a==b); -1:(a < b); 1:(a > b)
		 * 
		 */		
		private static function sortEntries( entry1:MatrixEntry, entry2:MatrixEntry):int
		{
			if( entry1.similarity > entry2.similarity) return 1;
			if( entry1.similarity < entry2.similarity) return -1;
			return 0;
		}
		
		/** 
		 * Calculates and returns the similarity measure
		 * @param similarityMatrix A 2D Array representing a similarity matrix
		 * @param neighborhoodMatrix A 2D Array representing a neighborhood matrix
		 * @return similarity measure for the parameter matrices
		 */		
		public static function getSimilarityMeasure(similarityMatrix:Array, neighborhoodMatrix:Array):Number
		{
			var sim:Number = 0 ; 
			var Nlength:uint = neighborhoodMatrix.length ;
			for( var i:int = 0; i < Nlength; i++ )
				for( var j:int = 0; j < Nlength; j++ )
					sim+=(similarityMatrix[i][j] * neighborhoodMatrix[i][j]);
			return sim; 
		}
		
		/**
		 * Searches for parameter IAttributeColumn inside the array parameter 
		 * @param column column to search for
		 * @param orderedColumns array of IAttributeColumns to search for column parameter
		 * @return the column if it is found, null if not
		 */		
		public static function searchForColumn(column:IAttributeColumn, orderedColumns:Array ):IAttributeColumn
		{
			for each (var col:IAttributeColumn in orderedColumns ) {
				if( col == column ) return col;
			}
			return null;
		}	
		
	}
}
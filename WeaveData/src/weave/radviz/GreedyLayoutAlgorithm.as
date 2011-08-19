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

package weave.radviz
{
	import weave.api.data.IAttributeColumn;
	import weave.core.LinkableHashMap;
	import weave.api.radviz.ILayoutAlgorithm;
	import weave.utils.RadVizUtils;
	
	/**
	 * An implementation of the GREEDY_LAYOUT dimensional ordering algorithm.
	 * This algorithm keeps adding nearest possible pairs of dimensions until all dimensions have been added.
	 * @author kmanohar 
	 */	
	public class GreedyLayoutAlgorithm extends AbstractLayoutAlgorithm implements ILayoutAlgorithm
	{
		public function GreedyLayoutAlgorithm()
		{
			super();
		}				
		
		private var similarityMatrix:Array ;
		private var neighborhoodMatrix:Array;
	
		override public function performLayout(columns:Array):void
		{
			similarityMatrix = RadVizUtils.getSortedSimilarityMatrix(columns, keyNumberMap);							
			
			orderedLayout.push(similarityMatrix[0].dimension1, similarityMatrix[0].dimension2);
			var columnBegin:IAttributeColumn = orderedLayout[0];
			var columnEnd:IAttributeColumn = orderedLayout[1];
			var column1:IAttributeColumn; 
			var column2:IAttributeColumn ;
			var i:int = 0; 
			
			while( orderedLayout.length < columns.length )
			{
				column1 = RadVizUtils.searchForColumn( similarityMatrix[i].dimension1, orderedLayout );
				column2 = RadVizUtils.searchForColumn( similarityMatrix[i].dimension2, orderedLayout );
				
				if(column1 && column2) 
				{
					i++; 
					continue;
				} 
				else if( column1 ) 
				{					
					column2 = similarityMatrix[i].dimension2;
					if( columnEnd == column1 ) 
					{
						orderedLayout.push(column2);
						columnEnd = column2;
					} 
					else if( columnBegin == column1 )
					{
						orderedLayout.unshift(column2);
						columnBegin = column2;
					} 
					else 
					{
						i++; 
						continue;
					}
				} 
				else if( column2 ) 
				{
					column1 = similarityMatrix[i].dimension1;
					if( columnEnd == column2 ) 
					{
						orderedLayout.push(column1);
						columnEnd = column1 ;
					} 
					else if (columnBegin == column2 ) 
					{
						orderedLayout.unshift(column1);
						columnBegin = column1 ;
					} 
					else 
					{
						i++; 
						continue ;
					}
				}
				else 
				{
					orderedLayout.push(similarityMatrix[i].dimension1, similarityMatrix[i].dimension2 );
					columnEnd = similarityMatrix[i].dimension2 ;
				}
				i++;
			}
			
			// debugging
			similarityMatrix = RadVizUtils.getGlobalSimilarityMatrix(orderedLayout, keyNumberMap);
			neighborhoodMatrix = RadVizUtils.getNeighborhoodMatrix(orderedLayout);
			trace( "greedy ", RadVizUtils.getSimilarityMeasure(similarityMatrix, neighborhoodMatrix));
		}
				
	}
}
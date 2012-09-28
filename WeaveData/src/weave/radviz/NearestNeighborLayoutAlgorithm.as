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
	 * An implementation of the NEAREST_NEIGHBOR dimensional ordering algorithm.
	 * This algorithm finds nearest neighbors of a dimension successfully until all dimensions have been added.
	 * @author kmanohar
	 */	
	public class NearestNeighborLayoutAlgorithm extends AbstractLayoutAlgorithm implements ILayoutAlgorithm
	{
		public function NearestNeighborLayoutAlgorithm()
		{
			super();
		}				
		
		private var similarityMatrix:Array ;
		private var neighborhoodMatrix:Array;
		
		override public function performLayout(columns:Array):void
		{
			similarityMatrix = RadVizUtils.getSortedSimilarityMatrix(columns, keyNumberMap);
			
			// push the two columns that are least similar into new column order
			orderedLayout.push(similarityMatrix[0].dimension1,similarityMatrix[0].dimension2);
			
			while( orderedLayout.length < columns.length)
			{
				var column:IAttributeColumn = searchForAnchorMatch( orderedLayout[orderedLayout.length-1], 
					orderedLayout[orderedLayout.length-2], orderedLayout);				
				orderedLayout.push(column);
			}
			
			// debugging
			similarityMatrix = RadVizUtils.getGlobalSimilarityMatrix(orderedLayout, keyNumberMap);
			neighborhoodMatrix = RadVizUtils.getNeighborhoodMatrix(orderedLayout);
			trace( "nearest neighbor ", RadVizUtils.getSimilarityMeasure(similarityMatrix,neighborhoodMatrix));
		}
			
		
		private function searchForAnchorMatch(matchTo:IAttributeColumn, ignore:IAttributeColumn, orderedColumns:Array):IAttributeColumn
		{
			loop:for( var i:int = 0; i < similarityMatrix.length; i++ )
			{
				if(similarityMatrix[i].dimension1 == matchTo || similarityMatrix[i].dimension2 == matchTo)
					if(similarityMatrix[i].dimension1 != ignore && similarityMatrix[i].dimension2 != ignore)
					{
						var matched:IAttributeColumn = (similarityMatrix[i].dimension1 == matchTo) ? similarityMatrix[i].dimension2 : similarityMatrix[i].dimension1;
						for each( var column:IAttributeColumn in orderedColumns)
						{
							if( column == matched ) continue loop; 
						}
						return matched;
					}
			}
			return null;
		}
	}
}
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
	 * An implementation of the incremental dimensional ordering algorithm.
	 * This algorithm successively adds dimensions to the best position in a search to define a suitable order. 
	 * @author kmanohar
	 */	
	public class IncrementalLayoutAlgorithm extends AbstractLayoutAlgorithm implements ILayoutAlgorithm
	{
		public function IncrementalLayoutAlgorithm()
		{
			super();
		}				
		
		private var similarityMatrix:Array ;
		private var neighborhoodMatrix:Array;
		
		override public function performLayout(columns:Array):void
		{
			var temp:Array ;
			var stored:Array ;
			var sim:Number ;
			var min:Number ;
			var column:IAttributeColumn;			
			
			similarityMatrix = RadVizUtils.getSortedSimilarityMatrix(columns, keyNumberMap);
			orderedLayout.push(similarityMatrix[0].dimension1, similarityMatrix[0].dimension2);
			
			for(var i:int = 0; i < columns.length; i++)
			{
				if( (columns[i] == orderedLayout[0]) || (columns[i] == orderedLayout[1]) )
					columns.splice(i,1);
			}
			
			while(columns.length)
			{
				column = columns.pop();
				
				for( i = 1; i < orderedLayout.length; i++ )
				{
					// store minimum ordering into stored array
					temp = [];
					for each( var col:IAttributeColumn in orderedLayout)
					{
						temp.push(col);
					}
					// insert dimension into new order
					temp.splice(i,0,column);
					
					similarityMatrix = RadVizUtils.getGlobalSimilarityMatrix(temp, keyNumberMap);				
					neighborhoodMatrix = RadVizUtils.getNeighborhoodMatrix(temp);
					sim = RadVizUtils.getSimilarityMeasure(similarityMatrix, neighborhoodMatrix);
					
					if( i == 1) min = sim;
					if( sim <= min ) //store current arrangement
					{		
						min = sim;
						stored = [];
						for each( var column1:IAttributeColumn in temp)
						{
							stored.push(column1);							
						}
					} 
					temp.splice(i,1); // remove inserted dimension in each iteration
				}
				orderedLayout = stored; //save best so far
			}
						
			trace( "incremental ", min);
		}
				
	}
}
/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

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
				orderedLayout = stored || []; //save best so far
			}
						
			trace( "incremental ", min);
		}
				
	}
}
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
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.api.radviz.ILayoutAlgorithm;
	import weave.utils.RadVizUtils;
	
	/**
	 * An implementation of the RANDOM_LAYOUT dimensional ordering algorithm.
	 * This algorithm randomly swaps dimensions for a certain number of iterations using a similarity measure.
	 * @author kmanohar
	 */	
	public class RandomLayoutAlgorithm extends AbstractLayoutAlgorithm implements ILayoutAlgorithm
	{
		public function RandomLayoutAlgorithm()
		{
			super();
		}
		
		public const iterations:LinkableNumber = registerLinkableChild(this, new LinkableNumber(100));
		
		private var similarityMatrix:Array ;
		private var neighborhoodMatrix:Array;
		
		override public function performLayout(columns:Array):void
		{
			similarityMatrix = RadVizUtils.getGlobalSimilarityMatrix(columns, keyNumberMap);				
			neighborhoodMatrix = RadVizUtils.getNeighborhoodMatrix(columns);
			
			var r1:Number; 
			var r2:Number;
			var prev:Number ;
			var sim:Number = 0 ;			

			var min:Number = prev = RadVizUtils.getSimilarityMeasure(similarityMatrix, neighborhoodMatrix);
			orderedLayout = columns; //store original layout for comparison
			
			for( var i:int = 0; i < iterations.value; i++ )
			{
				// get 2 random column numbers
				do{
					r1=Math.floor(Math.random()*100) % columns.length;	
					r2=Math.floor(Math.random()*100) % columns.length;	
				} while(r1 == r2);
				
				// swap columns r2 and r1
				var temp1:IAttributeColumn = new DynamicColumn() ; 
				var temp2:IAttributeColumn = new DynamicColumn() ;
				temp1 = columns[r1];
				columns.splice(r1, 1, columns[r2] );
				columns.splice(r2, 1, temp1);
				
				similarityMatrix = RadVizUtils.getGlobalSimilarityMatrix(columns, keyNumberMap);
				neighborhoodMatrix = RadVizUtils.getNeighborhoodMatrix(columns);
				if((sim = RadVizUtils.getSimilarityMeasure(similarityMatrix, neighborhoodMatrix)) <= min) 
				{	
					min = sim ;
					orderedLayout = columns;
				}
			}
			trace( "random swap", prev, min );			
		}
				
	}
}
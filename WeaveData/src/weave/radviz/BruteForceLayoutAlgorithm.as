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
	import weave.api.radviz.ILayoutAlgorithm;
	import weave.core.LinkableHashMap;
	import weave.utils.RadVizUtils;
	
	/**
	 * An implementation of the optimal layout algorithm that generates all permutations of the original anchor layout
	 * and returns the best one, if one exists
	 * @author kmanohar
	 */	
	public class BruteForceLayoutAlgorithm extends AbstractLayoutAlgorithm implements ILayoutAlgorithm
	{
		public function BruteForceLayoutAlgorithm()
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
						
			var fact:Number = factorial(columns.length);
			
			for( var i:int = 0; i < fact; i++)
			{
				var columnsCopy:Array = columns.slice();
				
				temp = getNthPermutation(columnsCopy, i);
				
				similarityMatrix = RadVizUtils.getGlobalSimilarityMatrix(temp, keyNumberMap);				
				neighborhoodMatrix = RadVizUtils.getNeighborhoodMatrix(temp);
				sim = RadVizUtils.getSimilarityMeasure(similarityMatrix, neighborhoodMatrix);
				
				if( i == 1) min = sim;
				if( sim <= min ) //store current arrangement
				{		
					min = sim;
					stored = temp;
				} 
			}
			orderedLayout = stored; //save best so far
			trace("optimal", min);

		}
		
		// get nth permutation of a set of symbols
		private function getNthPermutation(symbols:Array, n:uint):Array {
			return permutation(symbols, n_to_factoradic(n));
		}
		
		// convert n to factoradic notation
		private function n_to_factoradic(n:uint, p:uint=2):Array {
			if(n < p) return [n];
			var ret:Array = n_to_factoradic(n/p, p+1);
			ret.push(n % p);
			return ret;
		}
		
		// return nth permutation of set of symbols via factoradic
		private function permutation(symbols:Array, factoradic:Array):Array {
			factoradic.push(0);
			while(factoradic.length < symbols.length) factoradic.unshift(0);
			var ret:Array = [];
			while(factoradic.length) {
				var f:uint = factoradic.shift();
				ret.push(symbols[f]);
				symbols.splice(f, 1);
			}
			return ret;
		}
		
		private function factorial(n:Number):Number
		{
			var fact:Number = 1;
			if(!n) return fact;
			for(var i:Number = n; i > 1; i--)
			{
				fact *= i;
			}	
			return fact;
		}
				
	}
}
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

/**
 * Contains the properties that define a KMeans Clustering object
 * @spurushe
 * */
package weave.services.beans
{
	public class KMeansClusteringResult implements IDataMiningResult
	{
		private var _keys:Array = new Array();
		private const _identifier:String = "KMeansClustering";
		
		
		public var clusterVector:Array = new Array();//A vector of integers (from 1:k) indicating the cluster to which each point is allocated
		public var centers:Array = new Array();//A matrix of cluster centres. 
		public var totSumOfSquares:Number; //The total sum of squares
		public var withinSumOfSquares:Array;//Vector of within-cluster sum of squares, one component per cluster.
		public var totWithinSumOfSquares:Number;//Total within-cluster sum of squares, i.e., sum(withinSumOfSquares).
		public var betweenSumOfSquares:Number;//The between-cluster sum of squares, i.e. totSumOfSquares-totWithinSumOfSquares.
		public var clusterSize:Array;// The number of points in each cluster.
		
		
		public function KMeansClusteringResult(input:Array, token:Array)
		{
			 //to do: find better way of collecting centers
			this.clusterVector = input[0];
			_keys = token;
			var check:Array = new Array();
			check = input[1][0];
			this.centers.push(check);
			var check2:Array = input[1][1];this.centers.push(check2);
			var check3:Array = input[1][2];this.centers.push(check3);
			
			
			this.totSumOfSquares = input[2];
			this.withinSumOfSquares = input[3];
			this.totWithinSumOfSquares = input[4];
			this.betweenSumOfSquares = input[5];
			this.clusterSize = input[6];
			
		}
		
		

		public function get identifier(): String
		{
			return _identifier;
		}
		
		public function get keys():Array
		{
			return _keys;
		}
	}
}

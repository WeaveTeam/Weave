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
		public var clusterVector:Array;//A vector of integers (from 1:k) indicating the cluster to which each point is allocated
		public var centers:Array;//A matrix of cluster centres.
		private var _keys:Array;
		
		public function KMeansClusteringResult(servletResult:Array, keys:Array)
		{
			 //to do: find better way of collecting centers
			this.clusterVector = servletResult[0].value;
			this.centers = servletResult[1].value;
			this._keys = keys;
		}

		public function get identifier(): String
		{
			return "KMeansClustering";
		}
		
		public function get keys():Array
		{
			return _keys;
		}
	}
}

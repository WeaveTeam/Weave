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
 * Contains the properties that define a fuzzy KMeans Clustering object
 * @spurushe
 * */
package weave.services.beans
{
	public class FuzzyKMeansClusteringResult implements IDataMiningResult
	{
		//to do: dtermine which properties of the cluster result are important
		//for right now, only extracting cluster vector
		private const _identifier:String = "FuzzyKMeans";
		private var _keys:Array = new Array();
		public var clusteringVector:Array = new Array();
		
		public function FuzzyKMeansClusteringResult(input:Array, token:Array)
		{
			this.clusteringVector = input[0];
			_keys = token;
			
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

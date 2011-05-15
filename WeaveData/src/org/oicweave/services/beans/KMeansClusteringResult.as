// ActionScript file
package org.oicweave.services.beans
{
	import org.oicweave.data.AttributeColumns.NumberColumn;
	import org.oicweave.utils.VectorUtils;
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
	
	public class KMeansClusteringResult
	{
		public static function cast(object:Object):KMeansClusteringResult
		{
			return new KMeansClusteringResult(object);
		}
		
		public var clusterMeans:Array;
		public var clusterSize:Number;
		public var withinSumOfSquares:Number;
		public var clusterGroup:Array;
		public var RImageFilePath:String;
//		public var residual:NumberColumn = new NumberColumn(<attribute name="Residual values"/>);
		
		public function KMeansClusteringResult(kresult:Object)
		{
			this.clusterMeans = kresult.clusterMeans;
			this.clusterGroup = kresult.clusterGroup;
			this.withinSumOfSquares = kresult.withinSumOfSquares;
			this.clusterSize = kresult.clusterSize;
			this.RImageFilePath = kresult.RImageFilePath;
			
			
//			// convert arrays to vectors and store the residual values			
//			var keys:Vector.<String> = VectorUtils.copy(kresult.keys, new Vector.<String>());
//			var data:Vector.<Number> = VectorUtils.copy(kresult.residual, new Vector.<Number>());
//			//TODO: need residual.keyType
//			this.residual.updateRecords(keys, data, true);
		}
	}
}

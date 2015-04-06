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

/**
 * Contains the properties that define a KMeans Clustering object
 * @author spurushe
 */
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

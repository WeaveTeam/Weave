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
 * Contains the properties that define a PAM Clustering object
 * @author spurushe
 */
package weave.services.beans
{
	public class PartitionAroundMedoidsClusteringResult implements IDataMiningResult
	{
		private const _identifier:String = "PamClustering";
		private var _keys:Array = new Array();
		public var clusterVector:Array = new Array();//the clustering vector
		public var medoids:Array = new Array();//the medoids or representative objects of the clusters. 
		
		
		
		public function PartitionAroundMedoidsClusteringResult(input:Array, token:Array)
		{
			 //to do: find which propeeties of the result are necessary
			//var tempArray:Array = input[0];
			_keys = token;
			this.clusterVector = input[0];
			//this.clusterVector = tempArray[2];//cluster vector
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

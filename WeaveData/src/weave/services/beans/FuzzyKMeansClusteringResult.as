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
 * Contains the properties that define a fuzzy KMeans Clustering object
 * @author spurushe
 */
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

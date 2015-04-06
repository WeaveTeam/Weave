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

package weave.services.beans
{
	import weave.data.AttributeColumns.NumberColumn;
	import weave.utils.VectorUtils;
	
	public class HierarchicalClusteringResult
	{
		public static function cast(object:Object):HierarchicalClusteringResult
		{
			return new HierarchicalClusteringResult(object);
		}

		public var clusterSequence:Array;
		public var clusterMethod:String;
		//public var clusterLabels:String;
		public var clusterDistanceMeasure:String;
		
		public function HierarchicalClusteringResult(hresult:Object)
		{
			this.clusterSequence = hresult.clusterSequence;
			this.clusterMethod = hresult.clusterMethod;
			//this.clusterLabels = hresult.clusterLabels;
			this.clusterDistanceMeasure = hresult.clusterDistanceMeasure;			
		}
	}
}
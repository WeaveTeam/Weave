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
	public class DensityBasedClusteringResult
	{
		public static function cast(object:Object):DensityBasedClusteringResult
		{
			return new DensityBasedClusteringResult(object);
		}

		public var clusterGroup:Number;
		public var pointStatus:String;
		public var epsRadius:Number;
		public var minimumPoints:Number;
		
		public function DensityBasedClusteringResult(dbresult:Object)
		{
			this.clusterGroup = dbresult.clusterGroup;
			this.pointStatus = dbresult.pointStatus;
			this.epsRadius = dbresult.epsRadius;
			this.minimumPoints = dbresult.minimumPoints;
		}
	}
}
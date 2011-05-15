// ActionScript file
package org.oicweave.services.beans
{
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
// ActionScript file
package weave.services.beans
{
	import weave.data.AttributeColumns.NumberColumn;
	import weave.utils.VectorUtils;
	
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
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

package weave.visualization.plotters
{
	import flash.sampler.getLexicalScopes;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.primitives.IBounds2D;
	import weave.api.setSessionState;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.data.KeySets.SortedKeySet;
	import weave.data.QKeyManager;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;

	/**
	 * This plotter is for drawing text labels on the map, corresponding to a geometry column.
	 * 
	 * @author adufilie
	 */
	public class GeometryLabelPlotter extends TextGlyphPlotter
	{
		public function GeometryLabelPlotter()
		{
			registerSpatialProperty(geometryColumn);
			
			// hide dataX,dataY because they don't need to be shown in the session state.
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this, dataX);
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this, dataY);
			hideOverlappingText.value = true;

			// set up x,y columns to be derived from the geometry column
			linkSessionState(geometryColumn, dataX.requestLocalObject(ReprojectedGeometryColumn, true));
			linkSessionState(geometryColumn, dataY.requestLocalObject(ReprojectedGeometryColumn, true));
			
			_sortColumnCompare = SortedKeySet.generateCompareFunction([sortColumn, text]);
			_filteredKeySet.setColumnKeySources([geometryColumn], null, keyCompare);
		}
		
		public const geometryColumn:ReprojectedGeometryColumn = newSpatialProperty(ReprojectedGeometryColumn);
		
		private var _sortColumnCompare:Function;
		
		/**
		 * This function compares geometry record keys according to geometry bounding box area
		 * @param key1 First record key ("a")
		 * @param key2 Second record key ("b")
		 * @return Compare value: 0: (a == b), -1: (a &lt; b), 1: (a &gt; b)
		 */		
		public function keyCompare(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			try
			{
				// get the first geom in each list
				var geom1:GeneralizedGeometry = (geometryColumn.getValueFromKey(key1) as Array)[0] as GeneralizedGeometry;
				var geom2:GeneralizedGeometry = (geometryColumn.getValueFromKey(key2) as Array)[0] as GeneralizedGeometry;
				
				// sort descending by bounding box area
				var result:int = -ObjectUtil.numericCompare(geom1.bounds.getArea(), geom2.bounds.getArea());
				if (result != 0)
					return result;
			}
			catch (e:Error)
			{
				// we don't care if this fails
			}
			
			// revert to default compare
			return _sortColumnCompare(key1, key2);
		}
		
		// reusable temporary objects
		private var tempBounds1:IBounds2D = new Bounds2D();
		private var tempBounds2:IBounds2D = new Bounds2D();
		
		// backwards compatibility 0.9.6
		[Deprecated(replacement="geometryColumn")] public function set geometry(value:Object):void
		{
			setSessionState(geometryColumn.internalDynamicColumn, value);
		}
	}
}

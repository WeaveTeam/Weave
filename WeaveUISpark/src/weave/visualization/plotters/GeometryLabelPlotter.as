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
	import mx.utils.ObjectUtil;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.primitives.IBounds2D;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotter;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.data.KeySets.SortedKeySet;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;

	/**
	 * This plotter is for drawing text labels on the map, corresponding to a geometry column.
	 * 
	 * @author adufilie
	 */
	public class GeometryLabelPlotter extends TextGlyphPlotter
	{
		WeaveAPI.ClassRegistry.registerImplementation(IPlotter, GeometryLabelPlotter, "Geometry labels");

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
			
			_sortCopyKeys = SortedKeySet.generateSortCopyFunction([getGeometryArea, sortColumn, text], [-1, 1, 1]);
			_filteredKeySet.setColumnKeySources([geometryColumn, sortColumn, text], null, _sortCopyKeys);
		}
		
		public const geometryColumn:ReprojectedGeometryColumn = newSpatialProperty(ReprojectedGeometryColumn);
		
		private var _sortCopyKeys:Function;
		
		private function getGeometryArea(key:IQualifiedKey):Number
		{
			try
			{
				var geom:GeneralizedGeometry = geometryColumn.getValueFromKey(key, Array)[0] as GeneralizedGeometry;
				return geom.bounds.getArea();
			}
			catch (e:Error)
			{
				// we don't care if this fails
			}
			return NaN;
		}
		
		// backwards compatibility 0.9.6
		[Deprecated(replacement="geometryColumn")] public function set geometry(value:Object):void
		{
			setSessionState(geometryColumn.internalDynamicColumn, value);
		}
	}
}

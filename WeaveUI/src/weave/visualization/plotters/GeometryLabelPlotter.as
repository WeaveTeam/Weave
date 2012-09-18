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
	
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.primitives.IBounds2D;
	import weave.api.setSessionState;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotterWithKeyCompare;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;

	/**
	 * This plotter is for drawing text labels on the map, corresponding to a geometry column.
	 * 
	 * @author adufilie
	 */
	public class GeometryLabelPlotter extends TextGlyphPlotter implements IPlotterWithKeyCompare
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
		}
		
		public const geometryColumn:ReprojectedGeometryColumn = newSpatialProperty(ReprojectedGeometryColumn);
		
		/**
		 * This function compares geometry record keys according to geometry bounding box area
		 * @param key1 First record key ("a")
		 * @param key2 Second record key ("b")
		 * @return Compare value: 0: (a == b), -1: (a < b), 1: (a > b)
		 */		
		override public function keyCompare(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			try
			{
				// get the first geom in each list
				var geom1:GeneralizedGeometry = (geometryColumn.getValueFromKey(key1) as Array)[0] as GeneralizedGeometry;
				var geom2:GeneralizedGeometry = (geometryColumn.getValueFromKey(key2) as Array)[0] as GeneralizedGeometry;
				
				// sort descending by bounding box area
				return -ObjectUtil.numericCompare(geom1.bounds.getArea(), geom2.bounds.getArea())
					|| super.keyCompare(key1, key2);
			}
			catch (e:Error)
			{
				// we don't care if this fails
			}
			return super.keyCompare(key1, key2);
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

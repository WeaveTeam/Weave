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
	import flash.display.BitmapData;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.core.SessionManager;
	import weave.core.weave_internal;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.primitives.Bounds2D;
	import weave.primitives.GeneralizedGeometry;

	use namespace weave_internal;

	/**
	 * This plotter is for drawing text labels on the map, corresponding to a geometry column.
	 * 
	 * @author adufilie
	 */
	public class GeometryLabelPlotter extends TextGlyphPlotter
	{
		public function GeometryLabelPlotter()
		{
			init();
		}
		private function init():void
		{
			registerSpatialProperty(geometryColumn);
			
			// hide dataX,dataY because they don't need to be shown in the session state.
			(WeaveAPI.SessionManager as SessionManager).removeLinkableChildFromSessionState(this, dataX);
			(WeaveAPI.SessionManager as SessionManager).removeLinkableChildFromSessionState(this, dataY);
			hideOverlappingText.value = true;

			// set up x,y columns to be derived from the geometry column
			var xeq:EquationColumn = dataX.requestLocalObject(EquationColumn, true);
			var yeq:EquationColumn = dataY.requestLocalObject(EquationColumn, true);
			xeq.equation.value = 'getValue(geom)[0].bounds.getXCenter()';
			yeq.equation.value = 'getValue(geom)[0].bounds.getYCenter()';
			xeq.equation.lock();
			yeq.equation.lock();
			linkSessionState(geometryColumn, xeq.requestVariable("geom", ReprojectedGeometryColumn, true));
			linkSessionState(geometryColumn, yeq.requestVariable("geom", ReprojectedGeometryColumn, true));
		}
		
		public const geometryColumn:ReprojectedGeometryColumn = newSpatialProperty(ReprojectedGeometryColumn);
		
		override public function drawPlot(recordKeys:Array, dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// sort records by geometry bounds area before drawing them in the TextGlyphPlotter
			recordKeys.sort(sortBySize, Array.DESCENDING);
			
			super.drawPlot(recordKeys, dataBounds, screenBounds, destination);
		}
		
		/**
		 * This function sorts geometry record keys according to geometry bounding box size
		 * @param key1 First record key ("a")
		 * @param key2 Second record key ("b")
		 * @return Sort value: 0: (a == b), -1: (a < b), 1: (a > b)
		 */		
		private function sortBySize(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			try
			{
				// get the first geom in each list
				var geom1:GeneralizedGeometry = (geometryColumn.getValueFromKey(key1) as Array)[0] as GeneralizedGeometry;
				var geom2:GeneralizedGeometry = (geometryColumn.getValueFromKey(key2) as Array)[0] as GeneralizedGeometry;
				
				return ObjectUtil.numericCompare(geom1.bounds.getArea(), geom2.bounds.getArea())
					|| ObjectUtil.compare(key1, key2);
			}
			catch (e:Error)
			{
				// we don't care if this fails
			}
			return ObjectUtil.compare(key1, key2);
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

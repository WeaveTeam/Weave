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

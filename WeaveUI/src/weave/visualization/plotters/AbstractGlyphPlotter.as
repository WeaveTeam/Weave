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
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.KeySets.FilteredKeySet;
	import weave.primitives.GeneralizedGeometry;
	
	/**
	 * AbstractGlyphPlotter
	 * A glyph represents a point of data at an X and Y coordinate.
	 * 
	 * @author adufilie
	 */
	public class AbstractGlyphPlotter extends AbstractPlotter
	{
		public function AbstractGlyphPlotter()
		{
			init();
		}
		private function init():void
		{
			clipDrawing = false;
			setKeySource(dataX);
			
			// filter x and y columns so background data bounds will be correct
			filteredDataX.filter.requestLocalObject(FilteredKeySet, true);
			filteredDataY.filter.requestLocalObject(FilteredKeySet, true);
			
			registerSpatialProperty(dataX);
			registerSpatialProperty(dataY);
			
			linkSessionState(_filteredKeySet.keyFilter, filteredDataX.filter);
			linkSessionState(_filteredKeySet.keyFilter, filteredDataY.filter);
		}
		
		protected const filteredDataX:FilteredColumn = newDisposableChild(this, FilteredColumn);
		protected const filteredDataY:FilteredColumn = newDisposableChild(this, FilteredColumn);
		public const zoomToSubset:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		
		public function get dataX():DynamicColumn
		{
			return filteredDataX.internalDynamicColumn;
		}
		public function get dataY():DynamicColumn
		{
			return filteredDataY.internalDynamicColumn;
		}
		
		protected function getXFromRecordKey(recordKey:IQualifiedKey):Number
		{
			if (dataX.getMetadata(AttributeColumnMetadata.DATA_TYPE) == DataTypes.GEOMETRY)
			{
				var geoms:Array = dataX.getValueFromKey(recordKey) as Array;
				var geom:GeneralizedGeometry;
				if (geoms && geoms.length)
					geom = geoms[0] as GeneralizedGeometry;
				if (geom)
					return geom.bounds.getXCenter();
			}
			return dataX.getValueFromKey(recordKey, Number);
		}
		
		protected function getYFromRecordKey(recordKey:IQualifiedKey):Number
		{
			if (dataY.getMetadata(AttributeColumnMetadata.DATA_TYPE) == DataTypes.GEOMETRY)
			{
				var geoms:Array = dataY.getValueFromKey(recordKey) as Array;
				var geom:GeneralizedGeometry;
				if (geoms && geoms.length)
					geom = geoms[0] as GeneralizedGeometry;
				if (geom)
					return geom.bounds.getYCenter();
			}
			return dataY.getValueFromKey(recordKey, Number);
		}
		
		/**
		 * The data bounds for a glyph has width and height equal to zero.
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			var x:Number = getXFromRecordKey(recordKey);
			var y:Number = getYFromRecordKey(recordKey);
			
			var bounds:IBounds2D = getReusableBounds();
			bounds.setCenteredRectangle(x, y, 0, 0);
			if (isNaN(x))
				bounds.setXRange(-Infinity, Infinity);
			if (isNaN(y))
				bounds.setYRange(-Infinity, Infinity);
			return [bounds];
		}

		/**
		 * This function returns a Bounds2D object set to the data bounds associated with the background.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getBackgroundDataBounds():IBounds2D
		{
			// use filtered data so data bounds will not include points that have been filtered out.
			var bounds:IBounds2D = getReusableBounds();
			if (!zoomToSubset.value)
			{
				bounds.setBounds(
					WeaveAPI.StatisticsCache.getMin(filteredDataX),
					WeaveAPI.StatisticsCache.getMin(filteredDataY),
					WeaveAPI.StatisticsCache.getMax(filteredDataX),
					WeaveAPI.StatisticsCache.getMax(filteredDataY)
				);
			}
			return bounds;
		}
	}
}

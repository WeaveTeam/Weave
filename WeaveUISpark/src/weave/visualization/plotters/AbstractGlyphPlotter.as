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
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnStatistics;
	import weave.api.data.IKeySet;
	import weave.api.data.IProjector;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.KeySets.FilteredKeySet;
	import weave.data.KeySets.KeySetUnion;
	import weave.primitives.GeneralizedGeometry;
	import weave.utils.ColumnUtils;
	
	/**
	 * A glyph represents a point of data at an X and Y coordinate.
	 * 
	 * @author adufilie
	 */
	public class AbstractGlyphPlotter extends AbstractPlotter
	{
		public function AbstractGlyphPlotter()
		{
			clipDrawing = false;
			
			setColumnKeySources([dataX, dataY]);
			
			// filter x and y columns so background data bounds will be correct
			filteredDataX.filter.requestLocalObject(FilteredKeySet, true);
			filteredDataY.filter.requestLocalObject(FilteredKeySet, true);
			
			registerSpatialProperty(dataX, updateProjector);
			registerSpatialProperty(dataY, updateProjector);
			
			linkSessionState(_filteredKeySet.keyFilter, filteredDataX.filter);
			linkSessionState(_filteredKeySet.keyFilter, filteredDataY.filter);
		}
		
		private var _keySetUnion:KeySetUnion = newDisposableChild(this, KeySetUnion);
		
		protected const filteredDataX:FilteredColumn = newDisposableChild(this, FilteredColumn);
		protected const filteredDataY:FilteredColumn = newDisposableChild(this, FilteredColumn);
		public const zoomToSubset:LinkableBoolean = registerSpatialProperty(new LinkableBoolean(false));
		
		protected const statsX:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(filteredDataX));
		protected const statsY:IColumnStatistics = registerLinkableChild(this, WeaveAPI.StatisticsCache.getColumnStatistics(filteredDataY));
		
		public function hack_setSingleKeySource(keySet:IKeySet):void
		{
			setSingleKeySource(keySet);
		}
		
		public function get dataX():DynamicColumn
		{
			return filteredDataX.internalDynamicColumn;
		}
		public function get dataY():DynamicColumn
		{
			return filteredDataY.internalDynamicColumn;
		}
		
		public const sourceProjection:LinkableString = newSpatialProperty(LinkableString, updateProjector);
		public const destinationProjection:LinkableString = newSpatialProperty(LinkableString, updateProjector);
		
		protected const tempPoint:Point = new Point();
		private var _projector:IProjector;
		private var _xCoordCache:Dictionary;
		private var _yCoordCache:Dictionary;
		
		/**
		 * This gets called whenever any of the following change: dataX, dataY, sourceProjection, destinationProjection
		 */		
		private function updateProjector():void
		{
			_xCoordCache = null;
			_yCoordCache = null;
			
			var sourceSRS:String = sourceProjection.value;
			var destinationSRS:String = destinationProjection.value;
			
			// if sourceSRS is missing and both are geom columns...
			if (!sourceSRS &&
				dataX.getMetadata(AttributeColumnMetadata.DATA_TYPE) == DataTypes.GEOMETRY &&
				dataY.getMetadata(AttributeColumnMetadata.DATA_TYPE) == DataTypes.GEOMETRY)
			{
				// if both X and Y projections are the same...
				var projX:String = dataX.getMetadata(AttributeColumnMetadata.PROJECTION);
				var projY:String = dataY.getMetadata(AttributeColumnMetadata.PROJECTION);
				if (projX == projY)
					sourceSRS = projX;
			}
			
			if (sourceSRS && destinationSRS)
				_projector = WeaveAPI.ProjectionManager.getProjector(sourceSRS, destinationSRS);
			else
				_projector = null;
		}
		
		protected function getCoordsFromRecordKey(recordKey:IQualifiedKey, output:Point):void
		{
			if (_xCoordCache && _xCoordCache[recordKey] !== undefined)
			{
				output.x = _xCoordCache[recordKey];
				output.y = _yCoordCache[recordKey];
				return;
			}
			
			if (!_xCoordCache)
				_xCoordCache = new Dictionary(true);
			if (!_yCoordCache)
				_yCoordCache = new Dictionary(true);
			
			for (var i:int = 0; i < 2; i++)
			{
				var result:Number = NaN;
				var dataCol:IAttributeColumn = i == 0 ? dataX : dataY;
				if (dataCol.getMetadata(AttributeColumnMetadata.DATA_TYPE) == DataTypes.GEOMETRY)
				{
					var geoms:Array = dataCol.getValueFromKey(recordKey) as Array;
					var geom:GeneralizedGeometry;
					if (geoms && geoms.length)
						geom = geoms[0] as GeneralizedGeometry;
					if (geom)
					{
						if (i == 0)
							result = geom.bounds.getXCenter();
						else
							result = geom.bounds.getYCenter();
					}
				}
				else
				{
					result = dataCol.getValueFromKey(recordKey, Number);
				}
				
				if (i == 0)
				{
					output.x = result;
					_xCoordCache[recordKey] = result;
				}
				else
				{
					output.y = result;
					_yCoordCache[recordKey] = result;
				}
			}
			if (_projector)
				_projector.reproject(output);
		}
		
		/**
		 * The data bounds for a glyph has width and height equal to zero.
		 * This function returns a Bounds2D object set to the data bounds associated with the given record key.
		 * @param key The key of a data record.
		 * @param outputDataBounds A Bounds2D object to store the result in.
		 */
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey):Array
		{
			getCoordsFromRecordKey(recordKey, tempPoint);
			
			var bounds:IBounds2D = getReusableBounds();
			bounds.setCenteredRectangle(tempPoint.x, tempPoint.y, 0, 0);
			if (isNaN(tempPoint.x))
				bounds.setXRange(-Infinity, Infinity);
			if (isNaN(tempPoint.y))
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
					statsX.getMin(),
					statsY.getMin(),
					statsX.getMax(),
					statsY.getMax()
				);
			}
			return bounds;
		}
	}
}

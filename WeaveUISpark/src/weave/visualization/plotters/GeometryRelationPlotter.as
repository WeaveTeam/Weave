package weave.visualization.plotters
{
	import flash.geom.Point;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	
	import weave.api.WeaveAPI;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IProjector;
	import weave.api.data.IQualifiedKey;
	import weave.api.detectLinkableObjectChange;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.primitives.IBounds2D;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.ReprojectedGeometryColumn;
	import weave.primitives.GeneralizedGeometry;
	import weave.utils.BitmapText;

	// Refer to Feature #924 for detail description
	public class GeometryRelationPlotter extends AbstractPlotter
	{
		WeaveAPI.registerImplementation(IPlotter, GeometryRelationPlotter, "Geometry relations");

		public function GeometryRelationPlotter()
		{
			registerSpatialProperty(geometryColumn);
			
			// set up x,y columns to be derived from the geometry column
			linkSessionState(geometryColumn, dataX.requestLocalObject(ReprojectedGeometryColumn, true));
			linkSessionState(geometryColumn, dataY.requestLocalObject(ReprojectedGeometryColumn, true));
			setColumnKeySources([geometryColumn]);
		}
		// Need to set columns dataType in AdminConsole
		public const geometryColumn:ReprojectedGeometryColumn = newSpatialProperty(ReprojectedGeometryColumn);
		public const sourceKeyColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const destinationKeyColumn:DynamicColumn = newSpatialProperty(DynamicColumn);
		public const valueColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		public const lineWidth:LinkableNumber = registerLinkableChild(this, new LinkableNumber(5));
		public const posLineColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0xFF0000));
		public const negLineColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x0000FF));
		public const showValue:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const fontSize:LinkableNumber = registerLinkableChild(this, new LinkableNumber(11));
		public const fontColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		
		protected const filteredDataX:FilteredColumn = newDisposableChild(this, FilteredColumn);
		protected const filteredDataY:FilteredColumn = newDisposableChild(this, FilteredColumn);
		
		public function get dataX():DynamicColumn
		{
			return filteredDataX.internalDynamicColumn;
		}
		public function get dataY():DynamicColumn
		{
			return filteredDataY.internalDynamicColumn;
		}
		
		public const sourceProjection:LinkableString = newSpatialProperty(LinkableString);
		public const destinationProjection:LinkableString = newSpatialProperty(LinkableString);
		
		private const bitmapText:BitmapText = new BitmapText();
		protected const tempSourcePoint:Point = new Point();
		protected const tempDestinationPoint:Point = new Point();
		protected const tempGeometryPoint:Point = new Point();
		private var _projector:IProjector;
		private var _xCoordCache:Dictionary;
		private var _yCoordCache:Dictionary;
		
		/**
		 * This gets called whenever any of the following change: dataX, dataY, sourceProjection, destinationProjection
		 */		
		private function updateProjector():void
		{
			_xCoordCache = new Dictionary(true);
			_yCoordCache = new Dictionary(true);
			
			var sourceSRS:String = sourceProjection.value;
			var destinationSRS:String = destinationProjection.value;
			
			// if sourceSRS is missing and both X and Y projections are the same, use that.
			if (!sourceSRS)
			{
				var projX:String = dataX.getMetadata(ColumnMetadata.PROJECTION);
				var projY:String = dataY.getMetadata(ColumnMetadata.PROJECTION);
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
			if (detectLinkableObjectChange(updateProjector, dataX, dataY, sourceProjection, destinationProjection))
				updateProjector();
			
			if (_xCoordCache[recordKey] !== undefined)
			{
				output.x = _xCoordCache[recordKey];
				output.y = _yCoordCache[recordKey];
				return;
			}
			
			for (var i:int = 0; i < 2; i++)
			{
				var result:Number = NaN;
				var dataCol:IAttributeColumn = i == 0 ? dataX : dataY;
				if (dataCol.getMetadata(ColumnMetadata.DATA_TYPE) == DataTypes.GEOMETRY)
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
			{
				_projector.reproject(output);
				_xCoordCache[recordKey] = output.x;
				_yCoordCache[recordKey] = output.y;
			}
		}
		
		override public function getDataBoundsFromRecordKey(recordKey:IQualifiedKey, output:Array):void
		{
			getCoordsFromRecordKey(recordKey, tempGeometryPoint);
			var bounds:IBounds2D = initBoundsArray(output);
			bounds.setCenteredRectangle(tempGeometryPoint.x, tempGeometryPoint.y, 0, 0);
			if (isNaN(tempGeometryPoint.x))
				bounds.setXRange(-Infinity, Infinity);
			if (isNaN(tempSourcePoint.y))
				bounds.setYRange(-Infinity, Infinity);
		}
		
		override public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			var i:int;
			// Make sure all four column are populated
			if (sourceKeyColumn.keys.length == 0 || destinationKeyColumn.keys.length == 0 || valueColumn.keys.length == 0 || geometryColumn.keys.length == 0) return 1;
			
			// this template from AbstractPlotter will draw one record per iteration
			if (task.iteration < task.recordKeys.length)
			{
				//------------------------
				// draw one record
				var geoKey:IQualifiedKey = task.recordKeys[task.iteration] as IQualifiedKey;
				tempShape.graphics.clear();

				getCoordsFromRecordKey(geoKey, tempSourcePoint); // Get source coordinate
				task.dataBounds.projectPointTo(tempSourcePoint, task.screenBounds);

				// Loop over the data table to find all the row keys with this source key value
				var tempRowKeys:Array = new Array();
				for (i = 0; i < sourceKeyColumn.keys.length; i++)
				{
					if (sourceKeyColumn.getValueFromKey(sourceKeyColumn.keys[i], IQualifiedKey) == geoKey)
						tempRowKeys.push(sourceKeyColumn.keys[i]);
				}
				
				// Draw lines from source to destinations
				var max:Number; // Absoulte max used for normalization
				if (WeaveAPI.StatisticsCache.getColumnStatistics(valueColumn).getMax() > -WeaveAPI.StatisticsCache.getColumnStatistics(valueColumn).getMin())
					max = WeaveAPI.StatisticsCache.getColumnStatistics(valueColumn).getMax();
				else
					max = WeaveAPI.StatisticsCache.getColumnStatistics(valueColumn).getMin();
				
				// Value normalization
				for (i = 0; i < tempRowKeys.length; i++)
				{
					if (valueColumn.getValueFromKey(tempRowKeys[i], Number) > 0)
					{
						tempShape.graphics.lineStyle(Math.round((valueColumn.getValueFromKey(tempRowKeys[i], Number) / max) * lineWidth.value), posLineColor.value);
					}
					else
					{
						tempShape.graphics.lineStyle(-Math.round((valueColumn.getValueFromKey(tempRowKeys[i], Number) / max) * lineWidth.value), negLineColor.value);
					}
					
					tempShape.graphics.moveTo(tempSourcePoint.x, tempSourcePoint.y);
					getCoordsFromRecordKey(destinationKeyColumn.getValueFromKey(tempRowKeys[i], IQualifiedKey), tempDestinationPoint); // Get destionation coordinate
					task.dataBounds.projectPointTo(tempDestinationPoint, task.screenBounds);
					tempShape.graphics.lineTo(tempDestinationPoint.x, tempDestinationPoint.y);
				}
								
				task.buffer.draw(tempShape);
				
				if (showValue.value)
				{
					for (i = 0; i < tempRowKeys.length; i++)
					{
						getCoordsFromRecordKey(destinationKeyColumn.getValueFromKey(tempRowKeys[i], IQualifiedKey), tempDestinationPoint); // Get destionation coordinate
						task.dataBounds.projectPointTo(tempDestinationPoint, task.screenBounds);
						
						bitmapText.x = Math.round((tempSourcePoint.x + tempDestinationPoint.x) / 2);
						bitmapText.y = Math.round((tempSourcePoint.y + tempDestinationPoint.y) / 2);
						bitmapText.text = valueColumn.getValueFromKey(tempRowKeys[i], Number);
						bitmapText.verticalAlign = BitmapText.VERTICAL_ALIGN_MIDDLE;
						bitmapText.horizontalAlign = BitmapText.HORIZONTAL_ALIGN_CENTER;
						
						var f:TextFormat = bitmapText.textFormat;
						f.size = fontSize.value;
						f.color = fontColor.value;
						
						bitmapText.draw(task.buffer);
					}
				}
				
				// report progress
				return task.iteration / task.recordKeys.length;
			}
			
			// report progress
			return 1; // avoids division by zero in case task.recordKeys.length == 0
		}
	}
}
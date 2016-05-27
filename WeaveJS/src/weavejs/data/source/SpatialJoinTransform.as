package weavejs.data.source
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.data.ISelectableAttributes;
	import weavejs.core.LinkableString;
	import weavejs.data.ColumnUtils;
	import weavejs.data.column.DynamicColumn;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.column.StringColumn;
	import weavejs.util.ArrayUtils;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;

	public class SpatialJoinTransform extends AbstractDataSource implements ISelectableAttributes
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, SpatialJoinTransform, "Spatial Join Transform");

		public const geometryColumn:DynamicColumn = Weave.linkableChild(this, DynamicColumn);
		public const xColumn:DynamicColumn = Weave.linkableChild(this, DynamicColumn);
		public const yColumn:DynamicColumn = Weave.linkableChild(this, DynamicColumn);
		public const pointProjection:LinkableString = Weave.linkableChild(this, LinkableString);
		private var _source:Object; /* This is a ol.source.Vector */
		private var _parser:Object; /* This is an ol.format.GeoJSON */

		/* Output dataType is determined by the geometryColumn input. */
		/* Output keyType is determined by the xColumn/yColumn input. */

		public function get selectableAttributes():/*/Map<string, (weavejs.api.data.IColumnWrapper|weavejs.api.core.ILinkableHashMap)>/*/Object
		{
			return new JS.Map()
				.set("Join Geometry", geometryColumn)
				.set("Datapoint X", xColumn)
				.set("Datapoint Y", yColumn);
		}

		public function SpatialJoinTransform()
		{
			_source = new StandardLib.ol.source.Vector()
			_parser = new StandardLib.ol.format.GeoJSON();
		}

		override protected function initialize(forceRefresh:Boolean = false):void
		{
			super.initialize(true);
		}

		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();

			var geomKeys:Array = geometryColumn.keys;
			var rawGeometries:Array = weavejs.data.ColumnUtils.getGeoJsonGeometries(geometryColumn, geometryColumn.keys);
			var key:IQualifiedKey;
			var feature:*;

			_source.clear();

			for (var idx:int = 0; idx < geomKeys.length; idx++)
			{
				var rawGeom:* = rawGeometries[idx];
				key = geomKeys[idx] as IQualifiedKey;

				var geometry:* = _parser.readGeometry(rawGeom,
					{
						dataProjection: StandardLib.ol.proj.get(geometryColumn.getMetadata(ColumnMetadata.PROJECTION)),  
						featureProjection: StandardLib.ol.proj.get(pointProjection.value) 
					}
				);

				if (geometry.getExtent().some(StandardLib.lodash.isNaN))
				{
					JS.error("Dropping feature", key, "due to containing NaN coordinates. Possibly misconfigured projection?");
					continue;
				}

				feature = new StandardLib.ol.Feature({id: key, geometry: geometry});
				_source.addFeature(feature);
			}

			var keys:Array = [];
			var data:Array = [];
			for each (key in ArrayUtils.union(xColumn.keys, yColumn.keys))
			{
				var x:Number = xColumn.getValueFromKey(key, Number);
				var y:Number = yColumn.getValueFromKey(key, Number);

				var features:Array = _source.getFeaturesAtCoordinate([x,y]);

				for each (feature in features)
				{
					var featureKey:* = feature.getId();
					keys.push(key);
					data.push(featureKey.localName);
				}
			}

			var column:StringColumn = new StringColumn();
			column.setRecords(keys, data);
			proxyColumn.setInternalColumn(column);
		}
	}
}

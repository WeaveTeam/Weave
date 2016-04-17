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

package weavejs.data.source
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IDataSource_File;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.core.LinkableFile;
	import weavejs.core.LinkableString;
	import weavejs.data.column.GeometryColumn;
	import weavejs.data.column.NumberColumn;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.column.StringColumn;
	import weavejs.geom.GeneralizedGeometry;
	import weavejs.geom.GeoJSON;
	import weavejs.net.ResponseType;
	import weavejs.util.ArrayUtils;
	import weavejs.util.JS;
	
	public class GeoJSONDataSource extends AbstractDataSource implements IDataSource_File
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, GeoJSONDataSource, "GeoJSON file");
 		
		public function GeoJSONDataSource()
		{
		}

		public const url:LinkableFile = Weave.linkableChild(this, new LinkableFile(null, null, ResponseType.JSON), handleFile);
		public const keyType:LinkableString = Weave.linkableChild(this, LinkableString);
		public const keyProperty:LinkableString = Weave.linkableChild(this, LinkableString);
		
		/**
		 * Overrides the projection specified in the GeoJSON object.
		 */
		public const projection:LinkableString = Weave.linkableChild(this, LinkableString);
		
		/**
		 * The GeoJSON data.
		 */
		private var jsonData:GeoJSONDataSourceData = null;
		
		/**
		 * Gets the projection metadata used in the geometry column.
		 */
		public function getProjection():String
		{
			return projection.value
				|| (jsonData ? jsonData.projection : null)
				|| "EPSG:4326";
		}
		/**
		 * Gets the keyType metadata used in the columns.
		 */
		
		public function getPropertyNames():Array/*Array<string>*/
		{
			return (jsonData && jsonData.propertyNames) ? [].concat(jsonData.propertyNames) : [];
		}
		public function getKeyType():String
		{
			var kt:String = keyType.value;
			if (!kt)
			{
				kt = url.value;
				if (keyProperty.value)
					kt += "#" + keyProperty.value;
			}
			return kt;
		}
		
		override protected function get initializationComplete():Boolean
		{
			return super.initializationComplete && !Weave.isBusy(url) && jsonData;
		}
		
		/**
		 * This gets called as a grouped callback.
		 */		
		override protected function initialize(forceRefresh:Boolean = false):void
		{
			_rootNode = null;
			
			if (Weave.detectChange(initialize, keyType, keyProperty))
			{
				if (jsonData)
					jsonData.resetQKeys(getKeyType(), keyProperty.value);
			}
			
			// recalculate all columns previously requested because data may have changed.
			super.initialize(true);
		}
		
		private function handleFile():void
		{
			if (Weave.isBusy(url))
				return;
			
			jsonData = null;
			
			if (!url.result)
			{
				hierarchyRefresh.triggerCallbacks();
				
				if (url.error)
					JS.error(url.error);
				
				return;
			}
			
			try
			{
				var obj:Object = url.result;
				
				// make sure it's valid GeoJSON
				if (!GeoJSON.isGeoJSONObject(obj))
					throw new Error("Invalid GeoJSON file: " + url.value);
				
				// parse data
				jsonData = new GeoJSONDataSourceData(obj, getKeyType(), keyProperty.value);
				
				hierarchyRefresh.triggerCallbacks();
			}
			catch (e:Error)
			{
				JS.error(e);
			}
		}
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!(_rootNode is GeoJSONDataSourceNode))
			{
				var meta:Object = {};
				meta[ColumnMetadata.TITLE] = Weave.getRoot(this).getName(this);
				
				var rootChildren:Array = [];
				if (jsonData)
				{
					// include empty string for the geometry column
					rootChildren = [''].concat(jsonData.propertyNames)
						.map(function(n:String, i:*, a:*):*{ return generateHierarchyNode(n); })
						.filter(function(n:Object, ..._):Boolean{ return n != null; });
				}
				
				_rootNode = new GeoJSONDataSourceNode(this, meta, rootChildren);
			}
			return _rootNode;
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (metadata == null || !jsonData)
				return null;
			
			if (metadata is String)
			{
				var str:String = metadata as String;
				metadata = {};
				metadata[GEOJSON_PROPERTY_NAME] = str;
			}
			if (metadata && metadata.hasOwnProperty(GEOJSON_PROPERTY_NAME))
			{
				metadata = getMetadataForProperty(metadata[GEOJSON_PROPERTY_NAME]);
				return new GeoJSONDataSourceNode(this, metadata, null, [GEOJSON_PROPERTY_NAME]);
			}
			
			return null;
		}

		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var propertyName:String = proxyColumn.getMetadata(GEOJSON_PROPERTY_NAME);
			var metadata:Object = getMetadataForProperty(propertyName);
			if (!metadata || !jsonData || (propertyName && jsonData.propertyNames.indexOf(propertyName) < 0))
			{
				proxyColumn.dataUnavailable();
				return;
			}
			proxyColumn.setMetadata(metadata);
			
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];
			if (dataType == DataType.GEOMETRY)
			{
				var qkeys:Array = [];
				var geoms:Array = [];
				var i:int = 0;
				var initGeoms:Function = function(stopTime:int):Number
				{
					if (!jsonData)
					{
						proxyColumn.dataUnavailable();
						return 1;
					}
					for (; i < jsonData.qkeys.length; i++)
					{
						if (JS.now() > stopTime)
							return i / jsonData.qkeys.length;
						
						var geomsFromJson:Array = GeneralizedGeometry.fromGeoJson(jsonData.geometries[i]);
						for each (var geom:GeneralizedGeometry in geomsFromJson)
						{
							qkeys.push(jsonData.qkeys[i]);
							geoms.push(geom);
						}
					}
					return 1;
				}
				var setGeoms:Function = function():void
				{
					var gc:GeometryColumn = new GeometryColumn(metadata);
					gc.setRecords(qkeys, geoms);
					proxyColumn.setInternalColumn(gc);
				}
				// high priority because not much can be done without data
				WeaveAPI.Scheduler.startTask(proxyColumn, initGeoms, WeaveAPI.TASK_PRIORITY_HIGH, setGeoms);
			}
			else
			{
				var data:Array = ArrayUtils.pluck(jsonData.properties, propertyName);
				var type:String = jsonData.propertyTypes[propertyName];
				if (type == 'number')
				{
					var nc:NumberColumn = new NumberColumn(metadata);
					nc.setRecords(jsonData.qkeys, data);
					proxyColumn.setInternalColumn(nc);
				}
				else
				{
					var sc:StringColumn = new StringColumn(metadata);
					sc.setRecords(jsonData.qkeys, data);
					proxyColumn.setInternalColumn(sc);
				}
			}
		}
		
		private function getMetadataForProperty(propertyName:String):Object
		{
			if (!jsonData)
				return null;
			
			var meta:Object = null;
			if (!propertyName)
			{
				meta = {};
				meta[GEOJSON_PROPERTY_NAME] = '';
				meta[ColumnMetadata.TITLE] = getGeomColumnTitle();
				meta[ColumnMetadata.KEY_TYPE] = getKeyType();
				meta[ColumnMetadata.DATA_TYPE] = DataType.GEOMETRY;
				meta[ColumnMetadata.PROJECTION] = getProjection();
			}
			else if (jsonData.propertyNames.indexOf(propertyName) >= 0)
			{
				meta = {};
				meta[GEOJSON_PROPERTY_NAME] = propertyName;
				meta[ColumnMetadata.TITLE] = propertyName;
				meta[ColumnMetadata.KEY_TYPE] = getKeyType();
				
				if (propertyName == keyProperty.value)
					meta[ColumnMetadata.DATA_TYPE] = getKeyType();
				else
					meta[ColumnMetadata.DATA_TYPE] = jsonData.propertyTypes[propertyName];
			}
			return meta;
		}
		private static const GEOJSON_PROPERTY_NAME:String = 'geoJsonPropertyName';
		
		private function getGeomColumnTitle():String
		{
			return Weave.lang("{0} geometry", Weave.getRoot(this).getName(this));
		}
	}
}

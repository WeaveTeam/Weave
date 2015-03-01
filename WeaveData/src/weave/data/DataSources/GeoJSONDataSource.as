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

package weave.data.DataSources
{
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.detectLinkableObjectChange;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ProjectionManager;
	import weave.primitives.GeneralizedGeometry;
	import weave.services.addAsyncResponder;
	import weave.utils.GeoJSON;
	import weave.utils.VectorUtils;
	
	public class GeoJSONDataSource extends AbstractDataSource implements IDataSource_File
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, GeoJSONDataSource, "GeoJSON file");
 		
		public function GeoJSONDataSource()
		{
		}

		public const url:LinkableString = newLinkableChild(this, LinkableString);
		public const keyType:LinkableString = newLinkableChild(this, LinkableString);
		public const keyProperty:LinkableString = newLinkableChild(this, LinkableString);
		
		/**
		 * Overrides the projection specified in the GeoJSON object.
		 */
		public const projection:LinkableString = newLinkableChild(this, LinkableString);
		
		/**
		 * The GeoJSON data.
		 */
		private var jsonData:GeoJSONData = null;
		
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
			return super.initializationComplete
				&& !linkableObjectIsBusy(this)
				&& jsonData;
		}
		
		/**
		 * This gets called as a grouped callback.
		 */		
		override protected function initialize():void
		{
			_rootNode = null;
			
			if (detectLinkableObjectChange(initialize, url))
			{
				jsonData = null;
				if (url.value)
					addAsyncResponder(
						WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(url.value), URLLoaderDataFormat.TEXT),
						handleDownload,
						handleDownloadError,
						url.value
					);
			}
			
			if (detectLinkableObjectChange(initialize, keyType, keyProperty))
			{
				if (jsonData)
					jsonData.resetQKeys(getKeyType(), keyProperty.value);
			}
			
			// recalculate all columns previously requested because data may have changed.
			refreshAllProxyColumns();

			super.initialize();
		}
		
		/**
		 * Called when the CSV data is downloaded from a URL.
		 */
		private function handleDownload(event:ResultEvent, requestedUrl:String):void
		{
			// ignore old results
			if (requestedUrl != url.value)
				return;
			
			try
			{
				var json:Object;
				try
				{
					json = getDefinitionByName("JSON");
				}
				catch (e:Error)
				{
					throw new Error("GeoJSON: Your version of Flash Player (" + Capabilities.version + " " + Capabilities.playerType + ") does not have native JSON support.");
				}
				
				// parse the json
				var obj:Object = json.parse(event.result);
				
				// make sure it's valid GeoJSON
				if (!GeoJSON.isGeoJSONObject(obj))
					throw new Error("Invalid GeoJSON file: " + url.value);
				
				// parse data
				jsonData = new GeoJSONData(obj, getKeyType(), keyProperty.value);
				
				refreshHierarchy(); // this triggers callbacks
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		/**
		 * Called when the data fails to download from a URL.
		 */
		private function handleDownloadError(event:FaultEvent, requestedUrl:String):void
		{
			if (requestedUrl == url.value)
				reportError(event);
		}
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!(_rootNode is DataSourceNode))
			{
				var meta:Object = {};
				meta[ColumnMetadata.TITLE] = WeaveAPI.globalHashMap.getName(this);
				
				var rootChildren:Array = [];
				if (jsonData)
				{
					// include empty string for the geometry column
					rootChildren = [''].concat(jsonData.propertyNames)
						.map(function(n:String, i:*, a:*):*{ return generateHierarchyNode(n); })
						.filter(function(n:Object, ..._):Boolean{ return n != null; });
				}
				
				_rootNode = new DataSourceNode(this, meta, rootChildren);
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
				return new DataSourceNode(this, metadata, null, [GEOJSON_PROPERTY_NAME]);
			}
			
			return null;
		}

		/**
		 * @inheritDoc
		 */
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
				var keys:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
				var geoms:Vector.<GeneralizedGeometry> = new Vector.<GeneralizedGeometry>();
				var i:int = 0;
				function initGeoms(stopTime:int):Number
				{
					if (!jsonData)
					{
						proxyColumn.dataUnavailable();
						return 1;
					}
					for (; i < jsonData.qkeys.length; i++)
					{
						if (getTimer() > stopTime)
							return i / jsonData.qkeys.length;
						
						for each (var geom:GeneralizedGeometry in jsonData.convertToGeneralizedGeometries(i))
						{
							keys.push(jsonData.qkeys[i]);
							geoms.push(geom);
						}
					}
					return 1;
				}
				function setGeoms():void
				{
					var gc:GeometryColumn = new GeometryColumn(metadata);
					gc.setGeometries(keys, geoms);
					proxyColumn.setInternalColumn(gc);
				}
				// high priority because not much can be done without data
				WeaveAPI.StageUtils.startTask(proxyColumn, initGeoms, WeaveAPI.TASK_PRIORITY_HIGH, setGeoms);
			}
			else
			{
				var data:Array = VectorUtils.pluck(jsonData.properties, propertyName);
				var type:String = jsonData.propertyTypes[propertyName];
				if (type == 'number')
				{
					var nc:NumberColumn = new NumberColumn(metadata);
					nc.setRecords(jsonData.qkeys, Vector.<Number>(data));
					proxyColumn.setInternalColumn(nc);
				}
				else
				{
					var sc:StringColumn = new StringColumn(metadata);
					sc.setRecords(jsonData.qkeys, Vector.<String>(data));
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
			return lang("{0} geometry", WeaveAPI.globalHashMap.getName(this));
		}
	}
}

import flash.system.Capabilities;
import flash.utils.getDefinitionByName;

import weave.api.data.ColumnMetadata;
import weave.api.data.IColumnReference;
import weave.api.data.IDataSource;
import weave.api.data.IQualifiedKey;
import weave.api.data.IWeaveTreeNode;
import weave.compiler.StandardLib;
import weave.data.ProjectionManager;
import weave.primitives.GeneralizedGeometry;
import weave.primitives.GeometryType;
import weave.utils.BLGTreeUtils;
import weave.utils.GeoJSON;
import weave.utils.VectorUtils;

internal class DataSourceNode implements IWeaveTreeNode, IColumnReference
{
	private var idFields:Array;
	private var source:IDataSource;
	private var metadata:Object;
	private var children:Array;
	
	public function DataSourceNode(source:IDataSource, metadata:Object, children:Array = null, idFields:Array = null)
	{
		this.source = source;
		this.metadata = metadata || {};
		this.children = children;
		this.idFields = idFields;
	}
	public function equals(other:IWeaveTreeNode):Boolean
	{
		var that:DataSourceNode = other as DataSourceNode;
		if (that && this.source == that.source && StandardLib.compare(this.idFields, that.idFields) == 0)
		{
			if (idFields && idFields.length)
			{
				// check only specified fields
				for each (var field:String in idFields)
					if (this.metadata[field] != that.metadata[field])
						return false;
				return true;
			}
			// check all fields
			return StandardLib.compare(this.metadata, that.metadata) == 0;
		}
		return false;
	}
	public function getLabel():String
	{
		return metadata[ColumnMetadata.TITLE];
	}
	public function isBranch():Boolean
	{
		return children != null;
	}
	public function hasChildBranches():Boolean
	{
		return false;
	}
	public function getChildren():Array
	{
		return children;
	}
	
	public function getDataSource():IDataSource
	{
		return source;
	}
	public function getColumnMetadata():Object
	{
		return children ? null : metadata;
	}
}

internal class GeoJSONData
{
	public function GeoJSONData(obj:Object, keyType:String, keyPropertyName:String)
	{
		// get projection
		var crs:Object = obj[GeoJSON.P_CRS];
		if (crs && crs[GeoJSON.P_TYPE] == GeoJSON.CRS_T_NAME)
			projection = ProjectionManager.getProjectionFromURN(crs[GeoJSON.CRS_P_PROPERTIES][GeoJSON.CRS_N_P_NAME]);
		
		// get features
		var featureCollection:Object = GeoJSON.asFeatureCollection(obj);
		var features:Array = featureCollection[GeoJSON.FC_P_FEATURES];
		
		// save data from features
		ids = VectorUtils.pluck(features, GeoJSON.F_P_ID);
		geometries = VectorUtils.pluck(features, GeoJSON.F_P_GEOMETRY);
		properties = VectorUtils.pluck(features, GeoJSON.F_P_PROPERTIES);
		
		// if there are no ids, use index values
		if (ids.every(function(item:*, i:*, a:*):Boolean { return item === undefined; }))
			ids = features.map(function(o:*, i:*, a:*):* { return i; });
		
		// get property names
		propertyNames = [];
		propertyTypes = {};
		properties.forEach(function(props:Object, i:*, a:*):void {
			for (var key:String in props)
			{
				var value:Object = props[key];
				var oldType:String = propertyTypes[key];
				var newType:String = value == null ? oldType : typeof value; // don't let null affect type
				if (!propertyTypes.hasOwnProperty(key))
				{
					propertyTypes[key] = newType;
					propertyNames.push(key);
				}
				else if (oldType != newType)
				{
					// adjust type
					propertyTypes[key] = 'object';
				}
			}
		});
		StandardLib.sort(propertyNames);
		
		resetQKeys(keyType, keyPropertyName);
	}
	
	/**
	 * The projection specified in the GeoJSON object.
	 */
	public var projection:String = null;
	
	/**
	 * An Array of "id" values corresponding to the GeoJSON features.
	 */
	public var ids:Array = null;
	
	/**
	 * An Array of "geometry" objects corresponding to the GeoJSON features.
	 */
	public var geometries:Array = null;
	
	/**
	 * An Array of "properties" objects corresponding to the GeoJSON features.
	 */
	public var properties:Array = null;
	
	/**
	 * A list of property names found in the jsonProperties objects.
	 */
	public var propertyNames:Array = null;
	
	/**
	 * propertyName -> typeof
	 */
	public var propertyTypes:Object = null;
	
	/**
	 * An Array of IQualifiedKey objects corresponding to the GeoJSON features.
	 * This can be reinitialized via resetQKeys().
	 */
	public var qkeys:Vector.<IQualifiedKey> = null;
	
	/**
	 * Updates the qkeys Vector using the given keyType and property values under the given property name.
	 * If the property name is not found, index values will be used.
	 * @param keyType The keyType of each IQualifiedKey.
	 * @param propertyName The name of a property in the propertyNames Array.
	 */
	public function resetQKeys(keyType:String, propertyName:String):void
	{
		var values:Array = ids;
		if (propertyName && propertyNames.indexOf(propertyName) >= 0)
			values = VectorUtils.pluck(properties, propertyName);
		
		qkeys = Vector.<IQualifiedKey>(WeaveAPI.QKeyManager.getQKeys(keyType, values));
	}
	
	/**
	 * Derives GeneralizedGeometry objects from the GeoJSON data and overwrites the existing GeoJSON Geometry object.
	 * @param index Index in the geometries Array.
	 * @return An Array of GeneralizedGeometry objects
	 */
	public function convertToGeneralizedGeometries(index:int):Array
	{
		var obj:Object = geometries[index];
		var type:String = obj[GeoJSON.P_TYPE];
		var coords:Array = obj[GeoJSON.G_P_COORDINATES];
		
		// convert coords to MultiPolygon format: multi[ poly[ line[ point[] ] ] ]
		if (type == GeoJSON.T_POINT)
			type = GeometryType.POINT, coords = /*multi*/[/*poly*/[/*line*/[/*point*/coords]]];
		else if (type == GeoJSON.T_MULTI_POINT)
			type = GeometryType.POINT, coords = /*multi*/[/*poly*/[/*line*/coords]];
		else if (type == GeoJSON.T_LINE_STRING)
			type = GeometryType.LINE, coords = /*multi*/[/*poly*/[/*line*/coords]];
		else if (type == GeoJSON.T_MULTI_LINE_STRING)
			type = GeometryType.LINE, coords = /*multi*/[/*poly line*/coords];
		else if (type == GeoJSON.T_POLYGON)
			type = GeometryType.POLYGON, coords = /*multi*/[/*poly*/coords];
		else if (type == GeoJSON.T_MULTI_POLYGON)
			type = GeometryType.POLYGON;
		
		var result:Array = [];
		for each (var poly:Array in coords)
		{
			var geom:GeneralizedGeometry = new GeneralizedGeometry(type);
			var xyCoords:Array = [];
			for each (var part:Array in poly)
			{
				// add part marker if this is not the first part
				if (xyCoords.length > 0)
					xyCoords.push(NaN, NaN);
				// push x,y coords
				for each (var point:Array in part)
					xyCoords.push(point[0], point[1]);
			}
			geom.setCoordinates(xyCoords, BLGTreeUtils.METHOD_SAMPLE);
			result.push(geom);
		}
		return result;
	}
}

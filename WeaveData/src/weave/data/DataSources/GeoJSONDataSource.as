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
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IDataSource;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
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
	import weave.utils.GeoJSON;
	import weave.utils.VectorUtils;
	
	public class GeoJSONDataSource extends AbstractDataSource
	{
		//WeaveAPI.registerImplementation(IDataSource, GeoJSONDataSource, "GeoJSON");
 		
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
		
		private var rootChildren:Array = null;
		
		private function getProjection():String
		{
			return projection.value || (jsonData ? jsonData.projection : null);
		}
		
		override protected function get initializationComplete():Boolean
		{
			return super.initializationComplete;
		}
		
		/**
		 * This gets called as a grouped callback.
		 */		
		override protected function initialize():void
		{
			if (detectLinkableObjectChange(initialize, url))
			{
				jsonData = null;
				if (url.value)
					WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(url.value), handleDownload, handleDownloadError, url.value, URLLoaderDataFormat.TEXT);
			}
			
			if (detectLinkableObjectChange(initialize, keyType, keyProperty))
			{
				if (jsonData)
					jsonData.resetQKeys(keyType.value, keyProperty.value);
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
					throw new Error("Your version of Flash Player (" + Capabilities.version + ") does not have native JSON support.");
				}
				
				// parse the json
				var obj:Object = json.parse(event.result);
				
				// make sure it's valid GeoJSON
				if (!GeoJSON.isGeoJSONObject(obj))
					throw new Error("Invalid GeoJSON file: " + url);
				
				// parse data
				jsonData = new GeoJSONData(obj, keyType.value, keyProperty.value);
				
				// set up hierarchy
				rootChildren = jsonData.propertyNames.map(function(n:String, i:*, a:*):*{
					var m:Object = {"title": n, "dataType": jsonData.propertyTypes[n]};
					m[GEOJSON_PROPERTY_NAME] = n;
					return new DataSourceNode(this, m);
				}, this);
				rootChildren.unshift(new DataSourceNode(this, {"title": "the_geom", "dataType": DataTypes.GEOMETRY}));
				_rootNode = null;
				
				getCallbackCollection(this).triggerCallbacks();
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
				_rootNode = new DataSourceNode(this, {"title": WeaveAPI.globalHashMap.getName(this)}, rootChildren);
			return _rootNode;
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata || !jsonData)
				return null;
			
			var propertyName:String = metadata[GEOJSON_PROPERTY_NAME];
			
			if (propertyName && jsonData.propertyNames.indexOf(propertyName) < 0)
				return null;
			
			return new DataSourceNode(this, metadata);
		}


		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];
			var propertyName:String = metadata[GEOJSON_PROPERTY_NAME];
			if (!jsonData || (propertyName && jsonData.propertyNames.indexOf(propertyName) < 0))
			{
				proxyColumn.setInternalColumn(null);
				return;
			}
			
			if (dataType == DataTypes.GEOMETRY)
			{
				//TODO - make this async
				for (var i:int = 0; i < jsonData.qkeys.length; i++)
					jsonData.convertToGeneralizedGeometry(i);
				
				var gc:GeometryColumn = new GeometryColumn(metadata);
				gc.setGeometries(jsonData.qkeys, Vector.<GeneralizedGeometry>(jsonData.geometries));
				proxyColumn.setInternalColumn(gc);
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
		
		private static const GEOJSON_PROPERTY_NAME:String = 'geoJsonPropertyName';
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
	private var source:IDataSource;
	private var metadata:Object;
	private var children:Array;
	
	public function DataSourceNode(source:IDataSource, metadata:Object, children:Array = null)
	{
		this.source = source;
		this.metadata = metadata;
		this.children = children;
	}
	public function equals(other:IWeaveTreeNode):Boolean
	{
		var that:DataSourceNode = other as DataSourceNode;
		return that
			&& this.source == that.source
			&& StandardLib.compareDynamicObjects(this.metadata, that.metadata);
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
		return metadata;
	}
}

internal class GeoJSONData
{
	public function GeoJSONData(obj:Object, keyType:String, keyPropertyName:String)
	{
		// get projection
		var crs:Object = obj[GeoJSON.P_CRS];
		if (crs && crs[GeoJSON.P_TYPE] == GeoJSON.CRS_T_NAME)
			projection = ProjectionManager.getProjectionFromURN(crs[GeoJSON.CRS_N_P_NAME]);
		
		// get features
		var featureCollection:Object = GeoJSON.asFeatureCollection(obj);
		var features:Array = featureCollection[GeoJSON.FC_P_FEATURES];
		
		// save data from features
		ids = VectorUtils.pluck(features, GeoJSON.F_P_ID);
		geometries = VectorUtils.pluck(features, GeoJSON.F_P_GEOMETRY);
		properties = VectorUtils.pluck(features, GeoJSON.F_P_PROPERTIES);
		
		// get property names
		propertyNames = [];
		propertyTypes = {};
		properties.forEach(function(props:Object, i:*, a:*):void {
			for (var key:String in props)
			{
				var value:Object = props[key];
				var oldType:String = propertyTypes[key];
				var newType:String = value == null ? oldType : typeof value; // don't let null affect type
				if (!oldType)
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
		var values:Array;
		if (propertyName && propertyNames.indexOf(propertyName) >= 0)
			values = VectorUtils.pluck(properties, propertyName);
		else
			values = properties.map(function(o:*, i:*, a:*):* { return i; }); // index values
		
		qkeys = Vector.<IQualifiedKey>(WeaveAPI.QKeyManager.getQKeys(keyType, values));
	}
	
	/**
	 * Derives a GeneralizedGeometry from the GeoJSON data and overwrites the existing GeoJSON Geometry object.
	 * @param index Index in the geometries Array.
	 */
	public function convertToGeneralizedGeometry(index:int):void
	{
		var obj:Object = geometries[index];
		if (obj is GeneralizedGeometry)
			return;
		
		var type:String = obj[GeoJSON.P_TYPE];
		var coords:Array = obj[GeoJSON.G_P_COORDINATES];
		
		// convert coords to Multi format
		if (type == GeoJSON.T_POINT)
			type = GeoJSON.T_MULTI_POINT, coords = [coords];
		else if (type == GeoJSON.T_LINE_STRING)
			type = GeoJSON.T_MULTI_LINE_STRING, coords = [coords];
		else if (type == GeoJSON.T_POLYGON)
			type = GeoJSON.T_MULTI_POLYGON, coords = [coords];
		
		// use GeometryType constants
		if (type == GeoJSON.T_MULTI_POINT)
			type = GeometryType.POINT;
		else if (type == GeoJSON.T_MULTI_LINE_STRING)
			type = GeometryType.LINE;
		else if (type == GeoJSON.T_MULTI_POLYGON)
			type = GeometryType.POLYGON;
		
		var geom:GeneralizedGeometry = new GeneralizedGeometry(type);
		var xyCoords:Array = [];
		for each (var part:Array in coords)
		{
			// add part marker if this is not the first part
			if (xyCoords.length == 0)
				xyCoords.push(NaN, NaN);
			// push x,y coords
			for each (var coord:Array in part)
			xyCoords.push(coord[0], coord[1]);
		}
		geom.setCoordinates(xyCoords, BLGTreeUtils.METHOD_SAMPLE);
		
		// overwrite the GeoJSON Geometry object
		geometries[index] = geom;
	}
}
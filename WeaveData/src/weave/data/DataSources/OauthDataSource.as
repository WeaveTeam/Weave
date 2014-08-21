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
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.system.Capabilities;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObject;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.primitives.GeneralizedGeometry;
	import weave.services.OauthServlet;
	import weave.services.addAsyncResponder;
	import weave.utils.VectorUtils;

	public class OauthDataSource extends AbstractDataSource
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, OauthDataSource, "Auhtorized Data");
		public function OauthDataSource()
		{
			super();
			url.addImmediateCallback(this, handleURLChange, true);
		}
		
		public const clientID:LinkableString = registerLinkableChild(this, new LinkableString());
		public const clientSecret:LinkableString = registerLinkableChild(this, new LinkableString());
		public const redirectUri:LinkableString = registerLinkableChild(this, new LinkableString());
		public const authUri:LinkableString = registerLinkableChild(this, new LinkableString());
		public const tokenUri:LinkableString = registerLinkableChild(this, new LinkableString());
		public const code:LinkableString = registerLinkableChild(this, new LinkableString());
		
		public const authToken:LinkableString = registerLinkableChild(this, new LinkableString());
		
		public const apiURL:LinkableString = registerLinkableChild(this, new LinkableString());
		public const apiDataContentType:LinkableString = registerLinkableChild(this, new LinkableString());
		
		
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString);
		public const tableName:LinkableString = registerLinkableChild(this, new LinkableString());
		public const keyColumnName:LinkableString = registerLinkableChild(this, new LinkableString());
		public const columns:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array));
		
		public const url:LinkableString = registerLinkableChild(this,new LinkableString("/GoogleServices/OauthService"));
		private var _service:OauthServlet = null;
	
		
		/**
		 * This function prevents url.value from being null.
		 */
		private function handleURLChange():void
		{
			url.delayCallbacks();
			// replace old service
			disposeObject(_service);
			_service = registerLinkableChild(this, new OauthServlet(url.value));
			
			url.resumeCallbacks();
		}
		
		/**
		 * This gets called as a grouped callback.
		 */		
		override protected function initialize():void
		{
			_rootNode = null;
			
			if (detectLinkableObjectChange(apiURL,apiDataContentType, authToken))
			{
			//initiate OuathFlow
				//initiateOuathFlow();
				getdataFromApiCall();
					
			}
			
			// recalculate all columns previously requested because data may have changed.
			refreshAllProxyColumns();
			
			super.initialize();
		}
		private function handleDownload(event:ResultEvent, requestedUrl:String):void
		{
			trace('hi');
		}
		
		private function handleDownloadError(event:FaultEvent, requestedUrl:String):void
		{
			if (requestedUrl == url.value)
				reportError(event);
		}
		
		private function initiateOuathFlow():void{
			var asyncToken:AsyncToken = _service.triggerOauthFlow(clientID.value,clientSecret.value,authUri.value,tokenUri.value);
			addAsyncResponder(asyncToken, handleResult, handleFault, 'hi');
		}
		
		
		private function getdataFromApiCall():void{
			var request:URLRequest = new URLRequest(apiURL.value);
			request.method = URLRequestMethod.GET;
			var contentTypeHeader:URLRequestHeader = new URLRequestHeader("Accept", apiDataContentType.value);
			var authorizationHeader:URLRequestHeader = new URLRequestHeader("Authorization", 'Bearer ' + authToken.value);
			request.requestHeaders.push(contentTypeHeader);	
			request.requestHeaders.push(authorizationHeader);				
			WeaveAPI.URLRequestUtils.getURL(null, request, handleResult, handleFault, apiURL.value,'json');
			//navigateToURL(request,'_blank');
		}
		
		protected function handleResult(event:ResultEvent, token:String):void
		{
			
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
				
								
				jsonData = new AuthJSONData(obj, getKeyType(), tableName.value,keyColumnName.value);
				
				refreshHierarchy(); // this triggers callbacks
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
		protected function handleFault(event:FaultEvent, token:Object = null):void
		{
			reportError(event.fault);
		}
		
		/**
		 * The GeoJSON data.
		 */
		private var jsonData:AuthJSONData = null;
		
		/**
		 * Gets the keyType metadata used in the columns.
		 */
		public function getKeyType():String
		{
			var kt:String = keyType.value;
			if (!kt)
			{
				kt = url.value;
				if (keyColumnName.value)
					kt += "#" + keyColumnName.value;
			}
			return kt;
		}
		
		/**
		 * An Array of IQualifiedKey objects s.
		 * This can be reinitialized via resetQKeys().
		 */
		public var qkeys:Vector.<IQualifiedKey> = null;
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!(_rootNode is DataSourceNode))
			{
				var meta:Object = {};
				meta[ColumnMetadata.TITLE] = WeaveAPI.globalHashMap.getName(this);
				
				var rootChildren:Array = null;
				if (jsonData)
				{					
					rootChildren = [''].concat(jsonData.columnNames)
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
				metadata[AUTHJSON_PROPERTY_NAME] = str;
			}
			if (metadata && metadata.hasOwnProperty(AUTHJSON_PROPERTY_NAME))
			{
				metadata = getMetadataForProperty(metadata[AUTHJSON_PROPERTY_NAME]);
				return new DataSourceNode(this, metadata, null, [AUTHJSON_PROPERTY_NAME]);
			}
			
			return null;
		}
		
		private function getMetadataForProperty(propertyName:String):Object
		{
			if (!jsonData)
				return null;
			
			var meta:Object = null;
			if (jsonData.columnNames.indexOf(propertyName) >= 0)
			{
				meta = {};
				meta[AUTHJSON_PROPERTY_NAME] = propertyName;
				meta[ColumnMetadata.TITLE] = propertyName;
				meta[ColumnMetadata.KEY_TYPE] = getKeyType();
				
				if (propertyName == keyColumnName.value)
					meta[ColumnMetadata.DATA_TYPE] = getKeyType();
				else
					meta[ColumnMetadata.DATA_TYPE] = jsonData.columnTypes[propertyName];
			}
			return meta;
		}
		
		private static const AUTHJSON_PROPERTY_NAME:String = 'authJsonPropertyName';
		//private static const AUTH_COLUMN_TITLE:String = 'the_auth';
		
		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var propertyName:String = proxyColumn.getMetadata(AUTHJSON_PROPERTY_NAME);
			var metadata:Object = getMetadataForProperty(propertyName);
			if (!metadata || !jsonData || (propertyName && jsonData.columnNames.indexOf(propertyName) < 0))
			{
				proxyColumn.setInternalColumn(null);
				return;
			}
			proxyColumn.setMetadata(metadata);
			
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];
			
			
			var data:Array = VectorUtils.pluck(jsonData.columns, propertyName);
			var type:String = jsonData.columnTypes[propertyName];
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
}
import weave.api.data.ColumnMetadata;
import weave.api.data.IColumnReference;
import weave.api.data.IDataSource;
import weave.api.data.IQualifiedKey;
import weave.api.data.IWeaveTreeNode;
import weave.compiler.StandardLib;
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
		if (that && this.source == that.source && StandardLib.arrayCompare(this.idFields, that.idFields) == 0)
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
			return StandardLib.compareDynamicObjects(this.metadata, that.metadata) == 0;
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
		return metadata;
	}
}


internal class AuthJSONData
{
	public function AuthJSONData(obj:Object, keyType:String, tableName:String, keyColumnName:String)
	{
		
		// get features
		var featureCollection:Object = GeoJSON.asFeatureCollection(obj);
		columns = obj[tableName];
		
		// save data from features
		ids = VectorUtils.pluck(columns, "ids");
		//properties = VectorUtils.pluck(columns, tableName);
		
		// if there are no ids, use index values
		if (ids.every(function(item:*, i:*, a:*):Boolean { return item === undefined; }))
			ids = columns.map(function(o:*, i:*, a:*):* { return i; });
		
		// get property names
		columnNames = [];
		columnTypes = {};
		columns.forEach(function(props:Object, i:*, a:*):void {
			for (var key:String in props)
			{
				var value:Object = props[key];
				var oldType:String = columnTypes[key];
				var newType:String = value == null ? oldType : typeof value; // don't let null affect type
				if (!columnTypes.hasOwnProperty(key))
				{
					columnTypes[key] = newType;
					columnNames.push(key);
				}
				else if (oldType != newType)
				{
					// adjust type
					columnTypes[key] = 'object';
				}
			}
		});
		StandardLib.sort(columnNames);
		
		resetQKeys(keyType, keyColumnName);
	}
	
	
	/**
	 * An Array of "id" values corresponding to the GeoJSON features.
	 */
	public var ids:Array = null;
	
	
	
	/**
	 * An Array of "properties" objects corresponding to the GeoJSON features.
	 */
	public var columns:Array = null;
	
	/**
	 * A list of property names found in the jsonProperties objects.
	 */
	public var columnNames:Array = null;
	
	/**
	 * propertyName -> typeof
	 */
	public var columnTypes:Object = null;
	
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
		if (propertyName && columnNames.indexOf(propertyName) >= 0)
			values = VectorUtils.pluck(columns, propertyName);
		
		qkeys = Vector.<IQualifiedKey>(WeaveAPI.QKeyManager.getQKeys(keyType, values));
	}
	
	
}

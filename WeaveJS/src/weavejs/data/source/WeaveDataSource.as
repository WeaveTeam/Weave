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
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IDataSourceWithAuthentication;
	import weavejs.api.data.IDataSource_Service;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.api.net.IWeaveGeometryTileService;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;
	import weavejs.data.ColumnUtils;
	import weavejs.data.column.DateColumn;
	import weavejs.data.column.GeometryColumn;
	import weavejs.data.column.NumberColumn;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.column.SecondaryKeyNumColumn;
	import weavejs.data.column.StreamedGeometryColumn;
	import weavejs.data.column.StringColumn;
	import weavejs.data.hierarchy.EntityNode;
	import weavejs.data.key.QKeyManager;
	import weavejs.net.EntityCache;
	import weavejs.net.WeaveDataServlet;
	import weavejs.net.beans.AttributeColumnData;
	import weavejs.net.beans.TableData;
	import weavejs.util.DebugUtils;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	import weavejs.util.WeavePromise;
	
	/**
	 * WeaveDataSource is an interface for retrieving columns from Weave data servlets.
	 * 
	 * @author adufilie
	 */
	public class WeaveDataSource extends AbstractDataSource implements IDataSource_Service, IDataSourceWithAuthentication
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, WeaveDataSource, "Weave server");

		private static const SQLPARAMS:String = 'sqlParams';
		
		public static var debug:Boolean = false;
		
		public function WeaveDataSource()
		{
			url.addImmediateCallback(this, handleURLChange, true);
		}
		
		private var _service:WeaveDataServlet = null;
		private var _tablePromiseCache:Object;
		private var map_proxy_promise:Object;
		private var _entityCache:EntityCache = null;
		public const url:LinkableString = Weave.linkableChild(this, LinkableString);
		public const hierarchyURL:LinkableString = Weave.linkableChild(this, LinkableString);
		public const rootId:LinkableVariable = Weave.linkableChild(this, LinkableVariable);
		
		/**
		 * This is an Array of public metadata field names that should be used to uniquely identify columns when querying the server.
		 */
		private const _idFields:LinkableVariable = Weave.linkableChild(this, new LinkableVariable(Array, verifyStringArray));
		
		// for backwards compatibility to override server idFields setting
		private var _overrideIdFields:LinkableVariable;
		
		/**
		 * Provided for backwards compatibility - setting this will override the server setting.
		 */
		[Deprecated] public function get idFields():LinkableVariable
		{
			if (!_overrideIdFields)
				_overrideIdFields = Weave.linkableChild(_idFields, new LinkableVariable(Array, verifyStringArray), handleDeprecatedIdFields);
			return _overrideIdFields;
		}
		private function handleDeprecatedIdFields():void
		{
			// if session state is set to some array, use it as an override for the server setting. otherwise, ignore it.
			var state:Array = _overrideIdFields.getSessionState() as Array;
			if (state)
				_idFields.setSessionState(state);
		}
		
		/**
		 * @inheritDoc
		 */
		public function get authenticationSupported():Boolean
		{
			return  _service.authenticationSupported;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get authenticationRequired():Boolean
		{
			return _service.authenticationRequired;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get authenticatedUser():String
		{
			return _service.authenticatedUser;
		}
		
		/**
		 * @inheritDoc
		 */
		public function authenticate(user:String, pass:String):void
		{
			_service.authenticate(user, pass);
		}
		
		public function get entityCache():EntityCache
		{
			return _entityCache;
		}
		
		private function verifyStringArray(array:Array):Boolean
		{
			return !array || StandardLib.getArrayType(array) == String;
		}
		
		override protected function refreshHierarchy():void
		{
			super.refreshHierarchy();
			entityCache.invalidateAll();
			if (_rootNode is RootNode_TablesAndGeoms)
				(_rootNode as RootNode_TablesAndGeoms).refresh();
		}
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			var id:Object = rootId.getSessionState();
			if (typeof id == 'string')
				id = StandardLib.asNumber(id);
			var isNumber:Boolean = typeof id == 'number' && isFinite(id as Number);
			var isObject:Boolean = id != null && typeof id == 'object';
			
			if (!isNumber && !isObject)
			{
				// no valid id specified
				if (!(_rootNode is RootNode_TablesAndGeoms))
					_rootNode = new RootNode_TablesAndGeoms(this);
				return _rootNode;
			}
			
			var node:EntityNode = _rootNode as EntityNode;
			if (!node)
				_rootNode = node = new EntityNode();
			node.setEntityCache(entityCache);
			
			if (isNumber)
			{
				node.id = id as Number;
			}
			else if (Weave.detectChange(getHierarchyRoot, rootId))
			{
				node.id = -1;
				_service.findEntityIds(id, null).then(handleRootId.bind(this, rootId.triggerCounter));
			}
			
			return _rootNode;
		}
		private function handleRootId(triggerCount:int, result:Array):void
		{
			var node:EntityNode = getHierarchyRoot() as EntityNode;
			if (!node || rootId.triggerCounter != triggerCount)
				return;
			var ids:Array = result || [];
			if (!ids.length)
			{
				JS.error("No entity matches specified rootId: " + Weave.stringify(rootId.getSessionState()));
				return;
			}
			if (ids.length > 1)
				JS.error("Multiple entities (" + ids.length + ") match specified rootId: " + Weave.stringify(rootId.getSessionState()));
			node.id = ids[0];
			Weave.getCallbacks(this).triggerCallbacks();
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			// NOTE - this code won't work if idFields are specified and EntityNodes are used in the hierarchy.
			// This function would have to be made asynchronous in order to support that.
			
			var id:Number;
			if (typeof metadata != 'object')
			{
				id = StandardLib.asNumber(metadata);
			}
			else if (metadata.hasOwnProperty(ENTITY_ID))
			{
				id = metadata[ENTITY_ID]
			}
			else
			{
				return super.generateHierarchyNode(metadata);
			}
			
			var node:EntityNode = new EntityNode(entityCache);
			node.id = id;
			return node;
		}
		
		private static const DEFAULT_BASE_URL:String = '/WeaveServices';
		private static const DEFAULT_SERVLET_NAME:String = '/DataService';
		
		/**
		 * This function prevents url.value from being null.
		 */
		private function handleURLChange():void
		{
			url.delayCallbacks();
			
			for each (var deprecatedBaseURL:String in ['/OpenIndicatorsDataServices', '/OpenIndicatorsDataService'])
				if (url.value == deprecatedBaseURL || url.value == deprecatedBaseURL + DEFAULT_SERVLET_NAME)
					url.value = null;
			
			// backwards compatibility -- if url ends in default base url, append default servlet name
			if (url.value && url.value.split('/').pop() == DEFAULT_BASE_URL.split('/').pop())
				url.value += DEFAULT_SERVLET_NAME;
			
			// replace old service
			Weave.dispose(_service);
			Weave.dispose(_entityCache);
			_service = Weave.linkableChild(this, new WeaveDataServlet(url.value), setIdFields);
			_entityCache = Weave.linkableChild(_service, new EntityCache(_service));
			_tablePromiseCache = {};
			map_proxy_promise = new JS.WeakMap();
			
			url.resumeCallbacks();
		}
		
		public function get serverVersion():String
		{
			var info:Object = _service.getServerInfo();
			return info ? info['version'] : null;
		}
		
		private function setIdFields():void
		{
			// if deprecated idFields state has been set to an array, ignore server setting
			if (_overrideIdFields && _overrideIdFields.getSessionState())
				return;
			var info:Object = _service.getServerInfo();
			_idFields.setSessionState(info ? info['idFields'] as Array : null);
		}
		
		/**
		 * This gets called as a grouped callback when the session state changes.
		 */
		override protected function initialize(forceRefresh:Boolean = false):void
		{
			super.initialize(forceRefresh);
		}
		
		override protected function get initializationComplete():Boolean
		{
			return super.initializationComplete && _service.entityServiceInitialized;
		}
		
		override public function generateNewAttributeColumn(metadata:Object):IAttributeColumn
		{
			if (typeof metadata != 'object')
			{
				var meta:Object;
				var id:Number = StandardLib.asNumber(metadata);
				if (isFinite(id))
					meta = JS.copyObject(entityCache.getEntity(id).publicMetadata);
				else
					meta = {};
				meta[ENTITY_ID] = metadata;
				metadata = meta;
			}
			return super.generateNewAttributeColumn(metadata);
		}
		
		private static const NO_RESULT_ERROR:String = "Received null result from Weave server.";

		public static const ENTITY_ID:String = 'weaveEntityId';
		
		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			// get metadata properties from XML attributes
			var params:Object = getMetadata(proxyColumn, [ENTITY_ID, ColumnMetadata.MIN, ColumnMetadata.MAX, SQLPARAMS], false);
			var query:WeavePromise;
			var idFieldsArray:Array = _idFields.getSessionState() as Array;
			
			if (idFieldsArray || params[ENTITY_ID])
			{
				var id:Object = idFieldsArray ? getMetadata(proxyColumn, idFieldsArray, true) : StandardLib.asNumber(params[ENTITY_ID]);
				var sqlParams:Array = parseSqlParams(params[SQLPARAMS]);
				query = _service.getColumn(id, params[ColumnMetadata.MIN], params[ColumnMetadata.MAX], sqlParams);
			}
			else // backwards compatibility - search using metadata
			{
				getMetadata(proxyColumn, [ColumnMetadata.DATA_TYPE, 'dataTable', 'name', 'year', 'sqlParams'], false, params);
				// dataType is only used for backwards compatibility with geometry collections
				if (params[ColumnMetadata.DATA_TYPE] != DataType.GEOMETRY)
					delete params[ColumnMetadata.DATA_TYPE];
				
				query = _service.getColumnFromMetadata(params);
			}
			query.then(handleGetColumn.bind(this, proxyColumn), handleGetColumnFault.bind(this, proxyColumn));
			WeaveAPI.ProgressIndicator.addTask(query, proxyColumn, "Requesting column from server: " + Weave.stringify(params));
		}
		
		/**
		 * @param column An attribute column.
		 * @param propertyNames A list of metadata property names.
		 * @param forUniqueId If true, missing property values will be set to empty strings.
		 *                    If false, missing property values will be omitted.
		 * @param output An object to store the values.
		 * @return An object containing the metadata values.
		 */
		private function getMetadata(column:IAttributeColumn, propertyNames:Array, forUniqueId:Boolean, output:Object = null):Object
		{
			if (!output)
				output = {};
			var found:Boolean = false;
			var name:String;
			for each (name in propertyNames)
			{
				var value:String = column.getMetadata(name);
				if (value)
				{
					found = true;
					output[name] = value;
				}
			}
			if (!found && forUniqueId)
				for each (name in propertyNames)
					output[name] = '';
			return output;
		}
		
		private function handleGetColumnFault(column:ProxyColumn, error:Object):void
		{
			if (column.wasDisposed)
				return;
			
			JS.error(error, "Error retrieving column:", column.getProxyMetadata(), column);
			
			column.dataUnavailable();
		}
//		private function handleGetColumn(event:ResultEvent, token:Object = null):void
//		{
//			DebugUtils.callLater(5000, handleGetColumn2, arguments);
//		}
		
		private function parseSqlParams(sqlParams:String):Array
		{
			var result:Array;
			try {
				result = JSON.parse(sqlParams) as Array;
			} catch (e:Error) { }
			if (!(result is Array))
			{
				result = WeaveAPI.CSVParser.parseCSVRow(sqlParams);
				if (result && result.length == 0)
					result = null;
			}
			return result;
		}
		
		private function handleGetColumn(proxyColumn:ProxyColumn, result:AttributeColumnData):void
		{
			if (proxyColumn.wasDisposed)
				return;
			var metadata:Object = proxyColumn.getProxyMetadata();

			try
			{
				if (!result)
				{
					JS.error("Did not receive any data from service for attribute column:", metadata);
					return;
				}
				
				//trace("handleGetColumn",pathInHierarchy.toXMLString());
	
				// fill in metadata
				for (var metadataName:String in result.metadata)
				{
					var metadataValue:String = result.metadata[metadataName];
					if (metadataValue)
						metadata[metadataName] = metadataValue;
				}
				metadata[ENTITY_ID] = result.id;
				proxyColumn.setMetadata(metadata);
				
				// special case for geometry column
				var dataType:String = ColumnUtils.getDataType(proxyColumn);
				var isGeom:Boolean = StandardLib.stringCompare(dataType, DataType.GEOMETRY, true) == 0;
				if (isGeom && result.data == null)
				{
					var tileService:IWeaveGeometryTileService = _service.createTileService(result.id);
					proxyColumn.setInternalColumn(new StreamedGeometryColumn(result.metadataTileDescriptors, result.geometryTileDescriptors, tileService, metadata));
					return;
				}
				
				var setRecords:Function = function(qkeys:Array):void
				{
					if (result.data == null)
					{
						proxyColumn.dataUnavailable();
						return;
					}
					
					if (!dataType) // determine dataType from data
						dataType = DataType.getDataTypeFromData(result.data);
					
					if (isGeom) // result.data is an array of PGGeom objects.
					{
						var geometriesVector:Array = [];
						var createGeomColumn:Function = function():void
						{
							var newGeometricColumn:GeometryColumn = new GeometryColumn(metadata);
							newGeometricColumn.setRecords(qkeys, geometriesVector);
							proxyColumn.setInternalColumn(newGeometricColumn);
						};
						var pgGeomTask:Function = PGGeomUtil.newParseTask(result.data, geometriesVector);
						// high priority because not much can be done without data
						WeaveAPI.Scheduler.startTask(proxyColumn, pgGeomTask, WeaveAPI.TASK_PRIORITY_HIGH, createGeomColumn);
					}
					else if (result.thirdColumn != null)
					{
						// hack for dimension slider
						var newColumn:SecondaryKeyNumColumn = new SecondaryKeyNumColumn(metadata);
						newColumn.baseTitle = metadata['baseTitle'];
						newColumn.updateRecords(qkeys, result.thirdColumn, result.data);
						proxyColumn.setInternalColumn(newColumn);
						proxyColumn.setMetadata(null); // this will allow SecondaryKeyNumColumn to use its getMetadata() code
					}
					else if (StandardLib.stringCompare(dataType, DataType.NUMBER, true) == 0)
					{
						var newNumericColumn:NumberColumn = new NumberColumn(metadata);
						newNumericColumn.setRecords(qkeys, result.data);
						proxyColumn.setInternalColumn(newNumericColumn);
					}
					else if (StandardLib.stringCompare(dataType, DataType.DATE, true) == 0)
					{
						var newDateColumn:DateColumn = new DateColumn(metadata);
						newDateColumn.setRecords(qkeys, result.data);
						proxyColumn.setInternalColumn(newDateColumn);
					}
					else
					{
						var newStringColumn:StringColumn = new StringColumn(metadata);
						newStringColumn.setRecords(qkeys, result.data);
						proxyColumn.setInternalColumn(newStringColumn);
					} 
					//trace("column downloaded: ",proxyColumn);
				};
	
				var keyType:String = ColumnUtils.getKeyType(proxyColumn);
				if (result.data != null)
				{
					(WeaveAPI.QKeyManager as QKeyManager).getQKeysPromise(proxyColumn, keyType, result.keys).then(setRecords);
				}
				else // no data in result
				{
					if (!result.tableField || result.tableId == AttributeColumnData.NO_TABLE_ID)
					{
						proxyColumn.dataUnavailable();
						return;
					}
					
					// if table not cached, request table, store in cache, and await data
					var sqlParams:Array = parseSqlParams(proxyColumn.getMetadata(SQLPARAMS));
					var hash:String = Weave.stringify([result.tableId, sqlParams]);
					var promise:WeavePromise = _tablePromiseCache[hash];
					if (!promise)
					{
						var getTablePromise:WeavePromise = new WeavePromise(_service)
							.setResult(_service.getTable(result.tableId, sqlParams));
						
						var keyStrings:Array;
						promise = getTablePromise
							.then(function(tableData:TableData):TableData {
								if (debug)
									JS.log('received', DebugUtils.debugId(tableData), hash);
								
								if (!tableData.keyColumns)
									tableData.keyColumns = [];
								if (!tableData.columns)
									tableData.columns = {};
								
								var name:String;
								for each (name in tableData.keyColumns)
									if (!tableData.columns.hasOwnProperty(name))
										throw new Error(Weave.lang('Table {0} is missing key column "{1}"', tableData.id, name));
								
								if (tableData.keyColumns.length == 1)
								{
									keyStrings = tableData.columns[tableData.keyColumns[0]];
									return tableData;
								}
								
								// generate compound keys
								var nCol:int = tableData.keyColumns.length;
								var iCol:int, iRow:int, nRow:int = 0;
								for (iCol = 0; iCol < nCol; iCol++)
								{
									var keyCol:Array = tableData.columns[tableData.keyColumns[iCol]];
									if (iCol == 0)
										keyStrings = new Array(keyCol.length);
									nRow = keyStrings.length;
									for (iRow = 0; iRow < nRow; iRow++)
									{
										if (iCol == 0)
											keyStrings[iRow] = new Array(nCol);
										keyStrings[iRow][iCol] = keyCol[iRow];
									}
								}
								for (iRow = 0; iRow < nRow; iRow++)
									keyStrings[iRow] = WeaveAPI.CSVParser.createCSVRow(keyStrings[iRow]);
								
								// if no key columns were specified, generate keys
								if (!keyStrings)
								{
									var col:Array;
									for each (col in tableData.columns)
										break;
									keyStrings = col.map(function(v:*, i:int, a:Array):String { return 'row' + i; });
								}
								
								return tableData;
							})
							.then(function(tableData:TableData):WeavePromise {
								if (debug)
									JS.log('promising QKeys', DebugUtils.debugId(tableData), hash);
								return (WeaveAPI.QKeyManager as QKeyManager).getQKeysPromise(
									getTablePromise,
									keyType,
									keyStrings
								).then(function(qkeys:Array):TableData {
									if (debug)
										JS.log('got QKeys', DebugUtils.debugId(tableData), hash);
									tableData.derived_qkeys = qkeys;
									return tableData;
								});
							});
						_tablePromiseCache[hash] = promise;
					}
					
					// when the promise returns, set column data
					promise.then(function(tableData:TableData):void {
						result.data = tableData.columns[result.tableField];
						if (result.data == null)
						{
							proxyColumn.dataUnavailable(Weave.lang('(Missing column: {0})', result.tableField));
							return;
						}
						
						setRecords(tableData.derived_qkeys);
					});
					
					// make proxyColumn busy while table promise is busy
					if (!promise.getResult())
						WeaveAPI.SessionManager.assignBusyTask(promise, proxyColumn);
				}
			}
			catch (e:Error)
			{
				JS.error(e, "handleGetColumn", metadata);
			}
		}
	}
}

import weavejs.api.data.ColumnMetadata;
import weavejs.api.data.DataType;
import weavejs.api.data.EntityType;
import weavejs.api.data.IWeaveTreeNode;
import weavejs.api.net.beans.Entity;
import weavejs.api.net.beans.EntityHierarchyInfo;
import weavejs.data.hierarchy.EntityNode;
import weavejs.data.source.WeaveDataSource;
import weavejs.geom.BLGTreeUtils;
import weavejs.geom.GeneralizedGeometry;
import weavejs.geom.GeometryType;
import weavejs.net.EntityCache;
import weavejs.util.JS;

/**
 * Static functions for retrieving values from PGGeom objects coming from servlet.
 */
internal class PGGeomUtil
{
	/**
	 * This will generate an asynchronous task function for use with IScheduler.startTask().
	 * @param pgGeoms An Array of PGGeom beans from a Weave data service.
	 * @param output An Array to store GeneralizedGeometry objects created from the pgGeoms input.
	 * @return A new Function.
	 * @see weavejs.api.core.IScheduler
	 */
	public static function newParseTask(pgGeoms:Array, output:Array):Function
	{
		var i:int = 0;
		var n:int = pgGeoms.length;
		output.length = n;
		return function(returnTime:int):Number
		{
			for (; i < n; i++)
			{
				if (JS.now() > returnTime)
					return i / n;
				
				var item:Object = pgGeoms[i];
				var geomType:String = GeometryType.fromPostGISType(item[TYPE]);
				var geometry:GeneralizedGeometry = new GeneralizedGeometry(geomType);
				geometry.setCoordinates(item[XYCOORDS], BLGTreeUtils.METHOD_SAMPLE);
				output[i] = geometry;
			}
			return 1;
		};
	}
	
	/**
	 * The name of the type property in a PGGeom bean
	 */
	private static const TYPE:String = 'type';
	
	/**
	 * The name of the xyCoords property in a PGGeom bean
	 */
	private static const XYCOORDS:String = 'xyCoords';
}

/**
 * Has two children: "Data Tables" and "Geometry Collections"
 */
internal class RootNode_TablesAndGeoms implements IWeaveTreeNode
{
	private var source:WeaveDataSource;
	private var tableList:EntityNode;
	private var geomList:GeomListNode;
	private var children:Array;
	public function RootNode_TablesAndGeoms(source:WeaveDataSource)
	{
		this.source = source;
		tableList = new EntityNode(null, EntityType.TABLE);
		geomList = new GeomListNode(source);
		children = [tableList, geomList];
	}
	public function refresh():void
	{
		geomList.children = null;
	}
	public function equals(other:IWeaveTreeNode):Boolean { return other == this; }
	public function getLabel():String
	{
		return source.getLabel();
	}
	public function isBranch():Boolean { return true; }
	public function hasChildBranches():Boolean { return true; }
	public function getChildren():Array
	{
		tableList.setEntityCache(source.entityCache);
		
		var str:String = Weave.lang("Data Tables");
		if (tableList.getChildren().length)
			str = Weave.lang("{0} ({1})", str, tableList.getChildren().length);
		tableList._overrideLabel = str;
		
		return children;
	}
}

/**
 * Makes an RPC to find geometry columns for its children
 */
internal class GeomListNode implements IWeaveTreeNode
{
	private var source:WeaveDataSource;
	private var cache:EntityCache;
	internal var children:Array;
	public function GeomListNode(source:WeaveDataSource)
	{
		this.source = source;
	}
	public function equals(other:IWeaveTreeNode):Boolean { return other == this; }
	public function getLabel():String
	{
		var label:String = Weave.lang("Geometry Collections");
		if (children && children.length)
			return Weave.lang("{0} ({1})", label, children.length);
		return label;
	}
	public function isBranch():Boolean { return true; }
	public function hasChildBranches():Boolean { return false; }
	public function getChildren():Array
	{
		if (!children || cache != source.entityCache)
		{
			cache = source.entityCache;
			children = [];
			var meta:Object = {};
			meta[ColumnMetadata.ENTITY_TYPE] = EntityType.COLUMN;
			meta[ColumnMetadata.DATA_TYPE] = DataType.GEOMETRY;
			cache.getHierarchyInfo(meta).then(handleHierarchyInfo.bind(this, children));
		}
		return children;
	}
	private function handleHierarchyInfo(children:Array, result:Array):void
	{
		// ignore old results
		if (this.children != children)
			return;
		
		for each (var info:EntityHierarchyInfo in result)
		{
			var node:EntityNode = new GeomColumnNode(source.entityCache);
			node.id = info.id;
			children.push(node);
		}
		Weave.getCallbacks(source).triggerCallbacks();
	}
}

internal class GeomColumnNode extends EntityNode
{
	public function GeomColumnNode(cache:EntityCache)
	{
		super(cache);
	}
	
	override public function getLabel():String
	{
		var title:String = super.getLabel();
		var cache:EntityCache = getEntityCache();
		var entity:Entity = getEntity();
		for each (var parentId:int in entity.parentIds)
		{
			var info:EntityHierarchyInfo = cache.getBranchInfo(parentId);
			if (info && info.title && info.title != title)
				return title + " (" + info.title + ")";
		}
		return title;
	}
}
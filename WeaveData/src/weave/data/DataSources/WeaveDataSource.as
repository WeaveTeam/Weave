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

package weave.data.DataSources
{
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.EntityType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataRowSource;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSourceWithAuthentication;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.api.services.beans.Entity;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.data.QKeyManager;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.SecondaryKeyNumColumn;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.hierarchy.EntityNode;
	import weave.primitives.GeneralizedGeometry;
	import weave.services.EntityCache;
	import weave.services.WeaveDataServlet;
	import weave.services.addAsyncResponder;
	import weave.services.beans.AttributeColumnData;
	import weave.services.beans.TableData;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.WeavePromise;
	
	/**
	 * WeaveDataSource is an interface for retrieving columns from Weave data servlets.
	 * 
	 * @author adufilie
	 */
	public class WeaveDataSource extends AbstractDataSource_old implements IDataSource_Service, IDataRowSource, IDataSourceWithAuthentication
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
		private var _proxyPromiseCache:Dictionary;
		private var _entityCache:EntityCache = null;
		public const url:LinkableString = newLinkableChild(this, LinkableString);
		public const hierarchyURL:LinkableString = newLinkableChild(this, LinkableString);
		public const rootId:LinkableVariable = newLinkableChild(this, LinkableVariable);
		
		/**
		 * This is an Array of public metadata field names that should be used to uniquely identify columns when querying the server.
		 */
		private const _idFields:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array, verifyStringArray));
		
		// for backwards compatibility to override server idFields setting
		private var _overrideIdFields:LinkableVariable;
		
		/**
		 * Provided for backwards compatibility - setting this will override the server setting.
		 */
		[Deprecated] public function get idFields():LinkableVariable
		{
			if (!_overrideIdFields)
				_overrideIdFields = registerLinkableChild(_idFields, new LinkableVariable(Array, verifyStringArray), handleDeprecatedIdFields);
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
			// backwards compatibility
			if (_attributeHierarchy.value !== null)
				return super.getHierarchyRoot();
			
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
			else if (detectLinkableObjectChange(getHierarchyRoot, rootId))
			{
				node.id = -1;
				addAsyncResponder(_service.findEntityIds(id, null), handleRootId, null, rootId.triggerCounter);
			}
			
			return _rootNode;
		}
		private function handleRootId(event:ResultEvent, triggerCount:int):void
		{
			var node:EntityNode = getHierarchyRoot() as EntityNode;
			if (!node || rootId.triggerCounter != triggerCount)
				return;
			var ids:Array = event.result as Array || [];
			if (!ids.length)
			{
				reportError("No entity matches specified rootId: " + Compiler.stringify(rootId.getSessionState()));
				return;
			}
			if (ids.length > 1)
				reportError("Multiple entities (" + ids.length + ") match specified rootId: " + Compiler.stringify(rootId.getSessionState()));
			node.id = ids[0];
			getCallbackCollection(this).triggerCallbacks();
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
		
		public function getRows(keys:Array):AsyncToken
		{
			return _service.getRows(keys);
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
				if (!url.value || url.value == deprecatedBaseURL || url.value == deprecatedBaseURL + DEFAULT_SERVLET_NAME)
					url.value = WeaveDataServlet.DEFAULT_URL;
			
			// backwards compatibility -- if url ends in default base url, append default servlet name
			if (url.value.split('/').pop() == DEFAULT_BASE_URL.split('/').pop())
				url.value += DEFAULT_SERVLET_NAME;
			
			// replace old service
			disposeObject(_service);
			disposeObject(_entityCache);
			_service = registerLinkableChild(this, new WeaveDataServlet(url.value), setIdFields);
			_entityCache = registerLinkableChild(_service, new EntityCache(_service));
			_tablePromiseCache = {};
			_proxyPromiseCache = new Dictionary(true);
			
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
		
		override protected function handleHierarchyChange():void
		{
			super.handleHierarchyChange();
			_convertOldHierarchyFormat(_attributeHierarchy.value);
			_attributeHierarchy.detectChanges();
		}
		
		protected function _convertOldHierarchyFormat(root:XML):void
		{
			if (!root)
				return;
			
			HierarchyUtils.convertOldHierarchyFormat(root, "category", {
				dataTableName: "name"
			});
			HierarchyUtils.convertOldHierarchyFormat(root, "attribute", {
				attributeColumnName: "name",
				dataTableName: "dataTable",
				dataType: _convertOldDataType,
				projectionSRS: ColumnMetadata.PROJECTION
			});
			for each (var tag:XML in root.descendants())
			{
				if (!String(tag.@title))
				{
					var newTitle:String;
					if (String(tag.@name) && String(tag.@year))
						newTitle = String(tag.@name) + ' (' + tag.@year + ')';
					else if (String(tag.@name))
						newTitle = String(tag.@name);
					tag.@title = newTitle || 'untitled';
				}
			}
		}
		
		protected function _convertOldDataType(value:String):String
		{
			if (value == 'Geometry')
				return DataType.GEOMETRY;
			if (value == 'String')
				return DataType.STRING;
			if (value == 'Number')
				return DataType.NUMBER;
			return value;
		}

		override public function getAttributeColumn(metadata:Object):IAttributeColumn
		{
			if (typeof metadata != 'object')
			{
				var meta:Object;
				var id:Number = StandardLib.asNumber(metadata);
				if (isFinite(id))
					meta = ObjectUtil.copy(entityCache.getEntity(id).publicMetadata);
				else
					meta = {};
				meta[ENTITY_ID] = metadata;
				metadata = meta;
			}
			return super.getAttributeColumn(metadata);
		}
		
		/**
		 * This function must be implemented by classes which extend AbstractDataSource.
		 * This function should make a request to the source to fill in the hierarchy.
		 * @param subtreeNode A pointer to a node in the hierarchy representing the root of the subtree to request from the source.
		 */
		override protected function requestHierarchyFromSource(subtreeNode:XML = null):void
		{
			_convertOldHierarchyFormat(subtreeNode);
			
			//trace("requestHierarchyFromSource("+(subtreeNode?attributeHierarchy.getPathFromNode(subtreeNode).toXMLString():'')+")");

			if (!subtreeNode || subtreeNode == _attributeHierarchy.value)
			{
				if (hierarchyURL.value)
				{
					addAsyncResponder(
						WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(hierarchyURL.value)),
						handleHierarchyURLDownload,
						handleHierarchyURLDownloadError,
						hierarchyURL.value
					);
					trace("hierarchy url "+hierarchyURL.value);
				}
				return;
			}
			
			var idStr:String = subtreeNode.attribute(ENTITY_ID);
			if (idStr)
			{
				addAsyncResponder(
					_service.getEntities([int(idStr)]),
					function(event:ResultEvent, subtreeNode:XML):void
					{
						var entities:Array = event.result as Array;
						if (entities && entities.length)
						{
							getChildNodes(subtreeNode, Entity(entities[0]).childIds);
						}
						else
						{
							reportError(lang('WeaveDataSource: No entity exists with id={0}', idStr));
						}
					},
					handleFault,
					subtreeNode
				);
			}
			else
			{
				// backwards compatibility - get columns with matching dataTable metadata
				var dataTableName:String = subtreeNode.attribute("name");
				addAsyncResponder(
					_service.findEntityIds({"dataTable": dataTableName, "entityType": EntityType.COLUMN}, null),
					function(event:ResultEvent, subtreeNode:XML):void
					{
						var ids:Array = event.result as Array;
						StandardLib.sort(ids);
						getChildNodes(subtreeNode, ids);
					},
					handleFault,
					subtreeNode
				);
			}
			function getChildNodes(subtreeNode:XML, childIds:Array):void
			{
				if (childIds && childIds.length)
					addAsyncResponder(
						_service.getEntities(childIds),
						handleColumnEntities,
						handleFault,
						[subtreeNode, childIds]
					);
			}
		}
		
		private static const NO_RESULT_ERROR:String = "Received null result from Weave server.";
		
		/**
		 * Called when the hierarchy is downloaded from a URL.
		 */
		private function handleHierarchyURLDownload(event:ResultEvent, url:String):void
		{
			if (objectWasDisposed(this) || url != hierarchyURL.value)
				return;
			_attributeHierarchy.value = XML(event.result); // this will run callbacks
		}

		/**
		 * Called when the hierarchy fails to download from a URL.
		 */
		private function handleHierarchyURLDownloadError(event:FaultEvent, url:String):void
		{
			if (url != hierarchyURL.value)
				return;
			reportError(event, null, url);
		}
		
		public static const ENTITY_ID:String = 'weaveEntityId';
		
		private function handleColumnEntities(event:ResultEvent, hierarcyNode_entityIds:Array):void
		{
			if (objectWasDisposed(this))
				return;

			var i:int;
			var entity:Entity;
			var hierarchyNode:XML = hierarcyNode_entityIds[0] as XML; // the node to add the list of columns to
			var entityIds:Array = hierarcyNode_entityIds[1] as Array; // ordered list of ids

			hierarchyNode = HierarchyUtils.findEquivalentNode(_attributeHierarchy.value, hierarchyNode);
			if (!hierarchyNode)
				return;
			
			try
			{
				var entities:Array = event.result as Array;
				
				// sort entities by preferred id order
				var idOrder:Object = {}; // id -> index
				for (i = 0; i < entityIds.length; i++)
					idOrder[entityIds[i]] = i;
				function getEntityIndex(entity:Entity):int { return idOrder[entity.id]; }
				StandardLib.sortOn(entities, getEntityIndex);
				
				// append list of attributes
				for (i = 0; i < entities.length; i++)
				{
					entity = entities[i];
					var metadata:Object = entity.publicMetadata;
					metadata[ENTITY_ID] = entity.id;
					var node:XML = <attribute/>;
					for (var property:String in metadata)
						if (metadata[property])
							node['@'+property] = metadata[property];
					hierarchyNode.appendChild(node);
				}
			}
			catch (e:Error)
			{
				reportError(e, "Unable to process result from servlet: "+ObjectUtil.toString(event.result));
			}
			finally
			{
				//trace("updated hierarchy: "+ attributeHierarchy);
				_attributeHierarchy.detectChanges();
			}
		}
		private function handleFault(event:FaultEvent, token:Object = null):void
		{
			if (objectWasDisposed(_service))
				return;
			reportError(event);
			trace('async token',ObjectUtil.toString(token));
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			// get metadata properties from XML attributes
			var params:Object = getMetadata(proxyColumn, [ENTITY_ID, ColumnMetadata.MIN, ColumnMetadata.MAX, SQLPARAMS], false);
			var query:AsyncToken;
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
			addAsyncResponder(query, handleGetAttributeColumn, handleGetAttributeColumnFault, proxyColumn);
			WeaveAPI.ProgressIndicator.addTask(query, proxyColumn, "Requesting column from server: " + Compiler.stringify(params));
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
		
		private function handleGetAttributeColumnFault(event:FaultEvent, column:ProxyColumn):void
		{
			if (column.wasDisposed)
				return;
			
			var msg:String = "Error retrieving column: " + Compiler.stringify(column.getProxyMetadata()) + ' (' + event.fault.faultString + ')';
			reportError(event.fault, msg, column);
			
			column.dataUnavailable();
		}
//		private function handleGetAttributeColumn(event:ResultEvent, token:Object = null):void
//		{
//			DebugUtils.callLater(5000, handleGetAttributeColumn2, arguments);
//		}
		
		private function parseSqlParams(sqlParams:String):Array
		{
			var result:Array;
			try {
				result = Compiler.parseConstant(sqlParams) as Array;
			} catch (e:Error) { }
			if (!(result is Array))
				result = WeaveAPI.CSVParser.parseCSVRow(sqlParams);
			return result;
		}
		
		private function handleGetAttributeColumn(event:ResultEvent, proxyColumn:ProxyColumn):void
		{
			if (proxyColumn.wasDisposed)
				return;
			var metadata:Object = proxyColumn.getProxyMetadata();

			try
			{
				if (!event.result)
				{
					reportError("Did not receive any data from service for attribute column: " + Compiler.stringify(metadata));
					return;
				}
				
				var result:AttributeColumnData = AttributeColumnData(event.result);
				//trace("handleGetAttributeColumn",pathInHierarchy.toXMLString());
	
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
				var isGeom:Boolean = ObjectUtil.stringCompare(dataType, DataType.GEOMETRY, true) == 0;
				if (isGeom && result.data == null)
				{
					var tileService:IWeaveGeometryTileService = _service.createTileService(result.id);
					proxyColumn.setInternalColumn(new StreamedGeometryColumn(result.metadataTileDescriptors, result.geometryTileDescriptors, tileService, metadata));
					return;
				}
				
				var setRecords:Function = function(keysVector:Vector.<IQualifiedKey>):void
				{
					if (result.data == null)
					{
						proxyColumn.dataUnavailable();
						return;
					}
					
					if (isGeom) // result.data is an array of PGGeom objects.
					{
						var geometriesVector:Vector.<GeneralizedGeometry> = new Vector.<GeneralizedGeometry>();
						var createGeomColumn:Function = function():void
						{
							var newGeometricColumn:GeometryColumn = new GeometryColumn(metadata);
							newGeometricColumn.setGeometries(keysVector, geometriesVector);
							proxyColumn.setInternalColumn(newGeometricColumn);
						};
						var pgGeomTask:Function = PGGeomUtil.newParseTask(result.data, geometriesVector);
						// high priority because not much can be done without data
						WeaveAPI.StageUtils.startTask(proxyColumn, pgGeomTask, WeaveAPI.TASK_PRIORITY_HIGH, createGeomColumn);
					}
					else if (result.thirdColumn != null)
					{
						// hack for dimension slider
						var newColumn:SecondaryKeyNumColumn = new SecondaryKeyNumColumn(metadata);
						newColumn.baseTitle = metadata['baseTitle'];
						var secKeyVector:Vector.<String> = Vector.<String>(result.thirdColumn);
						newColumn.updateRecords(keysVector, secKeyVector, result.data);
						proxyColumn.setInternalColumn(newColumn);
						proxyColumn.setMetadata(null); // this will allow SecondaryKeyNumColumn to use its getMetadata() code
					}
					else if (ObjectUtil.stringCompare(dataType, DataType.NUMBER, true) == 0)
					{
						var newNumericColumn:NumberColumn = new NumberColumn(metadata);
						newNumericColumn.setRecords(keysVector, Vector.<Number>(result.data));
						proxyColumn.setInternalColumn(newNumericColumn);
					}
					else if (ObjectUtil.stringCompare(dataType, DataType.DATE, true) == 0)
					{
						var newDateColumn:DateColumn = new DateColumn(metadata);
						newDateColumn.setRecords(keysVector, Vector.<String>(result.data));
						proxyColumn.setInternalColumn(newDateColumn);
					}
					else
					{
						var newStringColumn:StringColumn = new StringColumn(metadata);
						newStringColumn.setRecords(keysVector, Vector.<String>(result.data));
						proxyColumn.setInternalColumn(newStringColumn);
					} 
					//trace("column downloaded: ",proxyColumn);
					// run hierarchy callbacks because we just modified the hierarchy.
					_attributeHierarchy.detectChanges();
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
					var hash:String = Compiler.stringify([result.tableId, sqlParams]);
					var promise:WeavePromise = _tablePromiseCache[hash];
					if (!promise)
					{
						var getTablePromise:WeavePromise = new WeavePromise(_service)
							.then(function(..._):AsyncToken {
								if (debug)
									weaveTrace('invoking getTable()', hash);
								return _service.getTable(result.tableId, sqlParams);
							});
						
						var keyStrings:Array;
						promise = getTablePromise
							.then(function(tableData:TableData):TableData {
								if (debug)
									weaveTrace('received', debugId(tableData), hash);
								
								if (!tableData.keyColumns)
									tableData.keyColumns = [];
								if (!tableData.columns)
									tableData.columns = {};
								
								var name:String;
								for each (name in tableData.keyColumns)
									if (!tableData.columns.hasOwnProperty(name))
										throw new Error(lang('Table {0} is missing key column "{1}"', tableData.id, name));
								
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
									weaveTrace('promising QKeys', debugId(tableData), hash);
								return (WeaveAPI.QKeyManager as QKeyManager).getQKeysPromise(
									getTablePromise,
									keyType,
									keyStrings
								).then(function(qkeys:Vector.<IQualifiedKey>):TableData {
									if (debug)
										weaveTrace('got QKeys', debugId(tableData), hash);
									tableData.derived_qkeys = qkeys;
									return tableData;
								});
							})
							.then(null, reportError);
						_tablePromiseCache[hash] = promise;
					}
					
					// when the promise returns, set column data
					promise.then(function(tableData:TableData):void {
						result.data = tableData.columns[result.tableField];
						if (result.data == null)
						{
							proxyColumn.dataUnavailable(lang('(Missing column: {0})', result.tableField));
							return;
						}
						
						setRecords(tableData.derived_qkeys);
					});
					
					// make proxyColumn busy while table promise is busy
					var proxyPromise:WeavePromise = _proxyPromiseCache[proxyColumn];
					if (!proxyPromise)
						_proxyPromiseCache[proxyColumn] = proxyPromise = new WeavePromise(proxyColumn).then(function(_:*):* { return promise; });
				}
			}
			catch (e:Error)
			{
				reportError(e);
				trace(this,"handleGetAttributeColumn",Compiler.stringify(metadata),e.getStackTrace());
			}
		}
	}
}

import flash.utils.getTimer;

import mx.rpc.events.ResultEvent;

import weave.api.data.ColumnMetadata;
import weave.api.data.DataType;
import weave.api.data.EntityType;
import weave.api.data.IWeaveTreeNode;
import weave.api.getCallbackCollection;
import weave.api.services.beans.Entity;
import weave.api.services.beans.EntityHierarchyInfo;
import weave.data.AttributeColumns.ProxyColumn;
import weave.data.DataSources.WeaveDataSource;
import weave.data.hierarchy.EntityNode;
import weave.primitives.GeneralizedGeometry;
import weave.primitives.GeometryType;
import weave.services.EntityCache;
import weave.services.addAsyncResponder;
import weave.utils.BLGTreeUtils;

/**
 * Static functions for retrieving values from PGGeom objects coming from servlet.
 */
internal class PGGeomUtil
{
	/**
	 * This will generate an asynchronous task function for use with IStageUtils.startTask().
	 * @param pgGeoms An Array of PGGeom beans from a Weave data service.
	 * @param output A vector to store GeneralizedGeometry objects created from the pgGeoms input.
	 * @return A new Function.
	 * @see weave.api.core.IStageUtils
	 */
	public static function newParseTask(pgGeoms:Array, output:Vector.<GeneralizedGeometry>):Function
	{
		var i:int = 0;
		var n:int = pgGeoms.length;
		output.length = n;
		return function(returnTime:int):Number
		{
			for (; i < n; i++)
			{
				if (getTimer() > returnTime)
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
		return WeaveAPI.globalHashMap.getName(source);
	}
	public function isBranch():Boolean { return true; }
	public function hasChildBranches():Boolean { return true; }
	public function getChildren():Array
	{
		tableList.setEntityCache(source.entityCache);
		
		var str:String = lang("Data Tables");
		if (tableList.getChildren().length)
			str = lang("{0} ({1})", str, tableList.getChildren().length);
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
		var label:String = lang("Geometry Collections");
		if (children && children.length)
			return lang("{0} ({1})", label, children.length);
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
			addAsyncResponder(cache.getHierarchyInfo(meta), handleHierarchyInfo, null, children);
		}
		return children;
	}
	private function handleHierarchyInfo(event:ResultEvent, children:Array):void
	{
		// ignore old results
		if (this.children != children)
			return;
		
		for each (var info:EntityHierarchyInfo in event.result)
		{
			var node:EntityNode = new GeomColumnNode(source.entityCache);
			node.id = info.id;
			children.push(node);
		}
		getCallbackCollection(source).triggerCallbacks();
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
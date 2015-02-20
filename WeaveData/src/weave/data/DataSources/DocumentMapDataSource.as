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
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.core.CallbackCollection;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.QKeyManager;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.services.AMF3Servlet;
	import weave.services.ProxyAsyncToken;
	import weave.services.addAsyncResponder;
	import weave.utils.VectorUtils;
	
	public class DocumentMapDataSource extends AbstractDataSource implements IDataSource_Service
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, DocumentMapDataSource, "Document Map server");
		
		public function DocumentMapDataSource()
		{
			url.addImmediateCallback(this, handleURLChange, true);
			rServiceUrl.addImmediateCallback(this, handleRURLChange, true);
		}
		
		private static const DEFAULT_BASE_URL:String = '/WeaveServices';
		private static const DEFAULT_SERVLET_NAME:String = '/DocumentMapService';
		
		public static const META_COLLECTION:String = 'DocumentMapDataSource_collection';
		public static const META_TABLE:String = 'DocumentMapDataSource_table';
		public static const META_COLUMN:String = 'DocumentMapDataSource_column';
		
		public static const META_ID_FIELDS:Array = [META_COLLECTION, META_TABLE, META_COLUMN];
		
		public static const TABLE_TOPICS:String = 'topics';
		public static const TABLE_DOC_METADATA:String = 'document_metadata';
		public static const TABLE_DOC_WEIGHTS:String = 'document_weights';
		public static const TABLE_NODES:String = 'nodes';
		
		public static const COLUMN_TOPIC_WORDS:String = 'topic_words';
		public static const COLUMN_NODE_X:String = 'node_x';
		public static const COLUMN_NODE_Y:String = 'node_y';
		
		private var _service:AMF3Servlet = null;
		private var _rService:AMF3Servlet = null;
		public const url:LinkableString = registerLinkableChild(this, new LinkableString('/DocumentMapService/'));
		public const rServiceUrl:LinkableString = registerLinkableChild(this, new LinkableString('http://corsac.binaryden.net:8080/WeaveServices/RService'));
		
		private function handleURLChange():void
		{
			disposeObject(_service);
			_service = registerLinkableChild(this, new AMF3Servlet(url.value));
			_listCollectionsCallbacks.triggerCallbacks();
		}
		
		private function handleRURLChange():void
		{
			disposeObject(_rService);
			_rService = registerLinkableChild(this, new AMF3Servlet(rServiceUrl.value));
		}
		
		/**
		 * This gets called as a grouped callback when the session state changes.
		 */
		override protected function initialize():void
		{
			super.initialize();
			
			if (detectLinkableObjectChange(initialize, url, rServiceUrl))
			{
				
			}
		}
		
		/**
		 * Classes that extend AbstractDataSource can define their own replacement for this function.
		 * All column requests will be delayed as long as this accessor function returns false.
		 * The default behavior is to return false during the time between a change in the session state and when initialize() is called.
		 */		
		override protected function get initializationComplete():Boolean
		{
			return _initializeCalled;
		}

		
		override public function refreshHierarchy():void
		{
			super.refreshHierarchy();
			_cache = {};
		}
		
		private var _cache:Object = {};
		/**
		 * @param resultCastFunction A function like function(result:Object):Object which converts the raw servlet result to another format.
		 */
		private function rpc(methodName:String, methodParameters:Array = null, resultCastFunction:Function = null):*
		{
			var stringified:String = Compiler.stringify({method: methodName, params: methodParameters});
			if (!_cache.hasOwnProperty(stringified))
			{
				_cache[stringified] = null;
				var proxyAsyncToken:ProxyAsyncToken = new ProxyAsyncToken(_service.invokeAsyncMethod, [methodName, methodParameters], resultCastFunction, false);
				addAsyncResponder(proxyAsyncToken, handleRPC, handleFault, {service: _service, stringified: stringified});
				proxyAsyncToken.invoke();
			}
			return _cache[stringified];
		}
		private function handleRPC(event:ResultEvent, token:Object):void
		{
			if (token.service != _service)
				return;
			
			_cache[token.stringified] = event.result;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		public function getKeyType(collectionName:String):String { return WeaveAPI.globalHashMap.getName(this) + '_' + collectionName; }
		
		private function getCachedColumn(collection:String, table:String, column:String, type:Class, metadata:Object):*
		{
			var stringified:String = Compiler.stringify(['getColumn', collection, table, column]);
			if (!_cache[stringified])
				_cache[stringified] = registerDisposableChild(_service, new type(metadata));
			return _cache[stringified];
		}
		
		private function getTopicWordsColumn(collectionName:String):StringColumn
		{
			// rpc returns topicID -> wordsArray
			return rpc('getTopicWords', [collectionName], function(topicIdToWords:Object):StringColumn {
				var topicIDs:Array = VectorUtils.getKeys(topicIdToWords);
				var topicWords:Array = topicIDs.map(function(topicID:String, i:int, a:Array):Array {
					return topicIdToWords[topicID].source;
				});
 				var sc:StringColumn = registerDisposableChild(_service, new StringColumn({title: lang('Topic Words')}));
				var keys:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
				(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(sc, getKeyType(collectionName), topicIDs, function():void {
					sc.setRecords(keys, Vector.<String>(topicWords));
				}, keys);
				return sc;
			});
		}
		
		private function getTopicDocWeights(collectionName:String):Object
		{
			return rpc('getTopicDocWeights', [collectionName], function(topicDocWeights:Object):Object {
				var docIDs:Array = [];
				var topicIDs:Array = [];
				var weights:Array = [];
				for (var topicID:String in topicDocWeights)
					for (var docID:String in topicDocWeights[topicID])
						docIDs.push(docID), topicIDs.push(topicID), weights.push(topicDocWeights[topicID][docID]);
				
				var tok:AsyncToken = _rService.invokeAsyncMethod('doForceDirectedLayout', [docIDs, topicIDs, weights, null, null, null, null]);
				addAsyncResponder(tok, function(event:ResultEvent, token:Object = null):void {
					// returns nodeId -> [x, y]
					var nodeIdToXY:Object = event.result;
					var keys:Array = VectorUtils.getKeys(nodeIdToXY);
					var outputKeys:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
					(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(_rService, getKeyType(collectionName), keys, function():void {
						var values:Array = VectorUtils.getItems(nodeIdToXY, keys, []);
						getNodeColumn(collectionName, COLUMN_NODE_X).setRecords(outputKeys, Vector.<Number>(VectorUtils.pluck(values, '0')));
						getNodeColumn(collectionName, COLUMN_NODE_Y).setRecords(outputKeys, Vector.<Number>(VectorUtils.pluck(values, '1')));
					}, outputKeys);
				});
				return topicDocWeights;
			});
		}
		
		private function getNodeColumn(collectionName:String, coord:String):NumberColumn
		{
			getTopicDocWeights(collectionName); // makes sure appropriate RPCs have been called
			return getCachedColumn(collectionName, TABLE_NODES, coord, NumberColumn, {title: lang('Node {0}', coord)});
		}
		
		// avoids recreating collection categories (tree collapse bug)
		private const _listCollectionsCallbacks:ICallbackCollection = newLinkableChild(this, CallbackCollection);
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			var source:DocumentMapDataSource = this;
			if (!_rootNode)
				_rootNode = new ColumnTreeNode({
					source: _listCollectionsCallbacks, // avoids recreating collection categories (tree collapse bug)
					data: {source: source},
					label: WeaveAPI.globalHashMap.getName(this),
					isBranch: true,
					children: function():Array {
						return rpc('listCollections', [], function(collections:Array):Array {
							_listCollectionsCallbacks.triggerCallbacks(); // avoids recreating collection categories (tree collapse bug)
							return collections.map(function(collectionName:String, i:int, a:Array):* {
								var keyType:String = getKeyType(collectionName);
								var topicMeta:Object = {
									title: lang('Topic Words'),
									keyType: keyType
								};
								topicMeta[META_COLLECTION] = collectionName;
								topicMeta[META_TABLE] = TABLE_TOPICS;
								topicMeta[META_COLUMN] = COLUMN_TOPIC_WORDS;

								return {
									source: _listCollectionsCallbacks, // avoids recreating collection categories (tree collapse bug)
									data: {source: source, collection: collectionName},
									isBranch: true,
									hasChildBranches: true,
									label: collectionName,
									children: [
										{
											source: _listCollectionsCallbacks, // avoids recreating collection categories (tree collapse bug)
											data: {source: source, collection: collectionName, table: 'topics'},
											isBranch: true,
											hasChildBranches: false,
											label: lang('Topics'),
											children: [
												{
													source: source,
													idFields: META_ID_FIELDS,
													columnMetadata: topicMeta
												}
											]
										},
										{
											source: source, // causes children refresh when data source triggers callbacks
											data: {source: source, collection: collectionName, table: 'documents'},
											isBranch: true,
											hasChildBranches: false,
											label: lang('Documents'),
											children: function():Array {
												var docPropertyColumns:Array = ['title', 'modifiedTime'].map(function(docProperty:String, i:int, a:Array):Object {
													var meta:Object = {
														title: lang('Document {0}', docProperty),
														keyType: keyType,
														dataType: docProperty == 'modifiedTime' ? DataType.DATE : DataType.STRING
													};
													meta[META_COLLECTION] = collectionName;
													meta[META_TABLE] = TABLE_DOC_METADATA;
													meta[META_COLUMN] = docProperty;
													return {
														source: source,
														idFields: META_ID_FIELDS,
														columnMetadata: meta
													};
												});
												
												var topicWordsColumn:StringColumn = getTopicWordsColumn(collectionName);
												var topicColumns:Array = [];
												if (topicWordsColumn)
												{
													var sortedKeys:Array = topicWordsColumn.keys.concat().sortOn('localName');
													topicColumns = sortedKeys.map(function(key:IQualifiedKey, i:int, a:Array):Object {
														var words:String = topicWordsColumn.getValueFromKey(key, String);
														var title:String = words
															? lang('Topic Weights ({0}: {1})', key.localName, words)
															: lang('Topic Weights ({0})', key.localName);
														var meta:Object = {
															title: title,
															keyType: keyType,
															dataType: DataType.NUMBER
														};
														meta[META_COLLECTION] = collectionName;
														meta[META_TABLE] = TABLE_DOC_WEIGHTS;
														meta[META_COLUMN] = key.localName;
														return {
															source: source,
															idFields: META_ID_FIELDS,
															columnMetadata: meta
														};
													});
												}
												
												return docPropertyColumns.concat(topicColumns);
											}
										},
										{
											source: _listCollectionsCallbacks, // avoids recreating collection categories (tree collapse bug)
											data: {source: source, collection: collectionName, table: 'nodes'},
											isBranch: true,
											hasChildBranches: false,
											label: lang('Nodes'),
											children: [COLUMN_NODE_X, COLUMN_NODE_Y].map(function(coord:String, i:int, a:Array):Object {
												var meta:Object = {
													title: lang('Node {0}', coord),
													keyType: keyType,
													dataType: DataType.NUMBER
												};
												meta[META_COLLECTION] = collectionName;
												meta[META_TABLE] = TABLE_NODES;
												meta[META_COLUMN] = coord;
												return {
													source: source,
													idFields: META_ID_FIELDS,
													columnMetadata: meta
												};
											})
										}
									]
								};
							});
						});
					}
				});
			
			return _rootNode;
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			return new ColumnTreeNode({source: this, columnMetadata: metadata});
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
			var metadata:Object = proxyColumn.getProxyMetadata()
			var collection:String = metadata[META_COLLECTION];
			var table:String = metadata[META_TABLE];
			var column:String = metadata[META_COLUMN];

			var data:Object;
			var dataType:String;
			
			if (table == TABLE_TOPICS)
			{
				proxyColumn.setInternalColumn(getTopicWordsColumn(collection));
				return;
			}
			else if (table == TABLE_DOC_METADATA)
			{
				data = rpc('getDocMetadata', [collection, column]);
				dataType = DataType.STRING;
			}
			else if (table == TABLE_DOC_WEIGHTS)
			{
				var topicDocWeights:Object = getTopicDocWeights(collection);
				data = topicDocWeights && topicDocWeights[column];
				dataType = DataType.NUMBER;
			}
			else if (table == TABLE_NODES)
			{
				proxyColumn.setInternalColumn(getNodeColumn(collection, column));
				return;
			}
			
			if (!data)
			{
				proxyColumn.dataUnavailable();
				return;
			}
			
			try
			{
				var keyType:String = getKeyType(collection);
				var keyStrings:Array = VectorUtils.getKeys(data);
				var keysVector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
				var setRecords:Function = function():void
				{
					if (ObjectUtil.stringCompare(dataType, DataType.NUMBER, true) == 0)
					{
						var values:Array = keyStrings.map(function(keyString:String, i:int, a:Array):Number {
							return data[keyString];
						});
						var newNumericColumn:NumberColumn = getCachedColumn(collection, table, column, NumberColumn, metadata);
						newNumericColumn.setRecords(keysVector, Vector.<Number>(values));
						proxyColumn.setInternalColumn(newNumericColumn);
					}
					else if (ObjectUtil.stringCompare(dataType, DataType.DATE, true) == 0)
					{
						var values:Array = keyStrings.map(function(keyString:String, i:int, a:Array):String {
							return data[keyString];
						});
						var newDateColumn:DateColumn = getCachedColumn(collection, table, column, DateColumn, metadata);
						newDateColumn.setRecords(keysVector, Vector.<String>(values));
						proxyColumn.setInternalColumn(newDateColumn);
					}
					else
					{
						var values:Array = keyStrings.map(function(keyString:String, i:int, a:Array):String {
							return data[keyString];
						});
						var newStringColumn:StringColumn = getCachedColumn(collection, table, column, StringColumn, metadata);
						newStringColumn.setRecords(keysVector, Vector.<String>(values));
						proxyColumn.setInternalColumn(newStringColumn);
					} 
				};
				
				(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(proxyColumn, keyType, VectorUtils.getKeys(data), setRecords, keysVector);
			}
			catch (e:Error)
			{
				reportError(e);
				trace(this,"handleGetAttributeColumn",Compiler.stringify(metadata),e.getStackTrace());
			}
		}
	}
}

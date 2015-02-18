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
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.EntityType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataRowSource;
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
	import weave.api.services.IWeaveGeometryTileService;
	import weave.api.services.beans.Entity;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.SecondaryKeyNumColumn;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.QKeyManager;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.data.hierarchy.EntityNode;
	import weave.primitives.GeneralizedGeometry;
	import weave.services.AMF3Servlet;
	import weave.services.EntityCache;
	import weave.services.ProxyAsyncToken;
	import weave.services.WeaveDataServlet;
	import weave.services.addAsyncResponder;
	import weave.services.beans.AttributeColumnData;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
	public class DocumentMapDataSource extends AbstractDataSource implements IDataSource_Service
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, DocumentMapDataSource, "Document Map server");
		
		public function DocumentMapDataSource()
		{
			url.addImmediateCallback(this, handleURLChange, true);
		}
		
		private var _service:AMF3Servlet = null;
		public const url:LinkableString = registerLinkableChild(this, new LinkableString('/DocumentMapService/'));
		
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
			var stringified:String = Compiler.stringify(arguments);
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
		
		private function getTopicWordsColumn(collectionName:String):StringColumn
		{
			// rpc returns topicID -> wordsArray
			return rpc('getTopics', [collectionName], function(topicIdToWords:Object):StringColumn {
				var topicIDs:Array = VectorUtils.getKeys(topicIdToWords);
				var topicWords:Array = topicIDs.map(function(topicID:String, i:int, a:Array):Array {
					return topicIdToWords[topicID];
				});
 				var sc:StringColumn = registerDisposableChild(_service, new StringColumn({title: lang('Topic Words')}));
				var keys:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
				(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(sc, getKeyType(collectionName), topicIDs, function():void {
					sc.setRecords(keys, Vector.<String>(topicWords));
				}, keys);
				return sc;
			});
		}
		
		public static const META_COLLECTION:String = 'DocumentMapDataSource_collectionName';
		public static const META_TOPIC:String = 'DocumentMapDataSource_topicID';
		public static const META_DOC_PROPERTY:String = 'DocumentMapDataSource_documentProperty';
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			var source:DocumentMapDataSource = this;
			if (!_rootNode)
				_rootNode = new ColumnTreeNode({
					source: source,
					children: function():Array{
						return rpc('listCollections', [], function(collections:Array):Array {
							return collections.map(function(collectionName:String, i:int, a:Array):* {
								var keyType:String = getKeyType(collectionName);
								var topicMeta:Object = {
									title: lang('Topic Words'),
									keyType: keyType
								};
								topicMeta[META_COLLECTION] = collectionName;

								return {
									source: source,
									label: collectionName,
									children: [
										{
											label: lang('Topics'),
											children: [
												{
													source: source,
													columnMetadata: topicMeta
												}
											]
										},
										{
											source: source,
											label: lang('Documents'),
											children: function():Array {
												var docPropertyColumns:Array = ['title'].map(function(docProperty:String, i:int, a:Array):Object {
													var meta:Object = {
														title: lang('Document {0}', docProperty),
														keyType: keyType,
														dataType: DataType.STRING
													};
													meta[META_COLLECTION] = collectionName;
													meta[META_DOC_PROPERTY] = docProperty;
													return {source: source, columnMetadata: meta};
												});
												
												var topicWordsColumn:StringColumn = getTopicWordsColumn(collectionName);
												var topicColumns:Array = [];
												if (topicWordsColumn)
													topicColumns = topicWordsColumn.keys.map(function(key:IQualifiedKey, i:int, a:Array):Object {
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
													meta[META_TOPIC] = key.localName;
													return {source: source, columnMetadata: meta};
												});
												
												return docPropertyColumns.concat(topicColumns);
											}
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
		
		private static const DEFAULT_BASE_URL:String = '/WeaveServices';
		private static const DEFAULT_SERVLET_NAME:String = '/DocumentMapService';
		
		/**
		 * This function prevents url.value from being null.
		 */
		private function handleURLChange():void
		{
			disposeObject(_service);
			_service = registerLinkableChild(this, new AMF3Servlet(url.value));
		}
		
		/**
		 * This gets called as a grouped callback when the session state changes.
		 */
		override protected function initialize():void
		{
			super.initialize();
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
			var collectionName:String = metadata[META_COLLECTION];
			var docProperty:String = metadata[META_DOC_PROPERTY];
			var topic:String = metadata[META_TOPIC];

			var data:Object;
			var dataType:String;
			if (docProperty)
			{
				data = rpc('getDocMetadata', [collectionName, docProperty]);
				dataType = DataType.STRING;
			}
			else
			{
				var topicDocWeights:Object = rpc('getTopicDocWeights', [collectionName]);
				data = topicDocWeights && topicDocWeights[topic];
				dataType = DataType.NUMBER;
			}
			
			if (!data)
			{
				proxyColumn.dataUnavailable();
				return;
			}
			
			try
			{
				var keyType:String = getKeyType(collectionName);
				var keyStrings:Array = VectorUtils.getKeys(data);
				var values:Array = keyStrings.map(function(keyString:String, i:int, a:Array):Array {
					return data[keyString];
				});
				var keysVector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
				var setRecords:Function = function():void
				{
					if (ObjectUtil.stringCompare(dataType, DataType.NUMBER, true) == 0)
					{
						var newNumericColumn:NumberColumn = new NumberColumn(metadata);
						newNumericColumn.setRecords(keysVector, Vector.<Number>(values));
						proxyColumn.setInternalColumn(newNumericColumn);
					}
					else if (ObjectUtil.stringCompare(dataType, DataType.DATE, true) == 0)
					{
						var newDateColumn:DateColumn = new DateColumn(metadata);
						newDateColumn.setRecords(keysVector, Vector.<String>(values));
						proxyColumn.setInternalColumn(newDateColumn);
					}
					else
					{
						var newStringColumn:StringColumn = new StringColumn(metadata);
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

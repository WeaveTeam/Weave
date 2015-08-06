package weave.data.DataSources
{
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.ClassUtils;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.services.JsonCache;
	import weave.services.URLRequestUtils;
	import weave.services.addAsyncResponder;
	import weave.utils.DataSourceUtils;
	import weave.utils.VectorUtils;
	
	public class MultiInterpreterDataSource extends AbstractDataSource implements IDataSource_Service
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, MultiInterpreterDataSource);
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString, refreshAllProxyColumns);
		public const targetKeyType:LinkableString = newLinkableChild(this, LinkableString, refreshAllProxyColumns);
		public const url:LinkableString = registerLinkableChild(this, new LinkableString("http://localhost:8080/api?kb=kb-wn-vn-single"), handleUrlChange);
		public const documentText:DynamicColumn = newLinkableChild(this, DynamicColumn, documentsChanged);
		public const documentTime:DynamicColumn = newLinkableChild(this, DynamicColumn, documentsChanged);
		
		
		private var alerts:Array = [];
		private var processedDocumentKeys:Array = [];
		private const cache:JsonCache = newLinkableChild(this, JsonCache);
		private static const JSON:Object = ClassUtils.getClassDefinition('JSON');
		
		public function MultiInterpreterDataSource()
		{
			super();
		}
		
		private function documentsChanged():void
		{
			VectorUtils.subtract(documentText.keys, processedDocumentKeys).map(processDocument, this);
		}
		
		private function processDocument(key:IQualifiedKey,..._):void
		{			
			processedDocumentKeys.push(key);
			
			var jsonBody:Object = {verb: "analyze", 
				retrieve: "alerts",
				text: documentText.getValueFromKey(key, String),
				dateLine: documentTime.getValueFromKey(key, String)};
			
			var req:URLRequest = new URLRequest(url.value);
			req.method = URLRequestMethod.POST;
			req.data = JSON.stringify(jsonBody);
			var token:AsyncToken;
			token = WeaveAPI.URLRequestUtils.getURL(this, req);
			addAsyncResponder(token, handleProcessedDocument, handleFailedDocument, key);
		}
		
		private function handleProcessedDocument(event:ResultEvent, token:Object = null):void
		{
			var jsonContent:Object = JSON.parse(event.result);
			var documentKey:IQualifiedKey = token as IQualifiedKey;

			for each (var row:Object in jsonContent.alerts)
			{
				row.documentKey = documentKey;
				alerts.push(row);
			}
			
			if (jsonContent.alerts.length > 0)
				refreshAllProxyColumns();

			return;
		}
		
		private function handleFailedDocument(event:FaultEvent, token:Object = null):void
		{
			var documentKey:IQualifiedKey = token as IQualifiedKey;
			reportError(event, "Failed to process document with key " + documentKey.localName, event.fault.content);
		}
		
		private function handleUrlChange():void
		{
			alerts = [];
			processedDocumentKeys = [];
			documentsChanged();
			refreshAllProxyColumns();
		}
		
		public static const MULTI_INTERPRETER_QUERY_META:String = "__MultiInterpreterQuery__";
		public static const MULTI_INTERPRETER_COLUMN_META:String = "__MultiInterpreterColumn__";
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			var self:MultiInterpreterDataSource = this;
			if (_rootNode) 
				return _rootNode
			else
			{
				return new ColumnTreeNode({
					dataSource: self,
					data: {},
					label: WeaveAPI.globalHashMap.getName(this),
					hasChildBranches: true,
					children: function():Array {
						return ["analyze"].map(function(item:String,..._):IWeaveTreeNode {
							var queryMeta:Object = {};
							queryMeta[MULTI_INTERPRETER_QUERY_META] = item;
							if (item == "analyze")
							{
								return new ColumnTreeNode({
									dataSource: self,
									data: queryMeta,
									label: item,
									idFields: [MULTI_INTERPRETER_QUERY_META],
									hasChildBranches: false,
									children: function():Array {
										return ALERTCOLUMNS.map(function(item:String,..._):IWeaveTreeNode {
											var columnMeta:Object = ObjectUtil.copy(queryMeta);
											columnMeta[MULTI_INTERPRETER_COLUMN_META] = item;
											return new ColumnTreeNode({
												dataSource: self,
												data: columnMeta,
												idFields: [MULTI_INTERPRETER_QUERY_META, MULTI_INTERPRETER_COLUMN_META], 
												label: item
											});
										}, self);
									}
								});	
							}
							else
								return null;
						});
					}
				});
			};
		}
		
		private static const ALERTID:String = "alertId";
		private static const ALERTTYPE:String = "alertType";
		private static const EVIDENCESPANS:String = "evidenceSpans";
		private static const ALERTEDKEYS:String = "alertedKeys";
		private static const DOCUMENTKEY:String = "documentKey";
		private static const ALERTCOLUMNS:Array = [ALERTID, ALERTTYPE, EVIDENCESPANS, ALERTEDKEYS, DOCUMENTKEY];
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			return new ColumnTreeNode({
				dataSource: this,
				data: metadata,
				idFields: VectorUtils.intersection(VectorUtils.getKeys(metadata), 
					[MULTI_INTERPRETER_COLUMN_META, MULTI_INTERPRETER_QUERY_META]),
				label: metadata[MULTI_INTERPRETER_COLUMN_META] || metadata[MULTI_INTERPRETER_QUERY_META]
			});
		}

		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var proxyMetadata:Object = ColumnMetadata.getAllMetadata(proxyColumn);
			var columnName:String = proxyMetadata[MULTI_INTERPRETER_COLUMN_META];

			var values:Array = [];
			var keys:Array = [];
			
			if (!proxyMetadata.hasOwnProperty(ColumnMetadata.KEY_TYPE))
			{
				proxyMetadata[ColumnMetadata.KEY_TYPE] = keyType.value;
			}
			
			var alert:Object;
			var key:String;
			var span:Object;

			switch (columnName)
			{
				case "alertId":
				case "alertType":
					for each (alert in alerts)
					{
						keys.push(alert[ALERTID]);
						values.push(alert[columnName]);
					}	
					break;
				case "documentKey":
					for each (alert in alerts)
					{
						keys.push(alert[ALERTID]);
						values.push(alert[columnName].localName);
					}
					proxyMetadata[ColumnMetadata.DATA_TYPE] = documentText.getMetadata(ColumnMetadata.KEY_TYPE);
					break;
				case "alertedKeys":
					for each (alert in alerts)
					{
						for each (key in alert[ALERTEDKEYS])
						{
							keys.push(alert[ALERTID]);
							values.push(key);
						}
					}
					proxyMetadata[ColumnMetadata.DATA_TYPE] = targetKeyType.value;
					break;
				case "evidenceSpans":
					for each (alert in alerts)
					{
						for each (span in alert[EVIDENCESPANS])
						{
							keys.push(alert[ALERTID]);
							values.push(span.f + "," + span.t);
						}
					}
					break;
				default:
					proxyColumn.dataUnavailable("Unknown column \"" + columnName + "\""); 
			}
			
			proxyColumn.setMetadata(proxyMetadata);

			DataSourceUtils.initColumn(proxyColumn, keys, values);
		}
	}
}
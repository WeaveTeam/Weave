package weave.data.DataSources
{
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.newLinkableChild;
	import weave.core.LinkableFile;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.flascc.date_parse;
	import weave.services.JsonCache;
	import weave.utils.DataSourceUtils;
	import weave.utils.VectorUtils;
	
	public class JsonDataSource extends AbstractDataSource implements IDataSource_File
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, JsonDataSource);
		
		public static const JSON_FIELD_META:String = "__JSONField__";
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString, columnsConfigChange);
		public const keyColName:LinkableString = newLinkableChild(this, LinkableString, columnsConfigChange);
		public const metadata:LinkableVariable = newLinkableChild(this, LinkableVariable, columnsConfigChange);
		public const url:LinkableFile = newLinkableChild(this, LinkableFile, handleFile);
		
		private var jsonData:Array = null;
		private var columnStructure:Object = null;
		
		public function JsonDataSource()
		{
			super();
		}

		private function columnsConfigChange():void
		{
			hierarchyRefresh.triggerCallbacks();
		}
		
		private static function getChain(obj:Object, chain:*):*
		{
			var value:* = obj;

			if (chain is String)
				chain = [chain];

			for each (var key:String in chain)
			{
				if (!value.hasOwnProperty(key))
				{
					return undefined;
				}
				else
				{
					value = value[key];
				}
			}
			return value;
		}
		
		private static function mergeProperties(objectA:Object, objectB:Object):void
		{
			for (var key:String in objectB)
			{
				var itemA:* = objectA[key];
				var itemB:* = objectB[key];
				if ((itemA is Object || itemA is Array) &&
					(itemB is Object || itemB is Array))
					mergeProperties(itemA, itemB);
				else if (!(itemA is Object || itemA is Array))
					objectA[key] = true;
			}
		}
		
		private function handleFile():void
		{
			jsonData = JsonCache.parseJSON(url.result as String || '') as Array;
			columnStructure = {};
			
			for each (var row:Object in jsonData)
			{
				mergeProperties(columnStructure, row);
			}
		}
		
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var proxyMetadata:Object = ColumnMetadata.getAllMetadata(proxyColumn);
			var propertyChain:* = JsonCache.parseJSON(proxyMetadata[JSON_FIELD_META]);
			
			if (!jsonData)
			{
				proxyColumn.dataUnavailable();
				return;
			}
			
			if (getChain(propertyChain, jsonData) === undefined)
			{
				proxyColumn.dataUnavailable("No such property " + proxyMetadata[JSON_FIELD_META] + " of JSON data.");
				return;
			}
			
			var values:Array = new Array(jsonData.length);
			var keys:Array = new Array(jsonData.length);
			var newMetadata:Object;

			if (metadata.getSessionState())
			{
				 newMetadata = metadata.getSessionState()[proxyMetadata[JSON_FIELD_META]] || {};
				 newMetadata[ColumnMetadata.KEY_TYPE] = keyType.value;
				 proxyColumn.setMetadata(newMetadata);
			}
			
			for (var index:int = 0; index < jsonData.length; index++)
			{
				keys[index] = jsonData[index][keyColName.value];
				values[index] = getChain(jsonData[index], propertyChain);
			}
			
			DataSourceUtils.initColumn(proxyColumn, keys, values);
		}
		
		private function pathHasChildBranches(path:Array):Boolean
		{
			var node:Object = getChain(columnStructure, path);
			for each (var item:* in node)
			{	
				if (typeof(item) == "object") return true;
			}
			return false;
		}
		
		private function buildNode(path:Array):ColumnTreeNode
		{
			return new ColumnTreeNode({
				dataSource: this,
				data: path,
				idFields: VectorUtils.getKeys(path),
				label: (path.length == 0 ? WeaveAPI.globalHashMap.getName(this) : path.slice(-1)[0]),
				hasChildBranches: pathHasChildBranches(path),
				children: function():Array {
					var parent:Object = getChain(jsonData, path);
					if (typeof(parent) == "boolean") return null;
					else return VectorUtils.getKeys(parent).map(
						function (key:String, ..._):Object {
							return buildNode(path.concat([key]));
						});
				}
			});
		}
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			var self:JsonDataSource = this;
			return buildNode([]);
		}
	}
}
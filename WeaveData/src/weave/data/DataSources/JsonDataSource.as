package weave.data.DataSources
{
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.compiler.Compiler;
	import weave.core.ClassUtils;
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
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString, refreshColumnsAndHierarchy);
		public const keyColName:LinkableString = newLinkableChild(this, LinkableString, refreshColumnsAndHierarchy);
		public const metadata:LinkableVariable = newLinkableChild(this, LinkableVariable, refreshColumnsAndHierarchy);
		public const url:LinkableFile = newLinkableChild(this, LinkableFile, handleFile);
		
		private var jsonData:Array = null;
		private var columnStructure:Object = null;
		
		public function JsonDataSource()
		{
			super();
		}
		
		private static function isObject(value:Object):Boolean
		{
			return value != null && typeof value == 'object';
		}
		
		public function get properties():Array
		{
			if (columnStructure)
			{
				return VectorUtils.getKeys(columnStructure).filter(
						function(d:String,..._):Boolean { return !isObject(columnStructure[d]); }
					);
			}
			else
			{
				return null;
			}
		}

		private function refreshColumnsAndHierarchy():void
		{
			refreshAllProxyColumns();
			hierarchyRefresh.triggerCallbacks();
		}

		private function handleFile():void
		{
			if (!url.result)
			{
				jsonData = null;
				return;
			}
				
			jsonData = JsonCache.parseJSON(url.result.toString() || '') as Array;
			columnStructure = {};
			
			for each (var row:Object in jsonData)
			{
				mergeProperties(columnStructure, row);
			}

			refreshColumnsAndHierarchy();
		}
		
		public static const JSON_FIELD_META_PREFIX:String = "__JsonPathIndex__";
		/* Encode the path arrays using special properties of the metadata object. */
		private static function fromPathToMetadata(path:Array):Object
		{
			var metadataObject:Object = {};
			for (var index:String in path)
			{
				metadataObject[JSON_FIELD_META_PREFIX + index] = path[index];
			}
			return metadataObject;
		}
		
		private static function fromMetadataToPath(metadataObject:Object):Array
		{
			var arrayOutput:Array = [];
			var index:String;
			for (var key:String in metadataObject)
			{
				if (key.indexOf(JSON_FIELD_META_PREFIX) == 0)
				{
					index = key.substr(JSON_FIELD_META_PREFIX.length);
					arrayOutput[index] = metadataObject[key];
				}
			}
			return arrayOutput;
		}
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			return _rootNode ? _rootNode : _rootNode = buildObjectNode([]);
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			return buildNode(fromMetadataToPath(metadata));
		}
		
		private function pathHasChildBranches(path:Array):Boolean
		{
			var node:Object = getChain(columnStructure, path);
			for each (var item:* in node)
			{	
				if (isObject(item))
					return true;
			}
			return false;
		}
		
		private function buildNode(path:Array):ColumnTreeNode
		{
			var obj:* = getChain(columnStructure, path);
			if (!isObject(obj))
				return buildColumnNode(path);
			else
				return buildObjectNode(path);
		}
		
		private function buildColumnNode(path:Array):ColumnTreeNode
		{
			var meta:Object = fromPathToMetadata(path);
			return new ColumnTreeNode({
				dataSource: this,
				data: meta,
				idFields: VectorUtils.getKeys(meta),
				label: path.slice(-1)[0],
				children: null
			});
		}

		private function buildObjectNode(path:Array):ColumnTreeNode
		{
			var meta:Object = fromPathToMetadata(path);
			var obj:* = getChain(columnStructure, path);
			return new ColumnTreeNode({
				dataSource: this,
				data: meta,
				idFields: path.length == 0 ? null : VectorUtils.getKeys(meta),
				label: (path.length == 0 ? WeaveAPI.globalHashMap.getName(this) : path.slice(-1)[0]),
				hasChildBranches: pathHasChildBranches(path),
				children: function():Array {
					return VectorUtils.getKeys(obj).map(
						function (key:String, ..._):Object {
							return buildNode(path.concat([key]));
						});
				}
			});
		}
		
		
		
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var proxyMetadata:Object = ColumnMetadata.getAllMetadata(proxyColumn);
			var path:Array = fromMetadataToPath(proxyMetadata);
			var JSON:Object = ClassUtils.getClassDefinition('JSON');
			var pathString:String = Compiler.stringify(path);
			
			if (!jsonData)
			{
				proxyColumn.dataUnavailable();
				return;
			}
			
			if (getChain(columnStructure, path) === undefined)
			{
				proxyColumn.dataUnavailable("No such property " + path.toString() + " of JSON data.");
				return;
			}
			
			var values:Array = new Array(jsonData.length);
			var keys:Array = new Array(jsonData.length);
			
			var metadataOverlay:Object = metadata.getSessionState() && metadata.getSessionState()[pathString];			

			if (metadataOverlay)
			{
				for (var key:String in metadataOverlay)
				{
					if (!proxyMetadata.hasOwnProperty(key))
					{
						proxyMetadata[key] = metadataOverlay[key];
					}
				}
			}
			
			
			if (!proxyMetadata.hasOwnProperty(ColumnMetadata.KEY_TYPE))
			{
				proxyMetadata[ColumnMetadata.KEY_TYPE] = keyType.value;
			}
			
			if (!proxyMetadata.hasOwnProperty(ColumnMetadata.TITLE))
			{
				proxyMetadata[ColumnMetadata.TITLE] = path.slice(-1)[0]; 
			}
			
			proxyColumn.setMetadata(proxyMetadata);
			var autoKey:int = 0;
			for (var index:int = 0; index < jsonData.length; index++)
			{
				if (keyColName.value)
					keys[index] = jsonData[index][keyColName.value];
				else
					keys[index] = autoKey++;
				
				values[index] = getChain(jsonData[index], path);
			}
			
			DataSourceUtils.initColumn(proxyColumn, keys, values);
		}
		

		private static function getChain(obj:Object, chain:*):*
		{
			var value:* = obj;

			if (chain is String)
				chain = [chain];

			for each (var key:String in chain)
			{
				if (!isObject(value) || !value.hasOwnProperty(key))
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
				if (isObject(itemA) && isObject(itemB))
					mergeProperties(itemA, itemB);
				else if (!(itemA is Object || itemA is Array))
					objectA[key] = true;
			}
		}
	}
}
package weave.data.DataSources
{
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableString;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.QKeyManager;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.utils.VectorUtils;

	public class AnnotationDataSource extends AbstractDataSource
	{
		public const annotations:LinkableVariable = newLinkableChild(this, LinkableVariable, updateKeyTypes);

		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, AnnotationDataSource, "Annotation Data Source");


		public const ANNOTATION_KEY_TYPE:String = "__Annotation_Key_Type__";

		private var keyTypes:Array = [];

		public function AnnotationDataSource():void
		{
			
		}

		private function updateKeyTypes():void
		{
			var annotation_keytypes:Object = annotations.getSessionState();

			if (!annotation_keytypes)
			{
				keyTypes = [];
				return;
			}

			keyTypes = VectorUtils.getKeys(annotation_keytypes);
		}

		public function setAnnotation(key:IQualifiedKey,value:String):void
		{
			var annotation_keytypes:Object = annotations.getSessionState();
			var annotation_locals:Object;

			if (!annotation_keytypes)
			{
				annotation_keytypes = {};
			}

			if (!annotation_keytypes[key.keyType] && value)
			{
				annotation_keytypes[key.keyType] = {};
			}

			annotation_locals = annotation_keytypes[key.keyType];

			if (value)
			{
				annotation_locals[key.localName] = value;
			}
			else
			{
				delete annotation_locals[key.localName];
			}

			if (VectorUtils.isEmpty(annotation_locals))
			{
				delete annotation_keytypes[key.keyType];
			}

			annotations.setSessionState(annotation_keytypes);

			return;
		}

		public function getAnnotation(key:IQualifiedKey):String
		{
			var annotation_keytypes:Object = annotations.getSessionState();
			if (!annotation_keytypes)
			{
				return undefined;
			}

			if (!annotation_keytypes[key.keyType])
			{
				return undefined;
			}

			return annotation_keytypes[key.keyType] && annotation_keytypes[key.keyType][key.localName];
		}

		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			return new ColumnTreeNode({
				source: this,
				idFields: [ANNOTATION_KEY_TYPE],
				columnMetadata: metadata
			});
		}

		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();

			var keyType:String = metadata[ANNOTATION_KEY_TYPE];

			metadata[ColumnMetadata.KEY_TYPE] = keyType;
			metadata[ColumnMetadata.DATA_TYPE] = DataType.STRING;

			var annotation_keytypes:Object = annotations.getSessionState();
			var annotation_locals:Object = annotation_keytypes[keyType];

			var key_column:Array = VectorUtils.getKeys(annotation_locals);
			var data_column:Array = VectorUtils.getItems(annotation_locals, key_column);

			var key_vector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>(key_column.length);
			var data_vector:Vector.<String> = new Vector.<String>(data_column.length);

			var new_column:StringColumn = new StringColumn(metadata);

			function setRecords():void
			{
				for (var idx:int = data_vector.length -1; idx >= 0; idx--)
				{
					data_vector[idx] = data_column[idx];
				}
				new_column.setRecords(key_vector, data_vector);
			}

			(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(keyType, key_column, proxyColumn, setRecords, key_vector);
		}

		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (_rootNode)
			{
				var source:AnnotationDataSource = this;
				_rootNode = new ColumnTreeNode({
					source: source,
					data: source,
					label: WeaveAPI.globalHashMap.getName(this),
					isBranch: true,
					hasChildBranches: false,
					children: function():Array {
						if (!keyTypes) updateKeyTypes();
						return keyTypes.map(function (keyType:String):IWeaveTreeNode
						{
							var meta:Object = {};
							meta[ANNOTATION_KEY_TYPE] = keyType;
							return generateHierarchyNode(meta);
						})
					}
				});
			}
			return _rootNode;
		}
	}
}
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
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.newLinkableChild;
	import weave.api.newDisposableChild;
	import weave.api.reportError;
	import weave.core.LinkableString;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.QKeyManager;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.utils.VectorUtils;

	public class AnnotationDataSource extends AbstractDataSource
	{
		public const annotations:LinkableVariable = newLinkableChild(this, LinkableVariable, updateKeyTypes);

		//WeaveAPI.ClassRegistry.registerImplementation(IDataSource, AnnotationDataSource, "Annotation Data Source");


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
				keyTypes = [null];
				return;
			}

			keyTypes = VectorUtils.getKeys(annotation_keytypes);
			keyTypes.push(null);
		}

		public function addDefaultProbeColumn():void
		{
			var probed_columns:LinkableHashMap = WeaveAPI.globalHashMap.getObject("Probed Columns") as LinkableHashMap;
			if (probed_columns)
			{
				var new_column_reference:ReferencedColumn = probed_columns.requestObject("Annotations", ReferencedColumn, false);
				var meta:Object = {};

				meta[ANNOTATION_KEY_TYPE] = null;
				meta[ColumnMetadata.TITLE] = lang("Annotations");

				new_column_reference.setColumnReference(this, meta);
			}
			return;
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

			refreshAllProxyColumns();

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
				dataSource: this,
				idFields: [ANNOTATION_KEY_TYPE],
				columnMetadata: metadata
			});
		}


		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();

			var requested_key_type:String = metadata[ANNOTATION_KEY_TYPE];
			var local_key_types:Array = keyTypes;

			if (requested_key_type)
			{
				local_key_types = [requested_key_type];
			}

			metadata[ColumnMetadata.KEY_TYPE] = requested_key_type;
			metadata[ColumnMetadata.DATA_TYPE] = DataType.STRING;

			var annotation_keytypes:Object = annotations.getSessionState();

			var final_key_array:Array = [];
			var final_data_array:Array = [];

			for (var keytype_idx:int = keyTypes.length - 1; keytype_idx >= 0; keytype_idx--)
			{

				var key_type:String = local_key_types[keytype_idx];

				if (!key_type) continue; /* Skip the blank key_type entry if it exists */
				var annotation_locals:Object = annotation_keytypes[key_type];

				var tmp_keys:Array = VectorUtils.getKeys(annotation_locals);
				var tmp_data:Array = new Array(tmp_keys.length);

				for (var idx:int = tmp_keys.length - 1; idx >= 0; idx--)
				{
					tmp_data[idx] = annotation_locals[tmp_keys[idx]];
				}

				tmp_keys = (WeaveAPI.QKeyManager as QKeyManager).getQKeys(key_type, tmp_keys);

				final_key_array = final_key_array.concat(tmp_keys);
				final_data_array = final_data_array.concat(tmp_data);
			}

			var new_column:StringColumn = new StringColumn(metadata);
			new_column.setRecords(Vector.<IQualifiedKey>(final_key_array), Vector.<String>(final_data_array));
			proxyColumn.setInternalColumn(new_column);
		}

		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!_rootNode)
			{
				var source:AnnotationDataSource = this;
				_rootNode = new ColumnTreeNode({
					dependency: annotations,
					label: WeaveAPI.globalHashMap.getName(this),
					isBranch: true,
					hasChildBranches: false,
					children: function():Array {
						if (!keyTypes)
							updateKeyTypes();
						return keyTypes.map(function (keyType:String, ..._):IWeaveTreeNode
						{
							var meta:Object = {};
							if (keyType)
							{
								meta[ANNOTATION_KEY_TYPE] = keyType;
								meta[ColumnMetadata.TITLE] = keyType + " " + lang("Annotations");
							}
							else
							{
								meta[ANNOTATION_KEY_TYPE] = keyType;
								meta[ColumnMetadata.TITLE] = lang("Annotations");
							}
							return generateHierarchyNode(meta);
						})
					}
				});
			}
			return _rootNode;
		}
	}
}

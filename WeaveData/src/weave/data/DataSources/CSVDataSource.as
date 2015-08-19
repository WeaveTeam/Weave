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
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.StringUtil;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableOwner;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.core.LinkableFile;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.core.LinkableXML;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.CSVParser;
	import weave.data.QKeyManager;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.utils.HierarchyUtils;
	
	/**
	 * 
	 * @author adufilie
	 * @author skolman
	 */
	public class CSVDataSource extends AbstractDataSource implements IDataSource_File
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, CSVDataSource, "CSV file / Delimited text");

		public function CSVDataSource()
		{
			registerLinkableChild(hierarchyRefresh, metadata);
		}

		public const csvData:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array), handleCSVDataChange);
		public const keyType:LinkableString = newLinkableChild(this, LinkableString, updateKeys);
		public const keyColName:LinkableString = newLinkableChild(this, LinkableString, updateKeys);
		
		public const metadata:LinkableVariable = registerLinkableChild(this, new LinkableVariable(null, verifyMetadata));
		private function verifyMetadata(value:Object):Boolean
		{
			// backwards compatibility for XML hierarchy
			if (LinkableXML.couldBeXML(value))
			{
				try
				{
					var xml:XML = LinkableXML.xmlFromState(value);
					HierarchyUtils.convertOldHierarchyFormat(xml, "attribute", {"name": METADATA_COLUMN_NAME});
					var xmlList:XMLList = xml.children();
					var objectArray:Array = [];
					for each (var tag:XML in xml.descendants('attribute'))
					{
						var title:String = String(tag['@title']);
						if (!title)
						{
							var name:String = String(tag['@name']);
							var year:String = String(tag['@year']);
							if (name && year)
								title = name + ' (' + year + ')';
							else if (name)
								title = name;
							else
								title = String(tag['@csvColumn']) || 'untitled';
							
							tag['@title'] = title;
						}
						objectArray.push(HierarchyUtils.getMetadata(tag));
					}
					metadata.setSessionState(objectArray);
					return false;
				}
				catch (e:Error)
				{
				}
			}
			
			return typeof value == 'object';
		}
		
		public const url:LinkableFile = newLinkableChild(this, LinkableFile, parseRawData);
		
		public const delimiter:LinkableString = registerLinkableChild(this, new LinkableString(',', verifyDelimiter), parseRawData);
		private function verifyDelimiter(value:String):Boolean { return value && value.length == 1 && value != '"'; }
		
		private function parseRawData():void
		{
			if (!url.value)
				return;
			
			if (url.error)
				reportError(url.error);
			
			if (detectLinkableObjectChange(parseRawData, delimiter))
			{
				if (csvParser)
					disposeObject(csvParser);
				csvParser = registerLinkableChild(this, new CSVParser(true, delimiter.value), handleCSVParser);
			}
			
			/*if (linkableObjectIsBusy(rawDataPromise))
				return;*/
			
			csvParser.parseCSV(String(url.result || ''));
		}
		
		private var csvParser:CSVParser;
		
		/**
		 * Called when csv parser finishes its task
		 */
		private function handleCSVParser():void
		{
			// when csv parser finishes, handle the result
			if (url.value)
			{
				// when using url, we don't want to set session state of csvData
				handleParsedRows(csvParser.parseResult);
			}
			else
			{
				csvData.setSessionState(csvParser.parseResult);
			}
		}
		
		/**
		 * Called when csvData session state changes
		 */		
		private function handleCSVDataChange():void
		{
			// save parsedRows only if csvData has non-null session state
			var rows:Array = csvData.getSessionState() as Array;
			// clear url value when we specify csvData session state
			if (url.value && rows != null && rows.length)
				url.value = null;
			if (!url.value)
				handleParsedRows(rows);
		}
		
		/**
		 * Contains the csv data that should be used elsewhere in the code
		 */		
		private var parsedRows:Array;
		private var cachedDataTypes:Object = {};
		private var columnIds:Array = [];
		private var keysVector:Vector.<IQualifiedKey>;
		private const keysCallbacks:ICallbackCollection = newLinkableChild(this, CallbackCollection);
		
		protected function handleParsedRows(rows:Array):void
		{
			if (!rows)
				rows = [];
			cachedDataTypes = {};
			parsedRows = rows;
			columnIds = rows[0] is Array ? (rows[0] as Array).concat() : [];
			// make sure column names are unique - if not, use index values for columns with duplicate names
			var nameLookup:Object = {};
			for (var i:int = 0; i < columnIds.length; i++)
			{
				if (!columnIds[i] || nameLookup.hasOwnProperty(columnIds[i]))
					columnIds[i] = i;
				else
					nameLookup[columnIds[i]] = true;
			}
			updateKeys(true);
			hierarchyRefresh.triggerCallbacks();
		}
		
		private function updateKeys(forced:Boolean = false):void
		{
			var changed:Boolean = detectLinkableObjectChange(updateKeys, keyType, keyColName);
			if (parsedRows && (forced || changed))
			{
				var colNames:Array = parsedRows[0] || [];
				// getColumnValues supports columnIndex -1
				var keyColIndex:int = -1;
				if (keyColName.value)
				{
					keyColIndex = colNames.indexOf(keyColName.value);
					// treat invalid keyColName as an error
					if (keyColIndex < 0)
						keyColIndex = -2;
				}
				var keyStrings:Array = getColumnValues(parsedRows, keyColIndex, []);
				var keyTypeString:String = keyType.value;
				
				keysVector = new Vector.<IQualifiedKey>();
				(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(keysCallbacks, keyType.value, keyStrings, null, keysVector);
			}
		}
		
		/**
		 * Convenience function for setting session state of csvData.
		 * @param rows
		 */
		public function setCSVData(rows:Array):void
		{
			csvData.setSessionState(rows);
		}
		
		public function getCSVData():Array
		{
			return csvData.getSessionState() as Array;
		}
		/**
		 * Convenience function for setting session state of csvData.
		 * @param csvDataString CSV string using comma as a delimiter.
		 */
		public function setCSVDataString(csvDataString:String):void
		{
			csvData.setSessionState(WeaveAPI.CSVParser.parseCSV(csvDataString));
		}
		
		/**
		 * This will get a list of column names in the data, which are taken directly from the header row and not guaranteed to be unique.
		 */		
		public function getColumnNames():Array
		{
			if (parsedRows && parsedRows.length)
				return parsedRows[0].concat();
			return [];
		}

		/**
		 * A unique list of identifiers for columns which may be a mix of Strings and Numbers, depending on the uniqueness of column names.
		 */
		public function getColumnIds():Array
		{
			return columnIds.concat();
		}
		
		/**
		 * Gets whatever is stored in the "metadata" session state for the specified id.
		 */
		private function getColumnMetadata(id:Object):Object
		{
			try
			{
				if (id is Number)
					id = columnIds[id];
				var meta:Object = metadata.getSessionState();
				if (meta is Array)
				{
					var array:Array = meta as Array;
					for (var i:int = 0; i < array.length; i++)
					{
						var item:Object = array[i];
						var itemId:* = item[METADATA_COLUMN_NAME] || item[METADATA_COLUMN_INDEX];
						if (itemId === undefined)
							itemId = columnIds[i];
						if (itemId === id)
							return item;
					}
					return null;
				}
				else if (meta)
					return meta[id];
			}
			catch (e:Error)
			{
				reportError(e);
			}
			return null;
		}
		
		public function getColumnTitle(id:Object):String
		{
			var meta:Object = getColumnMetadata(id);
			var title:String = meta ? meta[ColumnMetadata.TITLE] : null;
			if (!title && typeof id == 'number' && parsedRows && parsedRows.length)
				title = parsedRows[0][id];
			if (!title)
				title = String(id);
			return title;
		}
		
		private function getAttrTagFromColumnId(id:Object):XML
		{
			return HierarchyUtils.nodeFromMetadata(generateMetadataForColumnId(id));
		}
		
		public function generateMetadataForColumnId(id:Object):Object
		{
			var metadata:Object = {};
			metadata[ColumnMetadata.TITLE] = getColumnTitle(id);
			metadata[ColumnMetadata.KEY_TYPE] = keyType.value || DataType.STRING;
			if (cachedDataTypes[id])
				metadata[ColumnMetadata.DATA_TYPE] = cachedDataTypes[id];
			
			// get column metadata from session state
			var meta:Object = getColumnMetadata(id);
			for (var key:String in meta)
				metadata[key] = meta[key];
			
			// overwrite identifying property
			if (typeof id == 'number')
				metadata[METADATA_COLUMN_INDEX] = id;
			else
				metadata[METADATA_COLUMN_NAME] = id;
			
			return metadata;
		}
		
		override public function getAttributeColumn(metadata:Object):IAttributeColumn
		{
			if (typeof metadata != 'object')
				metadata = generateMetadataForColumnId(metadata);
			return super.getAttributeColumn(metadata);
		}
		
		/**
		 * This function will get a column by name or index.
		 * @param columnNameOrIndex The name or index of the CSV column to get.
		 * @return The column.
		 */		
		public function getColumnById(columnNameOrIndex:Object):IAttributeColumn
		{
			return WeaveAPI.AttributeColumnCache.getColumn(this, columnNameOrIndex);
		}
		
		/**
		 * This function will create a column in an ILinkableHashMap that references a column from this CSVDataSource.
		 * @param columnNameOrIndex Either a column name or zero-based column index.
		 * @param destinationHashMap The hash map to put the column in.
		 * @return The column that was created in the hash map.
		 */		
		public function putColumnInHashMap(columnNameOrIndex:Object, destinationHashMap:ILinkableHashMap):IAttributeColumn
		{
			var sourceOwner:ILinkableHashMap = getLinkableOwner(this) as ILinkableHashMap;
			if (!sourceOwner)
				return null;
			
			getCallbackCollection(destinationHashMap).delayCallbacks();
			var refCol:ReferencedColumn = destinationHashMap.requestObject(null, ReferencedColumn, false);
			refCol.setColumnReference(this, generateMetadataForColumnId(columnNameOrIndex));
			getCallbackCollection(destinationHashMap).resumeCallbacks();
			return refCol;
		}
		
		/**
		 * This will modify a column object in the session state to refer to a column in this CSVDataSource.
		 * @param columnNameOrIndex Either a column name or zero-based column index.
		 * @param columnPath A DynamicColumn or the path in the session state that refers to a DynamicColumn.
		 * @return A value of true if successful, false if not.
		 * @see weave.api.IExternalSessionStateInterface
		 */
		public function putColumn(columnNameOrIndex:Object, dynamicColumnOrPath:Object):Boolean
		{
			var sourceOwner:ILinkableHashMap = getLinkableOwner(this) as ILinkableHashMap;
			if (!sourceOwner)
				return false;
			
			var dc:DynamicColumn = dynamicColumnOrPath as DynamicColumn;
			if (!dc)
			{
				WeaveAPI.ExternalSessionStateInterface.requestObject(dynamicColumnOrPath as Array, getQualifiedClassName(DynamicColumn));
				dc = WeaveAPI.getObject(dynamicColumnOrPath as Array) as DynamicColumn;
			}
			if (!dc)
				return false;
			
			getCallbackCollection(dc).delayCallbacks();
			var refCol:ReferencedColumn = dc.requestLocalObject(ReferencedColumn, false);
			refCol.setColumnReference(this, generateMetadataForColumnId(columnNameOrIndex));
			getCallbackCollection(dc).resumeCallbacks();
			
			return true;
		}
		
		
		override protected function get initializationComplete():Boolean
		{
			// make sure csv data is set before column requests are handled.
			return super.initializationComplete && parsedRows && keysVector && !linkableObjectIsBusy(keysCallbacks);
		}
		
		/**
		 * This gets called as a grouped callback.
		 */		
		override protected function initialize():void
		{
			// if url is specified, do not use csvDataString
			if (url.value)
				csvData.setSessionState(null);
			
			// recalculate all columns previously requested because CSV data may have changed.
			refreshAllProxyColumns();

			super.initialize();
		}
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!_rootNode)
				_rootNode = new ColumnTreeNode({
					dataSource: this,
					label: WeaveAPI.globalHashMap.getName(this),
					children: function(root:ColumnTreeNode):Array {
						var items:Array = metadata.getSessionState() as Array;
						if (!items)
							items = getColumnIds();
						var children:Array = [];
						for (var i:int = 0; i < items.length; i++)
						{
							var item:Object = items[i];
							children[i] = generateHierarchyNode(item) || generateHierarchyNode(i);
						}
						return children;
					}
				});
			return _rootNode;
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (typeof metadata != 'object')
				metadata = generateMetadataForColumnId(metadata);
			
			if (!metadata)
				return null;
			
			if (metadata.hasOwnProperty(METADATA_COLUMN_INDEX) || metadata.hasOwnProperty(METADATA_COLUMN_NAME))
			{
				return new ColumnTreeNode({
					dataSource: this,
					label: getColumnNodeLabel,
					idFields: [METADATA_COLUMN_INDEX, METADATA_COLUMN_NAME],
					data: metadata
				});
			}
			
			return null;
		}
		private function getColumnNodeLabel(node:ColumnTreeNode):String
		{
			var title:String = node.data[ColumnMetadata.TITLE] || node.data[METADATA_COLUMN_NAME];
			if (!title && node.data['name'])
			{
				title = node.data['name'];
				if (node.data['year'])
					title = StandardLib.substitute("{0} ({1})", title, node.data['year']);
			}
			return title;
		}

		public static const METADATA_COLUMN_INDEX:String = 'csvColumnIndex';
		public static const METADATA_COLUMN_NAME:String = 'csvColumn';

		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();

			// get column id from metadata
			var columnId:Object = metadata[METADATA_COLUMN_INDEX];
			if (columnId != null)
			{
				columnId = int(columnId);
			}
			else
			{
				columnId = metadata[METADATA_COLUMN_NAME];
				if (!columnId)
				{
					// support for time slider
					for (var i:int = 0; i < columnIds.length; i++)
					{
						var meta:Object = getColumnMetadata(columnIds[i]);
						if (!meta)
							continue;
						var found:int = 0;
						for (var key:String in metadata)
						{
							if (meta[key] != metadata[key])
							{
								found = 0;
								break;
							}
							found++;
						}
						if (found)
						{
							columnId = i;
							break;
						}
					}
					
					// backwards compatibility
					if (!columnId)
						columnId = metadata["name"];
				}
			}
			
			// get column name and index from id
			var colNames:Array = parsedRows[0] || [];
			var colIndex:int, colName:String;
			if (typeof columnId == 'number')
			{
				colIndex = int(columnId);
				colName = colNames[columnId];
			}
			else
			{
				colIndex = colNames.indexOf(columnId);
				colName = String(columnId);
			}
			if (colIndex < 0)
			{
				proxyColumn.dataUnavailable(lang("No such column: {0}", columnId));
				return;
			}
			
			metadata = generateMetadataForColumnId(columnId);
			proxyColumn.setMetadata(metadata);
			
			var strings:Vector.<String> = getColumnValues(parsedRows, colIndex, new Vector.<String>());
			var numbers:Vector.<Number> = null;
			var dateFormats:Array = null;
			
			if (!keysVector || strings.length != keysVector.length)
			{
				proxyColumn.setInternalColumn(null);
				return;
			}
			
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];

			if (dataType == null || dataType == DataType.NUMBER)
			{
				numbers = stringsToNumbers(strings, dataType == DataType.NUMBER);
			}

			if ((!numbers && dataType == null) || dataType == DataType.DATE)
			{
				dateFormats = DateColumn.detectDateFormats(strings);
			}

			var newColumn:IAttributeColumn;
			if (numbers)
			{
				newColumn = new NumberColumn(metadata);
				(newColumn as NumberColumn).setRecords(keysVector, numbers);
			}
			else
			{
				if (dataType == DataType.DATE || (dateFormats && dateFormats.length > 0))
				{
					newColumn = new DateColumn(metadata);
					(newColumn as DateColumn).setRecords(keysVector, strings);
				}
				else
				{
					newColumn = new StringColumn(metadata);
					(newColumn as StringColumn).setRecords(keysVector, strings);
				}
			}
			cachedDataTypes[columnId] = newColumn.getMetadata(ColumnMetadata.DATA_TYPE);
			proxyColumn.setInternalColumn(newColumn);
		}
		
		/**
		 * @param rows The rows to get values from.
		 * @param columnIndex If this is -1, record index values will be returned.  Otherwise, this specifies which column to get values from.
		 * @param outputArrayOrVector Output Array or Vector to store the values from the specified column, excluding the first row, which is the header.
		 * @return outputArrayOrVector
		 */
		private function getColumnValues(rows:Array, columnIndex:int, outputArrayOrVector:*):*
		{
			outputArrayOrVector.length = Math.max(0, rows.length - 1);
			var i:int;
			if (columnIndex == -1)
			{
				// generate keys 0,1,2,3,...
				for (i = 1; i < rows.length; i++)
					outputArrayOrVector[i-1] = i;
			}
			else
			{
				// get column value from each row
				for (i = 1; i < rows.length; i++)
					outputArrayOrVector[i-1] = rows[i][columnIndex];
			}
			return outputArrayOrVector;
		}

		/**
		 * Attempts to convert a list of Strings to Numbers. If successful, returns the Numbers.
		 * @param strings The String values.
		 * @param forced Always return a Vector of Numbers, whether or not the Strings look like Numbers.
		 * @return Either a Vector of Numbers or null
		 */
		private function stringsToNumbers(strings:Vector.<String>, forced:Boolean):Vector.<Number>
		{
			var numbers:Vector.<Number> = new Vector.<Number>(strings.length);
			var i:int = strings.length;
			outerLoop: while (i--)
			{
				var string:String = StringUtil.trim(strings[i]);
				for each (var nullValue:String in nullValues)
				{
					var a:String = nullValue && nullValue.toLocaleLowerCase();
					var b:String = string && string.toLocaleLowerCase();
					if (a == b)
					{
						numbers[i] = NaN;
						continue outerLoop;
					}
				}

				// if a string is 2 characters or more and begins with a '0', treat it as a string.
				if (!forced && string.length > 1 && string.charAt(0) == '0' && string.charAt(1) != '.')
					return null;

				if (string.indexOf(',') >= 0)
					string = string.split(',').join('');
				
				var number:Number = Number(string);
				if (isNaN(number) && !forced)
					return null;
				
				numbers[i] = number;
			}
			return numbers;
		}
		
		private const nullValues:Array = [null, "", "null", "\\N", "NaN"];
		
		// backwards compatibility
		[Deprecated(replacement="csvData")] public function set csvDataString(value:String):void { setCSVDataString(value); }
		[Deprecated(replacement="getColumnById")] public function getColumnByName(name:String):IAttributeColumn { return getColumnById(name); }
		[Deprecated(replacement="metadata")] public function set attributeHierarchy(state:Object):void
		{
			if (LinkableXML.couldBeXML(state))
				metadata.setSessionState(state);
		}
	}
}

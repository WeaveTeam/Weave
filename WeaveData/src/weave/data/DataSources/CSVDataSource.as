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
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.getQualifiedClassName;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.StringUtil;
	
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
	import weave.core.LinkablePromise;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.CSVParser;
	import weave.data.QKeyManager;
	import weave.services.addAsyncResponder;
	import weave.utils.HierarchyUtils;
	
	/**
	 * 
	 * @author adufilie
	 * @author skolman
	 */
	public class CSVDataSource extends AbstractDataSource_old implements IDataSource_File
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, CSVDataSource, "CSV file / Delimited text");

		public function CSVDataSource()
		{
			registerLinkableChild(rawDataPromise, url);
		}

		public const csvData:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array), handleCSVDataChange);
		public const keyType:LinkableString = newLinkableChild(this, LinkableString, updateKeys);
		public const keyColName:LinkableString = newLinkableChild(this, LinkableString, updateKeys);
		
		public const metadata:LinkableVariable = registerLinkableChild(this, new LinkableVariable(null, typeofIsObject));
		private function typeofIsObject(value:Object):Boolean { return typeof value == 'object'; }
		
		public const url:LinkableString = newLinkableChild(this, LinkableString);
		
		public const delimiter:LinkableString = registerLinkableChild(this, new LinkableString(',', verifyDelimiter), parseRawData);
		private function verifyDelimiter(value:String):Boolean { return value && value.length == 1 && value != '"'; }
		
		private const rawDataPromise:LinkablePromise = registerLinkableChild(this, new LinkablePromise(getRawData, null, "Downloading CSV data"), parseRawData);
		private function getRawData():AsyncToken
		{
			if (!url.value)
				return null;
			return WeaveAPI.URLRequestUtils.getURL(rawDataPromise, new URLRequest(url.value));
		}
		private function parseRawData():void
		{
			if (rawDataPromise.error)
				reportError(rawDataPromise.error);
			
			if (detectLinkableObjectChange(parseRawData, delimiter))
			{
				if (csvParser)
					disposeObject(csvParser);
				csvParser = registerLinkableChild(this, new CSVParser(true, delimiter.value), handleCSVParser);
			}
			
			/*if (linkableObjectIsBusy(rawDataPromise))
				return;*/
			
			csvParser.parseCSV(String(rawDataPromise.result || ''));
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
		
		protected function handleParsedRows(rows:Array):void
		{
			cachedDataTypes = {};
			parsedRows = rows;
			columnIds = rows && rows[0] is Array ? (rows[0] as Array).concat() : [];
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
		}
		
		private function updateKeys(forced:Boolean = false):void
		{
			var changed:Boolean = detectLinkableObjectChange(updateKeys, keyType, keyColName);
			if (parsedRows && (forced || changed))
			{
				var colNames:Array = parsedRows[0] || [];
				// it is ok if keyColIndex is -1 because getColumnValues supports -1
				var keyColIndex:int = keyColName.value ? colNames.indexOf(keyColName.value) : -1;
				var keyStrings:Array = getColumnValues(parsedRows, keyColIndex, []);
				var keyTypeString:String = keyType.value;
				
				keysVector = new Vector.<IQualifiedKey>();
				(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(this, keyType.value, keyStrings, getCallbackCollection(this).triggerCallbacks, keysVector);
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
			var meta:Object = metadata.getSessionState();
			if (id is String && meta is Array)
				return meta[columnIds.indexOf(id)];
			else if (meta)
				return meta[id];
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
				dc = WeaveAPI.SessionManager.getObject(WeaveAPI.globalHashMap, dynamicColumnOrPath as Array) as DynamicColumn;
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
			return super.initializationComplete && parsedRows && keysVector;
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
			if (_attributeHierarchy.value === null)
			{
				if (!(_rootNode is CSVColumnNode))
					_rootNode = new CSVColumnNode(this);
				return _rootNode;
			}
			else
			{
				return super.getHierarchyRoot();
			}
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			var csvRoot:CSVColumnNode = getHierarchyRoot() as CSVColumnNode;
			if (!csvRoot)
				return super.generateHierarchyNode(metadata);
			
			if (metadata.hasOwnProperty(METADATA_COLUMN_INDEX))
				return new CSVColumnNode(this, metadata[METADATA_COLUMN_INDEX]);
			if (metadata.hasOwnProperty(METADATA_COLUMN_NAME))
			{
				var index:int = getColumnNames().indexOf(metadata[METADATA_COLUMN_NAME]);
				if (index >= 0)
					return new CSVColumnNode(this, index);
			}
			
			return null;
		}
		
		override protected function handleHierarchyChange():void
		{
			super.handleHierarchyChange();
			convertOldHierarchyFormat(_attributeHierarchy.value, "attribute", {"name": METADATA_COLUMN_NAME});
			if (_attributeHierarchy.value)
			{
				for each (var tag:XML in _attributeHierarchy.value.descendants('attribute'))
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
				}
			}
			_attributeHierarchy.detectChanges();
		}

		/**
		 * This function must be implemented by classes by extend AbstractDataSource.
		 * This function should make a request to the source to fill in the hierarchy.
		 * @param subtreeNode A pointer to a node in the hierarchy representing the root of the subtree to request from the source.
		 */
		override protected function requestHierarchyFromSource(subtreeNode:XML = null):void
		{
			// do nothing
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
					var metaArray:Array = this.metadata.getSessionState() as Array;
					if (metaArray)
					{
						for (var i:int = 0; i < metaArray.length; i++)
						{
							var found:int = 0;
							for (var key:String in metaArray[i])
							{
								if (metaArray[i][key] != metadata[key])
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
					}
					else if (attributeHierarchy.value)
					{
						var node:XML = HierarchyUtils.getFirstNodeContainingAttributes(attributeHierarchy.value.descendants(), HierarchyUtils.nodeFromMetadata(metadata));
						if (node)
							columnId = String(node.@[METADATA_COLUMN_NAME]) || String(node.@['name']);
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
			
			if (!metadata[ColumnMetadata.TITLE])
				metadata[ColumnMetadata.TITLE] = colName;
			
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
			if (columnIndex < 0)
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
		[Deprecated] public function set csvDataString(value:String):void
		{
			setCSVDataString(value);
		}
		
		[Deprecated(replacement="getColumnById")] public function getColumnByName(name:String):IAttributeColumn { return getColumnById(name); }
	}
}

import weave.api.data.ColumnMetadata;
import weave.api.data.IColumnReference;
import weave.api.data.IDataSource;
import weave.api.data.IWeaveTreeNode;
import weave.data.DataSources.CSVDataSource;

internal class CSVColumnNode implements IWeaveTreeNode, IColumnReference
{
	private var source:CSVDataSource;
	public var columnIndex:int;
	internal var children:Array;
	public function CSVColumnNode(source:CSVDataSource = null, columnIndex:int = -1)
	{
		this.source = source;
		this.columnIndex = columnIndex;
		if (columnIndex < 0)
			children = [];
	}
	public function equals(other:IWeaveTreeNode):Boolean
	{
		var that:CSVColumnNode = other as CSVColumnNode;
		return !!that
			&& this.source == that.source
			&& this.columnIndex == that.columnIndex;
	}
	public function getLabel():String
	{
		if (columnIndex < 0)
			return WeaveAPI.globalHashMap.getName(source);
		return source.getColumnTitle(columnIndex);
	}
	public function isBranch():Boolean { return columnIndex < 0; }
	public function hasChildBranches():Boolean { return false; }
	public function getChildren():Array
	{
		if (!children)
			return null;
		
		var ids:Array = source.getColumnIds();
		children.length = ids.length;
		for (var i:int = 0; i < ids.length; i++)
			if (!children[i])
				children[i] = new CSVColumnNode(source, i);
		return children;
	}
	
	public function getDataSource():IDataSource
	{
		return source;
	}
	public function getColumnMetadata():Object
	{
		var id:Object = source.getColumnIds()[columnIndex];
		return id != null && source.generateMetadataForColumnId(id);
	}
}

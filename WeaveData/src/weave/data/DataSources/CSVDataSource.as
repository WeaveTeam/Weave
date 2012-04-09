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
	import flash.utils.Dictionary;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableOwner;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.core.ErrorManager;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
	/**
	 * 
	 * @author adufilie
	 * @author skolman
	 */
	public class CSVDataSource extends AbstractDataSource
	{
		public function CSVDataSource()
		{
			url.addImmediateCallback(this, handleURLChange);
		}
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString);
		public const keyColName:LinkableString = newLinkableChild(this, LinkableString);
		public const csvDataString:LinkableString = newLinkableChild(this, LinkableString, handleCSVDataStringChange);
		
		// contains the parsed csv data
		private var csvDataArray:Array = null;
		
		
		/**
		 * This will get a list of column names in the CSV data.
		 * @return A list of column names in the CSV data. 
		 */		
		public function getColumnNames():Array
		{
			if (csvDataArray && csvDataArray.length)
				return csvDataArray[0].concat();
			return [];
		}
		
		/**
		 * This function will get a column by name.
		 * @param csvColumnName The name of the CSV column to get.
		 * @return The column.
		 */		
		public function getColumnByName(csvColumnName:String):IAttributeColumn
		{
			var sourceOwner:ILinkableHashMap = getLinkableOwner(this) as ILinkableHashMap;
			if (!sourceOwner)
				return null;
			_reusableReference.hierarchyPath.value = <attribute title={csvColumnName} csvColumn={ csvColumnName }/>;
			_reusableReference.dataSourceName.value = sourceOwner.getName(this);
			return WeaveAPI.AttributeColumnCache.getColumn(_reusableReference);
		}
		
		// used by getColumnByName
		private const _reusableReference:HierarchyColumnReference = newDisposableChild(this, HierarchyColumnReference);
		
		/**
		 * This function will create a column in an ILinkableHashMap that references a column from this CSVDataSource.
		 * @param csvColumnName The name of the CSV column to put in the hash map.
		 * @param destinationHashMap The hash map to put the column in.
		 * @return The column that was created in the hash map.
		 */		
		public function putColumnInHashMap(csvColumnName:String, destinationHashMap:ILinkableHashMap):IAttributeColumn
		{

			var sourceOwner:ILinkableHashMap = getLinkableOwner(this) as ILinkableHashMap;
			if (!sourceOwner)
				return null;
			
			getCallbackCollection(destinationHashMap).delayCallbacks();
			var refCol:ReferencedColumn = destinationHashMap.requestObject(null, ReferencedColumn, false);
			var hierarchyColRef1:HierarchyColumnReference =  refCol.dynamicColumnReference.requestLocalObject(HierarchyColumnReference, false);
			
			getCallbackCollection(hierarchyColRef1).delayCallbacks();
			hierarchyColRef1.hierarchyPath.value = <attribute title={csvColumnName} csvColumn={ csvColumnName }/>;
			hierarchyColRef1.dataSourceName.value = sourceOwner.getName(this);
			getCallbackCollection(hierarchyColRef1).resumeCallbacks();
			
			getCallbackCollection(destinationHashMap).resumeCallbacks();
			return refCol;
		}
		
		
		/**
		 * The keys in this Dictionary are ProxyColumns that have been filled in with data via requestColumnFromSource().
		 */
		private const _columnToReferenceMap:Dictionary = new Dictionary();
		
		private function handleURLChange():void
		{
			if (url.value == '')
				url.value = null;
			if (url.value != null)
			{
				// if url is specified, do not use csvDataString
				csvDataString.value = null;
				WeaveAPI.URLRequestUtils.getURL(new URLRequest(url.value), handleCSVDownload, handleCSVDownloadError, url.value, URLLoaderDataFormat.TEXT);
			}
		}
		
		private function handleCSVDataStringChange():void
		{
			if (csvDataString.value == '')
				csvDataString.value = null;
			if (csvDataString.value != null)
			{
				// if csvDataString is specified, do not use url
				url.value = null;
				csvDataArray = WeaveAPI.CSVParser.parseCSV(csvDataString.value);
			}
		}
		
		override protected function get initializationComplete():Boolean
		{
			// make sure csv data is set before column requests are handled.
			return super.initializationComplete && csvDataArray != null;
		}
		
		/**
		 * This gets called when callbacks are triggered.
		 */		
		override protected function initialize():void
		{
			if (_attributeHierarchy.value == null && csvDataArray != null)
			{
				// loop through column names, adding indicators to hierarchy
				var firstRow:Array = csvDataArray[0];
				var root:XML = <hierarchy/>;
				for each (var colName:String in firstRow)
				{
					var attr:XML = <attribute
						title={ colName }
					csvColumn={ colName }
					keyType={ keyType.value }/>;
					root.appendChild(attr);
				}
				_attributeHierarchy.value = root;
			}
			// recalculate all columns previously requested because CSV data may have changed.
			for (var proxyColumn:* in _columnToReferenceMap)
				requestColumnFromSource(_columnToReferenceMap[proxyColumn] as IColumnReference, proxyColumn);

			super.initialize();
		}
		
		override protected function handleHierarchyChange():void
		{
			super.handleHierarchyChange();
			convertOldHierarchyFormat(_attributeHierarchy.value, "attribute", {name: "csvColumn"});
			if (_attributeHierarchy.value)
			{
				for each (var tag:XML in _attributeHierarchy.value.descendants('attribute'))
				{
					if (!String(tag.@title))
					{
						var newTitle:String = String(tag.@name) || String(tag.@csvColumn);
						if (String(tag.@year))
							newTitle += ' (' + tag.@year + ')';
						tag.@title = newTitle;
					}
				}
			}
			_attributeHierarchy.detectChanges();
		}

		/**
		 * Called when the CSV data is downloaded from a URL.
		 */
		private function handleCSVDownload(event:ResultEvent, token:Object = null):void
		{
			debug("handleCSVDownload", url.value);
			// Only handle this download if it is for current url.
			if (token == url.value)
			{
				var cc:ICallbackCollection = getCallbackCollection(this);
				cc.delayCallbacks();
				
				csvDataArray = WeaveAPI.CSVParser.parseCSV(String(event.result));
				
				cc.triggerCallbacks(); // this causes initialize() to be called
				cc.resumeCallbacks();
			}
		}

		/**
		 * Called when the CSV data fails to download from a URL.
		 */
		private function handleCSVDownloadError(event:FaultEvent, token:Object = null):void
		{
			reportError(event);
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

		/**
		 * This function must be implemented by classes by extend AbstractDataSource.
		 * This function should make a request to the source to fill in the proxy column.
		 * @param columnReference An object that contains all the information required to request the column from this IDataSource. 
		 * @param A ProxyColumn object that will be updated when the column data is ready.
		 */
		override protected function requestColumnFromSource(columnReference:IColumnReference, proxyColumn:ProxyColumn):void
		{
			var hierarchyRef:HierarchyColumnReference = columnReference as HierarchyColumnReference;
			if (!hierarchyRef)
				return handleUnsupportedColumnReference(columnReference, proxyColumn);

			var pathInHierarchy:XML = hierarchyRef.hierarchyPath.value;
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			proxyColumn.setMetadata(leafNode);

			var colName:String = proxyColumn.getMetadata("csvColumn");
			
			// backwards compatibility
			if (colName == '')
				colName = proxyColumn.getMetadata("name");
			if (proxyColumn.getMetadata(AttributeColumnMetadata.TITLE))
				
			
			var colIndex:int = (csvDataArray[0] as Array).indexOf(colName);
			var keyColIndex:int = (csvDataArray[0] as Array).indexOf(keyColName.value); // it is ok if this is -1 because getColumnValues supports -1

			var i:int;
			var csvDataColumn:Vector.<String> = getColumnValues(colIndex);
			var keyStringsArray:Array = VectorUtils.copy(getColumnValues(keyColIndex), []);
			var keysArray:Array = WeaveAPI.QKeyManager.getQKeys(keyType.value, keyStringsArray);
			var keysVector:Vector.<IQualifiedKey> = Vector.<IQualifiedKey>(keysArray);

			// loop through values, determine column type
			var nullValue:String;
			var dataType:String = ColumnUtils.getDataType(proxyColumn);
			var isNumericColumn:Boolean = dataType == null || ObjectUtil.stringCompare(dataType, DataTypes.NUMBER, true) == 0;
			if (isNumericColumn)
			{
				//check if it is a numeric column.
				for each (var columnValue:String in csvDataColumn)
				{
					// if a string is 2 characters or more and begins with a '0', treat it as a string.
					if (columnValue.length > 1 && columnValue.charAt(0) == '0' && columnValue.charAt(1) != '.')
					{
						isNumericColumn = false;
						break;
					}
					if (!isNaN(getNumberFromString(columnValue)))
						continue;
					// if not numeric, compare to null values
					if (!stringIsNullValue(columnValue))
					{
						// stop when it is determined that the column is not numeric
						isNumericColumn = false;
						break;
					}
				}
			}

			// fill in initializedProxyColumn.internalAttributeColumn based on column type (numeric or string)
			var newColumn:IAttributeColumn;
			if (isNumericColumn)
			{
				var numericVector:Vector.<Number> = new Vector.<Number>();
				for (i = 0; i < csvDataColumn.length; i++)
					numericVector[i] = getNumberFromString(csvDataColumn[i]);

				newColumn = new NumberColumn(leafNode);
				(newColumn as NumberColumn).setRecords(keysVector, numericVector);
			}
			else
			{
				var stringVector:Vector.<String> = Vector.<String>(csvDataColumn);

				newColumn = new StringColumn(leafNode);
				(newColumn as StringColumn).setRecords(keysVector, stringVector);
			}
			proxyColumn.internalColumn = newColumn;
			_columnToReferenceMap[proxyColumn] = columnReference;
			
			debug("initialized column",proxyColumn);
		}

		/**
		 * @param columnIndex If this is -1, record index values will be returned.  Otherwise, this specifies which column to get values from.
		 * @return A list of values from the specified column, excluding the first row, which is the header.
		 */		
		private function getColumnValues(columnIndex:int):Vector.<String>
		{
			var values:Vector.<String> = new Vector.<String>();
			var i:int;
			if (columnIndex < 0)
			{
				for (i = 1; i < csvDataArray.length; i++)
					values[i-1] = String(i);
			}
			else
			{
				for (i = 1; i < csvDataArray.length; i++)
					values[i-1] = csvDataArray[i][columnIndex];
			}
			return values;
		}
		
		private function getNumberFromString(value:String):Number
		{
			if (stringIsNullValue(value))
				return NaN;
			// First trim out any commas since Number() does not work if numbers have commas. 
			return Number(value.split(",").join(""));
		}
		
		private function stringIsNullValue(value:String):Boolean
		{
			for each (var nullValue:String in nullValues)
				if (ObjectUtil.stringCompare(value, nullValue, true) == 0)
					return true;
			return false;
		}
		
		private const nullValues:Array = [null, "", "null", "\\N", "NaN"];
	}
}

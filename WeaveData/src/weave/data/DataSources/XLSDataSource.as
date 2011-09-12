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
	import com.as3xls.xls.ExcelFile;
	
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.services.IURLRequestUtils;
	import weave.core.ErrorManager;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;

	/**
	 * XLSDataSource
	 * 
	 * @author skolman
	 * @author adufile
	 */
	public class XLSDataSource extends AbstractDataSource
	{
		public function XLSDataSource()
		{
		}
		
		override protected function initialize():void
		{
			super.initialize();
//			keyColName.lock();
//			keyType.lock();

			if (url.value != "" && url.value != null)
			{
				var urlRequest:URLRequest = new URLRequest(url.value);
				urlRequest.contentType = "application/vnd.ms-excel";
				WeaveAPI.URLRequestUtils.getURL(urlRequest, handleXLSDownload, handleXLSDownloadError, null, URLLoaderDataFormat.BINARY);
			}
		}

		public const keyType:LinkableString = newLinkableChild(this, LinkableString);
		public const keyColName:LinkableString = newLinkableChild(this, LinkableString);
		
		// contains the parsed xls data
		private var xlsSheetsArray:ArrayCollection = null;
		private function loadXLSData(xlsSheetsArray:ArrayCollection):void
		{
			this.xlsSheetsArray = xlsSheetsArray;
			if (_attributeHierarchy.value == null)
			{
				// loop through column names, adding indicators to hierarchy
				var firstRow:Array = xlsSheetsArray[0].values[0];
				var category:XML = <category name="XLS Data"/>;
				for each (var colName:String in firstRow)
				{
					category.appendChild(<attribute title={colName} name={colName} keyType={ keyType.value }/>);
				}
				_attributeHierarchy.value = <hierarchy>{ category }</hierarchy>;
			}
			
			//trace("hierarchy was set to " + attributeHierarchy.xml);
		}
		
		/**
		 * handleXLSDownload
		 * Called when the XLS file is downloaded from the URL
		 */
		private function handleXLSDownload(event:ResultEvent, token:Object = null):void
		{
			var xls:ExcelFile = new ExcelFile();
			xls.loadFromByteArray(ByteArray(event.result));
			loadXLSData(xls.sheets);
		}
		
		/**
		 * handleXLSDownloadError
		 * Called when the XLS file fails to download from the URL
		 */
		private function handleXLSDownloadError(event:FaultEvent, token:Object = null):void
		{
			trace(event.type, event.message + '\n' + event.fault);
			WeaveAPI.ErrorManager.reportError(event.fault);
		}
		
		/**
		 * requestColumnFromSource
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
			var colName:String = String(proxyColumn.getMetadata("name"));
			trace(xlsSheetsArray[0].values[0]);
			var colIndex:int = getColumnIndexFromSheetValues(xlsSheetsArray[0].values[0],colName);
			var keyColIndex:int = getColumnIndexFromSheetValues(xlsSheetsArray[0].values[0],keyColName.value);
			if (keyColIndex == -1)
				keyColIndex = 0; // default to first column (temp solution)

			var xlsDataColumn:Vector.<String> = getColumnValues(colIndex);
			var keyStringsArray:Array = VectorUtils.copy(getColumnValues(keyColIndex), []);
			var keysArray:Array = WeaveAPI.QKeyManager.getQKeys(keyType.value, keyStringsArray);
			var keysVector:Vector.<IQualifiedKey> = Vector.<IQualifiedKey>(keysArray);

			// loop through values, determine column type
			var nullValues:Array = ["null", "\\N", "NaN"];
			var nullValue:String;
			var isNumericColumn:Boolean = true
			//check if it is a numeric column.
			for each (var columnValue:String in xlsDataColumn)
			{
				// if numeric, continue
				if (!isNaN(Number(columnValue)))
					continue;
				// if not numeric, compare to null values
				for each (nullValue in nullValues)
					if (ObjectUtil.stringCompare(columnValue, nullValue, true) != 0)
						isNumericColumn = false;
				// stop when it is determined that the column is not numeric
				if (!isNumericColumn)
					break;
			}

			// fill in initializedProxyColumn.internalAttributeColumn based on column type (numeric or string)
			var newColumn:IAttributeColumn;
			if (isNumericColumn)
			{
				newColumn = new NumberColumn(leafNode);
				(newColumn as NumberColumn).setRecords(keysVector, Vector.<Number>(xlsDataColumn));
			}
			else
			{
				newColumn = new StringColumn(leafNode);
				(newColumn as StringColumn).setRecords(keysVector, Vector.<String>(xlsDataColumn));
			}
			proxyColumn.internalColumn = newColumn;
		}

		private function getColumnValues(columnIndex:int):Vector.<String>
		{
			var values:Vector.<String> = new Vector.<String>();
			for (var i:int = 1; i < xlsSheetsArray[0].values.length; i++)
				values[i-1] = xlsSheetsArray[0].values[i][columnIndex];
			return values;
		}
		
		//similar to indexOf for arrays. This takes a string matchValue and returns the index in sheetValues, an array of Cell objects.
		private function getColumnIndexFromSheetValues(sheetValues:Array, matchValue:String):int
		{
			for (var i:int=0; i<sheetValues.length; i++)
			{
				if((ObjectUtil.stringCompare(matchValue,sheetValues[i].value,true) == 0))
					return i;
			}
			
			return -1;
		}
	}
}
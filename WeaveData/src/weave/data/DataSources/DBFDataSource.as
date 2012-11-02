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
	import flash.utils.ByteArray;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import org.vanrijkom.dbf.DbfField;
	import org.vanrijkom.dbf.DbfHeader;
	import org.vanrijkom.dbf.DbfRecord;
	import org.vanrijkom.dbf.DbfTools;
	
	import weave.api.WeaveAPI;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObjects;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.primitives.GeneralizedGeometry;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.ShpFileReader;

	/**
	 * @author adufilie
	 */
	public class DBFDataSource extends AbstractDataSource
	{
		public function DBFDataSource()
		{
			disposeObjects(url);
		}
		
		override protected function get initializationComplete():Boolean
		{
			// make sure everything is ready before column requests get handled.
			return super.initializationComplete && dbfData != null && shpfile != null && shpfile.geomsReady;
		}
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString);
		public const keyColName:LinkableString = newLinkableChild(this, LinkableString);
		public const dbfUrl:LinkableString = newLinkableChild(this, LinkableString, handleDbfUrlChange, true);
		public const shpUrl:LinkableString = newLinkableChild(this, LinkableString, handleShpUrlChange, true);
//		public const projection:LinkableString = newLinkableChild(this, LinkableString, handleProjectionChange, true);
		
		private function handleDbfUrlChange():void
		{
			if (dbfUrl.value != null)
			{
				dbfData = null;
				WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(dbfUrl.value), handleDBFDownload, handleDBFDownloadError, dbfUrl.value, URLLoaderDataFormat.BINARY);
				
				debug('dbf start downloading',dbfUrl.value);
			}
		}
		private function handleShpUrlChange():void
		{
			if (shpUrl.value != null)
			{
				if (shpfile)
					disposeObjects(shpfile)
				shpfile = null;
				WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(shpUrl.value), handleShpDownload, handleDBFDownloadError, shpUrl.value, URLLoaderDataFormat.BINARY);
				
				debug('shp start downloading',shpUrl.value);
			}
		}
		
		private var dbf:DbfHeader = null;
		private var dbfData:ByteArray = null;
		private var shpfile:ShpFileReader = null;
		
		private static const THE_GEOM_COLUMN:String = 'the_geom';
		
		/**
		 * Called when the DBF file is downloaded from the URL
		 */
		private function handleDBFDownload(event:ResultEvent, token:Object = null):void
		{
			if (objectWasDisposed(this))
				return;
			
			// ignore outdated results
			if (token != dbfUrl.value)
				return;
			
			debug('dbf download complete',dbfUrl.value);
			
			dbfData = ByteArray(event.result);
			if (dbfData.length == 0)
			{
				reportError("Zero-byte DBF: " + dbfUrl.value);
				return;
			}
			dbf = new DbfHeader( dbfData );	
			
			if (_attributeHierarchy.value == null)
			{	
				var category:XML = <category name="DBF Data"/>;
				category.appendChild(<attribute dataType={ DataTypes.GEOMETRY } title={ THE_GEOM_COLUMN } name={ THE_GEOM_COLUMN } keyType={ keyType.value }/>);
				
				for each( var column:DbfField in dbf.fields)
				{
					category.appendChild( <attribute title={ column.name } name={column.name} keyType={ keyType.value }/> );
				}
				
				
				_attributeHierarchy.value = <hierarchy>{ category }</hierarchy>;
			}
			initialize();
		}
		
		/**
		 * Called when the Shp file is downloaded from the URL
		 */
		private function handleShpDownload(event:ResultEvent, token:Object = null):void
		{
			if (objectWasDisposed(this))
				return;
			
			// ignore outdated results
			if (token != shpUrl.value)
				return;
			
			debug('shp download complete',shpUrl.value);
			
			if (shpfile)
				disposeObjects(shpfile);
			var bytes:ByteArray = ByteArray(event.result);
			if (bytes.length == 0)
			{
				reportError("Zero-byte ShapeFile: " + shpUrl.value);
				return;
			}
			shpfile = registerLinkableChild(this, new ShpFileReader(bytes));
		}

		/**
		 * Called when the DBF file fails to download from the URL
		 */
		private function handleDBFDownloadError(event:FaultEvent, token:Object = null):void
		{
			if (objectWasDisposed(this))
				return;
			
			// ignore outdated results
			if (token != shpUrl.value)
				return;
			
			reportError(event);
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

			//trace("requestColumnFromSource "+proxyColumn);

			var pathInHierarchy:XML = hierarchyRef.hierarchyPath.value;
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			proxyColumn.setMetadata(leafNode);
				
			//The column names
			var colName:String = proxyColumn.getMetadata('name');
			var _keyColName:String = this.keyColName.value;
			if (_keyColName == null)
				_keyColName = (dbf.fields[0] as DbfField).name;

			//Get a vector of all elements in that column
			var dbfDataColumn:Array = getColumnValues(colName);
			var keysArray:Array = WeaveAPI.QKeyManager.getQKeys(keyType.value, getColumnValues(_keyColName));
			var keysVector:Vector.<IQualifiedKey> = Vector.<IQualifiedKey>(keysArray);

			var newColumn:IAttributeColumn;
			if (ObjectUtil.stringCompare(ColumnUtils.getDataType(proxyColumn), DataTypes.GEOMETRY, true) == 0)
			{
				newColumn = new GeometryColumn(leafNode);
				(newColumn as GeometryColumn).setGeometries(keysVector, Vector.<GeneralizedGeometry>(dbfDataColumn));
			}
			else
			{
				// loop through values, determine column type
				var nullValues:Array = ["null", "\\N", "NaN"];
				var nullValue:String;
				var isNumericColumn:Boolean = true
				//check if it is a numeric column.
				for each (var columnValue:String in dbfDataColumn)
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
				if (isNumericColumn)
				{
					newColumn = new NumberColumn(leafNode);
					(newColumn as NumberColumn).setRecords(keysVector, Vector.<Number>(dbfDataColumn));
				}
				else
				{
					newColumn = new StringColumn(leafNode);
					(newColumn as StringColumn).setRecords(keysVector, Vector.<String>(dbfDataColumn));
				}
			}

			proxyColumn.setInternalColumn(newColumn);
		}

		private function getColumnValues(columnName:String):Array
		{
			var values:Array = [];
			if( columnName == THE_GEOM_COLUMN )
			{
				return shpfile.geoms;	
			}
			var record:DbfRecord = null; 
			for( var i:int = 0; i < dbf.recordCount; i++ )
			{ 
				record = DbfTools.getRecord(dbfData, dbf, i);
				values.push( record.values[columnName] );
			}
			return values;
		}
	}
}
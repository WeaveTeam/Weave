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

package org.oicweave.data.DataSources
{	
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.data.DataTypes;
	import org.oicweave.api.data.IAttributeColumn;
	import org.oicweave.api.data.IColumnReference;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.api.disposeObjects;
	import org.oicweave.api.newLinkableChild;
	import org.oicweave.api.registerLinkableChild;
	import org.oicweave.core.ErrorManager;
	import org.oicweave.core.LinkableString;
	import org.oicweave.core.weave_internal;
	import org.oicweave.data.AttributeColumns.GeometryColumn;
	import org.oicweave.data.AttributeColumns.NumberColumn;
	import org.oicweave.data.AttributeColumns.ProxyColumn;
	import org.oicweave.data.AttributeColumns.StringColumn;
	import org.oicweave.data.ColumnReferences.HierarchyColumnReference;
	import org.oicweave.primitives.GeneralizedGeometry;
	import org.oicweave.services.URLRequestUtils;
	import org.oicweave.utils.ColumnUtils;
	import org.oicweave.utils.HierarchyUtils;
	import org.oicweave.utils.ShpFileReader;
	import org.oicweave.utils.VectorUtils;
	import org.vanrijkom.dbf.DbfField;
	import org.vanrijkom.dbf.DbfHeader;
	import org.vanrijkom.dbf.DbfRecord;
	import org.vanrijkom.dbf.DbfTools;

	use namespace weave_internal;

	/**
	 * DBFDataSource
	 * 
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
		
		private function handleDbfUrlChange():void
		{
			if (dbfUrl.value != null)
			{
				dbfData = null;
				URLRequestUtils.getURL(new URLRequest(dbfUrl.value), handleDBFDownload, handleDBFDownloadError, null, URLLoaderDataFormat.BINARY);
			}
		}
		private function handleShpUrlChange():void
		{
			if (shpUrl.value != null)
			{
				if (shpfile)
					disposeObjects(shpfile)
				shpfile = null;
				URLRequestUtils.getURL(new URLRequest(shpUrl.value), handleShpDownload, handleDBFDownloadError, shpUrl.value, URLLoaderDataFormat.BINARY);
			}
		}
		
		private var dbf:DbfHeader = null;
		private var dbfData:ByteArray = null;
		private var shpfile:ShpFileReader = null;
		
		private static const THE_GEOM_COLUMN:String = 'the_geom';
		
		/**
		 * handleDBFDownload
		 * Called when the DBF file is downloaded from the URL
		 */
		private function handleDBFDownload(event:ResultEvent, token:Object = null):void
		{
			dbfData = ByteArray(event.result);
			dbf = new DbfHeader( dbfData );	
				
			if (_attributeHierarchy.value == null)
			{	
				var category:XML = <category name="DBF Data"/>;
				category.appendChild(<attribute dataType={ DataTypes.GEOMETRY } name={ THE_GEOM_COLUMN } keyType={ keyType.value }/>);
				
				for each( var column:DbfField in dbf.fields)
				{
					category.appendChild( <attribute name={column.name}/> );
				}
				
				
				_attributeHierarchy.value = <hierarchy>{ category }</hierarchy>;
			}
			initialize();
		}
		
		/**
		 * handleShpDownload
		 * Called when the Shp file is downloaded from the URL
		 */
		private function handleShpDownload(event:ResultEvent, token:Object = null):void
		{
			// ignore outdated results
			if (token != shpUrl.value)
				return;
			
			if (shpfile)
				disposeObjects(shpfile);
			shpfile = registerLinkableChild(this, new ShpFileReader(ByteArray(event.result)));
		}

		/**
		 * handleDBFDownloadError
		 * Called when the DBF file fails to download from the URL
		 */
		private function handleDBFDownloadError(event:FaultEvent, token:Object = null):void
		{
			// ignore outdated results
			if (token != shpUrl.value)
				return;
			
			trace(event.type, event.message + '\n' + event.fault);
			ErrorManager.reportError(event.fault);
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

			//trace("requestColumnFromSource "+proxyColumn);

			var pathInHierarchy:XML = hierarchyRef.hierarchyPath.value;
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			proxyColumn.setMetadata(leafNode);
				
			//The column names
			var colName:String = proxyColumn.getMetadata('name');
			var keyColName:String = keyColName.value;
			if (keyColName == null)
				keyColName = (dbf.fields[0] as DbfField).name;

			//Get a vector of all elements in that column
			var dbfDataColumn:Array = getColumnValues(colName);
			var keysArray:Array = WeaveAPI.QKeyManager.getQKeys(keyType.value, getColumnValues(keyColName));
			var keysVector:Vector.<IQualifiedKey> = VectorUtils.copy(keysArray, new Vector.<IQualifiedKey>());

			var newColumn:IAttributeColumn;
			if( ColumnUtils.getDataType(proxyColumn) == DataTypes.GEOMETRY )
			{
				newColumn = new GeometryColumn(leafNode);
				(newColumn as GeometryColumn).setGeometries(keysVector, VectorUtils.copy(dbfDataColumn, new Vector.<GeneralizedGeometry>()));
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
					(newColumn as NumberColumn).updateRecords(keysVector, VectorUtils.copy(dbfDataColumn, new Vector.<Number>()));
				}
				else
				{
					newColumn = new StringColumn(leafNode);
					(newColumn as StringColumn).updateRecords(keysVector, VectorUtils.copy(dbfDataColumn, new Vector.<String>()));
				}
			}

			proxyColumn.internalColumn = newColumn;
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
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

package weavejs.data.source
{	
	import org.vanrijkom.dbf.DbfField;
	import org.vanrijkom.dbf.DbfHeader;
	import org.vanrijkom.dbf.DbfRecord;
	import org.vanrijkom.dbf.DbfTools;
	
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IDataSource_File;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.core.LinkableString;
	import weavejs.data.column.DateColumn;
	import weavejs.data.column.GeometryColumn;
	import weavejs.data.column.NumberColumn;
	import weavejs.data.column.ProxyColumn;
	import weavejs.data.column.StringColumn;
	import weavejs.geom.ShpFileReader;
	import weavejs.net.URLRequest;
	import weavejs.util.JS;
	import weavejs.util.JSByteArray;
	import weavejs.util.StandardLib;

	/**
	 * @author adufilie
	 */
	public class DBFDataSource extends AbstractDataSource implements IDataSource_File
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, DBFDataSource, "SHP/DBF files");
		
		public function DBFDataSource()
		{
		}
		
		override protected function get initializationComplete():Boolean
		{
			// make sure everything is ready before column requests get handled.
			return super.initializationComplete
				&& dbfData
				&& (!shpfile || shpfile.geomsReady);
		}
		
		override protected function uninitialize():void
		{
			super.uninitialize();
			if (Weave.detectChange(uninitialize, dbfUrl))
			{
				dbfData = null;
				dbfHeader = null;
			}
			if (Weave.detectChange(uninitialize, shpUrl))
			{
				if (shpfile)
					Weave.dispose(shpfile)
				shpfile = null;
			}
		}
		
		override protected function initialize(forceRefresh:Boolean = false):void
		{
			if (Weave.detectChange(initialize, dbfUrl) && dbfUrl.value)
				WeaveAPI.URLRequestUtils.request(this, new URLRequest(dbfUrl.value))
					.then(handleDBFDownload.bind(this, dbfUrl.value), handleDBFDownloadError.bind(this, dbfUrl.value));
			if (Weave.detectChange(initialize, shpUrl) && shpUrl.value)
				WeaveAPI.URLRequestUtils.request(this, new URLRequest(shpUrl.value))
					.then(handleShpDownload.bind(this, shpUrl.value), handleShpDownloadError.bind(this, shpUrl.value));
			
			// recalculate all columns previously requested because data may have changed.
			super.initialize(true);
		}
		
		public const keyType:LinkableString = Weave.linkableChild(this, LinkableString);
		public const keyColName:LinkableString = Weave.linkableChild(this, LinkableString);
		public const dbfUrl:LinkableString = Weave.linkableChild(this, LinkableString);
		public const shpUrl:LinkableString = Weave.linkableChild(this, LinkableString);
		public const projection:LinkableString = Weave.linkableChild(this, LinkableString);
		
		private var dbfData:JSByteArray = null;
		private var dbfHeader:DbfHeader = null;
		private var shpfile:ShpFileReader = null;
		
		public static const DBF_COLUMN_NAME:String = 'name';
		public static const THE_GEOM_COLUMN:String = 'the_geom';
		private function getGeomColumnTitle():String
		{
			return Weave.lang("{0} geometry", Weave.getRoot(this).getName(this));
		}
		
		/**
		 * Called when the DBF file is downloaded from the URL
		 */
		private function handleDBFDownload(url:String, result:/*Uint8*/Array):void
		{
			// ignore outdated results
			if (Weave.wasDisposed(this) || url != dbfUrl.value)
				return;
			
			dbfData = new JSByteArray(result);
			if (dbfData.length == 0)
			{
				dbfData = null;
				JS.error("Zero-byte DBF: " + dbfUrl.value);
			}
			else
			{
				try
				{
					dbfData.position = 0;
					dbfHeader = new DbfHeader(dbfData);
				}
				catch (e:Error)
				{
					dbfData = null;
					JS.error(e);
				}
			}
			Weave.getCallbacks(this).triggerCallbacks();
		}
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!(_rootNode is DBFColumnNode))
				_rootNode = new DBFColumnNode(this);
			return _rootNode;
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			var root:DBFColumnNode = getHierarchyRoot() as DBFColumnNode;
			if (!root)
				return super.generateHierarchyNode(metadata);
			
			if (metadata.hasOwnProperty(DBF_COLUMN_NAME))
				return new DBFColumnNode(this, metadata[DBF_COLUMN_NAME]);
			
			return null;
		}
		
		/**
		 * Called when the Shp file is downloaded from the URL
		 */
		private function handleShpDownload(url:String, result:/*Uint8*/Array):void
		{
			// ignore outdated results
			if (Weave.wasDisposed(this) || url != shpUrl.value)
				return;
			
			//debugTrace(this, 'shp download complete', shpUrl.value);
			
			if (shpfile)
			{
				Weave.dispose(shpfile);
				shpfile = null;
			}
			var bytes:JSByteArray = new JSByteArray(result);
			if (bytes.length == 0)
			{
				JS.error("Zero-byte ShapeFile: " + shpUrl.value);
			}
			else
			{
				try
				{
					bytes.position = 0;
					shpfile = Weave.linkableChild(this, new ShpFileReader(bytes));
				}
				catch (e:Error)
				{
					JS.error(e);
				}
			}
			Weave.getCallbacks(this).triggerCallbacks();
		}

		/**
		 * Called when the DBF file fails to download from the URL
		 */
		private function handleDBFDownloadError(url:String, error:Error):void
		{
			if (Weave.wasDisposed(this))
				return;
			
			// ignore outdated results
			if (url != dbfUrl.value)
				return;
			
			JS.error(error);
			Weave.getCallbacks(this).triggerCallbacks();
		}

		/**
		 * Called when the DBF file fails to download from the URL
		 */
		private function handleShpDownloadError(url:String, error:Error):void
		{
			if (Weave.wasDisposed(this))
				return;
			
			// ignore outdated results
			if (url != shpUrl.value)
				return;
			
			JS.error(error);
			Weave.getCallbacks(this).triggerCallbacks();
		}

		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();
			
			// get column name from proxy metadata
			var columnName:String = metadata[DBF_COLUMN_NAME];
			
			// override proxy metadata
			metadata = getColumnMetadata(columnName);
			if (!metadata)
			{
				proxyColumn.dataUnavailable();
				return;
			}
			proxyColumn.setMetadata(metadata);

			var qkeys:Array = WeaveAPI.QKeyManager.getQKeys(getKeyType(), getColumnValues(keyColName.value));
			var data:Array = getColumnValues(columnName);

			var newColumn:IAttributeColumn;
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];
			if (dataType == DataType.GEOMETRY)
			{
				newColumn = new GeometryColumn(metadata);
				(newColumn as GeometryColumn).setGeometries(qkeys, data);
			}
			else if (dataType == DataType.DATE)
			{
				newColumn = new DateColumn(metadata);
				(newColumn as DateColumn).setRecords(qkeys, data);
			}
			else if (dataType == DataType.NUMBER)
			{
				newColumn = new NumberColumn(metadata);
				data.forEach(function(str:String, i:int, a:Array):Number { return StandardLib.asNumber(str); });
				(newColumn as NumberColumn).setRecords(qkeys, data);
			}
			else // string
			{
				newColumn = new StringColumn(metadata);
				(newColumn as StringColumn).setRecords(qkeys, data);
			}

			proxyColumn.setInternalColumn(newColumn);
		}
		
		public function getKeyType():String
		{
			return keyType.value || Weave.getRoot(this).getName(this);
		}
		public function getColumnNames():Array
		{
			var names:Array = [];
			if (shpfile)
				names.push(THE_GEOM_COLUMN);
			if (dbfHeader)
				for (var i:int = 0; i < dbfHeader.fields.length; i++)
					names.push((dbfHeader.fields[i] as DbfField).name);
			return names;
		}
		public function getColumnMetadata(columnName:String):Object
		{
			if (!columnName)
				return null;
			
			var meta:Object = {};
			meta[DBF_COLUMN_NAME] = columnName;
			meta[ColumnMetadata.KEY_TYPE] = getKeyType();
			meta[ColumnMetadata.PROJECTION] = projection.value;
			if (columnName == THE_GEOM_COLUMN)
			{
				meta[ColumnMetadata.TITLE] = getGeomColumnTitle();
				meta[ColumnMetadata.DATA_TYPE] = DataType.GEOMETRY;
				return meta;
			}
			else if (dbfHeader)
			{
				meta[ColumnMetadata.TITLE] = columnName;
				for each (var field:DbfField in dbfHeader.fields)
				{
					if (field.name == columnName)
					{
						var typeChar:String = String.fromCharCode(field.type);
						var dataType:String = FIELD_TYPE_LOOKUP[typeChar];
						if (dataType)
							meta[ColumnMetadata.DATA_TYPE] = dataType;
						if (dataType == DataType.DATE)
							meta[ColumnMetadata.DATE_FORMAT] = "YYYYMMDD";
						return meta;
					}
				}
			}
			return null;
		}
		private function getColumnValues(columnName:String):Array
		{
			var values:Array = [];
			if (columnName == THE_GEOM_COLUMN)
				return shpfile ? shpfile.geoms : [];
			
			if (!dbfHeader)
				return values;
			
			var record:DbfRecord = null;
			for (var i:int = 0; i < dbfHeader.recordCount; i++)
			{ 
				if (columnName)
				{
					record = DbfTools.getRecord(dbfData, dbfHeader, i);
					var value:* = record.map_field_value.get(columnName);
					values.push(value);
				}
				else
					values.push(String(i + 1));
			}
			return values;
		}
		
		private static const FIELD_TYPE_LOOKUP:Object = {
			"C": DataType.STRING, // Char - ASCII
			"D": DataType.DATE, // Date - 8 Ascii digits (0..9) in the YYYYMMDD format
			"F": DataType.NUMBER, // Numeric - Ascii digits (-.0123456789) variable position of floating point
			"N": DataType.NUMBER, // Numeric - Ascii digits (-.0123456789) fixed position/no floating point
			"2": DataType.NUMBER, // short int -- binary int
			"4": DataType.NUMBER, // long int - binary int
			"8": DataType.NUMBER, // double - binary signed double IEEE
			"L": "boolean", // Logical - Ascii chars (YyNnTtFf space ?)
			"M": null, // Memo - 10 digits representing the start block position in .dbt file, or 10 spaces if no entry in memo
			"B": null, // Binary - binary data in .dbt, structure like M
			"G": null, // General - OLE objects, structure like M
			"P": null, // Picture - binary data in .ftp, structure like M
			"I": null,
			"0": null,
			"@": null,
			"+": null
		};
	}
}

import weavejs.api.data.IColumnReference;
import weavejs.api.data.IDataSource;
import weavejs.api.data.IWeaveTreeNode;
import weavejs.data.source.DBFDataSource;

internal class DBFColumnNode implements IWeaveTreeNode, IColumnReference
{
	private var source:DBFDataSource;
	public var columnName:String;
	internal var children:Array;
	public function DBFColumnNode(source:DBFDataSource = null, columnName:String = null)
	{
		this.source = source;
		this.columnName = columnName;
	}
	public function equals(other:IWeaveTreeNode):Boolean
	{
		var that:DBFColumnNode = other as DBFColumnNode;
		return !!that
			&& this.source == that.source
			&& this.columnName == that.columnName;
	}
	public function getLabel():String
	{
		if (!columnName)
			return Weave.getRoot(source).getName(source);
		return columnName;
	}
	public function isBranch():Boolean { return !columnName; }
	public function hasChildBranches():Boolean { return false; }
	public function getChildren():Array
	{
		if (columnName)
			return null;
		
		if (!children)
			children = [];
		var names:Array = source.getColumnNames();
		for (var i:int = 0; i < names.length; i++)
		{
			if (children[i])
				(children[i] as DBFColumnNode).columnName = names[i];
			else
				children[i] = new DBFColumnNode(source, names[i]);
		}
		children.length = names.length;
		return children;
	}
	
	public function getDataSource():IDataSource { return source; }
	public function getColumnMetadata():Object { return source.getColumnMetadata(columnName); }
}

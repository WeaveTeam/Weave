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
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.StringUtil;
	
	import org.vanrijkom.dbf.DbfField;
	import org.vanrijkom.dbf.DbfHeader;
	import org.vanrijkom.dbf.DbfRecord;
	import org.vanrijkom.dbf.DbfTools;
	
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
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.primitives.GeneralizedGeometry;
	import weave.services.addAsyncResponder;
	import weave.utils.ShpFileReader;

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
				&& !linkableObjectIsBusy(this)
				&& (!shpfile || shpfile.geomsReady);
		}
		
		override protected function uninitialize():void
		{
			super.uninitialize();
			if (detectLinkableObjectChange(uninitialize, dbfUrl))
			{
				dbfData = null;
				dbfHeader = null;
			}
			if (detectLinkableObjectChange(uninitialize, shpUrl))
			{
				if (shpfile)
					disposeObject(shpfile)
				shpfile = null;
			}
		}
		
		override protected function initialize():void
		{
			if (detectLinkableObjectChange(initialize, dbfUrl) && dbfUrl.value)
				addAsyncResponder(
					WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(dbfUrl.value)),
					handleDBFDownload,
					handleDBFDownloadError,
					dbfUrl.value
				);
			if (detectLinkableObjectChange(initialize, shpUrl) && shpUrl.value)
				addAsyncResponder(
					WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(shpUrl.value)),
					handleShpDownload,
					handleShpDownloadError,
					shpUrl.value
				);
			
			// recalculate all columns previously requested because data may have changed.
			refreshAllProxyColumns();
			
			super.initialize();
		}
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString);
		public const keyColName:LinkableString = newLinkableChild(this, LinkableString);
		public const dbfUrl:LinkableString = newLinkableChild(this, LinkableString);
		public const shpUrl:LinkableString = newLinkableChild(this, LinkableString);
		public const projection:LinkableString = newLinkableChild(this, LinkableString);
		
		private var dbfData:ByteArray = null;
		private var dbfHeader:DbfHeader = null;
		private var shpfile:ShpFileReader = null;
		
		public static const DBF_COLUMN_NAME:String = 'name';
		public static const THE_GEOM_COLUMN:String = 'the_geom';
		private function getGeomColumnTitle():String
		{
			return lang("{0} geometry", WeaveAPI.globalHashMap.getName(this));
		}
		
		/**
		 * Called when the DBF file is downloaded from the URL
		 */
		private function handleDBFDownload(event:ResultEvent, url:String):void
		{
			// ignore outdated results
			if (objectWasDisposed(this) || url != dbfUrl.value)
				return;
			
			dbfData = ByteArray(event.result);
			if (dbfData.length == 0)
			{
				dbfData = null;
				reportError("Zero-byte DBF: " + dbfUrl.value);
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
					reportError(e);
				}
			}
			getCallbackCollection(this).triggerCallbacks();
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
		private function handleShpDownload(event:ResultEvent, url:String):void
		{
			// ignore outdated results
			if (objectWasDisposed(this) || url != shpUrl.value)
				return;
			
			//debugTrace(this, 'shp download complete', shpUrl.value);
			
			if (shpfile)
			{
				disposeObject(shpfile);
				shpfile = null;
			}
			var bytes:ByteArray = ByteArray(event.result);
			if (bytes.length == 0)
			{
				reportError("Zero-byte ShapeFile: " + shpUrl.value);
			}
			else
			{
				try
				{
					bytes.position = 0;
					shpfile = registerLinkableChild(this, new ShpFileReader(bytes));
				}
				catch (e:Error)
				{
					reportError(e);
				}
			}
			getCallbackCollection(this).triggerCallbacks();
		}

		/**
		 * Called when the DBF file fails to download from the URL
		 */
		private function handleDBFDownloadError(event:FaultEvent, url:String):void
		{
			if (objectWasDisposed(this))
				return;
			
			// ignore outdated results
			if (url != dbfUrl.value)
				return;
			
			reportError(event);
			getCallbackCollection(this).triggerCallbacks();
		}

		/**
		 * Called when the DBF file fails to download from the URL
		 */
		private function handleShpDownloadError(event:FaultEvent, url:String):void
		{
			if (objectWasDisposed(this))
				return;
			
			// ignore outdated results
			if (url != shpUrl.value)
				return;
			
			reportError(event);
			getCallbackCollection(this).triggerCallbacks();
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

			var keysVector:Vector.<IQualifiedKey> = Vector.<IQualifiedKey>(WeaveAPI.QKeyManager.getQKeys(getKeyType(), getColumnValues(keyColName.value, true)));
			var data:Array = getColumnValues(columnName);

			var newColumn:IAttributeColumn;
			var dataType:String = metadata[ColumnMetadata.DATA_TYPE];
			if (dataType == DataType.GEOMETRY)
			{
				newColumn = new GeometryColumn();
				(newColumn as GeometryColumn).setGeometries(keysVector, Vector.<GeneralizedGeometry>(data));
			}
			else if (dataType == DataType.DATE)
			{
				newColumn = new DateColumn(metadata);
				(newColumn as DateColumn).setRecords(keysVector, Vector.<String>(data));
			}
			else if (dataType == DataType.NUMBER)
			{
				newColumn = new NumberColumn(metadata);
				data.forEach(function(str:String, i:int, a:Array):Number { return StandardLib.asNumber(str); });
				(newColumn as NumberColumn).setRecords(keysVector, Vector.<Number>(data));
			}
			else // string
			{
				newColumn = new StringColumn(metadata);
				(newColumn as StringColumn).setRecords(keysVector, Vector.<String>(data));
			}

			proxyColumn.setInternalColumn(newColumn);
		}
		
		public function getKeyType():String
		{
			return keyType.value || WeaveAPI.globalHashMap.getName(this);
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
		private function getColumnValues(columnName:String, trimStrings:Boolean = false):Array
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
					var value:* = record.values[columnName];
					if (trimStrings)
						value = StringUtil.trim(value);
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

import weave.api.data.IColumnReference;
import weave.api.data.IDataSource;
import weave.api.data.IWeaveTreeNode;
import weave.data.DataSources.DBFDataSource;

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
			return WeaveAPI.globalHashMap.getName(source);
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

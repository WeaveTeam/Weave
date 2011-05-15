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
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	import mx.rpc.AsyncToken;
	
	import org.oicweave.api.WeaveAPI;
	import org.oicweave.api.data.IAttributeColumn;
	import org.oicweave.api.data.IColumnReference;
	import org.oicweave.api.data.IQualifiedKey;
	import org.oicweave.core.ErrorManager;
	import org.oicweave.data.AttributeColumns.NumberColumn;
	import org.oicweave.data.AttributeColumns.ProxyColumn;
	import org.oicweave.data.AttributeColumns.StringColumn;
	import org.oicweave.data.ColumnReferences.HierarchyColumnReference;
	import org.oicweave.api.data.DataTypes;
	import org.oicweave.utils.HierarchyUtils;
	import org.oicweave.utils.VectorUtils;
	
	/**
	 * GrailsDataSource
	 * 
	 * @author Curran Kelleher
	 */
	public class GrailsDataSource extends AbstractDataSource
	{
		/**
		 * initialize
		 */
		override protected function initialize():void
		{
			if (url.value == null)
				url.value = '/weaveServer/data/get';

			super.initialize();
		}

		public function radiusSearch(xCoordinate:Number, yCoordinate:Number):AsyncToken
		{
			//todo: add required parameters, return async token 
			return null;
		}

		/**
		 * requestHierarchyFromSource
		 * @param subtreeNode Specifies a subtree in the hierarchy to download.
		 */
		override protected function requestHierarchyFromSource(subtreeNode:XML=null):void
		{
			var urlLoader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(url.value);
			request.data = new URLVariables();
			
			if (subtreeNode == null) // download top-level hierarchy (list of tables)
			{
				// set url parameters
				request.data.method = "listTables";
				// add callbacks
				urlLoader.addEventListener(Event.COMPLETE, handleListTables);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleListTablesError);
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleListTablesError);
			}
			else // download list of columns
			{
				// set url parameters
				request.data.method = "listTableColumns";
				request.data.tableId = subtreeNode.attribute("tableId").toString();
				// add callbacks
				urlLoader.addEventListener(Event.COMPLETE, handleListTableColumns);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleListTableColumnsError);
				urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleListTableColumnsError);
				// associate the urlLoader with the hierarchy path and make the url request
				_loaderToTablePathMap[urlLoader] = _attributeHierarchy.getPathFromNode(subtreeNode);
			}
			
			//trace(request.data.toString())
			urlLoader.load(request);
		}
		private const _loaderToTablePathMap:Dictionary = new Dictionary(false); // maps a URLLoader object to a hierarchy path
		
		/**
		 * handleListTables
		 * @param event
		 */
		private function handleListTables(event:Event):void
		{
			var xml:XML = XML((event.target as URLLoader).data);
			//Alert.show(xml.toXMLString());
			var root:XML = <hierarchy name="Weave Grails Server"/>;
			var tables:XMLList = xml.table;
			for (var i:int = 0; i < tables.length(); i++)
				root.appendChild(<category name={ tables[i].@name } tableId={ tables[i].@tableId }/>);
			_attributeHierarchy.value = root;
		}

		/**
		 * handleListTablesError
		 * @param event
		 */
		private function handleListTablesError(event:ErrorEvent):void
		{
			ErrorManager.reportError(new Error(event.text));
		}
		
		/**
		 * handleListTableColumns
		 * @param event
		 */
		private function handleListTableColumns(event:Event):void
		{
			var result:XML = new XML(event.target.data);
			// Alert.show(result.toXMLString());

			var columnsList:XMLList = result.column;
                        //There will only be one of the from the grails XML output.
                        var keyColumn:XMLList = result.keyColumn;
			
			// define the hierarchy
			var path:XML = _loaderToTablePathMap[event.target]
			var node:XML = _attributeHierarchy.getNodeFromPath(path);
			if (node == null)
			{
				trace("path no longer exists in hierarchy: "+path.toXMLString());
				return;
			}
			delete _loaderToTablePathMap[event.target];

			for(var i:int = 0; i < columnsList.length(); i++)
			{
				var columnName:String = columnsList[i].attribute("name");
				var columnType:String = columnsList[i].attribute("type");
				var columnId:String = columnsList[i].attribute("id");
				var keyType:String = keyColumn[0].attribute("keyType");
				
				node.appendChild(
					<attribute
						id={ columnId }
						name={ columnName }
						title={ columnName }
						keyType={ keyType }
						dataType={ columnType }
					/>);
			}
			_attributeHierarchy.detectChanges();
		}
		
		/**
		 * handleMetadataDownloadError
		 * 
		 */
		private function handleListTableColumnsError(event:ErrorEvent):void
		{
			ErrorManager.reportError(new Error(event.text));
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
			//trace("requestColumnFromSource()",pathInHierarchy.toXMLString());
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			proxyColumn.setMetadata(leafNode);
			var columnId:String = leafNode.attribute("id");
			var url:String = url.value;
			var request:URLRequest = new URLRequest(url);
			request.data = new URLVariables();
			request.data.method = "listColumnValues";
			request.data.columnId = columnId;
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, handleColumnDownload);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleColumnDownloadFail);
			// save mapping from urlLoader to a ColumnRequestToken for when handleColumnDownload gets called
			_urlLoaderToColumnRequestMap[urlLoader] = new ColumnRequestToken(pathInHierarchy, proxyColumn);
			urlLoader.load(request);
		}
		private var _urlLoaderToColumnRequestMap:Dictionary = new Dictionary(false); // maps a URLLoader object to a ColumnRequestToken
		
		/**
		 * handleColumnDownload
		 * @param event
		 */
		private function handleColumnDownload(event:Event):void
		{
			var urlLoader:URLLoader = event.target as URLLoader;
			var request:ColumnRequestToken = _urlLoaderToColumnRequestMap[urlLoader] as ColumnRequestToken;
			var hierarchyPath:XML = request.pathInHierarchy;
			var proxyColumn:ProxyColumn = request.proxyColumn;
			var hierarchyNode:XML = HierarchyUtils.getLeafNodeFromPath(hierarchyPath);

			if(event.target.data == "Invalid columnId given!"){
				var message:String = "The requested data no longer exists on the server." 
				ErrorManager.reportError(new Error(message));
			}
			else{
				var result:XML = new XML(event.target.data);
				//trace(result.toXMLString());
	
				var typeName:String = hierarchyNode.@keyType; // typeName was previously stored here
				var propertyName:String = hierarchyNode.@name; // propertyName was previously stored here
				var dataType:String = hierarchyNode.@dataType;
	
			
				var dataList:XMLList = result.descendants("v").attribute("v");
				var keysList:XMLList = result.descendants("v").attribute("keyValue");
				// process keys into a vector
				var keyStrings:Array = VectorUtils.copyXMLListToVector(keysList, []);
				var keysArray:Array = WeaveAPI.QKeyManager.getQKeys(hierarchyNode.@keyType, keyStrings);
				var keysVector:Vector.<IQualifiedKey> = VectorUtils.copy(keysArray, new Vector.<IQualifiedKey>());
				
				// determine the data type, and create the appropriate type of IAttributeColumn
				var newColumn:IAttributeColumn;
				var dataVector:*;
				
				if (dataType == DataTypes.STRING)
				{
					newColumn = new StringColumn(hierarchyNode);
					dataVector = VectorUtils.copyXMLListToVector(dataList, new Vector.<String>());
					(newColumn as StringColumn).updateRecords(keysVector, dataVector);
				}
				else
				{
					newColumn = new NumberColumn(hierarchyNode);
					dataVector = VectorUtils.copyXMLListToVector(dataList, new Vector.<Number>());
					(newColumn as NumberColumn).updateRecords(keysVector, dataVector);
				}
				// save pointer to new column inside the matching proxy column
				proxyColumn.internalColumn = newColumn;
			}
		}
		
		/**
		 * handleColumnDownloadFail
		 * 
		 */
		private function handleColumnDownloadFail(event:IOErrorEvent):void
		{
			trace(event);
		}
	}
}

import org.oicweave.data.AttributeColumns.ProxyColumn;

/**
 * This object is used as a token in an AsyncResponder.
 */
internal class ColumnRequestToken
{
	public function ColumnRequestToken(pathInHierarchy:XML, proxyColumn:ProxyColumn)
	{
		this.pathInHierarchy = pathInHierarchy;
		this.proxyColumn = proxyColumn;
	}
	public var pathInHierarchy:XML;
	public var proxyColumn:ProxyColumn;
}

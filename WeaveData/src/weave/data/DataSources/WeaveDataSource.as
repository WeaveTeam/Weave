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
	import flash.net.URLRequest;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.Reports.WeaveReport;
	import weave.api.WeaveAPI;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataRowSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.services.IURLRequestUtils;
	import weave.api.services.IWeaveDataService;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.core.ErrorManager;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.SecondaryKeyNumColumn;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.services.DelayedAsyncResponder;
	import weave.services.URLRequestUtils;
	import weave.services.WeaveDataServlet;
	import weave.services.beans.AttributeColumnDataWithKeys;
	import weave.services.beans.DataServiceMetadata;
	import weave.services.beans.DataTableMetadata;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
	/**
	 * WeaveDataSource is an interface for retrieving columns from Weave data servlets.
	 * 
	 * @author adufilie
	 */
	public class WeaveDataSource extends AbstractDataSource implements IDataRowSource
	{
		public function WeaveDataSource()
		{
			url.addImmediateCallback(this, handleURLChange, null, true);
		}
		
		public function getRows(keys:Array):AsyncToken
		{
			return dataService.getRows(keys);
		}
		/**
		 * This function prevents url.value from being null.
		 */
		private function handleURLChange():void
		{
			dataService = null;
			
			var defaultBaseURL:String = '/WeaveServices';
			var defaultServletName:String = '/DataService';
			
			var deprecatedBaseURL:String = '/OpenIndicatorsDataServices';
			if (url.value == null || url.value == '' || url.value == deprecatedBaseURL || url.value == deprecatedBaseURL + defaultServletName)
				url.value = defaultBaseURL + defaultServletName;
			
			// backwards compatibility -- if url ends in default base url, append default servlet name
			if (url.value.split('/').pop() == defaultBaseURL.split('/').pop())
				url.value += defaultServletName;
		}
		
		/**
		 * This gets called as a grouped callback when the session state changes.
		 */
		override protected function initialize():void
		{
			if (dataService == null)
				dataService = new WeaveDataServlet(url.value);

			super.initialize();
		}
		
		override protected function handleHierarchyChange():void
		{
			super.handleHierarchyChange();
			convertOldHierarchyFormat(_attributeHierarchy.value);
			_attributeHierarchy.detectChanges();
		}

		override public function getAttributeColumn(columnReference:IColumnReference):IAttributeColumn
		{
			var hcr:HierarchyColumnReference = columnReference as HierarchyColumnReference;
			if (hcr)
			{
				var hash:String = columnReference.getHashCode();
				convertOldHierarchyFormat(hcr.hierarchyPath.value);
				hcr.hierarchyPath.detectChanges();
				if (hash != columnReference.getHashCode())
					return WeaveAPI.AttributeColumnCache.getColumn(columnReference);
			}
			return super.getAttributeColumn(columnReference);
		}
		
		private function convertOldHierarchyFormat(root:XML):void
		{
			if (root == null)
				return;
			
			var node:XML;
			var oldName:String;
			var value:String;
			var nodes:XMLList;
			var nameMap:Object;
			
			// backwards compatibility for category tags
			nodes = root.descendants("category");
			nameMap = {dataTableName: "name"};
			for each (node in nodes)
			{
				for (oldName in nameMap)
				{
					value = node.attribute(oldName);
					if (value != '')
					{
						delete node['@' + oldName];
						node['@' + nameMap[oldName]] = value;
					}
				}
			}
			// backwards compatibility for attribute tags
			nodes = root.descendants("attribute");
			nameMap = {attributeColumnName: "name", dataTableName: "dataTable"}; // old name to new name
			for each (node in nodes)
			{
				for (oldName in nameMap)
				{
					value = node.attribute(oldName);
					if (value != '')
					{
						delete node['@' + oldName];
						node['@' + nameMap[oldName]] = value;
					}
				}
			}
		}
		
		public const hierarchyURL:LinkableString = newLinkableChild(this, LinkableString);

		private var dataService:IWeaveDataService = null;
		
		/**
		 * requestHierarchyFromSource
		 * This function must be implemented by classes which extend AbstractDataSource.
		 * This function should make a request to the source to fill in the hierarchy.
		 * @param subtreeNode A pointer to a node in the hierarchy representing the root of the subtree to request from the source.
		 */
		override protected function requestHierarchyFromSource(subtreeNode:XML = null):void
		{
			convertOldHierarchyFormat(subtreeNode);
			var query:AsyncToken;
			
			//trace("requestHierarchyFromSource("+(subtreeNode?attributeHierarchy.getPathFromNode(subtreeNode).toXMLString():'')+")");

			if (subtreeNode == null || subtreeNode == _attributeHierarchy.value)
			{
				if (hierarchyURL.value != "" && hierarchyURL.value != null)
				{
					WeaveAPI.URLRequestUtils.getURL(new URLRequest(hierarchyURL.value), handleHierarchyURLDownload, handleHierarchyURLDownloadError);
					trace("hierarchy url "+hierarchyURL.value);
					return;
				}
				if (_attributeHierarchy.value != null)
				{
					// stop if hierarchy is defined
					return;
				}
				//trace("getDataServiceMetadata()");

				query = dataService.getDataServiceMetadata();
				DelayedAsyncResponder.addResponder(query, handleGetDataServiceMetadata, handleGetDataServiceMetadataFault);
			}
			else
			{
				// Right now, this just calls getDataTableMetadata.
				// TODO: The server code should return a subtree given a path in the hierarchy.
				var dataTableName:String = subtreeNode.attribute("name");
				//trace("getDataTableMetadata("+dataTableName+")");
				query = dataService.getDataTableMetadata(dataTableName);
				DelayedAsyncResponder.addResponder(query, handleGetDataTableMetadata, handleGetDataTableMetadataFault, subtreeNode);
			}
		}

		/**
		 * handleHierarchyURLDownload
		 * Called when the hierarchy is downloaded from a URL.
		 */
		private function handleHierarchyURLDownload(event:ResultEvent, token:Object = null):void
		{
			_attributeHierarchy.value = XML(event.result); // this will run callbacks
		}

		/**
		 * handleHierarchyURLDownloadError
		 * Called when the hierarchy fails to download from a URL.
		 */
		private function handleHierarchyURLDownloadError(event:FaultEvent, token:Object = null):void
		{
			WeaveAPI.ErrorManager.reportError(event.fault);
			trace(event.type, event.message + '\n' + event.fault);
		}
		
		private function handleGetDataServiceMetadata(event:ResultEvent, token:Object = null):void
		{
			try
			{
				//trace("handleGetDataServiceMetadata",ObjectUtil.toString(event));
				var result:DataServiceMetadata = new DataServiceMetadata(event.result);

				// get sorted list of categories to create (for data tables and/or geometry collections)
				var categoryNames:Array = [];
				var hashMap:Object = {};
				for each (var names:Array in [result.dataTableNames, result.geometryCollectionNames])
				{
					for each (var name:String in names)
					{
						if (!hashMap[name])
						{
							hashMap[name] = true;
							categoryNames.push(name);
						}
					}
				}
				categoryNames.sort(Array.CASEINSENSITIVE);

				if (_attributeHierarchy.value == null)
					_attributeHierarchy.value = <hierarchy name={ result.serverName }/>;
				
				// add each missing category
				var i:int;
				var parent:XML;

				parent = <category name="Data Tables"/>;
				_attributeHierarchy.value.appendChild(parent);
				for (i = 0; i < categoryNames.length; i++)
				{
					var categoryName:String = categoryNames[i];
					if (parent.category.(@name == categoryName).length() == 0)
						parent.appendChild(<category name={ categoryName }/>);
				}
				
				parent = <category name="Geometry Collections"/>;
				_attributeHierarchy.value.appendChild(parent);
				for (i = 0; i < result.geometryCollectionNames.length; i++)
				{
					var gcName:String = result.geometryCollectionNames[i];
					if (parent.category.(@name == gcName).length() == 0)
						parent.appendChild(<attribute name={ gcName } dataType={ DataTypes.GEOMETRY }/>);
				}
				
				_attributeHierarchy.detectChanges();
			}
			catch (e:Error)
			{
				trace(e.getStackTrace());
				var msg:String = "Unable to process result from servlet: "+ObjectUtil.toString(event.result);
				WeaveAPI.ErrorManager.reportError(new Error(msg));
			}
		}

		private function handleGetDataServiceMetadataFault(event:FaultEvent, token:Object = null):void
		{
			//trace("handleGetDataServiceMetadataFault", event.fault, event.message);
			WeaveAPI.ErrorManager.reportError(event.fault);
		}
		
		private function handleGetDataTableMetadata(event:ResultEvent, token:Object = null):void
		{
			var hierarchyNode:XML = token as XML; // the node to add the list of columns to
			try
			{
				//trace("handleGetDataTableMetadata",ObjectUtil.toString(event));
				var result:DataTableMetadata = new DataTableMetadata(event.result);
				
				// append geometry attribute tag if necessary
				if (result.geometryCollectionExists)
				{
					var geomName:String = hierarchyNode.@name;
					hierarchyNode.appendChild(
						<attribute
							name={ geomName }
							dataType={ DataTypes.GEOMETRY }
							keyType={ result.geometryCollectionKeyType }
							projectionSRS={ result.geometryCollectionProjectionSRS }
						/>
					);
				}
				
				// append list of attributes
				for (var i:int = 0; i < result.columnMetadata.length; i++)
				{
					var metadata:Object = result.columnMetadata[i];
					var node:XML = <attribute/>;
					for (var property:String in metadata)
						if (metadata[property] != null && metadata[property] != '')
							node['@'+property] = metadata[property];
					hierarchyNode.appendChild(node);
				}
			}
			catch (e:Error)
			{
				trace(e.getStackTrace());
				var msg:String = "Unable to process result from servlet: "+ObjectUtil.toString(event.result);
				WeaveAPI.ErrorManager.reportError(new Error(msg));
			}
			finally
			{
				//trace("updated hierarchy: "+ attributeHierarchy);
				_attributeHierarchy.detectChanges();
			}
		}
		private function handleGetDataTableMetadataFault(event:FaultEvent, token:Object = null):void
		{
			trace("handleGetDataTableMetadataFault", (token as XML).toXMLString(), event.fault, event.message);
			// TODO: should fill in pending column requests under this hierarchy path to ProxyColumn.undefinedColumn
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
			
			//trace("requestColumnFromSource()",pathInHierarchy.toXMLString());
			var query:AsyncToken;
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			proxyColumn.setMetadata(leafNode);
			if (ObjectUtil.stringCompare(ColumnUtils.getDataType(proxyColumn), DataTypes.GEOMETRY, true) == 0)
			{
				var tileService:IWeaveGeometryTileService = dataService.createTileService(proxyColumn.getMetadata('name'));
				proxyColumn.internalColumn = new StreamedGeometryColumn(tileService, leafNode);
			}
			else
			{
				// request attribute column
				query = dataService.getAttributeColumn(pathInHierarchy);
				var token:ColumnRequestToken = new ColumnRequestToken(pathInHierarchy, proxyColumn);
				DelayedAsyncResponder.addResponder(query, handleGetAttributeColumn, handleGetAttributeColumnFault, token);
			}
		}
		private function handleGetAttributeColumnFault(event:FaultEvent, token:Object = null):void
		{
			var request:ColumnRequestToken = token as ColumnRequestToken;

			if (request.proxyColumn.wasDisposed)
				return;
			
			request.proxyColumn.internalColumn = ProxyColumn.undefinedColumn;
			trace("handleGetAttributeColumnFault", ObjectUtil.toString(request.pathInHierarchy), event.fault, event.message);
			WeaveAPI.ErrorManager.reportError(event.fault);
		}
//		private function handleGetAttributeColumn(event:ResultEvent, token:Object = null):void
//		{
//			DebugUtils.callLater(5000, handleGetAttributeColumn2, arguments);
//		}
		private function handleGetAttributeColumn(event:ResultEvent, token:Object = null):void
		{
			var request:ColumnRequestToken = token as ColumnRequestToken;
			var pathInHierarchy:XML = request.pathInHierarchy;
			var proxyColumn:ProxyColumn = request.proxyColumn;

			if (proxyColumn.wasDisposed)
				return;
			
			try
			{
				if (!event.result)
				{
					var msg:String = "Did not receive any data from service for attribute column: "
						+ HierarchyUtils.getLeafNodeFromPath(request.pathInHierarchy).toXMLString();
					WeaveAPI.ErrorManager.reportError(new Error(msg));
					return;
				}
				var result:AttributeColumnDataWithKeys = new AttributeColumnDataWithKeys(event.result);
				//trace("handleGetAttributeColumn",pathInHierarchy.toXMLString());
	
				// stop if no data
				if (result.data == null)
				{
					proxyColumn.internalColumn = ProxyColumn.undefinedColumn;
					return;
				}
	
				// fill in metadata
				var hierarchyNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
				// if the node does not exist in hierarchy anymore, create a new XML separate from the hierarchy.
				if (hierarchyNode == null)
					hierarchyNode = <attribute/>;
				hierarchyNode.@keyType = result.keyType;
				hierarchyNode.@dataType = result.dataType;
				hierarchyNode.@name = result.attributeColumnName;

				hierarchyNode.@year = result.year;
				
				if (String(hierarchyNode.@title) == '')
				{
					hierarchyNode.@title = result.attributeColumnName;
					var year:String = hierarchyNode.@year;
					if (year != '')
						hierarchyNode.@title += ' (' + year + ')';
				}

				if (result.min != null && result.min != '')
					hierarchyNode.@min = result.min;
				else
					delete hierarchyNode["@min"];

				if (result.max != null && result.max != '')
					hierarchyNode.@max = result.max;
				else
					delete hierarchyNode["@max"];

				var keysArray:Array = WeaveAPI.QKeyManager.getQKeys(result.keyType, result.keys)
				var keysVector:Vector.<IQualifiedKey> = Vector.<IQualifiedKey>(keysArray);
				if (result.secKeys != null)
				{
					var newColumn:SecondaryKeyNumColumn = new SecondaryKeyNumColumn(hierarchyNode);
					var secKeyVector:Vector.<String> = Vector.<String>(result.secKeys);
					newColumn.updateRecords(keysVector, secKeyVector, result.data);
					proxyColumn.internalColumn = newColumn;
					proxyColumn.setMetadata(null); // this will allow SecondaryKeyNumColumn to use its getMetadata() code
				}
				else if (ObjectUtil.stringCompare(result.dataType, DataTypes.NUMBER, true) == 0)
				{
					var newNumericColumn:NumberColumn = new NumberColumn(hierarchyNode);
					newNumericColumn.updateRecords(keysVector, Vector.<Number>(result.data));
					proxyColumn.internalColumn = newNumericColumn;
				}
				else
				{
					var newStringColumn:StringColumn = new StringColumn(hierarchyNode);
					newStringColumn.updateRecords(keysVector, Vector.<String>(result.data), true);
					proxyColumn.internalColumn = newStringColumn;
				}
				//trace("column downloaded: ",proxyColumn);
				// run hierarchy callbacks because we just modified the hierarchy.
				_attributeHierarchy.detectChanges();
			}
			catch (e:Error)
			{
				trace(this,"handleGetAttributeColumn",pathInHierarchy.toXMLString(),e.getStackTrace());
			}
		}
		
		public function getReport(name:String, keyStrings:Array):void	
		{
			var query:AsyncToken = dataService.createReport(name, keyStrings);
			DelayedAsyncResponder.addResponder(query, handleReportResult, handleCreateReportFault);
		}
		
		public function handleReportResult(event:ResultEvent, token:Object = null):void 
		{
			WeaveReport.handleReportResult(event, dataService);
		}
		
		public function handleCreateReportFault(event:FaultEvent, token:Object = null):void
		{
			trace("Fault creating report: " + event.fault.name, event.message);
			WeaveAPI.ErrorManager.reportError(event.fault);
		}
	}
}

import weave.data.AttributeColumns.ProxyColumn;

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

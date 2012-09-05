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
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataRowSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.disposeObjects;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.reportError;
	import weave.api.services.IWeaveDataService;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.SecondaryKeyNumColumn;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.data.QKeyManager;
	import weave.services.DelayedAsyncResponder;
	import weave.services.WeaveDataServlet;
	import weave.services.beans.AttributeColumnDataWithKeys;
	import weave.services.beans.DataServiceMetadata;
	import weave.services.beans.DataTableMetadata;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	
	/**
	 * WeaveDataSource is an interface for retrieving columns from Weave data servlets.
	 * 
	 * @author adufilie
	 */
	public class WeaveDataSource extends AbstractDataSource implements IDataRowSource
	{
		public function WeaveDataSource()
		{
			url.addImmediateCallback(this, handleURLChange, true);
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
			url.delayCallbacks();
			
			var defaultBaseURL:String = '/WeaveServices';
			var defaultServletName:String = '/DataService';
			
			var deprecatedBaseURL:String = '/OpenIndicatorsDataServices';
			if (!url.value || url.value == deprecatedBaseURL || url.value == deprecatedBaseURL + defaultServletName)
				url.value = defaultBaseURL + defaultServletName;
			
			// backwards compatibility -- if url ends in default base url, append default servlet name
			if (url.value.split('/').pop() == defaultBaseURL.split('/').pop())
				url.value += defaultServletName;
			
			// replace old dataService
			disposeObjects(dataService);
			dataService = new WeaveDataServlet(url.value);
			
			url.resumeCallbacks();
		}
		
		/**
		 * This gets called as a grouped callback when the session state changes.
		 */
		override protected function initialize():void
		{
			super.initialize();
		}
		
		override protected function handleHierarchyChange():void
		{
			super.handleHierarchyChange();
			_convertOldHierarchyFormat(_attributeHierarchy.value);
			_attributeHierarchy.detectChanges();
		}
		
		protected function _convertOldHierarchyFormat(root:XML):void
		{
			if (!root)
				return;
			
			convertOldHierarchyFormat(root, "category", {
				dataTableName: "name"
			});
			convertOldHierarchyFormat(root, "attribute", {
				attributeColumnName: "name",
				dataTableName: "dataTable",
				dataType: _convertOldDataType,
				projectionSRS: AttributeColumnMetadata.PROJECTION
			});
			for each (var node:XML in root.descendants())
			{
				if (!String(node.@title))
				{
					node.@title = node.@name;
					if (String(node.@year))
						node.@title += ' (' + node.@year + ')';
				}
			}
		}
		
		protected function _convertOldDataType(value:String):String
		{
			if (value == 'Geometry')
				return DataTypes.GEOMETRY;
			if (value == 'String')
				return DataTypes.STRING;
			if (value == 'Number')
				return DataTypes.NUMBER;
			return value;
		}

		override public function getAttributeColumn(columnReference:IColumnReference):IAttributeColumn
		{
			var hcr:HierarchyColumnReference = columnReference as HierarchyColumnReference;
			if (hcr)
			{
				var hash:String = columnReference.getHashCode();
				_convertOldHierarchyFormat(hcr.hierarchyPath.value);
				hcr.hierarchyPath.detectChanges();
				if (hash != columnReference.getHashCode())
					return WeaveAPI.AttributeColumnCache.getColumn(columnReference);
			}
			return super.getAttributeColumn(columnReference);
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
			_convertOldHierarchyFormat(subtreeNode);
			var query:AsyncToken;
			
			//trace("requestHierarchyFromSource("+(subtreeNode?attributeHierarchy.getPathFromNode(subtreeNode).toXMLString():'')+")");

			if (subtreeNode == null || subtreeNode == _attributeHierarchy.value)
			{
				if (hierarchyURL.value != "" && hierarchyURL.value != null)
				{
					WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(hierarchyURL.value), handleHierarchyURLDownload, handleHierarchyURLDownloadError);
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
			if (objectWasDisposed(this))
				return;
			_attributeHierarchy.value = XML(event.result); // this will run callbacks
		}

		/**
		 * handleHierarchyURLDownloadError
		 * Called when the hierarchy fails to download from a URL.
		 */
		private function handleHierarchyURLDownloadError(event:FaultEvent, token:Object = null):void
		{
			reportError(event);
		}
		
		private function handleGetDataServiceMetadata(event:ResultEvent, token:Object = null):void
		{
			if (objectWasDisposed(this) || _attributeHierarchy.value != null)
				return;
			
			try
			{
				//trace("handleGetDataServiceMetadata",ObjectUtil.toString(event));
				var result:DataServiceMetadata = new DataServiceMetadata(event.result);

				if (_attributeHierarchy.value == null)
					_attributeHierarchy.value = <hierarchy name={ result.serverName }/>;
				
				// add each missing category
				var i:int;
				var parent:XML;

				parent = <category name="Data Tables"/>;
				_attributeHierarchy.value.appendChild(parent);
				for (i = 0; i < result.dataTableMetadata.length; i++)
				{
					var metadata:Object = result.dataTableMetadata[i];
					if (parent.category.(@name == metadata.name).length() == 0)
					{
						var tag:XML = <category/>;
						for (var attrName:String in metadata)
							tag['@'+attrName] = metadata[attrName];
						parent.appendChild(tag);
					}
				}
				
				parent = <category name="Geometry Collections"/>;
				_attributeHierarchy.value.appendChild(parent);
				for (i = 0; i < result.geometryCollectionNames.length; i++)
				{
					var gcName:String = result.geometryCollectionNames[i];
					var keyType:String = result.geometryCollectionKeyTypes[i];
					if (parent.category.(@name == gcName).length() == 0)
						parent.appendChild(<attribute title={ gcName } name={ gcName } dataType={ DataTypes.GEOMETRY } keyType={ keyType }/>);
				}
				
				_attributeHierarchy.detectChanges();
			}
			catch (e:Error)
			{
				reportError(e, "Unable to process result from servlet: "+ObjectUtil.toString(event.result));
			}
		}

		private function handleGetDataServiceMetadataFault(event:FaultEvent, token:Object = null):void
		{
			//trace("handleGetDataServiceMetadataFault", event.fault, event.message);
			reportError(event);
		}
		
		private function handleGetDataTableMetadata(event:ResultEvent, token:Object = null):void
		{
			if (objectWasDisposed(this))
				return;

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
							title={ geomName }
							name={ geomName }
							dataType={ DataTypes.GEOMETRY }
							keyType={ result.geometryCollectionKeyType }
							projection={ result.geometryCollectionProjectionSRS }
						/>
					);
				}
				
				// append list of attributes
				for (var i:int = 0; i < result.columnMetadata.length; i++)
				{
					var metadata:Object = result.columnMetadata[i];
					// fill in title if missing
					if (!metadata['title'])
					{
						metadata['title'] = metadata['name'];
						if (metadata['year'])
							metadata['title'] += ' (' + metadata['year'] + ')';
					}
					var node:XML = <attribute/>;
					for (var property:String in metadata)
						if (metadata[property])
							node['@'+property] = metadata[property];
					hierarchyNode.appendChild(node);
				}
			}
			catch (e:Error)
			{
				reportError(e, "Unable to process result from servlet: "+ObjectUtil.toString(event.result));
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
			reportError(event);
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
			if (ObjectUtil.stringCompare(ColumnUtils.getDataType(proxyColumn), DataTypes.GEOMETRY, true) == 0)
			{
				var tileService:IWeaveGeometryTileService = dataService.createTileService(proxyColumn.getMetadata('name'));
				proxyColumn.setInternalColumn(new StreamedGeometryColumn(tileService, leafNode));
			}
			else
			{
				// request attribute column
				var query:AsyncToken = dataService.getAttributeColumn(pathInHierarchy);
				var token:ColumnRequestToken = new ColumnRequestToken(pathInHierarchy, proxyColumn);
				DelayedAsyncResponder.addResponder(query, handleGetAttributeColumn, handleGetAttributeColumnFault, token);
				WeaveAPI.SessionManager.assignBusyTask(query, proxyColumn);
			}
		}
		private function handleGetAttributeColumnFault(event:FaultEvent, token:Object = null):void
		{
			var request:ColumnRequestToken = token as ColumnRequestToken;

			if (request.proxyColumn.wasDisposed)
				return;
			
			request.proxyColumn.setInternalColumn(ProxyColumn.undefinedColumn);
			reportError(event, null, token);
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
			
//			try
//			{
				if (!event.result)
				{
					var msg:String = "Did not receive any data from service for attribute column: "
						+ HierarchyUtils.getLeafNodeFromPath(request.pathInHierarchy).toXMLString();
					reportError(msg);
					return;
				}
				var result:AttributeColumnDataWithKeys = new AttributeColumnDataWithKeys(event.result);
				//trace("handleGetAttributeColumn",pathInHierarchy.toXMLString());
	
				// stop if no data
				if (result.data == null)
				{
					proxyColumn.setInternalColumn(ProxyColumn.undefinedColumn);
					return;
				}
	
				// fill in metadata
				var hierarchyNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
				// if the node does not exist in hierarchy anymore, create a new XML separate from the hierarchy.
				if (hierarchyNode == null)
					hierarchyNode = <attribute/>;
				for (var metadataName:String in result.metadata)
				{
					var metadataValue:String = result.metadata[metadataName];
					if (metadataValue)
						hierarchyNode['@' + metadataName] = metadataValue;
				}
				
				if (!String(hierarchyNode.@title))
				{
					hierarchyNode.@title = result.metadata.name; // temporary hack
					
					// year hack -- this could be replaced by a global "default title formatting function" like "title (year)"
					var year:String = hierarchyNode.@year;
					if (year)
						hierarchyNode.@title += ' (' + year + ')';
				}
				
				var keyType:String = hierarchyNode['@' + AttributeColumnMetadata.KEY_TYPE];
				var dataType:String = hierarchyNode['@' + AttributeColumnMetadata.DATA_TYPE];
				
				var keysVector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
				var setRecords:Function = function():void
				{
					if (result.thirdColumn != null)
					{
						// hack for dimension slider
						var newColumn:SecondaryKeyNumColumn = new SecondaryKeyNumColumn(hierarchyNode);
						var secKeyVector:Vector.<String> = Vector.<String>(result.thirdColumn);
						newColumn.updateRecords(keysVector, secKeyVector, result.data);
						proxyColumn.setInternalColumn(newColumn);
						proxyColumn.setMetadata(null); // this will allow SecondaryKeyNumColumn to use its getMetadata() code
					}
					else if (ObjectUtil.stringCompare(dataType, DataTypes.NUMBER, true) == 0)
					{
						var newNumericColumn:NumberColumn = new NumberColumn(hierarchyNode);
						newNumericColumn.setRecords(keysVector, Vector.<Number>(result.data));
						proxyColumn.setInternalColumn(newNumericColumn);
					}
					else
					{
						var newStringColumn:StringColumn = new StringColumn(hierarchyNode);
						newStringColumn.setRecords(keysVector, Vector.<String>(result.data));
						proxyColumn.setInternalColumn(newStringColumn);
					}
					//trace("column downloaded: ",proxyColumn);
					// run hierarchy callbacks because we just modified the hierarchy.
					_attributeHierarchy.detectChanges();
				};
				(WeaveAPI.QKeyManager as QKeyManager).getQKeysAsync(keyType, result.keys, proxyColumn, setRecords, keysVector);
//			}
//			catch (e:Error)
//			{
//				trace(this,"handleGetAttributeColumn",pathInHierarchy.toXMLString(),e.getStackTrace());
//			}
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
			reportError(event, "Fault creating report: " + event.fault.name, event.message);
		}
	}
}

import weave.api.WeaveAPI;
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

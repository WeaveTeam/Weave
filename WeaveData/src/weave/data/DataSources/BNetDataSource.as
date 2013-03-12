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
	
	import weave.api.WeaveAPI;
	import weave.api.disposeObjects;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.reportError;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataRowSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.core.LinkableString;
	import weave.data.QKeyManager;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.SecondaryKeyNumColumn;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.services.BNetServlet;
	import weave.services.addAsyncResponder;
	import weave.services.beans.AttributeColumnData;
	import weave.services.beans.EntityType;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.VectorUtils;
	
	/**
	 * WeaveDataSource is an interface for retrieving columns from Weave data servlets.
	 * 
	 * @author adufilie
	 */
	public class BNetDataSource extends AbstractDataSource implements IDataRowSource
	{
		public function BNetDataSource()
		{
			url.addImmediateCallback(this, handleURLChange, true);
		}
		
		public function getRows(keys:Array):AsyncToken
		{
			/* ... */
			//return dataService.getRows(keys);
			return null;
		}
		/**
		 * This function prevents url.value from being null.
		 */
		private function handleURLChange():void
		{
			url.delayCallbacks();
			
			var defaultBaseURL:String = '/WeaveServices';
			var defaultServletName:String = '/BNetService';
			
			if (!url.value)
				url.value = defaultBaseURL + defaultServletName;
			
			// replace old dataService
			disposeObjects(dataService);
			dataService = new BNetServlet(url.value);
			
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
			_attributeHierarchy.detectChanges();
		}
		

		override public function getAttributeColumn(columnReference:IColumnReference):IAttributeColumn
		{
			var hcr:HierarchyColumnReference = columnReference as HierarchyColumnReference;
			if (hcr)
			{
				var hash:String = columnReference.getHashCode();
				hcr.hierarchyPath.detectChanges();
				if (hash != columnReference.getHashCode())
					return WeaveAPI.AttributeColumnCache.getColumn(columnReference);
			}
			return super.getAttributeColumn(columnReference);
		}
		
		private var dataService:BNetServlet = null;
		
		/**
		 * This function must be implemented by classes which extend AbstractDataSource.
		 * This function should make a request to the source to fill in the hierarchy.
		 * @param subtreeNode A pointer to a node in the hierarchy representing the root of the subtree to request from the source.
		 */
		override protected function requestHierarchyFromSource(subtreeNode:XML = null):void
		{
			var query:AsyncToken;
			
			var _graphNames:Array = null;

			query = dataService.listNetworks();
			addAsyncResponder(query, handleNetworkNames, handleFault);

			function handleNetworkNames(event:ResultEvent, obj:Object = null)
			{
				_graphNames = event.result as Array;
				generateRootHierarchy(_graphNames);
			}
		}
		
		/**
		 * Called when the hierarchy is downloaded from a URL.
		 */
		private function handleHierarchyURLDownload(event:ResultEvent, token:Object = null):void
		{
			if (objectWasDisposed(this))
				return;
			_attributeHierarchy.value = XML(event.result); // this will run callbacks
		}

		/**
		 * Called when the hierarchy fails to download from a URL.
		 */
		private function handleHierarchyURLDownloadError(event:FaultEvent, token:Object = null):void
		{
			reportError(event, null, token);
		}
		
		public static const ENTITY_ID:String = 'weaveEntityId';
		
		private function generateRootHierarchy(graphs:Array):void
		{

			if (_attributeHierarchy.value == null)
				_attributeHierarchy.value = <hierarchy name="BNet Data Service"/>;

			for (var i = 0; i < graphs.length; i++)
			{
				/* For each bayesian network, generate "Nodes" and "Edges" subtrees. */
				var graph_tag:XML = <category/>;
				graph_tag["@title"] = "Network \'" + graphs[i] + "\'";
				graph_tag["@name"] = graphs[i];
				var node_tag:XML = <category title="Nodes" name="nodes"/>;
				var edge_tag:XML = <category title="Edges" name="edges"/>;
				_attributeHierarchy.value.appendChild(graph_tag);
				graph_tag.appendChild(node_tag);
				graph_tag.appendChild(edge_tag);
			}

			_attributeHierarchy.detectChanges();

		}

		private function handleColumnEntities(event:ResultEvent, hierarchyNode_entityIds:Array):void
		{
			if (objectWasDisposed(this))
				return;

			var hierarchyNode:XML = hierarchyNode_entityIds[0] as XML; // the node to add the list of columns to
			var entityIds:Array = hierarchyNode_entityIds[1] as Array; // ordered list of ids

			try
			{
				var entities:Array = event.result as Array;
				entities.sort(
					function(entity1:Object, entity2:Object):int
					{
						var i1:int = entityIds.indexOf(entity1.id);
						var i2:int = entityIds.indexOf(entity2.id);
						return ObjectUtil.numericCompare(i1, i2);
					}
				);
				
				// append list of attributes
				for (var i:int = 0; i < entities.length; i++)
				{
					var metadata:Object = entities[i].publicMetadata;
					metadata[ENTITY_ID] = entities[i].id;
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
		private function handleFault(event:FaultEvent, token:Object = null):void
		{
			reportError(event);
			trace('async token',ObjectUtil.toString(token));
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
			
			//trace("requestColumnFromSource()",pathInHierarchy.toXMLString());
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy) || <empty/>;
			proxyColumn.setMetadata(leafNode.copy());
			
			// get metadata properties from XML attributes
			var params:Object = new Object();
			const SQLPARAMS:String = 'sqlParams';
			var queryProperties:Array = [
				ENTITY_ID, SQLPARAMS,
				ColumnMetadata.DATA_TYPE, ColumnMetadata.MIN, ColumnMetadata.MAX,
				'dataTable', 'name', 'year'
			]; // use only these properties for querying
			for each (var attr:String in queryProperties)
			{
				var value:String = leafNode.attribute(attr);
				if (value)
					params[attr] = value;
			}
			
			var columnRequestToken:ColumnRequestToken = new ColumnRequestToken(pathInHierarchy, proxyColumn);
			var query:AsyncToken;
			if (params[ENTITY_ID])
			{
				var sqlParams:Array = VectorUtils.flatten(WeaveAPI.CSVParser.parseCSV(params[SQLPARAMS]));
				//query = dataService.getColumn(params[ENTITY_ID], params[ColumnMetadata.MIN], params[ColumnMetadata.MAX], sqlParams);
			}
			else // backwards compatibility - search using metadata
			{
				if (params[ColumnMetadata.DATA_TYPE] != DataTypes.GEOMETRY)
					delete params[ColumnMetadata.DATA_TYPE];
				
				//query = dataService.getColumnFromMetadata(params);
			}
			addAsyncResponder(query, handleGetAttributeColumn, handleGetAttributeColumnFault, columnRequestToken);
			WeaveAPI.SessionManager.assignBusyTask(query, proxyColumn);
		}
		
		private function handleGetAttributeColumnFault(event:FaultEvent, token:Object = null):void
		{
			var request:ColumnRequestToken = token as ColumnRequestToken;

			if (request.proxyColumn.wasDisposed)
				return;
			
			reportError(event, null, request);
			
			request.proxyColumn.setInternalColumn(ProxyColumn.undefinedColumn);
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
			var hierarchyNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			// if the node does not exist in hierarchy anymore, create a new XML separate from the hierarchy.
			if (hierarchyNode == null)
				hierarchyNode = <attribute/>;

			if (proxyColumn.wasDisposed)
				return;
			
			try
			{
				if (!event.result)
				{
					var msg:String = "Did not receive any data from service for attribute column: "
						+ HierarchyUtils.getLeafNodeFromPath(request.pathInHierarchy).toXMLString();
					reportError(msg);
					return;
				}
				
				var result:AttributeColumnData = new AttributeColumnData(event.result);
				//trace("handleGetAttributeColumn",pathInHierarchy.toXMLString());
	
				// fill in metadata
				for (var metadataName:String in result.metadata)
				{
					var metadataValue:String = result.metadata[metadataName];
					if (metadataValue)
						hierarchyNode['@' + metadataName] = metadataValue;
				}
				hierarchyNode['@id'] = result.id;
				
				// special case for geometry column
				var dataType:String = ColumnUtils.getDataType(proxyColumn);
				var isGeom:Boolean = ObjectUtil.stringCompare(dataType, DataTypes.GEOMETRY, true) == 0;
				if (isGeom)
				{
					/*
					var tileService:IWeaveGeometryTileService = dataService.createTileService(result.id);
					proxyColumn.setInternalColumn(new StreamedGeometryColumn(result.metadataTileDescriptors, result.geometryTileDescriptors, tileService, hierarchyNode));
					return;
					*/
					return;
				}
	
				// stop if no data
				if (result.data == null)
				{
					proxyColumn.setInternalColumn(ProxyColumn.undefinedColumn);
					return;
				}
				
				var keyType:String = hierarchyNode.attribute(ColumnMetadata.KEY_TYPE);
				dataType = hierarchyNode.attribute(ColumnMetadata.DATA_TYPE);
				
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
			}
			catch (e:Error)
			{
				trace(this,"handleGetAttributeColumn",pathInHierarchy.toXMLString(),e.getStackTrace());
			}
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

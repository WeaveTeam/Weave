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
	import flash.utils.Dictionary;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.EntityType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataRowSource;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.objectWasDisposed;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.api.services.beans.Entity;
	import weave.api.services.beans.EntitySearchCriteria;
	import weave.compiler.StandardLib;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.data.AttributeColumns.DateColumn;
	import weave.data.AttributeColumns.GeometryColumn;
	import weave.data.AttributeColumns.NumberColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.SecondaryKeyNumColumn;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.data.QKeyManager;
	import weave.data.hierarchy.EntityNode;
	import weave.primitives.GeneralizedGeometry;
	import weave.services.EntityCache;
	import weave.services.WeaveDataServlet;
	import weave.services.addAsyncResponder;
	import weave.services.beans.AttributeColumnData;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	
	/**
	 * WeaveDataSource is an interface for retrieving columns from Weave data servlets.
	 * 
	 * @author adufilie
	 */
	public class WeaveDataSource extends AbstractDataSource implements IDataRowSource
	{
		WeaveAPI.registerImplementation(IDataSource, WeaveDataSource, "Weave server");
		
		public function WeaveDataSource()
		{
			url.addImmediateCallback(this, handleURLChange, true);
		}
		
		private var _service:WeaveDataServlet = null;
		private var _entityCache:EntityCache = null;
		public const url:LinkableString = newLinkableChild(this, LinkableString);
		public const hierarchyURL:LinkableString = newLinkableChild(this, LinkableString);
		
		/**
		 * This is an Array of public metadata field names that should be used to uniquely identify columns when querying the server.
		 */		
		public const idFields:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array, verifyStringArray));
		
		public function get entityCache():EntityCache
		{
			return _entityCache;
		}
		
		private function verifyStringArray(array:Array):Boolean
		{
			return StandardLib.getArrayType(array) == String;
		}
		
		override public function refreshHierarchy():void
		{
			super.refreshHierarchy();
			entityCache.invalidateAll();
			if (_rootNode is RootNode_TablesAndGeoms)
				(_rootNode as RootNode_TablesAndGeoms).refresh();
		}
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (_attributeHierarchy.value === null)
			{
				if (!(_rootNode is RootNode_TablesAndGeoms))
					_rootNode = new RootNode_TablesAndGeoms(this);
				return _rootNode;
			}
			else
			{
				return super.getHierarchyRoot();
			}
		}
		
		/**
		 * Populates a LinkableDynamicObject with an IColumnReference corresponding to a node in the attribute hierarchy.
		 */
		override public function getColumnReference(node:IWeaveTreeNode, output:ILinkableDynamicObject):Boolean
		{
			if (node.getSource() != this || node.isBranch())
				return false;
			
			var entityNode:EntityNode = node as EntityNode;
			if (entityNode)
			{
				getCallbackCollection(output).delayCallbacks();
				var hcr:HierarchyColumnReference = output.requestLocalObject(HierarchyColumnReference, false);
				
				hcr.dataSourceName.value = WeaveAPI.globalHashMap.getName(this);
				
				var xml:XML = <attribute/>;
				var meta:Object = entityNode.getEntity().publicMetadata;
				for (var key:String in meta)
					xml['@' + key] = meta[key];
				xml['@' + ENTITY_ID] = entityNode.id;
				hcr.hierarchyPath.value = xml;
				
				getCallbackCollection(output).resumeCallbacks();
				return true;
			}
			
			return super.getColumnReference(node, output);
		}
		
		public function getRows(keys:Array):AsyncToken
		{
			return _service.getRows(keys);
		}
		/**
		 * This function prevents url.value from being null.
		 */
		private function handleURLChange():void
		{
			url.delayCallbacks();
			
			var defaultBaseURL:String = '/WeaveServices';
			var defaultServletName:String = '/DataService';
			
			var deprecatedBaseURL:String = '/OpenIndicatorsDataService';
			if (!url.value || url.value == deprecatedBaseURL || url.value == deprecatedBaseURL + defaultServletName)
				url.value = defaultBaseURL + defaultServletName;
			
			// backwards compatibility -- if url ends in default base url, append default servlet name
			if (url.value.split('/').pop() == defaultBaseURL.split('/').pop())
				url.value += defaultServletName;
			
			// replace old service
			disposeObject(_service);
			_service = registerLinkableChild(this, new WeaveDataServlet(url.value));
			_entityCache = registerLinkableChild(_service, new EntityCache(_service));
			
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
				projectionSRS: ColumnMetadata.PROJECTION
			});
			for each (var tag:XML in root.descendants())
			{
				if (!String(tag.@title))
				{
					var newTitle:String;
					if (String(tag.@name) && String(tag.@year))
						newTitle = String(tag.@name) + ' (' + tag.@year + ')';
					else if (String(tag.@name))
						newTitle = String(tag.@name);
					tag.@title = newTitle || 'untitled';
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
		
		/**
		 * This function must be implemented by classes which extend AbstractDataSource.
		 * This function should make a request to the source to fill in the hierarchy.
		 * @param subtreeNode A pointer to a node in the hierarchy representing the root of the subtree to request from the source.
		 */
		override protected function requestHierarchyFromSource(subtreeNode:XML = null):void
		{
			_convertOldHierarchyFormat(subtreeNode);
			
			//trace("requestHierarchyFromSource("+(subtreeNode?attributeHierarchy.getPathFromNode(subtreeNode).toXMLString():'')+")");

			if (!subtreeNode || subtreeNode == _attributeHierarchy.value)
			{
				if (hierarchyURL.value)
				{
					WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(hierarchyURL.value), handleHierarchyURLDownload, handleHierarchyURLDownloadError, hierarchyURL.value);
					trace("hierarchy url "+hierarchyURL.value);
				}
				return;
			}
			
			var idStr:String = subtreeNode.attribute(ENTITY_ID);
			if (idStr)
			{
				addAsyncResponder(
					_service.getEntities([int(idStr)]),
					function(event:ResultEvent, subtreeNode:XML):void
					{
						var entities:Array = event.result as Array;
						if (entities && entities.length)
						{
							getChildNodes(subtreeNode, Entity(entities[0]).childIds);
						}
						else
						{
							reportError(lang('WeaveDataSource: No entity exists with id={0}', idStr));
						}
					},
					handleFault,
					subtreeNode
				);
			}
			else
			{
				// backwards compatibility - get columns with matching dataTable metadata
				var dataTableName:String = subtreeNode.attribute("name");
				var em:EntitySearchCriteria = new EntitySearchCriteria();
				em.publicMetadata = {"dataTable": dataTableName, "entityType": EntityType.COLUMN};
				addAsyncResponder(
					_service.findEntityIds(em),
					function(event:ResultEvent, subtreeNode:XML):void
					{
						var ids:Array = event.result as Array;
						StandardLib.sort(ids);
						getChildNodes(subtreeNode, ids);
					},
					handleFault,
					subtreeNode
				);
			}
			function getChildNodes(subtreeNode:XML, childIds:Array):void
			{
				if (childIds && childIds.length)
					addAsyncResponder(
						_service.getEntities(childIds),
						handleColumnEntities,
						handleFault,
						[subtreeNode, childIds]
					);
			}
		}
		
		private static const NO_RESULT_ERROR:String = "Received null result from Weave server.";
		
		/**
		 * Called when the hierarchy is downloaded from a URL.
		 */
		private function handleHierarchyURLDownload(event:ResultEvent, url:String):void
		{
			if (objectWasDisposed(this) || url != hierarchyURL.value)
				return;
			_attributeHierarchy.value = XML(event.result); // this will run callbacks
		}

		/**
		 * Called when the hierarchy fails to download from a URL.
		 */
		private function handleHierarchyURLDownloadError(event:FaultEvent, url:String):void
		{
			if (url != hierarchyURL.value)
				return;
			reportError(event, null, url);
		}
		
		public static const ENTITY_ID:String = 'weaveEntityId';
		
		private function handleColumnEntities(event:ResultEvent, hierarcyNode_entityIds:Array):void
		{
			if (objectWasDisposed(this))
				return;

			var i:int;
			var entity:Entity;
			var hierarchyNode:XML = hierarcyNode_entityIds[0] as XML; // the node to add the list of columns to
			var entityIds:Array = hierarcyNode_entityIds[1] as Array; // ordered list of ids

			hierarchyNode = HierarchyUtils.findEquivalentNode(_attributeHierarchy.value, hierarchyNode);
			if (!hierarchyNode)
				return;
			
			try
			{
				var entities:Array = event.result as Array;
				
				// sort entities by preferred id order
				var idOrder:Object = {}; // id -> index
				for (i = 0; i < entityIds.length; i++)
					idOrder[entityIds[i]] = i;
				StandardLib.sort(
					entities,
					function(entity1:Entity, entity2:Entity):int
					{
						return ObjectUtil.numericCompare(idOrder[entity1.id], idOrder[entity2.id]);
					}
				);
				
				// append list of attributes
				for (i = 0; i < entities.length; i++)
				{
					entity = entities[i];
					var metadata:Object = entity.publicMetadata;
					metadata[ENTITY_ID] = entity.id;
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
			if (objectWasDisposed(_service))
				return;
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

			var pathInHierarchy:XML = hierarchyRef.hierarchyPath.value || <empty/>;
			
			//trace("requestColumnFromSource()",pathInHierarchy.toXMLString());
			var leafNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy) || <empty/>;
			proxyColumn.setMetadata(leafNode.copy());
			
			// get metadata properties from XML attributes
			const SQLPARAMS:String = 'sqlParams';
			var params:Object = getAttrs(leafNode, [ENTITY_ID, ColumnMetadata.MIN, ColumnMetadata.MAX, SQLPARAMS], false);
			var columnRequestToken:ColumnRequestToken = new ColumnRequestToken(pathInHierarchy, proxyColumn);
			var query:AsyncToken;
			var _idFields:Array = idFields.getSessionState() as Array;
			
			if (_idFields || params[ENTITY_ID])
			{
				var id:Object = _idFields ? getAttrs(leafNode, _idFields, true) : StandardLib.asNumber(params[ENTITY_ID]);
				var sqlParams:Array = WeaveAPI.CSVParser.parseCSVRow(params[SQLPARAMS]);
				query = _service.getColumn(id, params[ColumnMetadata.MIN], params[ColumnMetadata.MAX], sqlParams);
			}
			else // backwards compatibility - search using metadata
			{
				getAttrs(leafNode, [ColumnMetadata.DATA_TYPE, 'dataTable', 'name', 'year'], false, params);
				// dataType is only used for backwards compatibility with geometry collections
				if (params[ColumnMetadata.DATA_TYPE] != DataTypes.GEOMETRY)
					delete params[ColumnMetadata.DATA_TYPE];
				
				query = _service.getColumnFromMetadata(params);
			}
			addAsyncResponder(query, handleGetAttributeColumn, handleGetAttributeColumnFault, columnRequestToken);
			WeaveAPI.ProgressIndicator.addTask(query, proxyColumn);
		}
		
		/**
		 * @param node An XML node
		 * @param attrNames A list of attribute names
		 * @param forUniqueId Set this to true when these attributes are the ones specified by idFields to uniquely identify a column.
		 * @param output An object to store the values.
		 * @return An object containing the attribute values.  Empty strings will be omitted, unless all values were empty and forUniqueId == true.
		 */
		private function getAttrs(node:XML, attrNames:Array, forUniqueId:Boolean, output:Object = null):Object
		{
			var attrName:String;
			var found:Boolean = false;
			var result:Object = output || {};
			for each (attrName in attrNames)
			{
				// ignore missing values
				var attr:String = node.attribute(attrName);
				if (attr)
				{
					found = true;
					result[attrName] = attr;
				}
			}
			if (!found && forUniqueId)
				for each (attrName in attrNames)
					result[attrName] = '';
			return result;
		}
		
		private function handleGetAttributeColumnFault(event:FaultEvent, request:ColumnRequestToken):void
		{
			if (request.proxyColumn.wasDisposed)
				return;
			
			var xml:XML = HierarchyUtils.getLeafNodeFromPath(request.pathInHierarchy) || request.pathInHierarchy;
			var msg:String = "Error retrieving column: " + xml.toXMLString() + ' (' + event.fault.faultString + ')';
			reportError(event.fault, msg, request);
			
			request.proxyColumn.setInternalColumn(ProxyColumn.undefinedColumn);
		}
//		private function handleGetAttributeColumn(event:ResultEvent, token:Object = null):void
//		{
//			DebugUtils.callLater(5000, handleGetAttributeColumn2, arguments);
//		}
		private function handleGetAttributeColumn(event:ResultEvent, request:ColumnRequestToken):void
		{
			if (request.proxyColumn.wasDisposed)
				return;
			
			var pathInHierarchy:XML = request.pathInHierarchy;
			var proxyColumn:ProxyColumn = request.proxyColumn;
			var hierarchyNode:XML = HierarchyUtils.getLeafNodeFromPath(pathInHierarchy);
			// if the node does not exist in hierarchy anymore, create a new XML separate from the hierarchy.
			if (!hierarchyNode)
				hierarchyNode = <attribute/>;
			else
				proxyColumn.setMetadata(hierarchyNode);

			try
			{
				if (!event.result)
				{
					var msg:String = "Did not receive any data from service for attribute column: "
						+ HierarchyUtils.getLeafNodeFromPath(request.pathInHierarchy).toXMLString();
					reportError(msg);
					return;
				}
				
				var result:AttributeColumnData = AttributeColumnData(event.result);
				//trace("handleGetAttributeColumn",pathInHierarchy.toXMLString());
	
				// fill in metadata
				for (var metadataName:String in result.metadata)
				{
					var metadataValue:String = result.metadata[metadataName];
					if (metadataValue)
						hierarchyNode['@' + metadataName] = metadataValue;
				}
				hierarchyNode['@'+ENTITY_ID] = result.id;
				
				// special case for geometry column
				var dataType:String = ColumnUtils.getDataType(proxyColumn);
				var isGeom:Boolean = ObjectUtil.stringCompare(dataType, DataTypes.GEOMETRY, true) == 0;
				if (isGeom && result.data == null)
				{
					var tileService:IWeaveGeometryTileService = _service.createTileService(result.id);
					proxyColumn.setInternalColumn(new StreamedGeometryColumn(result.metadataTileDescriptors, result.geometryTileDescriptors, tileService, hierarchyNode));
					return;
				}
	
				// stop if no data
				if (result.data == null)
				{
					proxyColumn.setInternalColumn(ProxyColumn.undefinedColumn);
					return;
				}
				
				var keyType:String = ColumnUtils.getKeyType(proxyColumn);
				var keysVector:Vector.<IQualifiedKey> = new Vector.<IQualifiedKey>();
				var setRecords:Function = function():void
				{
					if (isGeom) // result.data is an array of PGGeom objects.
					{
						var geometriesVector:Vector.<GeneralizedGeometry> = new Vector.<GeneralizedGeometry>();
						var createGeomColumn:Function = function():void
						{
							var newGeometricColumn:GeometryColumn = new GeometryColumn(hierarchyNode);
							newGeometricColumn.setGeometries(keysVector, geometriesVector);
							proxyColumn.setInternalColumn(newGeometricColumn);
						};
						var pgGeomTask:Function = PGGeomUtil.newParseTask(result.data, geometriesVector);
						WeaveAPI.StageUtils.startTask(proxyColumn, pgGeomTask, WeaveAPI.TASK_PRIORITY_3_PARSING, createGeomColumn);
					}
					else if (result.thirdColumn != null)
					{
						// hack for dimension slider
						var newColumn:SecondaryKeyNumColumn = new SecondaryKeyNumColumn(hierarchyNode);
						newColumn.baseTitle = String(hierarchyNode.@baseTitle);
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
					else if (ObjectUtil.stringCompare(dataType, DataTypes.DATE, true) == 0)
					{
						var newDateColumn:DateColumn = new DateColumn(hierarchyNode);
						newDateColumn.setRecords(keysVector, Vector.<String>(result.data));
						proxyColumn.setInternalColumn(newDateColumn);
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

import flash.utils.getTimer;

import mx.rpc.events.ResultEvent;

import weave.api.WeaveAPI;
import weave.api.data.ColumnMetadata;
import weave.api.data.DataTypes;
import weave.api.data.EntityType;
import weave.api.data.IWeaveTreeNode;
import weave.api.getCallbackCollection;
import weave.api.services.beans.EntityHierarchyInfo;
import weave.data.AttributeColumns.ProxyColumn;
import weave.data.DataSources.WeaveDataSource;
import weave.data.hierarchy.EntityNode;
import weave.primitives.GeneralizedGeometry;
import weave.primitives.GeometryType;
import weave.services.EntityCache;
import weave.services.addAsyncResponder;
import weave.utils.BLGTreeUtils;

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

/**
 * Static functions for retrieving values from PGGeom objects coming from servlet.
 */
internal class PGGeomUtil
{
	/**
	 * This will generate an asynchronous task function for use with IStageUtils.startTask().
	 * @param pgGeoms An Array of PGGeom beans from a Weave data service.
	 * @param output A vector to store GeneralizedGeometry objects created from the pgGeoms input.
	 * @return A new Function.
	 * @see weave.api.core.IStageUtils
	 */
	public static function newParseTask(pgGeoms:Array, output:Vector.<GeneralizedGeometry>):Function
	{
		var i:int = 0;
		var n:int = pgGeoms.length;
		output.length = n;
		return function(returnTime:int):Number
		{
			for (; i < n; i++)
			{
				if (getTimer() > returnTime)
					return i / n;
				
				var item:Object = pgGeoms[i];
				var geomType:String = GeometryType.fromPostGISType(item[TYPE]);
				var geometry:GeneralizedGeometry = new GeneralizedGeometry(geomType);
				geometry.setCoordinates(item[XYCOORDS], BLGTreeUtils.METHOD_SAMPLE);
				output[i] = geometry;
			}
			return 1;
		};
	}
	
	/**
	 * The name of the type property in a PGGeom bean
	 */
	private static const TYPE:String = 'type';
	
	/**
	 * The name of the xyCoords property in a PGGeom bean
	 */
	private static const XYCOORDS:String = 'xyCoords';
}

/**
 * Has two children: "Data Tables" and "Geometry Collections"
 */
internal class RootNode_TablesAndGeoms implements IWeaveTreeNode
{
	private var source:WeaveDataSource;
	private var tableList:EntityNode;
	private var geomList:GeomListNode;
	private var children:Array;
	public function RootNode_TablesAndGeoms(source:WeaveDataSource)
	{
		this.source = source;
		tableList = new EntityNode(null, EntityType.TABLE);
		geomList = new GeomListNode(source);
		children = [tableList, geomList];
	}
	public function refresh():void
	{
		geomList.children = null;
	}
	public function getSource():Object { return source; }
	public function equals(other:IWeaveTreeNode):Boolean { return other == this; }
	public function getLabel():String
	{
		return WeaveAPI.globalHashMap.getName(source);
	}
	public function isBranch():Boolean { return true; }
	public function hasChildBranches():Boolean { return true; }
	public function getChildren():Array
	{
		tableList.setEntityCache(source.entityCache);
		
		var str:String = lang("Data Tables");
		if (tableList.getChildren().length)
			str = lang("{0} ({1})", str, tableList.getChildren().length);
		tableList._overrideLabel = str;
		
		return children;
	}
	public function addChildAt(newChild:IWeaveTreeNode, index:int):Boolean { throw new Error("Not implemented"); }
	public function removeChild(child:IWeaveTreeNode):Boolean { throw new Error("Not implemented"); }
}

/**
 * Makes an RPC to find geometry columns for its children
 */
internal class GeomListNode implements IWeaveTreeNode
{
	private var source:WeaveDataSource;
	private var cache:EntityCache;
	internal var children:Array;
	public function GeomListNode(source:WeaveDataSource)
	{
		this.source = source;
	}
	public function getSource():Object { return source; }
	public function equals(other:IWeaveTreeNode):Boolean { return other == this; }
	public function getLabel():String
	{
		var label:String = lang("Geometry Collections");
		if (children && children.length)
			return lang("{0} ({1})", label, children.length);
		return label;
	}
	public function isBranch():Boolean { return true; }
	public function hasChildBranches():Boolean { return false; }
	public function getChildren():Array
	{
		if (!children || cache != source.entityCache)
		{
			cache = source.entityCache;
			children = [];
			var meta:Object = {};
			meta[ColumnMetadata.ENTITY_TYPE] = EntityType.COLUMN;
			meta[ColumnMetadata.DATA_TYPE] = DataTypes.GEOMETRY;
			addAsyncResponder(cache.getHierarchyInfo(meta), handleInfo, null, children);
		}
		return children;
	}
	private function handleInfo(event:ResultEvent, children:Array):void
	{
		if (this.children != children)
			return;
		
		var infos:Array = event.result as Array;
		infos.forEach(function(obj:Object, index:int, a:Array):void {
			var node:EntityNode = new EntityNode(source.entityCache);
			node.id = EntityHierarchyInfo.getEntityIdFromResult(obj);
			children[index] = node;
			getCallbackCollection(source).triggerCallbacks();
		});
	}
	public function addChildAt(newChild:IWeaveTreeNode, index:int):Boolean { throw new Error("Not implemented"); }
	public function removeChild(child:IWeaveTreeNode):Boolean { throw new Error("Not implemented"); }
}
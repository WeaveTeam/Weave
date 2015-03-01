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
	import mx.utils.ObjectUtil;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.getCallbackCollection;
	import weave.api.registerLinkableChild;
	import weave.compiler.Compiler;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.ProxyColumn;
	
	public class CKANDataSource extends AbstractDataSource implements IDataSource_Service
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, CKANDataSource, "CKAN server");
		
		public function CKANDataSource()
		{
		}

		public const url:LinkableString = registerLinkableChild(this, new LinkableString());
		public const apiVersion:LinkableNumber = registerLinkableChild(this, new LinkableNumber(3, validateApiVersion));
		public const useHttpPost:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const showPackages:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const showGroups:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const showTags:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		public const useDataStore:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		private function validateApiVersion(value:Number):Boolean { return [1, 2, 3].indexOf(value) >= 0; }
		
		/**
		 * This gets called when callbacks are triggered.
		 */		
		override protected function initialize():void
		{
			// TODO handle url change

			super.initialize();
		}
		
		override public function refreshHierarchy():void
		{
			getCallbackCollection(this).delayCallbacks();
			for (var url:String in _dataSourceCache)
			{
				var ds:IDataSource = _dataSourceCache[url];
				ds.refreshHierarchy();
			}
			super.refreshHierarchy();
			getCallbackCollection(this).resumeCallbacks();
		}
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!(_rootNode is CKANAction))
				_rootNode = new CKANAction(this);
			return _rootNode;
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			var ds:IDataSource = getChildDataSource(metadata);
			if (!ds)
				return null;
			
			var node:CKANAction;
			if (metadata[PARAMS_CKAN_FORMAT] == DATASTORE_FORMAT)
			{
				node = new CKANAction(this);
				node.action = CKANAction.GET_COLUMN;
				node.params = {};
				node.params[PARAMS_CKAN_ID] = metadata[PARAMS_CKAN_ID];
				node.params[PARAMS_CKAN_URL] = metadata[PARAMS_CKAN_URL];
				node.params[PARAMS_CKAN_FORMAT] = metadata[PARAMS_CKAN_FORMAT];
				node.params[PARAMS_CKAN_FIELD] = metadata[PARAMS_CKAN_FIELD];
				return node;
			}
			
			var search:Object = ObjectUtil.copy(metadata);
			delete search[PARAMS_CKAN_ID];
			delete search[PARAMS_CKAN_URL];
			delete search[PARAMS_CKAN_FORMAT];
			
			var internalNode:IWeaveTreeNode = ds.findHierarchyNode(search);
			if (!internalNode)
				return null;
			
			node = new CKANAction(this);
			node.action = CKANAction.GET_COLUMN;
			node.params = {};
			node.params[PARAMS_CKAN_ID] = metadata[PARAMS_CKAN_ID];
			node.params[PARAMS_CKAN_URL] = metadata[PARAMS_CKAN_URL];
			node.params[PARAMS_CKAN_FORMAT] = metadata[PARAMS_CKAN_FORMAT];
			node.internalNode = internalNode
			return node;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var metadata:Object = proxyColumn.getProxyMetadata();
			var dataSource:IDataSource = getChildDataSource(metadata);
			if (dataSource)
			{
				if (metadata[PARAMS_CKAN_FORMAT] == DATASTORE_FORMAT)
					metadata = metadata[PARAMS_CKAN_FIELD];
				proxyColumn.setInternalColumn(dataSource.getAttributeColumn(metadata));
			}
			else
				proxyColumn.dataUnavailable();
		}
		
		public static const PARAMS_CKAN_ID:String = 'ckan_id';
		public static const PARAMS_CKAN_URL:String = 'ckan_url';
		public static const PARAMS_CKAN_FORMAT:String = 'ckan_format';
		public static const PARAMS_CKAN_FIELD:String = 'ckan_field';
		public static const DATASTORE_FORMAT:String = 'ckan_datastore';
		
		/**
		 * @private
		 */
		public function getChildDataSource(params:Object):IDataSource
		{
			var url:String = params[PARAMS_CKAN_URL];
			if (!url)
				return null;
			var dataSource:IDataSource = _dataSourceCache[url];
			if (!dataSource)
			{
				var format:String = String(params[PARAMS_CKAN_FORMAT]).toLowerCase();
				if (format == 'csv')
				{
					var csv:CSVDataSource = new CSVDataSource();
					csv.url.value = url;
					csv.keyType.value = url;
					dataSource = csv;
				}
				if (format == 'xls')
				{
					var xls:XLSDataSource = new XLSDataSource();
					xls.url.value = url;
					xls.keyType.value = url;
					dataSource = xls;
				}
				if (format == 'wfs')
				{
					var wfs:WFSDataSource = new WFSDataSource();
					wfs.url.value = url;
					dataSource = wfs;
				}
				if (format == DATASTORE_FORMAT)
				{
					var datastore:CSVDataSource = new CSVDataSource();
					var node:CKANAction = new CKANAction(this);
					node.action = CKANAction.DATASTORE_SEARCH;
					node.params = {"resource_id": params[PARAMS_CKAN_ID]};
					node.resultHandler = function(result:Object):void {
						datastore.metadata.setSessionState(
							result['fields'].map(function(field:Object, i:*, a:*):Object {
								var type:String = field['type'];
								if (type == 'numeric' || type == 'int4' || type == 'int' || type == 'float' || type == 'double')
									type = DataType.NUMBER;
								if (type == 'text')
									type = DataType.STRING;
								if (type == 'timestamp')
									type = DataType.DATE;
								var meta:Object = {};
								meta[ColumnMetadata.DATA_TYPE] = type;
								meta[ColumnMetadata.TITLE] = field['id'];
								meta[CSVDataSource.METADATA_COLUMN_NAME] = field['id'];
								return meta;
							})
						);
						var columnOrder:Array = result['fields'].map(function(field:Object, i:*, a:*):String { return field['id']; });
						var rows:Array = WeaveAPI.CSVParser.convertRecordsToRows(result['records'], columnOrder, true);
						datastore.csvData.setSessionState(rows);
					};
					node.result; // will cause resultHandler to be called later
					dataSource = datastore;
				}
			}
			// cache now if not cached
			if (dataSource && !_dataSourceCache[url])
				_dataSourceCache[url] = registerLinkableChild(this, dataSource);
			return dataSource;
		}
		
		/**
		 * url -> IDataSource
		 */
		private var _dataSourceCache:Object = {};
	}
}

import flash.events.Event;
import flash.external.ExternalInterface;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;

import mx.rpc.events.FaultEvent;
import mx.rpc.events.ResultEvent;
import mx.utils.ObjectUtil;
import mx.utils.URLUtil;

import weave.api.data.IColumnReference;
import weave.api.data.IDataSource;
import weave.api.data.IExternalLink;
import weave.api.data.IWeaveTreeNode;
import weave.api.data.IWeaveTreeNodeWithPathFinding;
import weave.api.detectLinkableObjectChange;
import weave.api.reportError;
import weave.compiler.Compiler;
import weave.compiler.StandardLib;
import weave.core.ClassUtils;
import weave.data.DataSources.CKANDataSource;
import weave.data.DataSources.CSVDataSource;
import weave.services.URLRequestUtils;
import weave.services.addAsyncResponder;
import weave.utils.VectorUtils;

internal class CKANAction implements IWeaveTreeNode, IColumnReference, IWeaveTreeNodeWithPathFinding
{
	public static const PACKAGE_LIST:String = 'package_list';
	public static const PACKAGE_SHOW:String = 'package_show';
	public static const GROUP_LIST:String = 'group_list';
	public static const GROUP_SHOW:String = 'group_show';
	public static const GROUP_PACKAGE_SHOW:String = 'group_package_show';
	public static const TAG_LIST:String = 'tag_list';
	public static const TAG_SHOW:String = 'tag_show';
	public static const DATASTORE_SEARCH:String = 'datastore_search';
	
	public static const GET_DATASOURCE:String = 'get_datasource';
	public static const GET_COLUMN:String = 'get_column';
	public static const NO_ACTION:String = 'no_action';
	
	private var source:CKANDataSource;
	/**
	 * The metadata associated with the node (includes more than just request params)
	 */
	public var metadata:Object;
	/**
	 * The CKAN API action associated with this node
	 */
	public var action:String;
	/**
	 * The CKAN API parameters for this action
	 */
	public var params:Object;

	public var internalNode:IWeaveTreeNode;
	
	private var _result:Object = {};
	
	public function CKANAction(source:CKANDataSource)
	{
		this.source = source;
	}
	
	/**
	 * The result received from the RPC
	 */
	public function get result():Object
	{
		if (detectLinkableObjectChange(this, source.url, source.apiVersion, source.useHttpPost))
		{
			if ([PACKAGE_LIST, PACKAGE_SHOW, GROUP_LIST, GROUP_SHOW, GROUP_PACKAGE_SHOW, TAG_LIST, TAG_SHOW, DATASTORE_SEARCH].indexOf(action) >= 0)
			{
				// make CKAN API request
				_result = {};
				addAsyncResponder(
					WeaveAPI.URLRequestUtils.getURL(source, getURLRequest(), URLRequestUtils.DATA_FORMAT_TEXT),
					handleResponse,
					handleResponse,
					_result
				);
			}
		}
		return _result || {};
	}
	
	/**
	 * This function will be passed the result when it is downloaded.
	 */
	public var resultHandler:Function = null;
	
	private function get apiVersion3():Boolean
	{
		return source.apiVersion.value == 3;
	}
	private function getURLRequest():URLRequest
	{
		// get base url
		var url:String = source.url.value || '';
		var i:int = url.lastIndexOf('/api');
		if (i >= 0)
			url = url.substr(0, i);
		if (url.charAt(url.length - 1) != '/')
			url += '/';
		
		// append api command to url
		var request:URLRequest;
		if (apiVersion3)
		{
			url = URLUtil.getFullURL(url, "api/3/action/" + action);
			request = new URLRequest(url);
			if (params)
			{
				if (source.useHttpPost.value)
				{
					request.method = URLRequestMethod.POST;
					request.requestHeaders = [new URLRequestHeader("Content-Type", "application/json; charset=utf-8")];
					request.data = stringifyJSON(params);
				}
				else
				{
					request.data = new URLVariables();
					for (var key:String in params)
						request.data[key] = params[key];
				}
			}
		}
		else
		{
			var cmd:String = 'api/' + source.apiVersion.value + '/rest/' + action.split('_')[0];
			if (params && params.hasOwnProperty('id'))
				cmd += '/' + params['id'];
			url = URLUtil.getFullURL(url, cmd);
			request = new URLRequest(url);
		}
		return request;
	}
	private function handleResponse(event:Event, result:Object):void
	{
		// ignore old results
		if (_result != result)
			return;
		
		var response:Object;
		if (event is ResultEvent)
		{
			response = (event as ResultEvent).result;
		}
		else
		{
			response = (event as FaultEvent).fault.content;
			if (!response)
			{
				reportError(event);
				return;
			}
		}
		
		response = parseJSON(response as String);
		if (apiVersion3 && response && response.hasOwnProperty('success') && response['success'])
		{
			_result = response['result'];
		}
		else if (!apiVersion3 && response)
		{
			_result = response;
		}
		else
		{
			var error:Object = response && response.hasOwnProperty('error') ? response['error'] : response;
			reportError("CKAN action failed: " + this.toString() + "; error=" + Compiler.stringify(error));
		}
		
		// hack to support DKAN
		if (action == PACKAGE_SHOW && _result is Array && _result.length == 1)
			_result = _result[0];
		
		if (resultHandler != null)
			resultHandler(_result);
	}
	private function stringifyJSON(obj:Object):Object
	{
		var JSON:Object = ClassUtils.getClassDefinition('JSON');
		if (JSON)
			return JSON.stringify(obj);
		else
			return Compiler.stringify(obj);
	}
	private function parseJSON(json:String):Object
	{
		try
		{
			var JSON:Object = ClassUtils.getClassDefinition('JSON');
			if (JSON)
				return JSON.parse(json);
			else if (ExternalInterface.available)
				return ExternalInterface.call('JSON.parse', json);
			
			reportError("No JSON parser available");
		}
		catch (e:Error)
		{
			reportError("Unable to parse JSON result");
			trace(json);
		}
		return null;
	}
	
	public function equals(other:IWeaveTreeNode):Boolean
	{
		var that:CKANAction = other as CKANAction;
		if (!that)
			return false;
		
		if (this.internalNode && that.internalNode)
			return this.source && that.source
				&& this.internalNode.equals(that.internalNode);
		
		return !this.internalNode == !that.internalNode
			&& this.source == that.source
			&& this.action == that.action
			&& ObjectUtil.compare(this.params, that.params) == 0;
	}
	public function getLabel():String
	{
		if (internalNode)
			return internalNode.getLabel();
		
		if (!action)
			return WeaveAPI.globalHashMap.getName(source);
		
		if (action == PACKAGE_LIST)
			return lang("Packages");
		if (action == GROUP_LIST)
			return lang("Groups");
		if (action == TAG_LIST)
			return lang("Tags");
		
		if (action == PACKAGE_SHOW || action == GROUP_SHOW || action == GROUP_PACKAGE_SHOW || action == TAG_SHOW)
			return metadata['display_name']
				|| metadata['name']
				|| metadata['title']
				|| metadata['description']
				|| metadata['url']
				|| (result is String
					? result as String
					: (result['title'] || result['display_name'] || result['name']))
				|| params['id'];
		
		if (action == GET_DATASOURCE || action == DATASTORE_SEARCH)
		{
			var str:String = metadata['name']
				|| metadata['title']
				|| metadata['description']
				|| metadata['url']
				|| metadata['id'];
			
			// hack to support DKAN
			if (!metadata['format'] && metadata['mimetype'] == 'text/csv')
				metadata['format'] = 'csv';
			
			// also display the format
			if (metadata['format'])
				str = StandardLib.substitute("{0} ({1})", str, metadata['format']);
			
			return str;
		}
		
		if (action == GET_COLUMN)
			return params[CKANDataSource.PARAMS_CKAN_FIELD];
		
		return this.toString();
	}
	public function isBranch():Boolean
	{
		if (internalNode)
			return internalNode.isBranch();
		
		if (action == GET_DATASOURCE || action == DATASTORE_SEARCH)
			return true;
		
		return action != NO_ACTION && action != GET_COLUMN;
	}
	public function hasChildBranches():Boolean
	{
		if (internalNode)
			return internalNode.hasChildBranches();
		
		if (action == PACKAGE_SHOW || action == GROUP_PACKAGE_SHOW)
			return getChildren().length > 0;
		if (action == GROUP_SHOW || action == TAG_SHOW)
		{
			var metapkg:Object = metadata['packages'];
			if (metapkg is Number)
				return metapkg > 0;
			if (metapkg is Array)
				return (metapkg as Array).length > 0;
			return getChildren().length > 0;
		}
		
		return action != GET_DATASOURCE && action != DATASTORE_SEARCH && action != NO_ACTION;
	}
	
	private var _childNodes:Array = [];
	/**
	 * @param input The input metadata items for generating child nodes
	 * @param childAction The action property of the child nodes
	 * @param updater A function like function(node:CKANAction, item:Object):void which receives the child node and its corresponding input metadata item.
	 * @return The updated _childNodes Array. 
	 */
	private function updateChildren(input:Array, updater:Function = null, nodeType:Class = null):Array
	{
		if (!nodeType)
			nodeType = CKANAction;
		var outputIndex:int = 0;
		for each (var item:Object in input)
		{
			var node:CKANAction = _childNodes[outputIndex];
			if (!node || Object(node).constructor != nodeType)
				_childNodes[outputIndex] = node = new nodeType(source);
			
			var oldAction:String = node.action;
			var oldParams:Object = node.params;
			
			updater(node, item);
			
			// if something changed, clear the previous result
			if (oldAction != node.action || ObjectUtil.compare(oldParams, node.params))
				node._result = null;
			
			outputIndex++;
		}
		_childNodes.length = outputIndex;
		return _childNodes;
	}
	
	public function getChildren():Array
	{
		if (internalNode)
			return internalNode.getChildren();
		
		if (!action)
		{
			var list:Array = [];
			if (source.showPackages.value)
				list.push([PACKAGE_LIST, null]);
			if (source.showGroups.value)
				list.push([GROUP_LIST, {"all_fields": true}]);
			if (source.showTags.value)
				list.push([TAG_LIST, {"all_fields": true}]);
			return updateChildren(list, function(node:CKANAction, actionAndParams:Array):void {
				node.action = actionAndParams[0];
				node.params = actionAndParams[1];
				node.metadata = null;
			});
		}
		
		// handle all situations where result is just an array of IDs
		if (StandardLib.getArrayType(result as Array) == String)
			return updateChildren(result as Array, function(node:CKANAction, id:String):void {
				if (action == PACKAGE_LIST || action == TAG_SHOW)
					node.action = PACKAGE_SHOW;
				if (action == GROUP_LIST)
					node.action = GROUP_PACKAGE_SHOW;
				if (action == TAG_LIST)
					node.action = TAG_SHOW;
				node.metadata = node.params = {"id": id};
			});
		
		if (action == GROUP_LIST || action == TAG_LIST)
			return updateChildren(result as Array, function(node:CKANAction, meta:Object):void {
				if (action == GROUP_LIST)
					node.action = GROUP_PACKAGE_SHOW;
				if (action == TAG_LIST)
					node.action = TAG_SHOW;
				node.metadata = meta;
				
				// hack to support DKAN
				if (!meta['id'] && meta['uuid'])
					meta['id'] = meta['uuid'];
				
				node.params = {"id": meta['id']};
			});
		
		if (result && (action == GROUP_SHOW || action == GROUP_PACKAGE_SHOW || action == TAG_SHOW))
			return updateChildren(result as Array || result['packages'], function(node:CKANAction, pkg:Object):void {
				if (pkg is String)
					pkg = {"id": pkg};
				node.action = PACKAGE_SHOW;
				node.metadata = pkg;
				node.params = {"id": pkg['id']};
			});
		
		if (action == PACKAGE_SHOW && result.hasOwnProperty('resources'))
		{
			return updateChildren(result['resources'], function(node:CKANAction, resource:Object):void {
				if (source.useDataStore.value && resource['datastore_active'])
				{
					node.action = DATASTORE_SEARCH;
					node.metadata = resource;
					node.params = {"resource_id": resource['id'], "limit": 0};
				}
				else
				{
					node.action = GET_DATASOURCE;
					node.metadata = resource;
					node.params = {};
					node.params[CKANDataSource.PARAMS_CKAN_ID] = resource['id'];
					node.params[CKANDataSource.PARAMS_CKAN_URL] = resource['url'];
					node.params[CKANDataSource.PARAMS_CKAN_FORMAT] = resource['format'];
				}
			});
		}
		
		if (action == DATASTORE_SEARCH)
		{
			return updateChildren(result['fields'], function(node:CKANAction, field:Object):void {
				node.action = GET_COLUMN;
				node.metadata = field;
				node.params = {};
				node.params[CKANDataSource.PARAMS_CKAN_ID] = metadata['id'];
				node.params[CKANDataSource.PARAMS_CKAN_URL] = CKANDataSource.DATASTORE_FORMAT + "://" + metadata['id'];
				node.params[CKANDataSource.PARAMS_CKAN_FORMAT] = CKANDataSource.DATASTORE_FORMAT;
				node.params[CKANDataSource.PARAMS_CKAN_FIELD] = field['id'];
			});
		}
		
		if (action == GET_DATASOURCE)
		{
			var ds:IDataSource = source.getChildDataSource(params);
			if (ds)
			{
				var root:IWeaveTreeNode = ds.getHierarchyRoot();
				return updateChildren(root.getChildren(), function(node:CKANAction, otherNode:IWeaveTreeNode):void {
					node.action = GET_COLUMN;
					node.internalNode = otherNode;
					node.params = params; // copy params from parent
				});
			}
			else
			{
				var keys:Array = VectorUtils.getKeys(metadata);
				keys = keys.filter(function(key:String, i:*, a:*):Boolean {
					return metadata[key] != null && metadata[key] != '';
				});
				StandardLib.sort(keys, keyCompare);
				return updateChildren(keys, function(node:MetadataNode, key:String):void {
					node.metadata = metadata;
					node.params = key;
				}, MetadataNode);
			}
		}
		
		_childNodes.length = 0;
		return _childNodes;
	}
	
	private const _KEY_ORDER:Array = [
		'title', 'display_name', 'name', 'description',
		'format', 'resource_type', 'mimetype',
		'url',
		'url_type',
		'created', 'publish-date',
		'last_modified', 'revision_timestamp'
	];
	private function keyCompare(a:Object, b:Object):int
	{
		var order:Array = _KEY_ORDER;
		var ia:int = order.indexOf(a);
		var ib:int = order.indexOf(b);
		if (ia >= 0 && ib >= 0)
			return ObjectUtil.numericCompare(ia, ib);
		if (ia >= 0)
			return -1;
		if (ib >= 0)
			return 1;
		
		return ObjectUtil.stringCompare(a as String, b as String, true);
	}

	public function getDataSource():IDataSource
	{
		return source;
	}
	public function getColumnMetadata():Object
	{
		if (internalNode is IColumnReference)
		{
			var meta:Object = (internalNode as IColumnReference).getColumnMetadata();
			meta[CKANDataSource.PARAMS_CKAN_ID] = params[CKANDataSource.PARAMS_CKAN_ID];
			meta[CKANDataSource.PARAMS_CKAN_FORMAT] = params[CKANDataSource.PARAMS_CKAN_FORMAT];
			meta[CKANDataSource.PARAMS_CKAN_URL] = params[CKANDataSource.PARAMS_CKAN_URL];
			return meta;
		}
		if (action == GET_COLUMN)
			return ObjectUtil.copy(params);
		return null;
	}
	
	public function findPathToNode(descendant:IWeaveTreeNode):Array
	{
		if (!descendant)
			return null;
		if (equals(descendant))
			return [this];
		
		// search cached children only
		for each (var child:CKANAction in _childNodes)
		{
			var path:Array = child.findPathToNode(descendant);
			if (path)
			{
				path.unshift(this);
				return path;
			}
		}
		return null;
	}
	
	public function toString():String
	{
		if (!action && !params)
			return Compiler.stringify(metadata);
		return Compiler.stringify({action: action, params: params});
	}
}

/**
 * No CKAN action is associated with this type of node.
 * Uses the 'params' property as a key for the 'metadata' object.
 */
internal class MetadataNode extends CKANAction implements IExternalLink
{
	public function MetadataNode(source:CKANDataSource)
	{
		super(source);
		action = NO_ACTION;
	}
	
	public function getURL():String
	{
		return params == 'url' ? metadata[params] : null;
	}
	
	override public function toString():String
	{
		return lang("{0}: {1}", params, Compiler.stringify(metadata[params]));
	}
}

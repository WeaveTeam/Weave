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
	import weavejs.WeaveAPI;
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IDataSource_Service;
	import weavejs.api.data.IWeaveTreeNode;
	import weavejs.core.LinkableBoolean;
	import weavejs.core.LinkableNumber;
	import weavejs.core.LinkableString;
	import weavejs.data.column.ProxyColumn;
	import weavejs.util.JS;
	
	public class CKANDataSource extends AbstractDataSource implements IDataSource_Service
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, CKANDataSource, "CKAN server");
		
		public function CKANDataSource()
		{
		}

		public const url:LinkableString = Weave.linkableChild(this, new LinkableString());
		public const apiVersion:LinkableNumber = Weave.linkableChild(this, new LinkableNumber(3, validateApiVersion));
		public const useHttpPost:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(false));
		public const showPackages:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true));
		public const showGroups:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true));
		public const showTags:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true));
		public const useDataStore:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true));
		
		private function validateApiVersion(value:Number):Boolean { return [1, 2, 3].indexOf(value) >= 0; }
		
		/**
		 * This gets called when callbacks are triggered.
		 */		
		override protected function initialize(forceRefresh:Boolean = false):void
		{
			// TODO handle url change

			super.initialize(forceRefresh);
		}
		
		override protected function refreshHierarchy():void
		{
			Weave.getCallbacks(this).delayCallbacks();
			for (var url:String in _dataSourceCache)
			{
				var ds:IDataSource = _dataSourceCache[url];
				ds.hierarchyRefresh.triggerCallbacks();
			}
			super.refreshHierarchy();
			Weave.getCallbacks(this).resumeCallbacks();
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
			
			var search:Object = JS.copyObject(metadata);
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
		
		public function getBaseURL():String
		{
			var baseurl:String = this.url.value || '';
			var i:int = baseurl.lastIndexOf('/api');
			if (i >= 0)
				baseurl = baseurl.substr(0, i);
			if (baseurl.charAt(baseurl.length - 1) != '/')
				baseurl += '/';
			return baseurl;
		}
		public function getFullURL(relativeURL:String):String
		{
			return getBaseURL() + relativeURL;
		}
		
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
//				if (format == 'xls')
//				{
//					var xls:XLSDataSource = new XLSDataSource();
//					xls.url.value = url;
//					xls.keyType.value = url;
//					dataSource = xls;
//				}
//				if (format == 'wfs')
//				{
//					var wfs:WFSDataSource = new WFSDataSource();
//					wfs.url.value = url;
//					dataSource = wfs;
//				}
				if (format == DATASTORE_FORMAT)
				{
					var datastore:CSVDataSource = new CSVDataSource();
					datastore.url.value = getFullURL('datastore/dump/' + params[PARAMS_CKAN_ID]);
					var node:CKANAction = new CKANAction(this);
					node.action = CKANAction.DATASTORE_SEARCH;
					node.params = {"resource_id": params[PARAMS_CKAN_ID], "limit": 1};
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
					};
					node.result; // will cause resultHandler to be called later
					dataSource = datastore;
				}
			}
			// cache now if not cached
			if (dataSource && !_dataSourceCache[url])
				_dataSourceCache[url] = Weave.linkableChild(this, dataSource);
			return dataSource;
		}
		
		/**
		 * url -> IDataSource
		 */
		private var _dataSourceCache:Object = {};
	}
}

import flash.net.URLRequestMethod;

import weavejs.WeaveAPI;
import weavejs.api.data.IColumnReference;
import weavejs.api.data.IDataSource;
import weavejs.api.data.IExternalLink;
import weavejs.api.data.IWeaveTreeNode;
import weavejs.api.data.IWeaveTreeNodeWithPathFinding;
import weavejs.data.source.CKANDataSource;
import weavejs.data.source.CSVDataSource;
import weavejs.net.ResponseType;
import weavejs.net.Servlet;
import weavejs.net.URLRequest;
import weavejs.util.JS;
import weavejs.util.StandardLib;

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
		if (Weave.detectChange(this, source.url, source.apiVersion, source.useHttpPost))
		{
			if ([PACKAGE_LIST, PACKAGE_SHOW, GROUP_LIST, GROUP_SHOW, GROUP_PACKAGE_SHOW, TAG_LIST, TAG_SHOW, DATASTORE_SEARCH].indexOf(action) >= 0)
			{
				// make CKAN API request
				_result = {};
				var handler:Function = handleResponse.bind(this, _result);
				WeaveAPI.URLRequestUtils.request(source, getURLRequest()).then(handler, handler);
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
		// append api command to url
		var request:URLRequest;
		if (apiVersion3)
		{
			request = new URLRequest(source.getFullURL("api/3/action/" + action));
			if (params)
			{
				if (source.useHttpPost.value)
				{
					request.method = URLRequestMethod.POST;
					request.requestHeaders = {"Content-Type": "application/json; charset=utf-8"};
					request.data = JSON.stringify(params);
				}
				else
				{
					request.url = Servlet.buildUrlWithParams(request.url, params);
				}
			}
		}
		else
		{
			var cmd:String = 'api/' + source.apiVersion.value + '/rest/' + action.split('_')[0];
			if (params && params.hasOwnProperty('id'))
				cmd += '/' + params['id'];
			request = new URLRequest(source.getFullURL(cmd));
		}
		request.responseType = ResponseType.JSON;
		
		return request;
	}
	private function handleResponse(placeholder:Object, response:Object):void
	{
		// ignore old results
		if (_result != placeholder)
			return;
		
		//response = JSON.parse(response as String);
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
			JS.error("CKAN action failed", this, error);
		}
		
		// hack to support DKAN
		if (action == PACKAGE_SHOW && _result is Array && _result.length == 1)
			_result = _result[0];
		
		if (resultHandler != null)
			resultHandler(_result);
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
			&& StandardLib.compare(this.params, that.params) == 0;
	}
	public function getLabel():String
	{
		if (internalNode)
			return internalNode.getLabel();
		
		if (!action)
			return source.getLabel();
		
		if (action == PACKAGE_LIST)
			return Weave.lang("Packages");
		if (action == GROUP_LIST)
			return Weave.lang("Groups");
		if (action == TAG_LIST)
			return Weave.lang("Tags");
		
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
			if (oldAction != node.action || StandardLib.compare(oldParams, node.params))
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
					node.params = {"resource_id": resource['id'], "limit": 1};
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
				var keys:Array = JS.objectKeys(metadata);
				keys = keys.filter(function(key:String, i:*, a:*):Boolean {
					return metadata[key] != null && metadata[key] != '';
				});
				keys.sort(keyCompare);
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
			return StandardLib.numericCompare(ia, ib);
		if (ia >= 0)
			return -1;
		if (ib >= 0)
			return 1;
		
		return StandardLib.stringCompare(a as String, b as String, true);
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
			return JS.copyObject(params);
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
			return Weave.stringify(metadata);
		return Weave.stringify({"action": action, "params": params});
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
		return Weave.lang("{0}: {1}", params, Weave.stringify(metadata[params]));
	}
}

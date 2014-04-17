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
	import weave.api.WeaveAPI;
	import weave.api.data.IDataSource;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.getCallbackCollection;
	import weave.api.registerLinkableChild;
	import weave.compiler.Compiler;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.ProxyColumn;
	
	/**
	 * 
	 * @author adufilie
	 */
	public class CKANDataSource extends AbstractDataSource
	{
		WeaveAPI.registerImplementation(IDataSource, CKANDataSource, "CKAN site");

		public function CKANDataSource()
		{
			(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, _attributeHierarchy);
		}

		public const url:LinkableString = registerLinkableChild(this, new LinkableString());
		
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
			
			var internalNode:IWeaveTreeNode = ds.findHierarchyNode(metadata);
			if (!internalNode)
				return null;
			
			var node:CKANAction = new CKANAction(this);
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
				proxyColumn.setInternalColumn(dataSource.getAttributeColumn(metadata));
			else
				proxyColumn.setInternalColumn(ProxyColumn.undefinedColumn);
		}
		
		public static const PARAMS_CKAN_ID:String = 'ckan_id';
		public static const PARAMS_CKAN_URL:String = 'ckan_url';
		public static const PARAMS_CKAN_FORMAT:String = 'ckan_format';
		
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

import weave.api.WeaveAPI;
import weave.api.data.IColumnReference;
import weave.api.data.IDataSource;
import weave.api.data.IWeaveTreeNode;
import weave.api.data.IWeaveTreeNodeWithPathFinding;
import weave.api.detectLinkableObjectChange;
import weave.api.reportError;
import weave.compiler.Compiler;
import weave.compiler.StandardLib;
import weave.core.ClassUtils;
import weave.data.DataSources.CKANDataSource;
import weave.services.URLRequestUtils;

internal class CKANAction implements IWeaveTreeNode, IColumnReference, IWeaveTreeNodeWithPathFinding
{
	public static const PACKAGE_LIST:String = 'package_list';
	public static const PACKAGE_SHOW:String = 'package_show';
	public static const GROUP_LIST:String = 'group_list';
	public static const GROUP_SHOW:String = 'group_show';
	public static const TAG_LIST:String = 'tag_list';
	public static const TAG_SHOW:String = 'tag_show';
	
	public static const GET_DATASOURCE:String = 'get_datasource';
	public static const GET_COLUMN:String = 'get_column';
	
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
	 * The result received from the action RPC
	 */
	public function get result():Object
	{
		if (detectLinkableObjectChange(this, source.url))
		{
			if ([PACKAGE_LIST, PACKAGE_SHOW, GROUP_LIST, GROUP_SHOW, TAG_LIST, TAG_SHOW].indexOf(action) >= 0)
			{
				// make CKAN API request
				_result = {};
				var url:String = source.url.value || '';
				var i:int = url.lastIndexOf('/api');
				if (i >= 0)
					url = url.substr(0, i);
				url = URLUtil.getFullURL(url, "/api/3/action/" + action);
				var request:URLRequest = new URLRequest(url);
				if (params)
				{
					request.data = new URLVariables();
					for (var key:String in params)
						request.data[key] = params[key];

//					request.method = URLRequestMethod.POST;
//					request.requestHeaders = [new URLRequestHeader("Content-Type", "application/json; charset=utf-8")];
//					//request.requestHeaders = [new URLRequestHeader("Content-Type", "application/x-www-form-urlencoded")];
//					request.data = Compiler.stringify(params);
				}
				WeaveAPI.URLRequestUtils.getURL(source, request, handleResponse, handleResponse, _result, URLRequestUtils.DATA_FORMAT_TEXT);
			}
		}
		return _result || {};
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
		if (response && response.hasOwnProperty('success') && response['success'])
		{
			_result = response['result'];
		}
		else
		{
			var error:Object = response.hasOwnProperty('error') ? response['error'] : response;
			reportError("CKAN action failed: " + this.toString() + "; error=" + Compiler.stringify(error));
		}
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
		return {};
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
			return lang("Datasets");
		if (action == GROUP_LIST)
			return lang("Groups");
		if (action == TAG_LIST)
			return lang("Tags");
		
		if (action == PACKAGE_SHOW || action == GROUP_SHOW || action == TAG_SHOW)
			return metadata['name'] || metadata['description'] || metadata['url']
				|| result['title'] || result['display_name'] || result['name']
				|| params['id'];
		
		if (action == GET_DATASOURCE)
		{
			var str:String = metadata['name'] || metadata['description'] || metadata['url'] || metadata['id'];
			
			// if we don't support this resource format, also display the format
			if (!isBranch())
				str = StandardLib.substitute("{0} ({1})", str, metadata['format']);
			
			return str;
		}
		
		return this.toString();
	}
	public function isBranch():Boolean
	{
		if (internalNode)
			return internalNode.isBranch();
		
		if (action == GET_DATASOURCE)
		{
			var format:String = String(metadata['format']).toLowerCase();
			return format == 'csv'
				|| format == 'xls'
				|| format == 'wfs';
		}
		
		return true;
	}
	public function hasChildBranches():Boolean
	{
		if (internalNode)
			return internalNode.hasChildBranches();
		
		return action != GET_DATASOURCE;
	}
	
	private var _childNodes:Array = [];
	/**
	 * @param input The input metadata items for generating child nodes
	 * @param childAction The action property of the child nodes
	 * @param updater A function like function(node:CKANAction, item:Object):void which receives the child node and its corresponding input metadata item.
	 * @return The updated _childNodes Array. 
	 */
	private function updateChildren(input:Array, updater:Function = null):Array
	{
		var outputIndex:int = 0;
		for each (var item:Object in input)
		{
			var node:CKANAction = _childNodes[outputIndex];
			if (!node)
				_childNodes[outputIndex] = node = new CKANAction(source);
			
			updater(node, item);
			
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
			return updateChildren([PACKAGE_LIST, GROUP_LIST, TAG_LIST], function(node:CKANAction, action:String):void {
				node.action = action;
			});
		
		if (action == PACKAGE_LIST || action == GROUP_LIST || action == TAG_LIST)
			return updateChildren(result as Array, function(node:CKANAction, id:String):void {
				node.action = StandardLib.replace(action, "_list", "_show");
				node.metadata = node.params = {"id": id};
			});
		
		if (action == GROUP_SHOW || action == TAG_SHOW)
			return updateChildren(result['packages'], function(node:CKANAction, pkg:Object):void {
				node.action = PACKAGE_SHOW;
				node.metadata = pkg;
				node.params = {"id": pkg.id};
			});
		
		if (action == PACKAGE_SHOW)
		{
			return updateChildren(result['resources'], function(node:CKANAction, resource:Object):void {
				node.action = GET_DATASOURCE;
				node.metadata = resource;
				node.params = {};
				node.params[CKANDataSource.PARAMS_CKAN_ID] = resource['id'];
				node.params[CKANDataSource.PARAMS_CKAN_URL] = resource['url'];
				node.params[CKANDataSource.PARAMS_CKAN_FORMAT] = resource['format'];
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
		}
		
		_childNodes.length = 0;
		return _childNodes;
	}
	
	public function addChildAt(newChild:IWeaveTreeNode, index:int):Boolean { return false; }
	public function removeChild(child:IWeaveTreeNode):Boolean { return false; }
	
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

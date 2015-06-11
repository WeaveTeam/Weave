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
	import avmplus.getQualifiedClassName;
	
	import flash.utils.ByteArray;
	
	import flashx.textLayout.tlf_internal;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.getSessionState;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.setSessionState;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableFile;
	import weave.core.LinkableHashMap;
	import weave.core.LinkablePromise;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.services.AMF3Servlet;
	import weave.services.URLRequestUtils;
	import weave.services.addAsyncResponder;
	import weave.utils.ColumnUtils;
	import weave.utils.VectorUtils;
	
	public class WeaveAnalystDataSource extends AbstractDataSource implements IDataSource_Service
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, WeaveAnalystDataSource, "Weave Analyst");
		
		public static const SCRIPT_OUTPUT_NAME:String = 'scriptOutputName';
		private static const RESULT_DATA:String = "resultData";
		private static const COLUMN_NAMES:String = "columnNames";
		
		public function WeaveAnalystDataSource()
		{
			promise.depend(url, scriptName, inputs, hierarchyRefresh);
			if (!cacheFile)
			{
				cacheFileName = getQualifiedClassName(WeaveAnalystDataSource).split('::').join('.') + '.cache';
				// register static LinkableFile as a child of the globalHashMap so it will not be disposed when an instance of this data source is disposed.
				cacheFile = registerLinkableChild(WeaveAPI.globalHashMap, new LinkableFile(URLRequestUtils.LOCAL_FILE_URL_SCHEME + cacheFileName), parseCacheFile);
			}
			registerLinkableChild(this, cacheFile, runScript);
		}
		
		private static const CACHE_STATE:String = 'sessionState';
		private static const CACHE_OUTPUT_STATE:String = 'outputCSV';
		private static var cacheFileName:String;
		private static var cacheFile:LinkableFile = null;
		private static var cache:Object;
		private static function parseCacheFile():void
		{
			try
			{
				cache = cacheFile.result.readObject();
			}
			catch (e:Error)
			{
				// ignore error
			}
		}
		private static function saveCache(source:WeaveAnalystDataSource):void
		{
			var name:String = WeaveAPI.globalHashMap.getName(source);
			if (!cache)
				cache = {};
			cache[name] = {};
			cache[name][CACHE_STATE] = getSessionState(source);
			cache[name][CACHE_OUTPUT_STATE] = getSessionState(source.outputCSV);
			var bytes:ByteArray = new ByteArray();
			bytes.writeObject(cache);
			WeaveAPI.URLRequestUtils.saveLocalFile(cacheFileName, bytes);
		}
		
		public const url:LinkableString = registerLinkableChild(this, new LinkableString('/WeaveAnalystServices/ComputationalServlet'), handleURLChange);
		public const scriptName:LinkableString = newLinkableChild(this, LinkableString);
		public const inputs:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
		public const inputKeyFilter:LinkableDynamicObject = registerLinkableChild(this, new LinkableDynamicObject(IKeyFilter));
		
		private const promise:LinkablePromise = registerLinkableChild(this, new LinkablePromise(runScript, describePromise));
		private function describePromise():String { return lang("Running script {0}", scriptName.value); }
		private const outputCSV:CSVDataSource = newLinkableChild(this, CSVDataSource);
		private var _service:AMF3Servlet;
		
		override protected function initialize():void
		{
			super.initialize();
			promise.validate();
		}
		
		private function handleURLChange():void
		{
			if (_service && _service.servletURL == url.value)
				return;
			disposeObject(_service);
			_service = registerLinkableChild(this, new AMF3Servlet(url.value));
			hierarchyRefresh.triggerCallbacks();
		}
		
		private function runScript():void
		{
			// if callbacks are delayed, we assume that hierarchyRefresh will be explicitly triggered later.
			if (getCallbackCollection(this).callbacksAreDelayed)
				return;
			
			// read from cache if present
			var currentState:Object = getSessionState(this);
			var name:String = WeaveAPI.globalHashMap.getName(this);
			if (cache && cache[name])
			{
				if (WeaveAPI.SessionManager.computeDiff(currentState, cache[name][CACHE_STATE]) === undefined)
				{
					setSessionState(outputCSV, cache[name][CACHE_OUTPUT_STATE]);
					return;
				}
			}
			
			// force retrieval of referenced columns
			for each (var refCol:ReferencedColumn in getLinkableDescendants(inputs, ReferencedColumn))
				refCol.getInternalColumn();
			if (linkableObjectIsBusy(inputs))
				return;
			
			var keyType:String;
			var columnArray:Array;
			var simpleInputs:Object = {};
			var columnsByKeyType:Object = {}; // Object(keyType -> Array of IAttributeColumn)
			for each (var obj:ILinkableObject in inputs.getObjects())
			{
				var name:String = inputs.getName(obj);
				var column:IAttributeColumn = obj as IAttributeColumn;
				var hashMap:ILinkableHashMap = obj as ILinkableHashMap;
				if (column || hashMap)
				{
					var columnDescendants:Array = null;
					if (column)
						columnDescendants = [column];
					else if (hashMap)
						columnDescendants = getLinkableDescendants(hashMap, IAttributeColumn);
					
					for each (column in columnDescendants)
					{
						keyType = column.getMetadata(ColumnMetadata.KEY_TYPE);
						columnArray = columnsByKeyType[keyType] || (columnsByKeyType[keyType] = [])
						columnArray.push(column);
					}
				}
				else
				{
					simpleInputs[name] = getSessionState(obj);
				}
			}
			
			var columnData:Object = {}; // Object(keyType -> {keys: [], columns: Object(name -> Array) })
			for (keyType in columnsByKeyType)
			{
				var cols:Array = columnsByKeyType[keyType];
				var joined:Array = ColumnUtils.joinColumns(cols, null, true, inputKeyFilter.target);
				var keys:Array = VectorUtils.pluck(joined.shift() as Array, 'localName');
				var colMap:Object = {};
				for (var i:int = 0; i <  joined.length; i++)
					setChain(colMap, WeaveAPI.SessionManager.getPath(inputs, cols[i]), joined[i]);
				columnData[keyType] = {keys: keys, columns: colMap};
			}
			
			outputCSV.setCSVData(null);
			outputCSV.metadata.setSessionState(null);
			
			addAsyncResponder(
				_service.invokeAsyncMethod('runScriptWithInputs', [scriptName.value, simpleInputs, columnData]),
				handleScriptResult,
				handleScriptError,
				currentState
			);
		}
		
		private function setChain(root:Object, property_chain:Array, value:Object):*
		{
			property_chain = [].concat(property_chain); // makes a copy and converts a single string into an array
			var last_property:String = property_chain.pop();
			for each (var prop:String in property_chain)
				root = root[prop] || (root[prop] = {});
			// if value not given, return current value
			if (arguments.length == 2)
				return root[last_property];
			// set the value and return it
			return root[last_property] = value;
		};
		
		private function handleScriptResult(event:ResultEvent, sessionState:Object):void
		{
			// ignore outdated response
			if (WeaveAPI.SessionManager.computeDiff(sessionState, getSessionState(this)) !== undefined)
				return;
			
			var result:Object = event.result;
			var columnNames:Array = result[COLUMN_NAMES]; // array of strings
			var resultData:Array = result[RESULT_DATA]; // array of columns
			if (resultData)
			{
				var rows:Array = VectorUtils.transpose(resultData);
				rows.unshift(columnNames);
				outputCSV.setCSVData(rows);
			}
			else
				outputCSV.setCSVData(null);
			
			saveCache(this);
		}
		
		private function handleScriptError(event:FaultEvent, sessionState:Object):void
		{
			// ignore outdated response
			if (WeaveAPI.SessionManager.computeDiff(sessionState, getSessionState(this)) !== undefined)
				return;
			reportError(event);
		}
		
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			if (!_rootNode)
			{
				_rootNode = new ColumnTreeNode({
					label: WeaveAPI.globalHashMap.getName(this),
					dataSource: this,
					dependency: outputCSV,
					hasChildBranches: false,
					children: function(root:ColumnTreeNode):Array {
						var csvRoot:IWeaveTreeNode = outputCSV.getHierarchyRoot();
						return csvRoot.getChildren().map(function(csvNode:IColumnReference, ..._):IWeaveTreeNode {
							var meta:Object = csvNode.getColumnMetadata();
							meta[SCRIPT_OUTPUT_NAME] = meta[CSVDataSource.METADATA_COLUMN_NAME] || meta[CSVDataSource.METADATA_COLUMN_INDEX];
							return generateHierarchyNode(meta);
						});
					}
				});
			}
			return _rootNode;
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			
			return new ColumnTreeNode({
				dataSource: this,
				idFields: [SCRIPT_OUTPUT_NAME],
				data: metadata
			});
		}
		
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			var name:String = proxyColumn.getMetadata(SCRIPT_OUTPUT_NAME);
			var column:IAttributeColumn = outputCSV.getColumnById(name);
			if (column)
				proxyColumn.setInternalColumn(column);
			else
				proxyColumn.dataUnavailable();
		}
	}
}

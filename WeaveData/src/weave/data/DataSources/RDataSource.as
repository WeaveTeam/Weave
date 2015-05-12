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
	import flash.events.ErrorEvent;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.getSessionState;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.core.LinkableHashMap;
	import weave.core.LinkablePromise;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.services.AMF3Servlet;
	import weave.services.JsonCache;
	import weave.services.WeaveRServlet;
	import weave.services.addAsyncResponder;
	import weave.utils.ColumnUtils;
	import weave.utils.VectorUtils;
	
	public class RDataSource extends AbstractDataSource implements IDataSource_Service
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, RDataSource, "R Data Source");
		
		public static const SCRIPT_OUTPUT_NAME:String = 'scriptOutputName';
		private static const RESULT_DATA:String = "resultData";
		private static const COLUMN_NAMES:String = "columnNames";
		
		public function RDataSource()
		{
			promise.depend(url, scriptName, inputs, hierarchyRefresh);
		}
		
		public const url:LinkableString = registerLinkableChild(this, new LinkableString('/WeaveAnalystServices/ComputationalServlet'), handleURLChange);
		public const scriptName:LinkableString = newLinkableChild(this, LinkableString);
		public const inputs:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
		
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
			// force retrieval of referenced columns
			for each (var refCol:ReferencedColumn in getLinkableDescendants(inputs, ReferencedColumn))
				refCol.getInternalColumn();
			if (linkableObjectIsBusy(inputs))
				return;
			
			var keyType:String;
			var simpleInputs:Object = {};
			var columnsByKeyType:Object = {}; // Object(keyType -> Array of IAttributeColumn)
			for each (var obj:ILinkableObject in inputs.getObjects())
			{
				var name:String = inputs.getName(obj);
				var column:IAttributeColumn = obj as IAttributeColumn;
				if (column)
				{
					keyType = column.getMetadata(ColumnMetadata.KEY_TYPE);
					var columnArray:Array = columnsByKeyType[keyType] || (columnsByKeyType[keyType] = [])
					columnArray.push(column);
				}
				else
				{
					simpleInputs[name] = getSessionState(inputs.getObject(name));
				}
			}
			
			var columnData:Object = {}; // Object(keyType -> {keys: [], columns: Object(name -> Array) })
			for (keyType in columnsByKeyType)
			{
				var cols:Array = columnsByKeyType[keyType];
				var joined:Array = ColumnUtils.joinColumns(cols, null, true);
				var keys:Array = VectorUtils.pluck(joined.shift() as Array, 'localName');
				var colMap:Object = {};
				for (var i:int = 0; i <  joined.length; i++)
					colMap[ inputs.getName(cols[i]) ] = joined[i];
				columnData[keyType] = {keys: keys, columns: colMap};
			}
			
			outputCSV.setCSVData(null);
			outputCSV.metadata.setSessionState(null);
			
			addAsyncResponder(
				_service.invokeAsyncMethod('runScriptWithInputs', [scriptName.value, simpleInputs, columnData]),
				handleScriptResult,
				handleScriptError,
				getSessionState(this)
			);
		}
		
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
				var name:String = WeaveAPI.globalHashMap.getName(this);
				var source:RDataSource = this;
				_rootNode = new ColumnTreeNode({
					label: name,
					dataSource: this,
					dependency: outputCSV,
					hasChildBranches: false,
					children: function():Array {
						var csvRoot:IWeaveTreeNode = outputCSV.getHierarchyRoot();
						return csvRoot.getChildren().map(function(csvNode:IColumnReference, ..._):IWeaveTreeNode {
							var meta:Object = csvNode.getColumnMetadata();
							meta[SCRIPT_OUTPUT_NAME] = meta[CSVDataSource.METADATA_COLUMN_NAME];
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

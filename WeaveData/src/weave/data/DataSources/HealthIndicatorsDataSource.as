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
    import mx.rpc.Fault;
    
    import weave.api.data.ColumnMetadata;
    import weave.api.data.IDataSource;
    import weave.api.data.IDataSource_Service;
    import weave.api.data.IWeaveTreeNode;
    import weave.api.registerLinkableChild;
    import weave.compiler.Compiler;
    import weave.core.LinkableString;
    import weave.data.AttributeColumns.ProxyColumn;
    import weave.data.hierarchy.ColumnTreeNode;
    import weave.services.JsonCache;
    import weave.utils.DataSourceUtils;
    import weave.utils.WeavePromise;

    public class HealthIndicatorsDataSource extends AbstractDataSource implements IDataSource_Service
    {
        WeaveAPI.ClassRegistry.registerImplementation(IDataSource, HealthIndicatorsDataSource, "HealthIndicators.gov");

        private static const baseUrl:String = "http://services.HealthIndicators.gov/v5/REST.svc/";
		
		public const apiKey:LinkableString = registerLinkableChild(this, new LinkableString("447a0d0174514ca9be9bbf3433892b84"));
		private const cache:JsonCache = registerLinkableChild(this, new JsonCache({"Accept": "application/json"}));
		
		private function getJson(method:String, params:Object = null):WeavePromise
		{
			if (!params)
				params = {};
			params.Key = apiKey.value;
			return cache.getJsonPromise(this, JsonCache.buildURL(baseUrl + method, params) + "&{}")
				.then(function(result:Object):Object {
					if (result.Status != 'Success')
					{
						var fault:Fault = new Fault(result.Status, result.Message);
						fault.content = result;
						throw fault;
					}
					return result;
				});
		}
		
		private function getAllPages(method:String, params:Object = null):WeavePromise
		{
			var output:Array = [];
			
			if (method.substr(-5) == '/Data')
			{
				// backup if PageCount request fails - request each page until no data is returned
				var page:int = 0;
				function handlePage(result:Object = null):*
				{
					// on last page, return output
					if (result && result.DataLength == 0)
						return output;
					// append current page results to output
					if (result)
						output.push.apply(output, result.Data);
					return getJson(method + '/' + (++page), params)
						.then(handlePage);
				}
				return handlePage();
			}
			
			return getJson(method + '/PageCount', params)
				.then(function(result:Object):* {
					var pageCount:int = result.Data;
					// immediately call getJson() on each page so they will be retrieved simultaneously
					var promises:Array = new Array(pageCount).map(function(_:*, i:*, a:*):* {
						return getJson(method + '/' + (i + 1), params);
					});
					if (!promises.length)
						return output;
					var finalPromise:WeavePromise = null;
					for each (var promise:WeavePromise in promises)
						finalPromise = finalPromise ? finalPromise.then(function(_:*):* { return promise; }) : promise;
					return finalPromise
						.then(function(..._):* {
							// append results to output in order
							for each (var promise:WeavePromise in promises)
								output.push.apply(output, promise.getResult().Data);
							return output;
						});
				});
		}
		
		// http://services.healthindicators.gov/v5/REST.svc/IndicatorDescriptions/1?Key=...
		// http://services.healthindicators.gov/v5/REST.svc/IndicatorDescription/98/Data/1?Key=447a0d0174514ca9be9bbf3433892b84
		
        override public function getHierarchyRoot():IWeaveTreeNode
        {
            if (!_rootNode)
                _rootNode = new ColumnTreeNode({
					dataSource: this,
					label: WeaveAPI.globalHashMap.getName(this),
					children: function(parent:ColumnTreeNode):Array {
						var children:Array = [];
						getAllPages('IndicatorDescriptions').then(function(output:Array):void {
							for each (var item:Object in output)
								children.push({
									dataSource: parent.dataSource,
									data: item,
									label: item.ShortDescription,
									children: []
								});
						});
						return children;
					}
				});
            return _rootNode;
        }
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			if (!metadata)
				return null;
			var idFields:Array = [];

			var ctn:ColumnTreeNode = new ColumnTreeNode({dataSource: this, idFields: idFields, data: metadata});
			return ctn; 
		}
        override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
        {   		
        	var metadata:Object = ColumnMetadata.getAllMetadata(proxyColumn);
        	
			getAllPages('').then(
				function(columnInfo:Object):void
				{
					proxyColumn.setMetadata(columnInfo.metadata);
					
					DataSourceUtils.initColumn(proxyColumn, columnInfo.keys, columnInfo.data);
				},
				function (error:*):void
				{
					proxyColumn.dataUnavailable(Compiler.stringify(error));
				}
			);
        }
    }
}
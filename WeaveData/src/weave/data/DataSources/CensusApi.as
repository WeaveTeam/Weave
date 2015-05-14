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
	import mx.utils.ObjectUtil;
	
	import org.apache.flex.promises.interfaces.IThenable;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.newLinkableChild;
	import weave.api.reportError;
	import weave.compiler.StandardLib;
	import weave.services.JsonCache;
	import weave.utils.VectorUtils;
	import weave.utils.WeavePromise;
	
	public class CensusApi implements ILinkableObject
	{
		public static const BASE_URL:String = "http://api.census.gov/";
		private const jsonCache:JsonCache = newLinkableChild(this, JsonCache);
		
		public static function getUrl(serviceUrl:String, params:Object):String
		{
			var paramsStr:String = '';
			for (var key:String in params)
				paramsStr += (paramsStr ? '&' : '?') + key + '=' + params[key];
			return serviceUrl + paramsStr;
		}
		
		public function CensusApi():void
		{
			
		}
		
		public function getDatasets():WeavePromise
		{
			return jsonCache.getJsonPromise(this, BASE_URL + "data.json");
		}
		
		/* TODO: Add memoized promises for preprocessing steps */
		
		private function getDatasetPromise(dataSetIdentifier:String):IThenable
		{
			return getDatasets().then(
				function (result:Object):Object
				{
					for each (var tmp_dataset:Object in result)
					{
						if (tmp_dataset.identifier == dataSetIdentifier)
						{
							return tmp_dataset;
						}
					}
					throw new Error("No such dataset: " + dataSetIdentifier);
				}, reportError
			);
		}
		private function getVariablesPromise(dataSetIdentifier:String):IThenable
		{
			return getDatasetPromise(dataSetIdentifier).then(
				function (dataset:Object):IThenable
				{
					return jsonCache.getJsonPromise(this, dataset.c_variablesLink);
				}
			);
		}
		private function getGeographiesPromise(dataSetIdentifier:String):IThenable
		{
			return getDatasetPromise(dataSetIdentifier).then(
				function (dataset:Object):IThenable
				{
					return jsonCache.getJsonPromise(this, dataset.c_geographyLink);
				}
			, reportError);
		}
		
		public function getVariables(dataSetIdentifier:String):IThenable
		{
			return getVariablesPromise(dataSetIdentifier).then(
				function (result:Object):Object
				{
					var variableInfo:Object = ObjectUtil.copy(result.variables);
					delete variableInfo["for"];
					delete variableInfo["in"];
					
					return variableInfo;
				}
			, reportError);
		}
		
		public function getGeographies(dataSetIdentifier:String):IThenable
		{
			return getGeographiesPromise(dataSetIdentifier).then(
				function (result:Object):Object
				{
					var geo:Object = {};
					for each (var geo_description:Object in result.fips)
					{
						geo[geo_description.name] = {
							id: geo_description.geoLevelId,
							requires: geo_description.requires
						};
					}
					
					return geo;
				}
			, reportError);
		}
		
		/**
		 * 
		 * @param metadata
		 * @return An object containing three fields, "keys," "values," and "metadata" 
		 */				
		public function getColumn(metadata:Object, depends:ILinkableObject):IThenable
		{	
			var dataset_name:String = metadata[CensusDataSource.DATASET];
			var geography_name:String = metadata[CensusDataSource.FOR_GEOGRAPHY];
			var variable_name:String = metadata[CensusDataSource.VARIABLE_NAME];
			var title:String = null;
			var service_url:String = null;
			var filters:Array = [];
			var requires:Array = null;
			
			for (var key:String in metadata)
			{
				var sections:Array = key.split("#");
				if (sections.length == 2)
				{
					filters.push(sections[1] + ":" + metadata[key]);
				}
			}
			
			var params:Object = {
				get: variable_name,
				"for": geography_name + ":*",
				"in": filters.join(",")
			};
			
			return getDatasetPromise(dataset_name).then(
				function (datasetInfo:Object):IThenable
				{
					service_url = datasetInfo.webService;
					return getVariables(dataset_name);
				}
			).then(
				function (variableInfo:Object):IThenable
				{
					title = variableInfo[variable_name].label;
					return getGeographies(dataset_name);	
				}
			).then(
				function (geographyInfo:Object):IThenable
				{
					requires = VectorUtils.copy(geographyInfo[geography_name].requires || []);
					requires.push(geography_name);
					return jsonCache.getJsonPromise(this, getUrl(service_url, params)).depend(depends);
				}
			).then(
				function (dataResult:Object):Object
				{
					if (dataResult == null)
						return null;
					var idx:int;
					var columns:Array = dataResult[0] as Array;
					var rows:Array = dataResult as Array;
					var data_column:Array = new Array(rows.length - 1);
					var key_column:Array = new Array(rows.length - 1);
					var key_column_indices:Array = new Array(columns.length);
					var data_column_index:int = columns.indexOf(variable_name);
					
					var tmp_key_type:String = WeaveAPI.CSVParser.createCSVRow(requires);

					metadata[ColumnMetadata.KEY_TYPE] = tmp_key_type;
					metadata[ColumnMetadata.TITLE] = title;
					for (idx = 0; idx < requires.length; idx++)
					{
						key_column_indices[idx] = columns.indexOf(requires[idx]);
					}
					for (var row_idx:int = 0; row_idx < data_column.length; row_idx++)
					{
						var row:Array = rows[row_idx+1];
						var key_values:Array = new Array(key_column_indices.length);
						
						for (idx = 0; idx < key_column_indices.length; idx++)
						{
							key_values[idx] = row[key_column_indices[idx]];
						}
						key_column[row_idx] = key_values.join("");
						data_column[row_idx] = row[data_column_index];
					}
					
					return {
						keys: key_column,
						data: data_column,
						metadata: metadata
					};
				}
			);
		}
	}
}
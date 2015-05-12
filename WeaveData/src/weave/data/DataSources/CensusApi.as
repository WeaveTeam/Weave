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
	import org.apache.flex.promises.interfaces.IThenable;
	
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
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
				paramsStr += (paramsStr ? '&' : '?');
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
				}
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
			);
		}
		
		public function getVariables(dataSetIdentifier:String):IThenable
		{
			return getVariablesPromise(dataSetIdentifier).then(
				function (result:Object):Array
				{
					delete result.variables["for"];
					delete result.variables["in"];
					
					var variable_list:Array = [];
					
					for (var key:String in result.variables)
					{
						result.variables[key].id = key;
						variable_list.push(result.variables[key]);
					}
					return variable_list;
				}
			);
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
			);
		}
	}
}
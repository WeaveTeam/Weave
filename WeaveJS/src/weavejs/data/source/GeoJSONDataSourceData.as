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
	import weavejs.geom.GeoJSON;
	import weavejs.geom.ProjectionManager;
	import weavejs.util.ArrayUtils;
	import weavejs.util.AsyncSort;

	internal class GeoJSONDataSourceData
	{
		public function GeoJSONDataSourceData(obj:Object, keyType:String, keyPropertyName:String)
		{
			// get projection
			var crs:Object = obj[GeoJSON.P_CRS];
			if (crs && crs[GeoJSON.P_TYPE] == GeoJSON.CRS_T_NAME)
				projection = ProjectionManager.getProjectionFromURN(crs[GeoJSON.CRS_P_PROPERTIES][GeoJSON.CRS_N_P_NAME]);
			
			// get features
			var featureCollection:Object = GeoJSON.asFeatureCollection(obj);
			var features:Array = featureCollection[GeoJSON.FC_P_FEATURES];
			
			// save data from features
			ids = ArrayUtils.pluck(features, GeoJSON.F_P_ID);
			geometries = ArrayUtils.pluck(features, GeoJSON.F_P_GEOMETRY);
			properties = ArrayUtils.pluck(features, GeoJSON.F_P_PROPERTIES);
			
			// if there are no ids, use index values
			if (ids.every(function(item:*, i:*, a:*):Boolean { return item === undefined; }))
				ids = features.map(function(o:*, i:*, a:*):* { return i; });
			
			// get property names
			propertyNames = [];
			propertyTypes = {};
			properties.forEach(function(props:Object, i:*, a:*):void {
				for (var key:String in props)
				{
					var value:Object = props[key];
					var oldType:String = propertyTypes[key];
					var newType:String = value == null ? oldType : typeof value; // don't let null affect type
					if (!propertyTypes.hasOwnProperty(key))
					{
						propertyTypes[key] = newType;
						propertyNames.push(key);
					}
					else if (oldType != newType)
					{
						// adjust type
						propertyTypes[key] = 'object';
					}
				}
			});
			AsyncSort.sortImmediately(propertyNames);
			
			resetQKeys(keyType, keyPropertyName);
		}
		
		/**
		 * The projection specified in the GeoJSON object.
		 */
		public var projection:String = null;
		
		/**
		 * An Array of "id" values corresponding to the GeoJSON features.
		 */
		public var ids:Array = null;
		
		/**
		 * An Array of "geometry" objects corresponding to the GeoJSON features.
		 */
		public var geometries:Array = null;
		
		/**
		 * An Array of "properties" objects corresponding to the GeoJSON features.
		 */
		public var properties:Array = null;
		
		/**
		 * A list of property names found in the jsonProperties objects.
		 */
		public var propertyNames:Array = null;
		
		/**
		 * propertyName -> typeof
		 */
		public var propertyTypes:Object = null;
		
		/**
		 * An Array of IQualifiedKey objects corresponding to the GeoJSON features.
		 * This can be reinitialized via resetQKeys().
		 */
		public var qkeys:Array = null;
		
		/**
		 * Updates the qkeys Vector using the given keyType and property values under the given property name.
		 * If the property name is not found, index values will be used.
		 * @param keyType The keyType of each IQualifiedKey.
		 * @param propertyName The name of a property in the propertyNames Array.
		 */
		public function resetQKeys(keyType:String, propertyName:String):void
		{
			var values:Array = ids;
			if (propertyName && propertyNames.indexOf(propertyName) >= 0)
				values = ArrayUtils.pluck(properties, propertyName);
			
			qkeys = WeaveAPI.QKeyManager.getQKeys(keyType, values);
		}
	}
}

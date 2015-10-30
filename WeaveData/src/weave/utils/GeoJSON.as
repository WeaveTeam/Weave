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

package weave.utils
{
	import weave.compiler.StandardLib;
	
	public class GeoJSON
	{
		// GeoJSON object properties
		public static const P_TYPE:String = 'type';
		public static const P_CRS:String = 'crs';
		public static const P_BBOX:String = 'bbox';
		
		// Geometry object property
		public static const G_P_COORDINATES:String = 'coordinates';
		
		// GeometryCollection property
		public static const GC_P_GEOMETRIES:String = 'geometries';
		
		// Feature properties
		public static const F_P_ID:String = 'id';
		public static const F_P_GEOMETRY:String = 'geometry';
		public static const F_P_PROPERTIES:String = 'properties';
		
		// CRS properties
		public static const CRS_P_TYPE:String = 'type';
		public static const CRS_P_PROPERTIES:String = 'properties';
		public static const CRS_T_NAME:String = 'name';
		public static const CRS_T_LINK:String = 'link';
		public static const CRS_N_P_NAME:String = 'name';
		public static const CRS_L_P_HREF:String = 'href';
		public static const CRS_L_P_TYPE:String = 'type';
		
		// FeatureCollection properties
		public static const FC_P_FEATURES:String = 'features';
		
		// GeoJSON object types
		public static const T_POINT:String = 'Point';
		public static const T_MULTI_POINT:String = 'MultiPoint';
		public static const T_LINE_STRING:String = 'LineString';
		public static const T_MULTI_LINE_STRING:String = 'MultiLineString';
		public static const T_POLYGON:String = 'Polygon';
		public static const T_MULTI_POLYGON:String = 'MultiPolygon';
		public static const T_GEOMETRY_COLLECTION:String = 'GeometryCollection';
		public static const T_FEATURE:String = 'Feature';
		public static const T_FEATURE_COLLECTION:String = 'FeatureCollection';

		//-------------------------------------------------------------------------------------------

		public static function isGeoJSONObject(obj:Object, ..._):Boolean
		{
			return isFeatureObject(obj)
				|| isFeatureCollectionObject(obj)
				|| isGeometryObject(obj);
		}
		private static function couldBeGeoJSONObject(obj:Object):Boolean
		{
			return obj
				&& obj.hasOwnProperty(P_TYPE)
				&& (!obj.hasOwnProperty(P_CRS) || isCRSObject(obj[P_CRS]))
				&& (!obj.hasOwnProperty(P_BBOX) || isBBOXObject(obj[P_BBOX]));
		}
		public static function isFeatureObject(obj:Object, ..._):Boolean
		{
			return couldBeGeoJSONObject(obj)
				&& obj[P_TYPE] == T_FEATURE
				&& obj.hasOwnProperty(F_P_GEOMETRY)
				&& (obj[F_P_GEOMETRY] === null || isGeometryObject(obj[F_P_GEOMETRY]))
				&& obj.hasOwnProperty(F_P_PROPERTIES)
				&& typeof obj[F_P_PROPERTIES] == 'object';
		}
		public static function isFeatureCollectionObject(obj:Object, ..._):Boolean
		{
			return couldBeGeoJSONObject(obj)
				&& obj[P_TYPE] == T_FEATURE_COLLECTION
				&& obj.hasOwnProperty(FC_P_FEATURES)
				&& obj[FC_P_FEATURES] is Array
				&& (obj[FC_P_FEATURES] as Array).every(isFeatureObject);
		}
		public static function isGeometryObject(obj:Object, ..._):Boolean
		{
			if (!couldBeGeoJSONObject(obj))
				return false;
			
			var coords:Array = obj.hasOwnProperty(G_P_COORDINATES)
				? obj[G_P_COORDINATES] as Array
				: null;
			
			switch (obj[P_TYPE])
			{
				case T_POINT:
					return isPositionCoords(coords);
				case T_MULTI_POINT:
					return coords && coords.every(isPositionCoords);
				case T_LINE_STRING:
					return isLineStringCoords(coords);
				case T_MULTI_LINE_STRING:
					return coords && coords.every(isLineStringCoords);
				case T_POLYGON:
					return isPolygonCoords(coords);
				case T_MULTI_POLYGON:
					return coords && coords.every(isPolygonCoords);
				case T_GEOMETRY_COLLECTION:
					return isGeometryCollectionObject(obj);
				default:
					return false;
			}
		}
		private static function isGeometryCollectionObject(obj:Object):Boolean
		{
			return couldBeGeoJSONObject(obj)
				&& obj.hasOwnProperty(GC_P_GEOMETRIES)
				&& obj[GC_P_GEOMETRIES] is Array
				&& (obj[GC_P_GEOMETRIES] as Array).every(isGeometryObject);
		}
		private static function isPositionCoords(coords:Object, ..._):Boolean
		{
			var array:Array = coords as Array;
			return array
				&& array.length >= 2
				&& StandardLib.getArrayType(array) == Number;
		}
		private static function isLineStringCoords(coords:Object, ..._):Boolean
		{
			var array:Array = coords as Array;
			return array
				&& array.length >= 2
				&& array.every(isPositionCoords);
		}
		private static function isLinearRingCoords(coords:Object, ..._):Boolean
		{
			var array:Array = coords as Array;
			return array
				&& array.length >= 4
				&& array.every(isPositionCoords)
				&& StandardLib.compare(array[0], array[array.length - 1]) == 0;
		}
		private static function isPolygonCoords(coords:Object, ..._):Boolean
		{
			var array:Array = coords as Array;
			return array
				&& array.every(isLinearRingCoords);
		}
		private static function isCRSObject(obj:Object):Boolean
		{
			// null CRS is valid
			if (obj == null)
				return true;
			
			// check for required properties
			if (!obj.hasOwnProperty(CRS_P_TYPE) || !obj.hasOwnProperty(CRS_P_PROPERTIES))
				return false;
			
			var props:Object = obj[CRS_P_PROPERTIES];
			switch (obj[CRS_P_TYPE])
			{
				case CRS_T_NAME:
					return props
						&& props.hasOwnProperty(CRS_N_P_NAME)
						&& props[CRS_N_P_NAME] is String;
				case CRS_T_LINK:
					return props
						&& props.hasOwnProperty(CRS_L_P_HREF)
						&& props[CRS_L_P_HREF] is String
						&& (!props.hasOwnProperty(CRS_L_P_TYPE) || props[CRS_L_P_TYPE] is String);
				default:
					return false;
			}
		}
		private static function isBBOXObject(obj:Object):Boolean
		{
			var array:Array = obj as Array;
			return StandardLib.getArrayType(array) == Number
				&& array.length >= 4 
				&& array.length % 2 == 0;
		}
		
		//-------------------------------------------------------------------------------------------
		
		/**
		 * Wraps a GeoJSON object in a GeoJSON FeatureCollection object if it isn't one already.
		 * @param obj A GeoJSON object.
		 * @return A GeoJSON FeatureCollection object.
		 */
		public static function asFeatureCollection(obj:Object, ..._):Object
		{
			// feature collection
			if (isFeatureCollectionObject(obj))
				return obj;
			
			var features:Array = null;
			
			// single feature
			if (isFeatureObject(obj))
				features = [obj];
			
			// geometry collection
			if (isGeometryCollectionObject(obj))
				features = (obj[GC_P_GEOMETRIES] as Array).map(geometryAsFeature);
			
			// single geometry
			if (isGeometryObject(obj))
				features = [geometryAsFeature(obj)];
			
			var featureCollection:Object = {};
			featureCollection[P_TYPE] = T_FEATURE_COLLECTION;
			featureCollection[FC_P_FEATURES] = features || [];
			return featureCollection;
		}
		private static function geometryAsFeature(obj:Object, id:* = undefined, _:* = undefined):Object
		{
			var feature:Object = {};
			feature[T_FEATURE]
			if (id !== undefined)
				feature[F_P_ID] = id;
			feature[F_P_GEOMETRY] = obj;
			feature[F_P_PROPERTIES] = null;
			return feature;
		}
		
		/**
		 * Combines an Array of GeoJson Geometry objects into a single "Multi" Geometry object.
		 * This assumes all geometry objects are of the same type.
		 * @param geoms An Array of GeoJson Geometry objects sharing a common type.
		 * @return A single GeoJson Geometry object with type MultiPoint/MultiLineString/MultiPolygon
		 */
		public static function getMultiGeomObject(geoms:Array):Object
		{
			var first:Object = geoms[0];
			var type:String = first ? first[P_TYPE] : T_MULTI_POINT;
			var multiType:String = typeToMultiType(type);
			
			var allCoords:Array = geoms.map(function(geom:Object, ..._):Array {
				return geom[G_P_COORDINATES];
			});
			var multiCoords:Array;
			if (type == multiType)
			{
				multiCoords = [];
				multiCoords = multiCoords.concat.apply(multiCoords, allCoords);
			}
			else
			{
				multiCoords = allCoords;
			}
			
			var multiGeom:Object = {};
			multiGeom[P_TYPE] = multiType;
			multiGeom[G_P_COORDINATES] = multiCoords;
			return multiGeom;
		}
		
		private static function typeToMultiType(type:String):String
		{
			if (type == T_POINT || type == T_MULTI_POINT)
				return T_MULTI_POINT;
			if (type == T_LINE_STRING || type == T_MULTI_LINE_STRING)
				return T_MULTI_LINE_STRING;
			if (type == T_POLYGON || type == T_MULTI_POLYGON)
				return T_MULTI_POLYGON;
			return null;
		}
	}
}

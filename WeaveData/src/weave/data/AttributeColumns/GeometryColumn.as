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

package weave.data.AttributeColumns
{
	import flash.utils.Dictionary;
	
	import weave.api.data.IQualifiedKey;
	import weave.primitives.GeneralizedGeometry;
	
	/**
	 * The values in this column are Arrays of GeneralizedGeometry objects.
	 * 
	 * @author adufilie
	 */
	public class GeometryColumn extends AbstractAttributeColumn
	{
		public function GeometryColumn(metadata:Object = null)
		{
			super(metadata);
		}
		
		/**
		 * This object maps a key to an array of geometry objects that have that key.
		 */
		private var _keyToGeometryArrayMapping:Dictionary = new Dictionary();
		
		/**
		 * This vector maps an index value to a GeneralizedGeometry object.
		 */
		private const _geometryVector:Vector.<GeneralizedGeometry> = new Vector.<GeneralizedGeometry>();
		
		/**
		 * This maps a GeneralizedGeometry object to its index in _geometryVector.
		 */
		private var _geometryToIndexMapping:Object = new Dictionary(true);
		
		protected const _uniqueKeys:Array = new Array();
		protected var _keyToIndex:Dictionary = new Dictionary(true);
		
		/**
		 * This is a list of unique keys this column defines values for.
		 */
		override public function get keys():Array
		{
			return _uniqueKeys;
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return _keyToGeometryArrayMapping[key] != undefined;
		}

		public function setGeometries(keys:Vector.<IQualifiedKey>, geometries:Vector.<GeneralizedGeometry>):void
		{
			if (_geometryVector.length > 0)
			{
				// clear existing mappings
				_keyToGeometryArrayMapping = new Dictionary();
				_geometryToIndexMapping = new Dictionary(true);
				_keyToIndex = new Dictionary(true);
			}
			
			if (keys.length != geometries.length)
			{
				trace("number of keys does not match number of geometires in GeometryColumn.setGeometries()");
				return;
			}
			
			// make a copy of the geometry vector and 
			// create key->geom and geom->index mappings
			var geom:GeneralizedGeometry;
			var key:IQualifiedKey;
			var uniqueKeyIndex:int = 0;
			for (var geomIndex:int = 0; geomIndex < geometries.length; geomIndex++)
			{
				geom = geometries[geomIndex];
				key = keys[geomIndex];
				_geometryVector[geomIndex] = geom;
				if (_keyToGeometryArrayMapping[key] == undefined)
				{
					_keyToGeometryArrayMapping[key] = [geom];
					_uniqueKeys[uniqueKeyIndex] = key; // remember unique keys
					_keyToIndex[key] = uniqueKeyIndex;
					uniqueKeyIndex++;
				}
				else
					(_keyToGeometryArrayMapping[key] as Array).push(geom);
				_geometryToIndexMapping[geom] = geomIndex;
			}
			// trim vectors to new sizes
			_geometryVector.length = geometries.length;
			_uniqueKeys.length = uniqueKeyIndex;
			
			triggerCallbacks();
		}
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class=null):*
		{
			var value:* = _keyToGeometryArrayMapping[key];
			
			// cast to different types
			if (dataType == Boolean)
				value = (value is Array);
			else if (dataType == Number)
			{
				var sum:Number = value is Array ? 0 : NaN;
				for each (var geom:GeneralizedGeometry in value)
					sum += geom.bounds.getArea();
				value = sum;
			}
			else if (dataType == String)
				value = value ? 'Geometry(' + key.keyType + '#' + key.localName + ')' : undefined;
			
			return value;
		}
	}
}

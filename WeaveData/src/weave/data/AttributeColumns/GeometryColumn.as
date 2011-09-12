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

package weave.data.AttributeColumns
{
	import flash.utils.Dictionary;
	
	import weave.api.data.IQualifiedKey;
	import weave.primitives.GeneralizedGeometry;
	
	/**
	 * GeometryAttributeColumn
	 * The values in this column are Arrays of GeneralizedGeometry objects.
	 * 
	 * @author adufilie
	 */
	public class GeometryColumn extends AbstractAttributeColumn
	{
		public function GeometryColumn(metadata:XML = null)
		{
			super(metadata);
		}
		
		/**
		 * _keyToGeometryArrayMapping
		 * This object maps a key to an array of geometry objects that have that key.
		 */
		private var _keyToGeometryArrayMapping:Dictionary = new Dictionary();
		
		/**
		 * _geometryVector
		 * This vector maps an index value to a GeneralizedGeometry object.
		 */
		private const _geometryVector:Vector.<GeneralizedGeometry> = new Vector.<GeneralizedGeometry>();
		
		/**
		 * _geometryToIndexMapping
		 * This maps a GeneralizedGeometry object to its index in _geometryVector.
		 */
		private var _geometryToIndexMapping:Object = new Dictionary(true);
		
		/**
		 * This is a list of unique keys this column defines values for.
		 */
		override public function get keys():Array
		{
			return _uniqueKeys;
		}
		protected const _uniqueKeys:Array = new Array();

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

		/**
		 * recordCount
		 * This is the number of unique record keys this column defines values for.
		 */		
		public function get recordCount():int
		{
			return _uniqueKeys.length;
		}
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class=null):*
		{
			return _keyToGeometryArrayMapping[key];
		}
	}
}

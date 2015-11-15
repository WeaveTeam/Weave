/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.path
{
	import weavejs.Weave;

	public class WeavePathDataShared
	{
		public static const DEFAULT_PROBE_KEY_SET:String = 'defaultProbeKeySet';
		public static const DEFAULT_SELECTION_KEY_SET:String = 'defaultSelectionKeySet';
		public static const DEFAULT_SUBSET_KEY_FILTER:String = 'defaultSubsetKeyFilter';
		public static const EDC:String = 'weave.data.AttributeColumns::ExtendedDynamicColumn';
		public static const DC:String = 'weave.data.AttributeColumns::DynamicColumn';
		public static const RC:String = 'weave.data.AttributeColumns::ReferencedColumn';
		
		public function WeavePathDataShared(weave:Weave)
		{
			Weave.bindAll(this);
			
			this.weave = weave;
			
			this.probe_keyset = weave.path(DEFAULT_PROBE_KEY_SET);
			this.selection_keyset = weave.path(DEFAULT_SELECTION_KEY_SET);
			this.subset_filter = weave.path(DEFAULT_SUBSET_KEY_FILTER);
			
			this.isColumn = weave.directAPI.evaluateExpression(null, "o => o is IAttributeColumn");
			this.joinColumns = weave.directAPI.evaluateExpression(null, "ColumnUtils.joinColumns");
			this.getLabel = weave.directAPI.evaluateExpression(null, "WeaveAPI.EditorManager.getLabel");
			this.setLabel = weave.directAPI.evaluateExpression(null, "WeaveAPI.EditorManager.setLabel");
			this.getColumnType = weave.directAPI.evaluateExpression(null, 'o => { for each (var t in types) if (o is t) return t; }', {types: [EDC, DC, RC]});
			this.getFirstDataSourceName = weave.directAPI.evaluateExpression([], '() => this.getNames(IDataSource)[0]');
		}
		
		public var weave:Weave;
		
		public var probe_keyset:WeavePath;
		public var selection_keyset:WeavePath;
		public var subset_filter:WeavePath;

		public var _qkeys_to_numeric:Object = {};
		public var _numeric_to_qkeys:Object = {};
		public var _numeric_key_idx:int = 0;
		public var _keyIdPrefix:String = "WeaveQKey";
		public var _key_buffers:Object = {};
		
		/** 
		 * Retrieves or allocates the index for the given QualifiedKey object based on its localName and keyType properties
		 * @public 
		 * @param  {object} key A QualifiedKey object (containing keyType and localName properties) to be converted.
		 * @return {number}     The existing or newly-allocated index for the qualified key.
		 */
		public function qkeyToIndex(key:Object):int
		{
			var local_map:Object = this._qkeys_to_numeric[key.keyType] || (this._qkeys_to_numeric[key.keyType] = {});
			
			if (local_map[key.localName] === undefined)
			{
				var idx:int = this._numeric_key_idx++;
				
				local_map[key.localName] = idx;
				this._numeric_to_qkeys[idx] = key;
			}
			
			return local_map[key.localName];
		}
		
		/**
		 * Retrieves the corresponding qualified key object from its numeric index.
		 * @private
		 * @param  {number} index The numeric index, as received from qkeyToIndex
		 * @return {object}       The corresponding QualifiedKey object.
		 */
		public function indexToQKey(index:int):Object
		{
			return this._numeric_to_qkeys[index];
		}
		
		/**
		 * Retrieves an alphanumeric string unique to a QualifiedKey
		 * This is also available as an alias on the WeavePath object.
		 * @param  {object} key The QualifiedKey object to convert.
		 * @return {string}     The corresponding alphanumeric key.
		 */
		public function qkeyToString(key:Object):String
		{
			return this._keyIdPrefix + this.qkeyToIndex(key);
		}
		
		/**
		 * Retrieves the QualifiedKey object corresponding to a given alphanumeric string.
		 * This is also available as an alias on the WeavePath object.
		 * @param  {string} s The keystring to convert.
		 * @return {object}   The corresponding QualifiedKey
		 */
		public function stringToQKey(s:String):Object
		{
			var idx:int = int(s.substr(this._keyIdPrefix.length));
			return this.indexToQKey(idx);
		}
		
		/**
		 * Gets the key add/remove buffers for a specific session state path.
		 * @private
		 * @param  {Array} pathArray A raw session state path.
		 * @return {object}           An object containing the key add/remove queues for the given path.
		 */
		public function _getKeyBuffers(pathArray:Array):Object
		{
			var path_key:String = JSON.stringify(pathArray);
			
			var key_buffers_dict:Object = this._key_buffers;
			var key_buffers:Object = key_buffers_dict[path_key] || (key_buffers_dict[path_key] = {});
			
			if (key_buffers.add === undefined) key_buffers.add = {};
			if (key_buffers.remove === undefined) key_buffers.remove = {};
			if (key_buffers.timeout_id === undefined) key_buffers.timeout_id = null;
			
			return key_buffers;
		}
		
		/**
		 * Flushes the key add/remove buffers for a specific session state path. 
		 * @private
		 * @param  {Array} pathArray The session state path to flush.         
		 */
		public function _flushKeys(pathArray:Array):void
		{
			var key_buffers:Object = this._getKeyBuffers(pathArray);
			var add_keys:Array = Weave.objectKeys(key_buffers.add);
			var remove_keys:Array = Weave.objectKeys(key_buffers.remove);
			
			add_keys = add_keys.map(this.stringToQKey, this);
			remove_keys = remove_keys.map(this.stringToQKey, this);
			
			key_buffers.add = {};
			key_buffers.remove = {};
			
			weave.directAPI.evaluateExpression(pathArray, 'this.addKeys(keys)', {keys: add_keys}, null, "");
			weave.directAPI.evaluateExpression(pathArray, 'this.removeKeys(keys)', {keys: remove_keys}, null, "");
			
			key_buffers.timeout_id = null;
		}
		
		/**
		 * Set a timeout to flush the add/remove key buffers for a given session state path if one isn't already in progress.
		 * @private
		 * @param  {Array} pathArray The session state path referencing a KeySet to flush.
		 */
		public function _flushKeysLater(pathArray:Array):void
		{
			var key_buffers:Object = this._getKeyBuffers(pathArray);
			if (key_buffers.timeout_id === null)
				key_buffers.timeout_id = Weave.global.setTimeout(_flushKeys, 25, pathArray);
		}
		
		/**
		 * Queue keys to be added to a specified path.
		 * @private
		 * @param {Array} pathArray      The session state path referencing a KeySet
		 * @param {Array} keyStringArray The set of keys to add.
		 */
		public function _addKeys(pathArray:Array, keyStringArray:Array):void
		{
			var key_buffers:Object = this._getKeyBuffers(pathArray);
			
			keyStringArray.forEach(function(str:String):void
			{
				key_buffers.add[str] = true;
				delete key_buffers.remove[str];
			});
			
			this._flushKeysLater(pathArray);
		}
		
		/**
		 * Queue keys to be removed from a specified path.
		 * @private
		 * @param {Array} pathArray      The session state path referencing a KeySet
		 * @param {Array} keyStringArray The set of keys to remove.
		 */
		public function _removeKeys(pathArray:Array, keyStringArray:Array):void
		{
			var key_buffers:Object = this._getKeyBuffers(pathArray);
			
			keyStringArray.forEach(function(str:String):void
			{
				key_buffers.remove[str] = true;
				delete key_buffers.add[str];
			});
			
			this._flushKeysLater(pathArray);
		}
		
		////////////////////////////////
		
		/**
		 * @private
		 * A function that tests if a WeavePath references an IAttributeColumn
		 */
		public var isColumn:Function;
		
		/**
		 * @private
		 * A pointer to ColumnUtils.joinColumns.
		 */
		public var joinColumns:Function;
		
		public var getLabel:Function;
		public var setLabel:Function;
		public var getColumnType:Function;
		public var getFirstDataSourceName:Function;
	}
}

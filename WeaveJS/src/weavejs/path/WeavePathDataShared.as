/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.path
{
	import weavejs.WeaveAPI;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.data.IQualifiedKeyManager;
	import weavejs.util.JS;

	public class WeavePathDataShared
	{
		public static const DEFAULT_PROBE_KEY_SET:String = 'defaultProbeKeySet';
		public static const DEFAULT_SELECTION_KEY_SET:String = 'defaultSelectionKeySet';
		public static const DEFAULT_SUBSET_KEY_FILTER:String = 'defaultSubsetKeyFilter';
		
		public function WeavePathDataShared()
		{
		}
		
		public function init(weave:Weave):void
		{
			this.weave = weave;
			this.qkm = WeaveAPI.QKeyManager;
			this.probe_keyset = weave.path(DEFAULT_PROBE_KEY_SET);
			this.selection_keyset = weave.path(DEFAULT_SELECTION_KEY_SET);
			this.subset_filter = weave.path(DEFAULT_SUBSET_KEY_FILTER);
		}
		
		private var qkm:IQualifiedKeyManager;
		
		public var weave:Weave;
		
		public var probe_keyset:WeavePath;
		public var selection_keyset:WeavePath;
		public var subset_filter:WeavePath;

		public var _key_buffers:Object = {};
		
		/** 
		 * Retrieves or allocates the index for the given QualifiedKey object based on its localName and keyType properties
		 * @param  {object} key A QualifiedKey object (containing keyType and localName properties) to be converted.
		 * @return {number}     The existing or newly-allocated index for the qualified key.
		 */
		public function qkeyToIndex(key:Object):int
		{
			return this.qkm.getQKey(key.keyType, key.localName).toNumber();
		}
		
		/**
		 * Retrieves the corresponding qualified key object from its numeric index.
		 * @private
		 * @param  {number} index The numeric index, as received from qkeyToIndex
		 * @return {object}       The corresponding untyped QualifiedKey object.
		 */
		public function indexToQKey(index:int):Object
		{
			var qkey:IQualifiedKey = this.qkm.numberToQKey(index);
			return {keyType: qkey.keyType, localName: qkey.localName};
		}
		
		/**
		 * Retrieves an alphanumeric string unique to a QualifiedKey
		 * This is also available as an alias on the WeavePath object.
		 * @param  {object} key The QualifiedKey object to convert.
		 * @return {string}     The corresponding alphanumeric key.
		 */
		public function qkeyToString(key:Object):String
		{
			return this.qkm.getQKey(key.keyType, key.localName).toString();
		}
		
		/**
		 * Retrieves the QualifiedKey object corresponding to a given alphanumeric string.
		 * This is also available as an alias on the WeavePath object.
		 * @param  {string} s The keystring to convert.
		 * @return {object}   The corresponding untyped QualifiedKey
		 */
		public function stringToQKey(s:String):Object
		{
			var qkey:IQualifiedKey = this.qkm.stringToQKey(s);
			return {keyType: qkey.keyType, localName: qkey.localName};
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
			var add_keys:Array = JS.objectKeys(key_buffers.add);
			var remove_keys:Array = JS.objectKeys(key_buffers.remove);
			
			add_keys = add_keys.map(this.stringToQKey, this);
			remove_keys = remove_keys.map(this.stringToQKey, this);
			
			key_buffers.add = {};
			key_buffers.remove = {};
			
			var obj:Object = weave.path(pathArray).getObject();
			obj.addKeys(add_keys);
			obj.removeKeys(remove_keys);
			
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
				key_buffers.timeout_id = JS.setTimeout(_flushKeys, 25, pathArray);
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
	}
}

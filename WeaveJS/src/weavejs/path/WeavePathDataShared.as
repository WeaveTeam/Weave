/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.path
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.data.IKeySet;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.data.IQualifiedKeyManager;
	import weavejs.util.Dictionary2D;
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
			this.probe_keyset = weave.path(DEFAULT_PROBE_KEY_SET) as WeavePathData;
			this.selection_keyset = weave.path(DEFAULT_SELECTION_KEY_SET) as WeavePathData;
			this.subset_filter = weave.path(DEFAULT_SUBSET_KEY_FILTER) as WeavePathData;
		}
		
		private var qkm:IQualifiedKeyManager;
		
		public var weave:Weave;
		
		public var probe_keyset:WeavePathData;
		public var selection_keyset:WeavePathData;
		public var subset_filter:WeavePathData;

		private var d2d_keySet_addedKeys:Dictionary2D = new Dictionary2D(true);
		private var d2d_keySet_removedKeys:Dictionary2D = new Dictionary2D(true);
		private var map_keySet_timeoutId:Object = new JS.WeakMap();
		
		/** 
		 * Retrieves or allocates the index for the given QualifiedKey object based on its localName and keyType properties
		 * @param  {object} key A QualifiedKey object (containing keyType and localName properties) to be converted.
		 * @return {number}     The existing or newly-allocated index for the qualified key.
		 */
		public function qkeyToIndex(qkey:IQualifiedKey):int
		{
			return qkey.toNumber();
		}
		
		/**
		 * Retrieves the corresponding qualified key object from its numeric index.
		 * @private
		 * @param  {number} index The numeric index, as received from qkeyToIndex
		 * @return {object}       The corresponding untyped QualifiedKey object.
		 */
		public function indexToQKey(index:int):Object
		{
			return this.qkm.numberToQKey(index);
		}
		
		/**
		 * Retrieves an alphanumeric string unique to a QualifiedKey
		 * This is also available as an alias on the WeavePath object.
		 * @param  {object} qkey The QualifiedKey object to convert.
		 * @return {string}     The corresponding alphanumeric key.
		 */
		public function qkeyToString(qkey:Object):String
		{
			return qkey.toString();
		}
		
		/**
		 * Retrieves the QualifiedKey object corresponding to a given alphanumeric string.
		 * This is also available as an alias on the WeavePath object.
		 * @param  {string} s The keystring to convert.
		 * @return {object}   The corresponding untyped QualifiedKey
		 */
		public function stringToQKey(s:String):Object
		{
			return s as IQualifiedKey || this.qkm.stringToQKey(s);
		}
		
		/**
		 * Flushes the key add/remove buffers for a specific session state path. 
		 * @private
		 * @param  {Array} pathArray The session state path to flush.         
		 */
		public function _flushKeys(keySet:ILinkableObject):void
		{
			var add_keys:Array = d2d_keySet_addedKeys.secondaryKeys(keySet);
			var remove_keys:Array = d2d_keySet_removedKeys.secondaryKeys(keySet);
			
			d2d_keySet_addedKeys.removeAllPrimary(keySet);
			d2d_keySet_removedKeys.removeAllPrimary(keySet);
			
			keySet['addKeys'](add_keys);
			keySet['removeKeys'](remove_keys);
			
			map_keySet_timeoutId['delete'](keySet);
		}
		
		/**
		 * Set a timeout to flush the add/remove key buffers for a given session state path if one isn't already in progress.
		 * @private
		 * @param  {Array} pathArray The session state path referencing a KeySet to flush.
		 */
		public function _flushKeysLater(keySet:ILinkableObject):void
		{
			if (!map_keySet_timeoutId.has(keySet))
				map_keySet_timeoutId.set(keySet, JS.setTimeout(_flushKeys, 25, keySet));
		}
		
		/**
		 * Queue keys to be added to a specified path.
		 * @private
		 * @param {Array} pathArray      The session state path referencing a KeySet
		 * @param {Array} keyStringArray The set of keys to add.
		 */
		public function _addKeys(keySet:ILinkableObject, qkeyStrings:Array):void
		{
			this.qkm.getQKeys(null, qkeyStrings)
				.forEach(function(qkey:IQualifiedKey):void {
					d2d_keySet_addedKeys.set(keySet, qkey, true);
					d2d_keySet_removedKeys.remove(keySet, qkey);
				});
			
			this._flushKeysLater(keySet);
		}
		
		/**
		 * Queue keys to be removed from a specified path.
		 * @private
		 * @param {Array} pathArray      The session state path referencing a KeySet
		 * @param {Array} keyStringArray The set of keys to remove.
		 */
		public function _removeKeys(keySet:ILinkableObject, qkeyStrings:Array):void
		{
			this.qkm.getQKeys(null, qkeyStrings)
				.forEach(function(qkey:IQualifiedKey):void {
					d2d_keySet_removedKeys.set(keySet, qkey, true);
					d2d_keySet_addedKeys.remove(keySet, qkey);
				});
			
			this._flushKeysLater(keySet);
		}
	}
}

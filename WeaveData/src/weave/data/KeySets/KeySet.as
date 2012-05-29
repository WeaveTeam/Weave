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

package weave.data.KeySets
{
	import flash.utils.Dictionary;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.copySessionState;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.getSessionState;
	import weave.api.setSessionState;
	import weave.compiler.StandardLib;
	import weave.core.LinkableVariable;
	
	/**
	 * This class contains a set of IQualifiedKeys and functions for adding/removing keys from the set.
	 * 
	 * @author adufilie
	 */
	public class KeySet extends LinkableVariable implements IKeySet
	{
		public function KeySet()
		{
			super(Array);
			// The first callback will update the keys from the session state.
			addImmediateCallback(this, updateKeys);
		}
		
		/**
		 * Changed to use StandardLib.arrayCompare().
		 */
		override protected function sessionStateEquals(otherSessionState:*):Boolean
		{
			return StandardLib.arrayCompare(_sessionState, otherSessionState) == 0;
		}
		
		/**
		 * This flag is used to avoid recursion while the keys are being synchronized with the session state.
		 */		
		private var _currentlyUpdating:Boolean = false;

		/**
		 * This is the first callback that runs when the KeySet changes.
		 * The keys will be updated based on the session state.
		 */
		private function updateKeys():void
		{
			// avoid recursion
			if (_currentlyUpdating)
				return;

			// each row of CSV represents a different keyType (keyType is the first token in the row)
			var newKeys:Array = [];
			for each (var row:Array in _sessionState)
				(newKeys.push as Function).apply(null, WeaveAPI.QKeyManager.getQKeys(row[0], row.slice(1)));
			
			// avoid internal recursion while still allowing callbacks to cause recursion afterwards
			delayCallbacks();
			_currentlyUpdating = true;
			replaceKeys(newKeys);
			_currentlyUpdating = false;
			resumeCallbacks();
		}
		
		/**
		 * This function will derive the session state from the IQualifiedKey objects in the keys array.
		 */		
		private function updateSessionState():void
		{
			// avoid recursion
			if (_currentlyUpdating)
				return;
			
			// from the IQualifiedKey objects, generate the session state
			var _keyTypeToKeysMap:Object = {};
			for each (var key:IQualifiedKey in _keys)
			{
				if (_keyTypeToKeysMap[key.keyType] == undefined)
					_keyTypeToKeysMap[key.keyType] = [];
				(_keyTypeToKeysMap[key.keyType] as Array).push(key.localName);
			}
			// for each keyType, create a row for the CSV parser
			var keyTable:Array = [];
			for (var keyType:String in _keyTypeToKeysMap)
			{
				var newKeys:Array = _keyTypeToKeysMap[keyType];
				newKeys.unshift(keyType);
				keyTable.push(newKeys);
			}
			
			// avoid internal recursion while still allowing callbacks to cause recursion afterwards
			delayCallbacks();
			_currentlyUpdating = true;
			setSessionState(keyTable);
			_currentlyUpdating = false;
			resumeCallbacks();
		}
		
		/**
		 * This object maps keys to index values
		 */
		private var _keyIndex:Dictionary = new Dictionary();
		/**
		 * This maps index values to IQualifiedKey objects
		 */
		private var _keys:Array = new Array();

		/**
		 * A list of keys included in this KeySet.
		 */
		public function get keys():Array
		{
			return _keys;
		}

		/**
		 * Overwrite the current set of keys.
		 * @param newKeys An Array of IQualifiedKey objects.
		 * @return true if the set changes as a result of calling this function.
		 */
		public function replaceKeys(newKeys:Array):Boolean
		{
			if (_locked)
				return false;
			
			if (newKeys == _keys)
				_keys = _keys.concat();
			
			var key:Object;
			var changeDetected:Boolean = false;
			
			// copy the previous key-to-index mapping for detecting changes
			var prevKeyIndex:Dictionary = _keyIndex;

			// initialize new key index
			_keyIndex = new Dictionary();
			// copy new keys and create new key index
			_keys.length = newKeys.length; // allow space for all keys
			var outputIndex:int = 0; // index to store internally
			for (var inputIndex:int = 0; inputIndex < newKeys.length; inputIndex++)
			{
				key = newKeys[inputIndex] as IQualifiedKey;
				// avoid storing duplicate keys
				if (_keyIndex[key] != undefined)
					continue;
				// copy key
				_keys[outputIndex] = key;
				// save key-to-index mapping
				_keyIndex[key] = outputIndex;
				// if the previous key index did not have this key, a change has been detected.
				if (prevKeyIndex[key] == undefined)
					changeDetected = true;
				// increase stored index
				outputIndex++;
			}
			_keys.length = outputIndex; // trim to actual length
			// loop through old keys and see if any were removed
			if (!changeDetected)
			{
				for (key in prevKeyIndex)
				{
					if (_keyIndex[key] == undefined) // if this previous key is gone now, change detected
					{
						changeDetected = true;
						break;
					}
				}
			}

			if (changeDetected)
				updateSessionState();
			
			return changeDetected;
		}

		/**
		 * Clear the current set of keys.
		 * @return true if the set changes as a result of calling this function.
		 */
		public function clearKeys():Boolean
		{
			if (_locked)
				return false;
			
			// stop if there are no keys to remove
			if (_keys.length == 0)
				return false; // set did not change

			// clear key-to-index mapping
			_keyIndex = new Dictionary();
			_keys = [];
			
			updateSessionState();

			// set changed
			return true;
		}

		/**
		 * @param key A IQualifiedKey object to check.
		 * @return true if the given key is included in the set.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			// the key is included in the set if it is in the key-to-index mapping.
			return _keyIndex[key] != undefined;
		}
		
		/**
		 * Adds a vector of additional keys to the set.
		 * @param additionalKeys A list of keys to add to this set.
		 * @return true if the set changes as a result of calling this function.
		 */
		public function addKeys(additionalKeys:Array):Boolean
		{
			if (_locked)
				return false;
			
			var changeDetected:Boolean = false;
			for each (var key:IQualifiedKey in additionalKeys)
			{
				if (_keyIndex[key] == undefined)
				{
					// add key
					var newIndex:int = _keys.length;
					_keys[newIndex] = key;
					_keyIndex[key] = newIndex;
					
					changeDetected = true;
				}
			}
			
			if (changeDetected)
				updateSessionState();

			return changeDetected;
		}

		/**
		 * Removes a vector of additional keys to the set.
		 * @param unwantedKeys A list of keys to remove from this set.
		 * @return true if the set changes as a result of calling this function.
		 */
		public function removeKeys(unwantedKeys:Array):Boolean
		{
			if (_locked)
				return false;
			
			if (unwantedKeys == _keys)
				return clearKeys();
			
			var changeDetected:Boolean = false;
			for each (var key:IQualifiedKey in unwantedKeys)
			{
				if (_keyIndex[key] != undefined)
				{
					// drop key from _keys vector
					var droppedIndex:int = _keyIndex[key];
					if (droppedIndex < _keys.length - 1) // if this is not the last entry
					{
						// move the last entry to the droppedIndex slot
						var lastKey:IQualifiedKey = _keys[keys.length - 1] as IQualifiedKey;
						_keys[droppedIndex] = lastKey;
						_keyIndex[lastKey] = droppedIndex;
					}
					// update length of vector
					_keys.length--;
					// drop key from object mapping
					delete _keyIndex[key];

					changeDetected = true;
				}
			}

			if (changeDetected)
				updateSessionState();

			return changeDetected;
		}

		/**
		 * This function sets the session state for the KeySet.
		 * @param value A CSV-formatted String where each row is a keyType followed by a list of key strings of that keyType.
		 */		
		override public function setSessionState(value:Object):void
		{
			// backwards compatibility 0.9.6
			if (!(value is String) && !(value is Array) && value != null)
			{
				var keysProperty:String = 'sessionedKeys';
				var keyTypeProperty:String = 'sessionedKeyType';
				if (value.hasOwnProperty(keysProperty) && value.hasOwnProperty(keyTypeProperty))
					if (value[keyTypeProperty] != null && value[keysProperty] != null)
						value = WeaveAPI.CSVParser.createCSVToken(value[keyTypeProperty]) + ',' + value[keysProperty];
			}
			// backwards compatibility -- parse CSV
			if (value is String)
				value = WeaveAPI.CSVParser.parseCSV(value as String);
			
			// expecting a two-dimensional Array at this point
			// TODO: error checking?
			super.setSessionState(value);
		}
		
		//---------------------------------------------------------------------------------
		// test code
		// { test(); }
		private static function test():void
		{
			var k:KeySet = new KeySet();
			var k2:KeySet = new KeySet();
			k.addImmediateCallback(null, function():void { traceKeySet(k); });
			
			testFunction(k, k.replaceKeys, 'create k', 't', ['a','b','c'], 't', ['a', 'b', 'c']);
			testFunction(k, k.addKeys, 'add', 't', ['b','c','d','e'], 't', ['a','b','c','d','e']);
			testFunction(k, k.removeKeys, 'remove', 't', ['d','e','f','g'], 't', ['a','b','c']);
			testFunction(k, k.replaceKeys, 'replace', 't', ['b','x'], 't', ['b','x']);
			
			k2.replaceKeys(WeaveAPI.QKeyManager.getQKeys('t', ['a','b','x','y']));
			trace('copy k2 to k');
			copySessionState(k2, k);
			assert(k, WeaveAPI.QKeyManager.getQKeys('t', ['a','b','x','y']));
			
			trace('test deprecated session state');
			setSessionState(k, {sessionedKeyType: 't2', sessionedKeys: 'a,b,x,y'}, true);
			assert(k, WeaveAPI.QKeyManager.getQKeys('t2', ['a','b','x','y']));
			
			testFunction(k, k.replaceKeys, 'replace k', 't', ['1'], 't', ['1']);
			testFunction(k, k.addKeys, 'add k', 't2', ['1'], 't', ['1'], 't2', ['1']);
			testFunction(k, k.removeKeys, 'remove k', 't', ['1'], 't2', ['1']);
			testFunction(k, k.addKeys, 'add k', 't2', ['1'], 't2', ['1']);
			
			for each (var t:String in WeaveAPI.QKeyManager.getAllKeyTypes())
				trace('all keys ('+t+'):', getKeyStrings(WeaveAPI.QKeyManager.getAllQKeys(t)));
		}
		private static function getKeyStrings(qkeys:Array):Array
		{
			var keyStrings:Array = [];
			for each (var key:IQualifiedKey in qkeys)
				keyStrings.push(key.keyType + '#' + key.localName);
			return keyStrings;
		}
		private static function traceKeySet(keySet:KeySet):void
		{
			trace(' ->', getKeyStrings(keySet.keys));
			trace('   ', ObjectUtil.toString(getSessionState(keySet)));
		}
		private static function testFunction(keySet:KeySet, func:Function, comment:String, keyType:String, keys:Array, expectedResultKeyType:String, expectedResultKeys:Array, expectedResultKeyType2:String = null, expectedResultKeys2:Array = null):void
		{
			trace(comment, keyType, keys);
			func(WeaveAPI.QKeyManager.getQKeys(keyType, keys));
			var keys1:Array = expectedResultKeys ? WeaveAPI.QKeyManager.getQKeys(expectedResultKeyType, expectedResultKeys) : [];
			var keys2:Array = expectedResultKeys2 ? WeaveAPI.QKeyManager.getQKeys(expectedResultKeyType2, expectedResultKeys2) : [];
			assert(keySet, keys1, keys2);
		}
		private static function assert(keySet:KeySet, expectedKeys1:Array, expectedKeys2:Array = null):void
		{
			var qkey:IQualifiedKey;
			var qkeyMap:Dictionary = new Dictionary();
			for each (var keys:Array in [expectedKeys1, expectedKeys2])
			{
				for each (qkey in keys)
				{
					if (!keySet.containsKey(qkey))
						throw new Error("KeySet does not contain expected keys");
					qkeyMap[qkey] = true;
				}
			}
			
			for each (qkey in keySet.keys)
				if (qkeyMap[qkey] == undefined)
					throw new Error("KeySet contains unexpected keys");
		}
	}
}

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

package weave.data
{
	import flash.utils.getTimer;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.data.DataType;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IQualifiedKeyManager;
	import weave.flascc.stringHash;
	
	/**
	 * This class manages a global list of IQualifiedKey objects.
	 * 
	 * The getQKey() function must be used to get IQualifiedKey objects.  Each QKey returned by
	 * getQKey() with the same parameters will be the same object, so IQualifiedKeys can be compared
	 * with the == operator or used as keys in a Dictionary.
	 * 
	 * @author adufilie
	 */
	public final class QKeyManager implements IQualifiedKeyManager
	{
		/**
		 * Get the QKey object for a given key type and key.
		 *
		 * @return The QKey object for this type and key.
		 */
		public function getQKey(keyType:String, localName:String):IQualifiedKey
		{
			_keyBuffer[0] = localName;
			getQKeys_range(keyType, _keyBuffer, 0, 1, _keyBuffer);
			return _keyBuffer[0] as IQualifiedKey;
		}
		
		private const _keyBuffer:Array = []; // holds one key
		
		/**
		 * @param output An output Array or Vector for IQualifiedKeys.
		 */
		public function getQKeys_range(keyType:String, keyStrings:Array, iStart:uint, iEnd:uint, output:*):void
		{
			// if there is no keyType specified, use the default
			if (!keyType)
				keyType = DataType.STRING;
			
			// get mapping of key strings to QKey weak references
			var keyLookup:Object = _keys[keyType] as Object;
			if (keyLookup === null)
			{
				// key type not seen before, so initialize it
				keyLookup = {};
				_keys[keyType] = keyLookup;
			}
			
			for (var i:int = iStart; i < iEnd; i++)
			{
				var localName:* = keyStrings[i];
				var hash:int = stringHash(localName); // using stringHash improves lookup speed for a large number of strings
				var qkey:* = keyLookup[hash];
				if (qkey === undefined)
				{
					// QKey not created for this key yet (or it has been garbage-collected)
					qkey = new QKey(keyType, localName);
					keyLookup[hash] = qkey;
				}
				
				output[i] = qkey;
			}
		}
		
		/**
		 * Get a list of QKey objects, all with the same key type.
		 * 
		 * @return An array of QKeys.
		 */
		public function getQKeys(keyType:String, keyStrings:Array):Array
		{
			var keys:Array = new Array(keyStrings.length);
			getQKeys_range(keyType, keyStrings, 0, keyStrings.length, keys);
			return keys;
		}
		
		/**
		 * This will replace untyped Objects in an Array with their IQualifiedKey counterparts.
		 * Each object in the Array should have two properties: <code>keyType</code> and <code>localName</code>
		 * @param objects An Array to modify.
		 * @return The same Array that was passed in, modified.
		 */
		public function convertToQKeys(objects:Array):Array
		{
			var i:int = objects.length;
			while (i--)
			{
				var item:Object = objects[i];
				if (!(item is IQualifiedKey))
					objects[i] = getQKey(item.keyType, item.localName);
			}
			return objects;
		}

		/**
		 * Get a list of QKey objects, all with the same key type.
		 * 
		 * @return An array of QKeys that will be filled in asynchronously.
		 */
		public function getQKeysAsync(keyType:String, keyStrings:Array, relevantContext:Object, asyncCallback:Function, outputKeys:Vector.<IQualifiedKey>):void
		{
			new QKeyGetter(this, keyType, keyStrings, relevantContext, asyncCallback, outputKeys);
		}

		/**
		 * Get a list of all previoused key types.
		 *
		 * @return An array of QKeys.
		 */
		public function getAllKeyTypes():Array
		{
			var types:Array = [];
			for (var type:String in _keys)
				types.push(type);
			return types;
		}
		
		/**
		 * Get a list of all referenced QKeys for a given key type
		 * @return An array of QKeys
		 */
		public function getAllQKeys(keyType:String):Array
		{
			var qkeys:Array = [];
			for each (var qkey:IQualifiedKey in _keys[keyType])
				qkeys.push(qkey);
			return qkeys;
		}
		
		/**
		 * keyType -> Object( localName -> IQualifiedKey )
		 */
		private const _keys:Object = {};

		/**
		 * This will compare two keys.
		 * @param key1
		 * @param key2
		 * @return -1, 0, or 1
		 */		
		public static function keyCompare(key1:IQualifiedKey, key2:IQualifiedKey):int
		{
			return ObjectUtil.stringCompare(key1.keyType, key2.keyType)
				|| ObjectUtil.stringCompare(key1.localName, key2.localName);
		}
	}
}

/**
 * This class is internal to QKeyManager because instances
 * of QKey should not be instantiated outside QKeyManager.
 */
internal class QKey implements IQualifiedKey
{
	public function QKey(keyType:String, key:*)
	{
		_keyType = keyType;
		_localName = key;
	}
	
	private var _keyType:String; // namespace
	private var _localName:*; // localname/record identifier
	
	/**
	 * This is the namespace of the QKey.
	 */
	public function get keyType():String
	{
		return _keyType;
	}
	
	/**
	 * This is local record identifier in the namespace of the QKey.
	 */
	public function get localName():String
	{
		return _localName;
	}
	
	// This is a String containing both the namespace and the local name of the QKey
	//	public function toString():String
	//	{
	//		// The # sign is used in anticipation that a key type will be a URI.
	//		return _keyType + '#' + _key;
	//	}
}

import flash.utils.getTimer;

import weave.api.data.IQualifiedKey;
import weave.data.QKeyManager;

internal class QKeyGetter
{
	public function QKeyGetter(manager:QKeyManager, keyType:String, keyStrings:Array, relevantContext:Object, asyncCallback:Function, outputKeys:Vector.<IQualifiedKey>)
	{
		this.manager = manager;
		this.keyType = keyType;
		this.keyStrings = keyStrings;
		this.outputKeys = outputKeys;
		
		outputKeys.length = keyStrings.length;
		// high priority because all visualizations depend on key sets
		WeaveAPI.StageUtils.startTask(relevantContext, iterate, WeaveAPI.TASK_PRIORITY_HIGH, asyncCallback/*, lang("Initializing {0} record identifiers", keyStrings.length)*/);
	}
	
	private var i:int = 0;
	private var manager:QKeyManager;
	private var keyType:String;
	private var keyStrings:Array;
	private var outputKeys:Vector.<IQualifiedKey>;
	private const batch:uint = 5000;
	
	private function iterate(stopTime:int):Number
	{
		for (; i < keyStrings.length; i += batch)
		{
			if (getTimer() > stopTime)
				return i / keyStrings.length;
			
			manager.getQKeys_range(keyType, keyStrings, i, Math.min(i + batch, keyStrings.length), outputKeys);
		}
		return 1;
	}
}

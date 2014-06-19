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
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.DataTypes;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IQualifiedKeyManager;
	import weave.api.getCallbackCollection;
	
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
		private var _callbackCollection:ICallbackCollection = getCallbackCollection(this as ILinkableObject);
		
		/**
		 * Get the QKey object for a given key type and key.
		 *
		 * @return The QKey object for this type and key.
		 */
		public function getQKey(keyType:String, localName:String):IQualifiedKey
		{
			// if there is no keyType specified, use the default
			if (!keyType)
				keyType = DataTypes.STRING;
			
			// get mapping of key strings to QKey weak refrences
			var keyToQKeyRefMap:Object = _keyTypeMap[keyType] as Object;
			if (keyToQKeyRefMap == null)
			{
				// key type not seen before, so initialize it
				keyToQKeyRefMap = new Object();
				_keyTypeMap[keyType] = keyToQKeyRefMap;
			}
			
			// get QKey weak reference from key string
			var qkeyRef:Dictionary = keyToQKeyRefMap[localName] as Dictionary
			if (qkeyRef == null)
			{
				// Dictionary uses weak keys so QKey objects get garbage-collected
				qkeyRef = new Dictionary(true);
				keyToQKeyRefMap[localName] = qkeyRef;
			}
			
			// get QKey object from weak reference
			var qkey:QKey = null;
			for (var qkeyObj:* in qkeyRef)
				qkey = qkeyObj;
			
			if (qkey == null)
			{
				// QKey not created for this key yet (or it has been garbage-collected)
				qkey = new QKey(keyType, localName);
				qkeyRef[qkey] = null; //save weak reference
				
				// trigger callbacks whenever a new key is created
				_callbackCollection.triggerCallbacks();
			}
			
			return qkey;
		}
		
		/**
		 * Get a list of QKey objects, all with the same key type.
		 * 
		 * @return An array of QKeys.
		 */
		public function getQKeys(keyType:String, keyStrings:Array):Array
		{
			_callbackCollection.delayCallbacks();
			
			var i:int = keyStrings.length;
			var keys:Array = new Array(i);
			while (i--)
				keys[i] = getQKey(keyType, keyStrings[i]);
			
			_callbackCollection.resumeCallbacks();
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
			outputKeys.length = keyStrings.length;
			var i:int = 0;
			function iterate(stopTime:int):Number
			{
				for (; i < keyStrings.length; i++)
				{
					if (getTimer() > stopTime)
						return i / keyStrings.length;
					outputKeys[i] = getQKey(keyType, keyStrings[i]);
				}
				return 1;
			};
			WeaveAPI.StageUtils.startTask(relevantContext, iterate, WeaveAPI.TASK_PRIORITY_3_PARSING, asyncCallback);
		}

		/**
		 * Get a list of all previoused key types.
		 *
		 * @return An array of QKeys.
		 */
		public function getAllKeyTypes():Array
		{
			var types:Array = [];
			for (var type:String in _keyTypeMap)
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
			for each (var qkeyRef:Dictionary in _keyTypeMap[keyType])
				for (var qkey:* in qkeyRef)
					qkeys.push(qkey);
			return qkeys;
		}
		
		/**
		 * keyType -> Object( localName -> Dictionary( IQualifiedKey -> true ) )
		 */
		private const _keyTypeMap:Object = new Object();

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

import weave.api.data.IQualifiedKey;

/**
 * This class is internal to QKeyManager because instances
 * of QKey should not be instantiated outside QKeyManager.
 */
internal class QKey implements IQualifiedKey
{
	public function QKey(keyType:String, key:String)
	{
		_keyType = keyType;
		_localName = key;
	}

	private var _keyType:String; // namespace
	private var _localName:String; // localname/record identifier

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

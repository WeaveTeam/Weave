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
	import flash.utils.getQualifiedClassName;
	
	import mx.core.Singleton;
	
	import weave.core.weave_internal;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IQualifiedKeyManager;
	
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
			if (keyType == null)
				keyType = 'String';
			
//			// special case -- if keyType is null, return a unique QKey object
//			if (keyType == null)
//			{
//				_constructorOK = true;
//				var uniqueQKey:QKey = new QKey(null, key);
//				_constructorOK = false;
//				return uniqueQKey;
//			}
			
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
			var keys:Array = new Array(keyStrings.length);
			for (var i:int = 0; i < keyStrings.length; i++)
				keys[i] = getQKey(keyType, keyStrings[i]);
			return keys;
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
		
		// maps keyType to Object, which maps key String to QKey weak reference
		private const _keyTypeMap:Object = new Object();
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

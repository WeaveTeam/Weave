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

package weavejs.data.key
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.data.DataType;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.data.IQualifiedKeyManager;
	import weavejs.util.Dictionary2D;
	import weavejs.util.JS;
	import weavejs.util.StandardLib;
	import weavejs.util.WeavePromise;
	
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
		
		private var _keyBuffer:Array = []; // holds one key
		
		/**
		 * @param output An output Array for IQualifiedKeys.
		 */
		public function getQKeys_range(keyType:String, keyStrings:Array, iStart:uint, iEnd:uint, output:*):void
		{
			// if there is no keyType specified, use the default
			if (!keyType)
				keyType = DataType.STRING;
			
			// get mapping of key strings to QKey weak references
			var map_localName_qkey:Object = map_keyType_localName_qkey.map.get(keyType);
			if (!map_localName_qkey)
			{
				// key type not seen before, so initialize it
				map_localName_qkey = new JS.Map();
				map_keyType_localName_qkey.map.set(keyType, map_localName_qkey);
			}
			
			for (var i:int = iStart; i < iEnd; i++)
			{
				var localName:* = keyStrings[i];
				var qkey:* = map_localName_qkey.get(localName);
				if (qkey === undefined)
				{
					// QKey not created for this key yet (or it has been garbage-collected)
					qkey = new QKey(keyType, localName);
					map_localName_qkey.set(localName, qkey);
					map_qkey_keyType.set(qkey, keyType);
					map_qkey_localName.set(qkey, localName);
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
		public function getQKeysAsync(relevantContext:ILinkableObject, keyType:String, keyStrings:Array, asyncCallback:Function, outputKeys:Array):void
		{
			var qkg:QKeyGetter = map_context_qkeyGetter.get(relevantContext);
			if (!qkg)
				map_context_qkeyGetter.set(relevantContext, qkg = new QKeyGetter(this, relevantContext));
			qkg.asyncStart(keyType, keyStrings, outputKeys).then(function(..._):* { asyncCallback(); });
		}
		
		/**
		 * Get a list of QKey objects, all with the same key type.
		 * @param relevantContext The owner of the WeavePromise. Only one WeavePromise will be generated per owner.
		 * @param keyType The keyType.
		 * @param keyStrings An Array of localName values.
		 * @return A WeavePromise that produces an Array of IQualifiedKeys.
		 */
		public function getQKeysPromise(relevantContext:Object, keyType:String, keyStrings:Array):WeavePromise
		{
			var qkg:QKeyGetter = map_context_qkeyGetter.get(relevantContext);
			if (!qkg)
				map_context_qkeyGetter.set(relevantContext, qkg = new QKeyGetter(this, relevantContext));
			qkg.asyncStart(keyType, keyStrings);
			return qkg;
		}
		
		private var map_context_qkeyGetter:Object = new JS.WeakMap();

		/**
		 * Get a list of all previoused key types.
		 *
		 * @return An array of QKeys.
		 */
		public function getAllKeyTypes():Array
		{
			return map_keyType_localName_qkey.primaryKeys();
		}
		
		/**
		 * Get a list of all referenced QKeys for a given key type
		 * @return An array of QKeys
		 */
		public function getAllQKeys(keyType:String):Array
		{
			return JS.mapValues(map_keyType_localName_qkey.map.get(keyType));
		}
		
		/**
		 * keyType -> Object( localName -> IQualifiedKey )
		 */
		private var map_keyType_localName_qkey:Dictionary2D = new Dictionary2D();
		
		/**
		 * Maps IQualifiedKey to keyType - faster than reading the keyType property of a QKey
		 */
		public var map_qkey_keyType:Object = new JS.WeakMap();
		
		/**
		 * Maps IQualifiedKey to localName - faster than reading the localName property of a QKey
		 */
		public var map_qkey_localName:Object = new JS.WeakMap();

		/**
		 * This makes a sorted copy of an Array of keys.
		 * @param An Array of IQualifiedKeys.
		 * @return A sorted copy of the keys.
		 */
		public static function keySortCopy(keys:Array):Array
		{
			var qkm:QKeyManager = WeaveAPI.QKeyManager as QKeyManager;
			var params:Array = [qkm.map_qkey_keyType, qkm.map_qkey_localName];
			return StandardLib.sortOn(keys, params, null, false);
		}
	}
}

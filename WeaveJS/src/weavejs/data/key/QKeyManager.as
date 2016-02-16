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
	import weavejs.api.data.ICSVParser;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.api.data.IQualifiedKeyManager;
	import weavejs.data.CSVParser;
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
		public function QKeyManager()
		{
			// map_qkeyString_qkey corresponds to a null keyType
			map_qkeyString_qkey = new JS.Map();
			map_keyType_localName_qkey.map.set(null, map_qkeyString_qkey);
		}
		
		/**
		 * Maps IQualifiedKey to keyType - faster than reading the keyType property of a QKey
		 */
		public var map_qkey_keyType:/*/WeakMap<IQualifiedKey,string>/*/Object = new JS.WeakMap();
		
		/**
		 * Maps IQualifiedKey to localName - faster than reading the localName property of a QKey
		 */
		public var map_qkey_localName:/*/WeakMap<IQualifiedKey,string>/*/Object = new JS.WeakMap();
		
		/**
		 * keyType -> Object( localName -> IQualifiedKey )
		 */
		private var map_keyType_localName_qkey:Dictionary2D = new Dictionary2D();
		
		private var map_qkeyString_qkey:Object;

		private var map_context_qkeyGetter:Object = new JS.WeakMap();
		
		private var _keyBuffer:Array = []; // holds one key
		
		// The # sign is used in anticipation that a key type will be a URI.
		private static const DELIMITER:String = '#';
		private var csvParser:ICSVParser;
		private var array_numberToQKey:Array = [];
		
		public function stringToQKey(qkeyString:String):IQualifiedKey
		{
			var qkey:IQualifiedKey = map_qkeyString_qkey.get(qkeyString);
			if (qkey)
				return qkey;
			
			if (!csvParser)
				csvParser = new CSVParser(false, DELIMITER);
			var a:Array = csvParser.parseCSVRow(qkeyString);
			if (a.length != 2)
				throw new Error("qkeyString must be formatted like " + csvParser.createCSVRow(['keyType', 'localName']));
			return getQKey(a[0], a[1])
		}
		
		public function numberToQKey(qkeyNumber:Number):IQualifiedKey
		{
			return array_numberToQKey[qkeyNumber];
		}
		
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
		
		private function init_map_localName_qkey(keyType:String):Object
		{
			// key type not seen before, so initialize it
			var map_localName_qkey:Object = new JS.Map();
			map_keyType_localName_qkey.map.set(keyType, map_localName_qkey);
			return map_localName_qkey;
		}
		
		/**
		 * @param output An output Array for IQualifiedKeys.
		 */
		public function getQKeys_range(keyType:String, keyStrings:Array/*/<string>/*/, iStart:uint, iEnd:uint, output:Array/*/<IQualifiedKey>/*/):void
		{
			keyType = keyType == null ? null : String(keyType);
			
			// get mapping of key strings to QKey weak references
			var map_localName_qkey:Object = map_keyType_localName_qkey.map.get(keyType);
			if (!map_localName_qkey)
				map_localName_qkey = init_map_localName_qkey(keyType);
			
			if (!csvParser)
				csvParser = new CSVParser(false, DELIMITER);
			
			for (var i:int = iStart; i < iEnd; i++)
			{
				var localName:String = String(keyStrings[i]);
				var qkey:* = map_localName_qkey.get(localName);
				if (qkey === undefined)
				{
					// QKey not created for this key yet (or it has been garbage-collected)
					var qkeyString:String;
					if (keyType)
					{
						qkeyString = csvParser.createCSVRow([keyType, localName]);
					}
					else
					{
						qkeyString = localName;
					}
					var qkeyTyped:QKey = qkey = new QKey(keyType, localName, qkeyString);
					
					array_numberToQKey[qkeyTyped.toNumber()] = qkey;
					if (map_localName_qkey !== map_qkeyString_qkey)
						map_localName_qkey.set(localName, qkey);
					map_qkeyString_qkey.set(qkeyString, qkey);
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
		public function getQKeys(keyType:String, keyStrings:Array/*/<string>/*/):Array/*/<IQualifiedKey>/*/
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
		public function convertToQKeys(objects:Array/*/<{keyType:string, localName:string}>/*/):Array/*/<IQualifiedKey>/*/
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
		public function getQKeysAsync(relevantContext:ILinkableObject, keyType:String, keyStrings:Array/*/<string>/*/, asyncCallback:/*/(keys:IQualifiedKey[])=>void/*/Function, outputKeys:Array/*/<IQualifiedKey>/*/):void
		{
			var qkg:QKeyGetter = map_context_qkeyGetter.get(relevantContext);
			if (!qkg)
				map_context_qkeyGetter.set(relevantContext, qkg = new QKeyGetter(this, relevantContext));
			var promise:WeavePromise = qkg.asyncStart(keyType, keyStrings, outputKeys);
			if (asyncCallback != null)
				promise.then(asyncCallback);
		}
		
		/**
		 * Get a list of QKey objects, all with the same key type.
		 * @param relevantContext The owner of the WeavePromise. Only one WeavePromise will be generated per owner.
		 * @param keyType The keyType.
		 * @param keyStrings An Array of localName values.
		 * @return A WeavePromise that produces an Array of IQualifiedKeys.
		 */
		public function getQKeysPromise(relevantContext:Object, keyType:String, keyStrings:Array/*/<string>/*/):WeavePromise
		{
			var qkg:QKeyGetter = map_context_qkeyGetter.get(relevantContext);
			if (!qkg)
				map_context_qkeyGetter.set(relevantContext, qkg = new QKeyGetter(this, relevantContext));
			qkg.asyncStart(keyType, keyStrings);
			return qkg;
		}
		
		/**
		 * Get a list of all previoused key types.
		 *
		 * @return An array of QKeys.
		 */
		public function getAllKeyTypes():Array/*/<string>/*/
		{
			return map_keyType_localName_qkey.primaryKeys();
		}
		
		/**
		 * Get a list of all referenced QKeys for a given key type
		 * @return An array of QKeys
		 */
		public function getAllQKeys(keyType:String):Array/*/<IQualifiedKey>/*/
		{
			return JS.mapValues(map_keyType_localName_qkey.map.get(keyType));
		}
		
		/**
		 * This makes a sorted copy of an Array of keys.
		 * @param An Array of IQualifiedKeys.
		 * @return A sorted copy of the keys.
		 */
		public static function keySortCopy(keys:Array/*/<IQualifiedKey>/*/):Array/*/<IQualifiedKey>/*/
		{
			var qkm:QKeyManager = WeaveAPI.QKeyManager as QKeyManager;
			var params:Array = [qkm.map_qkey_keyType, qkm.map_qkey_localName];
			return StandardLib.sortOn(keys, params, null, false);
		}
	}
}

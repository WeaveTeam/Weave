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

package weave.data
{
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.DataType;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IQualifiedKeyManager;
	import weave.compiler.StandardLib;
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
				var hash:int = stringHash(localName, true); // using stringHash improves lookup speed for a large number of strings
				var qkey:* = keyLookup[hash];
				if (qkey === undefined)
				{
					// QKey not created for this key yet (or it has been garbage-collected)
					qkey = new QKey(keyType, localName);
					keyLookup[hash] = qkey;
					keyTypeLookup[qkey] = keyType;
					localNameLookup[qkey] = localName;
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
		public function getQKeysAsync(relevantContext:ILinkableObject, keyType:String, keyStrings:Array, asyncCallback:Function, outputKeys:Vector.<IQualifiedKey>):void
		{
			var qkg:QKeyGetter = _qkeyGetterLookup[relevantContext] as QKeyGetter;
			if (!qkg)
				_qkeyGetterLookup[relevantContext] = qkg = new QKeyGetter(this, relevantContext);
			qkg.asyncStart(keyType, keyStrings, asyncCallback, outputKeys);
		}
		
		private const _qkeyGetterLookup:Dictionary = new Dictionary(true);

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
		 * Maps IQualifiedKey to keyType - faster than reading the keyType property of a QKey
		 */
		public const keyTypeLookup:Dictionary = new Dictionary(true);
		
		/**
		 * Maps IQualifiedKey to localName - faster than reading the localName property of a QKey
		 */
		public const localNameLookup:Dictionary = new Dictionary(true);

		/**
		 * This makes a sorted copy of an Array of keys.
		 * @param An Array of IQualifiedKeys.
		 * @return A sorted copy of the keys.
		 */
		public static function keySortCopy(keys:Array):Array
		{
			var qkm:QKeyManager = WeaveAPI.QKeyManager as QKeyManager;
			var params:Array = [qkm.keyTypeLookup, qkm.localNameLookup];
			return StandardLib.sortOn(keys, params, null, false);
		}
	}
}

/**
 * This class is internal to QKeyManager because instances
 * of QKey should not be instantiated outside QKeyManager.
 */
internal class QKey implements IQualifiedKey
{
	public function QKey(keyType:String, localName:*)
	{
		kt = keyType;
		ln = localName;
	}
	
	private var kt:String;
	private var ln:*;
	
	/**
	 * This is the namespace of the QKey.
	 */
	public function get keyType():String
	{
		return kt;
	}
	
	/**
	 * This is local record identifier in the namespace of the QKey.
	 */
	public function get localName():String
	{
		return ln;
	}
	
	// This is a String containing both the namespace and the local name of the QKey
	//	public function toString():String
	//	{
	//		// The # sign is used in anticipation that a key type will be a URI.
	//		return kt + '#' + ln;
	//	}
}

import flash.utils.getTimer;

import weave.api.core.ILinkableObject;
import weave.api.data.IQualifiedKey;
import weave.api.detectLinkableObjectChange;
import weave.data.QKeyManager;

internal class QKeyGetter
{
	public function QKeyGetter(manager:QKeyManager, relevantContext:ILinkableObject)
	{
		this.manager = manager;
		this.relevantContext = relevantContext;
	}
	
	public function asyncStart(keyType:String, keyStrings:Array, asyncCallback:Function, outputKeys:Vector.<IQualifiedKey>):void
	{
		this.manager = manager;
		this.keyType = keyType;
		this.keyStrings = keyStrings;
		this.outputKeys = outputKeys;
		this.i = 0;
		this.asyncCallback = asyncCallback;
		
		outputKeys.length = keyStrings.length;
		// high priority because all visualizations depend on key sets
		WeaveAPI.StageUtils.startTask(relevantContext, iterate, WeaveAPI.TASK_PRIORITY_HIGH, asyncComplete, lang("Initializing {0} record identifiers", keyStrings.length));
	}
	
	private var asyncCallback:Function;
	private var i:int;
	private var manager:QKeyManager;
	private var relevantContext:ILinkableObject;
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
	
	private function asyncComplete():void
	{
		if (asyncCallback != null)
			asyncCallback();
	}
}

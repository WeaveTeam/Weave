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
	import mx.utils.object_proxy;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.DataTypes;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.api.data.IQualifiedKeyManager;
	import weave.api.getCallbackCollection;
	import weave.core.SessionManager;
	import weave.core.weave_internal;
	import weave.primitives.AttributeHierarchy;
	import weave.primitives.WeakReference;
	
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
			while (--i >= 0)
				keys[i] = getQKey(keyType, keyStrings[i]);
			
			_callbackCollection.resumeCallbacks();
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

		
		/**
		 * This object maps a keyType to an Array of related IColumnReference objects for key mapping purposes.
		 */
		private const keyType_to_refHash_Array:Object = new Object();
		
		/**
		 * This object maps a column reference hash value to an IColumnReference object that was previously registered.
		 * TODO: This is currently storing STRONG references to these objects. Refactor to WEAK?
		 */
		private const refHash_to_columnReference_Array:Object = new Object();
		
		/**
		 * This function should be called to register a column as a key mapping between two key types.
		 * @param column The column that maps keys of one key type to corresponding keys of another type.
		 */
		public function registerKeyMapping(columnReference:IColumnReference):void
		{
			// get the keyType(domain) and dataType(range) from the reference and store a lookup from those types to the IColumnReference.
			var keyType:String = columnReference.getMetadata(AttributeColumnMetadata.KEY_TYPE);
			var dataType:String = columnReference.getMetadata(AttributeColumnMetadata.DATA_TYPE);
			// make sure the referenced column is actually a key mapping
			if (!keyType || !dataType ||
				dataType == DataTypes.STRING ||
				dataType == DataTypes.NUMBER ||
				dataType == DataTypes.GEOMETRY)
			{
				return; // this reference is not a key mapping
			}
			
			// now we know it's a useful reference, so let's save a pointer to the reference
				
			// first, check for an equivalent column reference that was previously registered
			var refHash:String = columnReference.getHashCode();
			if (refHash_to_columnReference_Array[refHash] != undefined)
			{
				// there are already existing equivalent references, so append to the array
				(refHash_to_columnReference_Array[refHash] as Array).push(columnReference);
			}
			else
			{
				// there are no existing equivalent references, so create a new array
				refHash_to_columnReference_Array[refHash] = [columnReference];
			}
			
			// save a mapping from keyType and dataType to the refHash, so from that we can get the IColumnReference.
			for each (var type:String in [keyType, dataType])
			{
				var refList:Array = keyType_to_refHash_Array[type] as Array;
				if (!refList) // none registered yet
					keyType_to_refHash_Array[type] = [refHash]; // create new
				else
					refList.push(refHash); // append
			}
			
			_callbackCollection.triggerCallbacks();
		}
		
		/**
		 * This function returns an Array of IColumnReference objects that refer to columns that provide a mapping from one key type to another.
		 * @param sourceKeyType The desired input key type.
		 * @param destinationKeyType The desired output key type.
		 * @return An Array of IColumnReference objects that refer to columns that provide a mapping from the source key type to the destination key type.
		 */
		public function getKeyMappings(sourceKeyType:String, destinationKeyType:String):Array
		{
			// TODO: column references need to be registered using this function
			
			
			
			
			var refList:Array = getCompatibleColumnReferences(sourceKeyType);
			// remove incompatible refs from the list
			for (var i:int = refList.length - 1; i >= 0; i--)
				if ((refList[i] as IColumnReference).getMetadata(AttributeColumnMetadata.DATA_TYPE) != destinationKeyType)
					refList.splice(i, 1);
			return refList;
		}
		
		/**
		 * This function returns an array of key types (Strings) for which there exist mappings to or from the given key type.
		 * @param keyType A key type.
		 * @return A list of compatible types.
		 */		
		public function getCompatibleKeyTypes(keyType:String):Array
		{
			var typesLookup:Object = {}; // keyType -> true, used to eliminate duplicates
			var refList:Array = getCompatibleColumnReferences(keyType);
			var ref:IColumnReference;
			for each (ref in refList)
			{
				typesLookup[ref.getMetadata(AttributeColumnMetadata.KEY_TYPE)] = true;
				typesLookup[ref.getMetadata(AttributeColumnMetadata.DATA_TYPE)] = true;
			}
			var typesList:Array = [];
			for (var type:String in typesLookup)
				typesList.push(type);
			return typesList;
		}
			
		/**
		 * This function returns IColumnReferences that refer to key mappings to or from a given keyType.
		 * @param keyType A keyType.
		 * @return  An Array of IColumnReference objects that are compatible with the given keyType.
		 */		
		private function getCompatibleColumnReferences(keyType:String):Array
		{
			var hashList:Array = keyType_to_refHash_Array[keyType] as Array || [];
			var refList:Array = [];
			for each (var hash:String in hashList)
			{
				var refsForThisHash:Array = refHash_to_columnReference_Array[hash] as Array;
				for (var i:int = refsForThisHash.length - 1; i >= 0; i--)
				{
					var ref:IColumnReference = refsForThisHash[i] as IColumnReference;
					// if the ref is no longer valid, throw it away
					if ((WeaveAPI.SessionManager as SessionManager).objectWasDisposed(ref))
					{
						refsForThisHash.splice(i, 1);
					}
					else
					{
						refList.push(ref);
						break;
					}
				}
			}
			return refList;
		}
		// TODO: note that if the column references are modified, this code just breaks.
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

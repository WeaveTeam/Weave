/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.data
{
	import weave.api.core.ILinkableObject;

	/**
	 * This class manages a global list of IQualifiedKey objects.
	 * 
	 * The getQKey() function must be used to get IQualifiedKey objects.  Each QKey returned by
	 * getQKey() with the same parameters will be the same object, so IQualifiedKeys can be compared
	 * with the == operator or used as keys in a Dictionary.
	 * 
	 * The callbacks for this class should be triggered whenever a new key is created.
	 * 
	 * @author adufilie
	 */
	public interface IQualifiedKeyManager extends ILinkableObject
	{
		/**
		 * Get the QKey object for a given key type and key.
		 *
		 * @return The QKey object for this type and key.
		 */
		function getQKey(keyType:String, localName:String):IQualifiedKey;
		
		/**
		 * Get a list of QKey objects, all with the same key type.
		 * 
		 * @return An array of QKeys.
		 */
		function getQKeys(keyType:String, keyStrings:Array):Array;

		/**
		 * Get a list of all previoused key types.
		 *
		 * @return An array of QKeys.
		 */
		function getAllKeyTypes():Array;

		/**
		 * Get a list of all referenced QKeys for a given key type
		 * @return An array of QKeys
		 */
		function getAllQKeys(keyType:String):Array;
		
		/**
		 * This function should be called to register a column as a key mapping between two key types.
		 * @param column A reference to the column that maps keys of one key type to corresponding keys of another type.
		 */
		function registerKeyMapping(column:IColumnReference):void;
		
		/**
		 * This function returns an Array of IColumnReference objects that refer to columns that provide a mapping from one key type to another.
		 * @param sourceKeyType The desired input key type.
		 * @param destinationKeyType The desired output key type.
		 * @return An Array of IColumnReference objects that refer to columns that provide a mapping from the source key type to the destination key type.
		 */
		function getKeyMappings(sourceKeyType:String, destinationKeyType:String):Array;
		
		/**
		 * This function returns an array of key types (Strings) for which there exist mappings to or from the given key type.
		 * @param keyType A key type.
		 * @return A list of compatible types.
		 */		
		function getCompatibleKeyTypes(keyType:String):Array;
	}
}

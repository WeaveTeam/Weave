/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
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

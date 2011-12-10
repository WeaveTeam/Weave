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
	import weave.api.core.ICallbackCollection;

	/**
	 * IAttributeColumn
	 * This is an interface to a mapping of keys to data values.
	 * 
	 * @author adufilie
	 */
	public interface IAttributeColumn extends ICallbackCollection, IKeySet
	{
		/**
		 * This function gets metadata associated with the column.
		 * For standard metadata property names, refer to the AttributeColumnMetadata class.
		 * @param propertyName The name of the metadata property to retrieve.
		 * @result The value of the specified metadata property.
		 */
		function getMetadata(propertyName:String):String;
		
		//TODO: need a function for listing available metadata property names
		
		/**
		 * This function gets a value associated with a record key.
		 * @param key A record key.
		 * @return The value associated with the given record key.
		 */
		function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*;
	}
}

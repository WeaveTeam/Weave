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

package weave.api.ui
{
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;

	/**
	 * This is an interface for the implementations of specialized spatial index classes which
	 * provide more accurate results using computational geometry algorithms.
	 * 
	 * @author kmonico
	 */
	public interface ISpatialIndexImplementation
	{
		/**
		 * This function will cache the key inside the implementation.
		 *  
		 * @param key The IQualifiedKey object to cache.
		 */		
		function cacheKey(key:IQualifiedKey):void;
		
		/**
		 * This function will return the data bounds associated with the key.
		 *  
		 * @param key The IQualifiedKey to find.
		 * @return The data bounds associated with the key. 
		 */				
		function getBoundsFromKey(key:IQualifiedKey):Array;
		
		/**
		 * This function will iterate through the keys and determine which keys contain the center of the bounds object.
		 *  
		 * @param bounds The bounds to use for checking.
		 * @param stopOnFirstFind If this is <code>true</code>, this function will return at most 1 key. Otherwise it will return all keys which contain the point.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of IQualifiedKey objects which contain the center of the bounds object.
		 */		
		function getKeysContainingBoundsCenter(bounds:IBounds2D, stopOnFirstFind:Boolean = true, xPrecision:Number = NaN, yPrecision:Number = NaN):Array;
		
		/**
		 * This function will iterate through the keys and determine which keys overlap the bounds object.
		 *  
		 * @param bounds The bounds to use for checking.
		 * @param xPrecision If specified, X distance values will be divided by this and truncated before comparing.
		 * @param yPrecision If specified, Y distance values will be divided by this and truncated before comparing.
		 * @return An array of IQualifiedKey objects which contain the center of the bounds object.
		 */		
		function getKeysOverlappingBounds(bounds:IBounds2D, xPrecision:Number = NaN, yPrecision:Number = NaN):Array;

		/**
		 * Set the keys source for the index.
		 * 
		 * @param keys An array of IQualifiedKey objects.
		 */
		function setKeySource(keys:Array):void;
		
		/**
		 * Insert a key into the index with the bounds as its lookup.
		 *
		 * @param bounds The bounds used to insert this key.
		 * @param key The key to insert.
		 */
		function insertKey(bounds:IBounds2D, key:IQualifiedKey):void;
	
		/**
		 * Get the keys for this index. 
		 * 
		 * @return An array of IQualifiedKey objects. 
		 */		
		function getKeys():Array;
		
		/**
		 * Return the number of keys in this index.
		 * 
		 * @return The number of keys in the index. 
		 */		
		function getRecordCount():int;
		
		/**
		 * Clear the KDTree in the index.
		 */
		function clearTree():void;
		
		/**
		 * Get a value indicating whether this index's tree has autobalance enabled or disabled.
		 * 
		 * @return True if the KDTree has autobalancing and false otherwise.
		 */		
		function getAutoBalance():Boolean;
	}
}
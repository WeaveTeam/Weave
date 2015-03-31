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

package weave.utils
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	/**
	 * This class is a wrapper for a weak reference to an object.
	 * See the documentation for the Dictionary class for more info about weak references.
	 * 
	 * @author adufilie
	 */	
	public class WeakReference
	{
		public function WeakReference(value:Object = null)
		{
			this.value = value;
		}

		/**
		 * A weak reference to an object.
		 */
		public function get value():Object
		{
			for (var key:* in dictionary)
				return key;
			return null;
		}
		public function set value(newValue:Object):void
		{
			for (var key:* in dictionary)
			{
				// do nothing if value didn't change
				if (key === newValue)
					return;
				delete dictionary[key];
			}
			if (newValue != null)
			{
				/*
					TEMPORARY SOLUTION for garbage-collection bug:
					https://bugs.adobe.com/jira/browse/FP-5372
					https://bugs.adobe.com/jira/browse/FP-5860
					Until this bug is fixed, Functions must have strong references.
				*/
				if (newValue is Function && getQualifiedClassName(newValue) != 'Function')
					dictionary[newValue] = newValue; // change to null when flash player bug is fixed
				else
					dictionary[newValue] = null;
			}
		}

		/**
		 * The reference is stored as a key in this Dictionary, which uses the weakKeys option.
		 */
		private var dictionary:Dictionary = new Dictionary(true);
	}
}

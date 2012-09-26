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

package weave.utils
{
	import avmplus.getQualifiedClassName;
	
	import flash.utils.Dictionary;

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
		public function set value(value:Object):void
		{
			for (var key:* in dictionary)
				delete dictionary[key];
			if (value != null)
			{
				/*
					TEMPORARY SOLUTION for garbage-collection bug:
					https://bugs.adobe.com/jira/browse/FP-5372
					https://bugs.adobe.com/jira/browse/FP-5860
					Until this bug is fixed, Functions must have strong references.
				*/
				if (value is Function && getQualifiedClassName(value) != 'Function')
					dictionary[value] = value; // change to null when flash player bug is fixed
				else
					dictionary[value] = null;
			}
		}

		/**
		 * The reference is stored as a key in this Dictionary, which uses the weakKeys option.
		 */
		private var dictionary:Dictionary = new Dictionary(true);
	}
}

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

package org.oicweave.utils
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import org.oicweave.core.ClassUtils;
	
	/**
	 * This class contains static functions for pooling reusable objects.  The purpose of this class
	 * is to avoid unnecessary garbage-collection activity that slows performance.  It is recommended
	 * that you only use this class for simple, reusable objects that do not contain pointers to other
	 * objects. Use this class with care to prevent memory leaks.
	 * 
	 * @author adufilie
	 */
	public class ObjectPool
	{
		/**
		 * This Dictionary maps a Class definition to a Dictionary whose keys are instances of that class.
		 * A Dictionary is used instead of an Array to avoid having multiple pointers to the same object.
		 */
		private static const pool:Dictionary = new Dictionary();
		
		/**
		 * This function asks the pool for an object with the intention of returning it when it is no longer needed.
		 * Be aware that an object from the pool may have values set 
		 * @param objectType The type of object that you want to get from the pool.
		 * @return An object of the requested type from the pool, or a new one if the pool is empty.
		 */
		public static function borrowObject(objectType:Class):*
		{
			for (var object:* in pool[objectType])
			{
				delete pool[objectType][object];
				return object;
			}
			return new objectType();
		}
		
		/**
		 * This function tells the ObjectPool that an object is no longer in use and it can go back into
		 * the pool so some other code can use it.  This function should only be used on objects that you
		 * are sure no other code is still using.  Also, any object you pass in here should not contain any
		 * pointers to other objects. If your code never uses borrowObject(), there is no reason to call
		 * returnObject().  If returnObject() is called more often than borrowObject(), that is basically
		 * a memory leak.
		 * @param object A simple reusable object that is no longer in use.
		 */		
		public static function returnObject(object:Object):void
		{
			var objectType:Class = ClassUtils.getClassDefinition(getQualifiedClassName(object)) as Class;
			if (pool[objectType] == undefined)
				pool[objectType] = new Dictionary();
			pool[objectType][object] = null;
		}
	}
}

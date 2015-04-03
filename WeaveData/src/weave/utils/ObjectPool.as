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
		private static const pool:Dictionary = new Dictionary(true);
		
		/**
		 * This function asks the pool for an object with the intention of returning it when it is no longer needed.
		 * Be aware that an object from the pool may have values set 
		 * @param objectType The type of object that you want to get from the pool.
		 * @return An object of the requested type from the pool, or a new one if the pool is empty.
		 */
		public static function borrowObject(objectType:Class):*
		{
			var objects:Array = pool[objectType] as Array;
			if (objects && objects.length)
			{
				var object:* = objects.pop();
				pool[object] = false; // set flag to remember we don't have this object anymore
				return object;
			}
			return new objectType();
		}
		
		/**
		 * This function tells the ObjectPool that an object is no longer in use and it can go back into
		 * the pool so some other code can use it.  This function should only be used on objects that you
		 * are sure no other code is still using.  Also, any object you pass in here should not contain any
		 * pointers to other objects. If your code never uses borrowObject(), there is no reason to call
		 * returnObject().  An Error will be thrown if returnObject() is called more than once on the same object
		 * before it is returned from borrowObject() in order to alert the developer that the code is misbehaving.
		 * If this Error is ignored, unexpected results may occur similar to a buffer overflow because multiple
		 * parts of the code may end up using the same object.
		 * @param object A simple reusable object that is no longer in use.
		 */		
		public static function returnObject(object:Object):void
		{
			// stop if the object was already returned (this will prevent returning the same object twice from borrowObject)
			if (pool[object])
			{
				// It's important to know when this occurs because if it does, most likely some code is incorrect.
				// If this is ignored, the code will seem to behave randomly if the same object is being used for multiple purposes.
				// Make sure when returnObject() is called that any code using the object clears all references to it.
				throw new Error("object was passed to returnObject() more times than necessary");
			}
			
			var objectType:Class = Object(object).constructor; //ClassUtils.getClassDefinition(getQualifiedClassName(object)) as Class;
			var objects:Array = pool[objectType] as Array;
			if (!objects)
				pool[objectType] = objects = [];
			objects.push(object);
			// set flag to remember that this object is in the pool
			pool[object] = true;
		}
	}
}

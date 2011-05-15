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

package org.oicweave.core
{
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.describeType;
	
	import mx.controls.SWFLoader;

	/**
	 * ClassUtils
	 * This is an all-static class containing functions related to qualified class names.
	 * 
	 * @author adufilie
	 */
	public class ClassUtils
	{
		/**
		 * This function gets a Class definition for a qualified class name.
		 * @param classQName The qualified name of a class.
		 * @return The class definition, or null if the class cannot be resolved.
		 */
		public static function getClassDefinition(classQName:String):Class
		{
			var domain:ApplicationDomain = ApplicationDomain.currentDomain;
			if (domain.hasDefinition(classQName))
				return domain.getDefinition(classQName) as Class;
			return null;
		}

		/**
		 * This function loads a SWF library into the current ApplicationDomain so getClassDefinition() and getDefinitionByName() can get its class definitions.
		 * @param source Either the URL to a SWF or a ByteArray containing the SWF to load.
		 * @param callback The function to call when the SWF is finished loading.
		 * @param callbackParams Optional parameters to pass to the callback function.
		 */
		public static function loadSWF(source:Object, callback:Function, callbackParams:Array = null):void
		{
			var loader:SWFLoader = new SWFLoader();
			// loading the plugin in the same ApplicationDomain allows getDefinitionByName() to return results from the plugin.
			loader.loaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
			loader.load(source);
			loader.addEventListener(
				Event.COMPLETE,
				function(e:Event):void
				{
					callback.apply(null, callbackParams);
				}
			);
		}

		/**
		 * @param classQName A qualified class name.
		 * @param implementsQName A qualified interface name.
		 * @return true if the class implements the interface, or if the two QNames are equal.
		 */
		public static function classImplements(classQName:String, implementsQName:String):Boolean
		{
			if (classQName == implementsQName)
				return true;
			try {
				if (!cacheClassInfo(classQName))
					return false;
				return classImplementsMap[classQName][implementsQName] != undefined;
			} catch (e:Error) { trace(e.getStackTrace()); }
			return false;
		}
		/**
		 * @param classQName A qualified class name of a class in question.
		 * @param extendsQName A qualified class name that the class specified by classQName may extend.
		 * @return true if clasQName extends extendsQName, or if the two QNames are equal.
		 */
		public static function classExtends(classQName:String, extendsQName:String):Boolean
		{
			if (classQName == extendsQName)
				return true;
			try {
				if (!cacheClassInfo(classQName))
						return false;
				return classExtendsMap[classQName][extendsQName] != undefined;
			} catch (e:Error) { trace(e.getStackTrace()); }
			return false;
		}
		/**
		 * @param classQName A qualified class name.
		 * @param isQName A qualified class or interface name.
		 * @return true if classQName extends or implements isQName, or if the two QNames are equal.
		 */
		public static function classIs(classQName:String, isQName:String):Boolean
		{
			return classImplements(classQName, isQName) || classExtends(classQName, isQName);
		}
		
		/**
		 * This maps a qualified class name to an object.
		 * For each interface the class implements, the object maps the qualified class name of the interface to a value of true.
		 */
		private static const classImplementsMap:Object = new Object();
		/**
		 * This maps a qualified class name to an object.
		 * For each interface the class extends, the object maps the qualified class name of the interface to a value of true.
		 */
		private static const classExtendsMap:Object = new Object();
		/**
		 * This function will populate the classImplementsMap and classExtendsMap for the given qualified class name.
		 * @param classQName A qualified class name.
		 * @return true if the class info has been cached.
		 */
		private static function cacheClassInfo(classQName:String):Boolean
		{
			if (classImplementsMap[classQName] != undefined && classExtendsMap[classQName] != undefined)
				return true; // already cached
			
			var classDef:Class = getClassDefinition(classQName);
			if (classDef == null)
				return false;
			var type:XML = describeType(classDef);

			var iMap:Object = new Object();
			for each (var i:XML in type.factory.implementsInterface)
				iMap[i.attribute("type").toString()] = true;
			classImplementsMap[classQName] = iMap;

			var eMap:Object = new Object();
			for each (var e:XML in type.factory.extendsClass)
				eMap[e.attribute("type").toString()] = true;
			classExtendsMap[classQName] = eMap;
			
			return true; // successfully cached
		}
	}
}

/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.core
{
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableDynamicObject;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILinkableObject;

	/**
	 * Represents an object that must be instantiated asynchronously.
	 */
	public class LinkablePlaceholder/*/<T extends ILinkableObject>/*/ extends LinkableVariable
	{
		public function LinkablePlaceholder(classDef:/*/new(..._:any[])=>T/*/Class)
		{
			this.classDef = classDef;
			_bypassDiff = classDef === LinkableVariable || classDef.prototype is LinkableVariable;
		}
		
		private var classDef:Class;
		private var instance:ILinkableObject;
		
		public function getClass():/*/new(..._:any[])=>T/*/Class
		{
			return classDef;
		}
		
		public function getInstance():/*/T & ILinkableObject/*/ILinkableObject
		{
			return instance;
		}
		
		public function setInstance(instance:/*/T/*/ILinkableObject):void
		{
			if (Weave.wasDisposed(this))
				throw new Error("LinkablePlaceholder was already disposed");
			
			if (!(instance is classDef))
				throw new Error("Unexpected object type");
			
			replace(this, instance);
			
			this.instance = instance;
		}
		
		/**
		 * @return success flag
		 */
		private static function replace(oldObject:ILinkableObject, newObject:ILinkableObject):void
		{
			var owner:ILinkableObject = Weave.getOwner(oldObject);
			var lhm:ILinkableHashMap = owner as ILinkableHashMap;
			var ldo:ILinkableDynamicObject = owner as ILinkableDynamicObject;
			if (!lhm && !ldo)
				throw new Error("Unable to replace object because owner is not an ILinkableHashMap or ILinkableDynamicObject");
			
			var ownerCC:ICallbackCollection = Weave.getCallbacks(owner);
			ownerCC.delayCallbacks();
			try
			{
				var sessionState:Object = Weave.getState(oldObject);
				if (lhm)
					lhm.setObject(lhm.getName(oldObject), newObject);
				else if (ldo)
					ldo.target = newObject;
				Weave.setState(newObject, sessionState);
			}
			finally
			{
				ownerCC.resumeCallbacks();
			}
		}
		
		/**
		 * A utility function for getting the class definition from LinkablePlaceholders as well as regular objects.
		 * @param object An object, which may be null.
		 * @return The class definition, or null if the object was null.
		 */
		public static function getClass(object:/*/ILinkableObject | LinkablePlaceholder<ILinkableObject>/*/Object):/*/new(..._:any[])=>ILinkableObject/*/Class
		{
			var placeholder:LinkablePlaceholder = object as LinkablePlaceholder;
			if (placeholder)
				return placeholder.getClass();
			if (object)
				return object.constructor;
			return null;
		}
		
		/**
		 * Replaces a LinkablePlaceholder with an instance of the expected type.
		 * @param possiblePlaceholder A LinkablePlaceholder or the instance object if it has already been placed.
		 * @param instance An instance of the type of object that the placeholder is expecting.
		 */
		public static function setInstance(possiblePlaceholder:ILinkableObject, instance:ILinkableObject):void
		{
			// stop if instance has already been placed
			if (possiblePlaceholder === instance)
				return;
			
			var placeholder:LinkablePlaceholder = possiblePlaceholder as LinkablePlaceholder;
			if (!placeholder)
				throw new Error("Attempted to put an instance where there was no placeholder for it.");
			
			placeholder.setInstance(instance);
		}
		
		public static function replaceInstanceWithPlaceholder(instance:ILinkableObject):void
		{
			if (instance is LinkablePlaceholder || Weave.wasDisposed(instance))
				return;
			
			var placeholder:LinkablePlaceholder = new LinkablePlaceholder(getClass(instance));
			try
			{
				replace(instance, placeholder);
			}
			catch (e:Error)
			{
				Weave.dispose(placeholder);
				throw e;
			}
		}
	}
}

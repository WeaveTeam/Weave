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
	public class LinkablePlaceholder extends LinkableVariable
	{
		public function LinkablePlaceholder(classDef:Class)
		{
			this.classDef = classDef;
		}
		
		private var classDef:Class;
		private var instance:ILinkableObject;
		
		public function getClass():Class
		{
			return classDef;
		}
		
		public function getInstance():ILinkableObject
		{
			return instance;
		}
		
		public function setInstance(instance:ILinkableObject):void
		{
			if (Weave.wasDisposed(this))
				throw new Error("LinkablePlaceholder was already disposed");
			
			var owner:ILinkableObject = Weave.getOwner(this);
			var lhm:ILinkableHashMap = owner as ILinkableHashMap;
			var ldo:ILinkableDynamicObject = owner as ILinkableDynamicObject;
			if (!lhm && !ldo)
				throw new Error("Unable to replace LinkablePlaceholder with instance because owner is not an ILinkableHashMap or ILinkableDynamicObject");
			
			var ownerCC:ICallbackCollection = Weave.getCallbacks(owner);
			ownerCC.delayCallbacks();
			
			this.instance = instance;
			var sessionState:Object = this.state;
			if (lhm)
				lhm.setObject(lhm.getName(this), instance);
			else if (ldo)
				ldo.target = instance;
			Weave.setState(instance, sessionState);
			
			ownerCC.resumeCallbacks();
		}
		
		/**
		 * A utility function for getting the class definition from LinkablePlaceholders as well as regular objects.
		 * @param object An object, which may be null.
		 * @return The class definition, or null if the object was null.
		 */
		public static function getClass(object:Object):Class
		{
			var placeholder:LinkablePlaceholder = object as LinkablePlaceholder;
			if (placeholder)
				return placeholder.getClass();
			if (object)
				return object.constructor;
			return null;
		}
	}
}

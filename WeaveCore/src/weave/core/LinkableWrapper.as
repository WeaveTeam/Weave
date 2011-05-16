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

package weave.core
{
	import flash.utils.getQualifiedClassName;
	
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObjects;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	
	/**
	 * This is a wrapper for a dynamically created object that does not have to implement ILinkableObject.
	 * 
	 * @author adufilie
	 */
	public class LinkableWrapper extends CallbackCollection implements ILinkableObject
	{
		public function LinkableWrapper(typeRestriction:Class = null)
		{
			WeaveXMLDecoder.includePackages(typeRestriction);
			_typeRestrictionQName = getQualifiedClassName(typeRestriction);
			addImmediateCallback(this, handleSessionStateChange);
		}
		
		public const objectType:LinkableString = newLinkableChild(this, LinkableString);
		public const properties:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable);
		
		private var _typeRestrictionQName:String = null; // restriction on the type of object that can be generated
		private var _generatedObject:Object = null; // returned by public getter
		
		/**
		 * This is the object that was generated from the session state.
		 */
		public function get generatedObject():*
		{
			return _generatedObject;
		}

		/**
		 * This function will update the generatedObject using the current session state.
		 */
		private function handleSessionStateChange():void
		{
			try
			{
				var newType:Class = WeaveXMLDecoder.getClassDefinition(objectType.value);
				if (_typeRestrictionQName == null || ClassUtils.classIs(getQualifiedClassName(newType), _typeRestrictionQName))
				{
					_generatedObject = updateObject(_generatedObject, newType, properties.value);
					properties.value = _generatedObject;
				}
				else
				{
					_generatedObject = null;
				}
			}
			catch (e:Error)
			{
				ErrorManager.reportError(e);
			}
		}

		/**
		 * This updates an existing object, changing the type if necessary and setting the properties.
		 * @param object The existing object to update.
		 * @param newType The desired object type.
		 * @param newProperties The new values for the properties of the object.
		 * @return The existing object or a new one of the desired type.
		 */
		private function updateObject(object:Object, newType:Class, newProperties:Object):Object
		{
			// update the type of object if necessary
			if (newType == null)
			{
				disposeObjects(object);
				return null;
			}
			if (!(object is newType))
			{
				disposeObjects(object);
				object = new newType();
				if (object is ILinkableObject)
					registerLinkableChild(this, object as ILinkableObject);
			}
			// update the properties
			for (var name:String in newProperties)
			{
				if (object.hasOwnProperty(name))
				{
					object[name] = newProperties[name];
				}
			}
			return object;
		}
	}
}

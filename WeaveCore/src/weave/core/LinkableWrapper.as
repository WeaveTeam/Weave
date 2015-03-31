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

package weave.core
{
	import flash.utils.getQualifiedClassName;
	
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObject;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	
	/**
	 * This is a wrapper for a dynamically created object that does not have to implement ILinkableObject.
	 * 
	 * @author adufilie
	 */
	[ExcludeClass]
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
				var typeQName:String = WeaveXMLDecoder.getClassName(objectType.value)
				if (_typeRestrictionQName == null || ClassUtils.classIs(typeQName, _typeRestrictionQName))
				{
					var newType:Class = ClassUtils.getClassDefinition(typeQName);
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
				reportError(e);
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
				disposeObject(object);
				return null;
			}
			if (!(object is newType))
			{
				disposeObject(object);
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

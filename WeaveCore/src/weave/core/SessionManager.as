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
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableCompositeObject;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableVariable;
	import weave.api.core.ISessionManager;
	import weave.api.reportError;
	import weave.compiler.StandardLib;

	use namespace weave_internal;

	/**
	 * This is a collection of core functions in the Weave session framework.
	 * 
	 * @author adufilie
	 */
	public class SessionManager implements ISessionManager
	{
		/**
		 * This function will create a new instance of the specified child class and register it as a child of the parent.
		 * If a callback function is given, the callback will be added to the child and cleaned up when the parent is disposed of.
		 * 
		 * Example usage:   public const foo:LinkableNumber = newLinkableChild(this, LinkableNumber, handleFooChange);
		 * 
		 * @param linkableParent A parent ILinkableObject to create a new child for.
		 * @param linkableChildType The class definition that implements ILinkableObject used to create the new child.
		 * @param callback A callback with no parameters that will be added to the child that will run before the parent callbacks are triggered, or during the next ENTER_FRAME event if a grouped callback is used.
		 * @param useGroupedCallback If this is true, addGroupedCallback() will be used instead of addImmediateCallback().
		 * @return The new child object.
		 */
		public function newLinkableChild(linkableParent:Object, linkableChildType:Class, callback:Function = null, useGroupedCallback:Boolean = false):*
		{
			if (!(linkableParent is ILinkableObject))
				throw new Error("newLinkableChild(): Parent does not implement ILinkableObject.");
			
			var childQName:String = getQualifiedClassName(linkableChildType);
			if (!ClassUtils.classImplements(childQName, ILinkableObjectQualifiedClassName))
				throw new Error("newLinkableChild(): Child class does not implement ILinkableObject.");
			
			var linkableChild:ILinkableObject = new linkableChildType() as ILinkableObject;
			return registerLinkableChild(linkableParent, linkableChild, callback, useGroupedCallback);
		}
		
		/**
		 * This function tells the SessionManager that the session state of the specified child should appear in the
		 * session state of the specified parent, and the child should be disposed of when the parent is disposed.
		 * 
		 * There is one other requirement for the child session state to appear in the parent session state -- the child
		 * must be accessible through a public variable of the parent or through an accessor function of the parent.
		 * 
		 * This function will add callbacks to the sessioned children that cause the parent callbacks to run.
		 * 
		 * If a callback function is given, the callback will be added to the child and cleaned up when the parent is disposed of.
		 * 
		 * Example usage:   public const foo:LinkableNumber = registerLinkableChild(this, someLinkableNumber, handleFooChange);
		 * 
		 * @param linkableParent A parent ILinkableObject that the child will be registered with.
		 * @param linkableChild The child ILinkableObject to register as a child.
		 * @param callback A callback with no parameters that will be added to the child that will run before the parent callbacks are triggered, or during the next ENTER_FRAME event if a grouped callback is used.
		 * @param useGroupedCallback If this is true, addGroupedCallback() will be used instead of addImmediateCallback().
		 * @return The linkableChild object that was passed to the function.
		 */
		public function registerLinkableChild(linkableParent:Object, linkableChild:ILinkableObject, callback:Function = null, useGroupedCallback:Boolean = false):*
		{
			if (!(linkableParent is ILinkableObject))
				throw new Error("registerLinkableChild(): Parent does not implement ILinkableObject.");
			if (!(linkableChild is ILinkableObject))
				throw new Error("registerLinkableChild(): Child does not implement ILinkableObject.");
			if (linkableParent == linkableChild)
				throw new Error("registerLinkableChild(): Invalid attempt to register sessioned property having itself as its parent");
			
			// add a callback that will be cleaned up when the parent is disposed of.
			// add this callback BEFORE registering the child, so this callback triggers first.
			if (callback != null)
			{
				var cc:ICallbackCollection = getCallbackCollection(linkableChild);
				if (useGroupedCallback)
					cc.addGroupedCallback(linkableParent as ILinkableObject, callback);
				else
					cc.addImmediateCallback(linkableParent as ILinkableObject, callback);
			}
			
			// if the child doesn't have an owner yet, this parent is the owner of the child
			// and the child should be disposed when the parent is disposed.
			// registerDisposedChild() also initializes the required Dictionaries.
			registerDisposableChild(linkableParent, linkableChild);

			// only continue if the child is not already registered with the parent
			if (childToParentDictionaryMap[linkableChild][linkableParent] === undefined)
			{
				// remember this child-parent relationship
				childToParentDictionaryMap[linkableChild][linkableParent] = true;
				parentToChildDictionaryMap[linkableParent][linkableChild] = true;
				
				// make child changes trigger parent callbacks
				var parentCC:ICallbackCollection = getCallbackCollection(linkableParent as ILinkableObject);
				// set alwaysCallLast=true for triggering parent callbacks, so parent will be triggered after all the other child callbacks
				getCallbackCollection(linkableChild).addImmediateCallback(linkableParent, parentCC.triggerCallbacks, null, false, true); // parent-child relationship
			}

			return linkableChild;
		}
		
		/**
		 * This function will create a new instance of the specified child class and register it as a child of the parent.
		 * The child will be disposed when the parent is disposed.
		 * 
		 * Example usage:   public const foo:LinkableNumber = newDisposableChild(this, LinkableNumber);
		 * 
		 * @param disposableParent A parent ILinkableObject to create a new child for.
		 * @param disposableChildType The class definition that implements ILinkableObject used to create the new child.
		 * @return The new child object.
		 */
		public function newDisposableChild(disposableParent:Object, disposableChildType:Class):*
		{
			return registerDisposableChild(disposableParent, new disposableChildType());
		}
		
		/**
		 * This will register a child of a parent and cause the child to be disposed when the parent is disposed.
		 * If the child already has a registered owner, this function has no effect.
		 * 
		 * Example usage:   public const foo:LinkableNumber = registerDisposableChild(this, someLinkableNumber);
		 * 
		 * @param disposableParent A parent disposable object that the child will be registered with.
		 * @param disposableChild The disposable object to register as a child of the parent.
		 * @return The linkableChild object that was passed to the function.
		 */
		public function registerDisposableChild(disposableParent:Object, disposableChild:Object):*
		{
			// if this parent has no owner-to-child mapping, initialize it now with parent-to-child mapping
			if (ownerToChildDictionaryMap[disposableParent] === undefined)
			{
				ownerToChildDictionaryMap[disposableParent] = new Dictionary(true); // weak links to be GC-friendly
				parentToChildDictionaryMap[disposableParent] = new Dictionary(true); // weak links to be GC-friendly
			}
			// if this child has no owner yet...
			if (childToOwnerMap[disposableChild] === undefined)
			{
				// make this first parent the owner
				childToOwnerMap[disposableChild] = disposableParent;
				ownerToChildDictionaryMap[disposableParent][disposableChild] = true;
				// initialize the parent dictionary for this child
				childToParentDictionaryMap[disposableChild] = new Dictionary(true); // weak links to be GC-friendly
			}
			return disposableChild;
		}
		
		/**
		 * Use this function with care.  This will remove child objects from the session state of a parent and
		 * stop the child from triggering the parent callbacks.
		 * @param parent A parent that the specified child objects were previously registered with.
		 * @param child The child object to unregister from the parent.
		 */
		weave_internal function unregisterLinkableChild(parent:ILinkableObject, child:ILinkableObject):void
		{
			removeLinkableChildFromSessionState(parent, child);
			getCallbackCollection(child).removeCallback(getCallbackCollection(parent).triggerCallbacks);
		}
		
		/**
		 * This function will add or remove child objects from the session state of a parent.  Use this function
		 * with care because the child will no longer be "sessioned."  The child objects will continue to trigger the
		 * callbacks of the parent object, but they will no longer be considered a part of the parent's session state.
		 * If you are not careful, this will break certain functionalities that depend on the session state of the parent.
		 * @param parent A parent that the specified child objects were previously registered with.
		 * @param child The child object to remove from the session state of the parent.
		 */
		public function removeLinkableChildFromSessionState(parent:ILinkableObject, child:ILinkableObject):void
		{
			if (parent == null || child == null)
			{
				reportError("SessionManager.removeLinkableChildrenFromSessionState(): Parameters to this function cannot be null.");
				return;
			}
			if (childToParentDictionaryMap[child] !== undefined)
				delete childToParentDictionaryMap[child][parent];
			if (parentToChildDictionaryMap[parent] !== undefined)
				delete parentToChildDictionaryMap[parent][child];
		}
		
		/**
		 * This function will return all the child objects that have been registered with a parent.
		 * @param parent A parent object to get the registered children of.
		 * @return An Array containing a list of linkable objects that have been registered as children of the specified parent.
		 *         This list includes all children that have been registered, even those that do not appear in the session state.
		 */
		weave_internal function getRegisteredChildren(parent:ILinkableObject):Array
		{
			var result:Array = [];
			if (parentToChildDictionaryMap[parent] !== undefined)
				for (var key:* in parentToChildDictionaryMap[parent])
					result.push(key);
			return result;
		}

		/**
		 * This function gets the owner of a linkable object.  The owner of an object is defined as its first registered parent.
		 * @param child An ILinkableObject that was registered as a child of another ILinkableObject.
		 * @return The owner of the child object (the first parent that was registered with the child), or null if the child has no owner.
		 */
		public function getLinkableOwner(child:ILinkableObject):ILinkableObject
		{
			return childToOwnerMap[child] as ILinkableObject;
		}

		/**
		 * This function checks if a parent-child relationship exists between two ILinkableObjects
		 * and the child appears in the session state of the parent.
		 * @param parent A suspected parent object.
		 * @param child A suspected child object.
		 * @return true if the child is registered as a child of the parent.
		 */
		weave_internal function isChildInSessionState(parent:ILinkableObject, child:ILinkableObject):Boolean
		{
			return childToParentDictionaryMap[child] !== undefined && childToParentDictionaryMap[child][parent];
		}
		
		/**
		 * This function will copy the session state from one sessioned object to another.
		 * If the two objects are of different types, the behavior of this function is undefined.
		 * @param source A sessioned object to copy the session state from.
		 * @param source A sessioned object to copy the session state to.
		 */
		public function copySessionState(source:ILinkableObject, destination:ILinkableObject):void
		{
			var sessionState:Object = getSessionState(source);
			setSessionState(destination, sessionState, true);
		}

		/**
		 * @param linkableObject An object containing sessioned properties (sessioned objects may be nested).
		 * @param newState An object containing the new values for sessioned properties in the sessioned object.
		 * @param removeMissingDynamicObjects If true, this will remove any properties from an ILinkableCompositeObject that do not appear in the session state.
		 */
		public function setSessionState(linkableObject:ILinkableObject, newState:Object, removeMissingDynamicObjects:Boolean = true):void
		{
			if (linkableObject == null)
			{
				reportError("SessionManager.setSessionState(): linkableObject cannot be null.");
				return;
			}

			// special cases:
			if (linkableObject is ILinkableVariable)
			{
				var lv:ILinkableVariable = linkableObject as ILinkableVariable;
				if (removeMissingDynamicObjects == false && newState && getQualifiedClassName(newState) == 'Object')
				{
					// apply diff
					var oldState:Object = lv.getSessionState();
					for (var key:String in newState)
					{
						var value:Object = newState[key];
						//if (typeof(value) == 'object')
						//	todo: recursive call
						//else
						oldState[key] = value;
					}
					lv.setSessionState(oldState);
				}
				else
				{
					lv.setSessionState(newState);
				}
				return;
			}
			if (linkableObject is ILinkableCompositeObject)
			{
				(linkableObject as ILinkableCompositeObject).setSessionState(newState as Array, removeMissingDynamicObjects);
				return;
			}

			if (newState == null)
				return;

			// delay callbacks before setting session state
			var objectCC:ICallbackCollection = getCallbackCollection(linkableObject);
			objectCC.delayCallbacks();

			// set session state
			var name:String;
			for each (name in getLinkablePropertyNames(linkableObject))
			{
				if (!newState.hasOwnProperty(name))
					continue;
				
				var property:ILinkableObject = null;
				try
				{
					property = linkableObject[name] as ILinkableObject;
				}
				catch (e:Error)
				{
					trace('SessionManager.setSessionState(): Unable to get property "'+name+'" of class "'+getQualifiedClassName(linkableObject)+'"',e.getStackTrace());
				}

				if (property == null)
					continue;

				// skip this property if it was not registered as a linkable child of the sessionedObject.
				if (childToParentDictionaryMap[property] === undefined || childToParentDictionaryMap[property][linkableObject] === undefined)
					continue;
					
				setSessionState(property, newState[name], removeMissingDynamicObjects);
			}
			
			// pass deprecated session state to deprecated setters
			for each (name in getDeprecatedSetterNames(linkableObject))
				if (newState.hasOwnProperty(name))
					linkableObject[name] = newState[name];
			
			// resume callbacks after setting session state
			objectCC.resumeCallbacks();
		}
		
		/**
		 * @param linkableObject An object containing sessioned properties (sessioned objects may be nested).
		 * @return An object containing the values from the sessioned properties.
		 */
		public function getSessionState(linkableObject:ILinkableObject):Object
		{
			if (linkableObject == null)
			{
				reportError("SessionManager.getSessionState(): linkableObject cannot be null.");
				return null;
			}
			
			var result:Object = internalGetSessionState(linkableObject, new Dictionary(true));
			//trace("getSessionState " + getQualifiedClassName(sessionedObject).split("::")[1] + ObjectUtil.toString(result));
			return result;
		}
		
		/**
		 * This function is for internal use only.
		 * @param sessionedObject An object containing sessioned properties (sessioned objects may be nested).
		 * @param ignoreList A dictionary that keeps track of which objects this function has already traversed.
		 * @return An object containing the values from the sessioned properties.
		 */
		private function internalGetSessionState(sessionedObject:ILinkableObject, ignoreList:Dictionary):Object
		{
			// use ignore list to prevent infinite recursion
			ignoreList[sessionedObject] = true;
			
			// special cases (explicit session state)
			if (sessionedObject is ILinkableVariable)
				return (sessionedObject as ILinkableVariable).getSessionState();
			if (sessionedObject is ILinkableCompositeObject)
				return (sessionedObject as ILinkableCompositeObject).getSessionState();

			// implicit session state
			// first pass: get property names
			var propertyNames:Array = getLinkablePropertyNames(sessionedObject);
			var resultNames:Array = [];
			var resultProperties:Array = [];
			var property:ILinkableObject = null;
			var i:int;
			//trace("getting session state for "+getQualifiedClassName(sessionedObject),"propertyNames="+propertyNames);
			for (i = 0; i < propertyNames.length; i++)
			{
				var name:String = propertyNames[i];
				try
				{
					property = null; // must set this to null first because accessing the property may fail
					property = sessionedObject[name] as ILinkableObject;
				}
				catch (e:Error)
				{
					trace('SessionManager.internalGetSessionState(): Unable to get property "'+name+'" of class "'+getQualifiedClassName(sessionedObject)+'"',e.getStackTrace());
				}
				// first pass: set result[name] to the ILinkableObject
				if (property != null && ignoreList[property] === undefined)
				{
					// skip this property if it was not registered as a linkable child of the sessionedObject.
					if (childToParentDictionaryMap[property] === undefined || childToParentDictionaryMap[property][sessionedObject] === undefined)
						continue;
					// only include this property in the session state once
					ignoreList[property] = true;
					resultNames.push(name);
					resultProperties.push(property);
				}
				else
				{
					//trace("skipped property",name,property,ignoreList[property]);
				}
			}
			// special case if there are no child objects
			if (resultNames.length == 0)
				return null;
			// second pass: get values from property names
			var result:Object = new Object();
			for (i = 0; i < resultNames.length; i++)
			{
				var value:Object = internalGetSessionState(resultProperties[i], ignoreList);
				property = resultProperties[i] as ILinkableObject;
				// do not include objects that have a null implicit session state (no child objects)
				if (value == null && !(property is ILinkableVariable) && !(property is ILinkableCompositeObject))
					continue;
				result[resultNames[i]] = value;
				//trace("getState",getQualifiedClassName(sessionedObject),resultNames[i],result[resultNames[i]]);
			}
			return result;
		}
		
		/**
		 * This maps a qualified class name to an Array of names of sessioned properties contained in that class.
		 */
		private const classNameToSessionedPropertyNamesMap:Object = new Object();
		/**
		 * This maps a qualified class name to an Array of names of deprecated setter functions contained in that class.
		 */
		private const classNameToDeprecatedSetterNamesMap:Object = new Object();

		/**
		 * This function will return all the descendant objects that implement ILinkableObject.
		 * If the filter parameter is specified, the results will contain only those objects that extend or implement the filter class.
		 * @param root A root object to get the descendants of.
		 * @param filter An optional Class definition which will be used to filter the results.
		 * @return An Array containing a list of descendant objects.
		 */
		public function getLinkableDescendants(root:ILinkableObject, filter:Class = null):Array
		{
			if (root == null)
			{
				reportError("SessionManager.getDescendants(): root cannot be null.");
				return [];
			}

			var result:Array = [];
			internalGetDescendants(result, root, filter, new Dictionary(true), int.MAX_VALUE);
			// don't include root object
			if (result.length > 0 && result[0] == root)
				result.shift();
			return result;
		}
		private function internalGetDescendants(output:Array, root:ILinkableObject, filter:Class, ignoreList:Dictionary, depth:int):void
		{
			if (root == null || ignoreList[root] !== undefined)
				return;
			ignoreList[root] = true;
			if (filter == null || root is filter)
				output.push(root);
			if (--depth <= 0)
				return;
			
			var object:ILinkableObject;
			var names:Array;
			var name:String;
			var i:int;
			if (root is ILinkableDynamicObject)
			{
				object = (root as ILinkableDynamicObject).internalObject;
				internalGetDescendants(output, object, filter, ignoreList, depth);
			}
			else if (root is ILinkableHashMap)
			{
				names = (root as ILinkableHashMap).getNames();
				var objects:Array = (root as ILinkableHashMap).getObjects();
				for (i = 0; i < names.length; i++)
				{
					name = names[i] as String;
					object = objects[i] as ILinkableObject;
					internalGetDescendants(output, object, filter, ignoreList, depth);
				}
			}
			else
			{
				names = getLinkablePropertyNames(root);
				for (i = 0; i < names.length; i++)
				{
					name = names[i] as String;
					object = root[name] as ILinkableObject;
					internalGetDescendants(output, object, filter, ignoreList, depth);
				}
			}
		}
		
		/**
		 * @private
		 */
		weave_internal function getDeprecatedSetterNames(linkableObject:ILinkableObject):Array
		{
			if (linkableObject == null)
			{
				reportError("SessionManager.getDeprecatedSetterNames(): linkableObject cannot be null.");
				return [];
			}
			
			var className:String = getQualifiedClassName(linkableObject);
			var names:Array = classNameToDeprecatedSetterNamesMap[className] as Array;
			if (names == null)
			{
				names = [];
				for each (var tag:XML in describeType(linkableObject).accessor.(@access != "readonly"))
					if (tag.metadata.(@name == "Deprecated").length() > 0)
						names.push(tag.attribute("name"));
				names.sort();
				classNameToDeprecatedSetterNamesMap[className] = names;
			}
			return names;
		}

		/**
		 * This function gets a list of sessioned property names so accessor functions for non-sessioned properties do not have to be called.
		 * @param linkableObject An object containing sessioned properties.
		 * @return An Array containing the names of the sessioned properties of that object class.
		 */
		weave_internal function getLinkablePropertyNames(linkableObject:ILinkableObject):Array
		{
			if (linkableObject == null)
			{
				reportError("SessionManager.getLinkablePropertyNames(): linkableObject cannot be null.");
				return [];
			}

			var className:String = getQualifiedClassName(linkableObject);
			var propertyNames:Array = classNameToSessionedPropertyNamesMap[className] as Array;
			if (propertyNames == null)
			{
				propertyNames = [];
				// iterate over the public properties, saving the names of the ones that implement ILinkableObject
				var xml:XML = describeType(linkableObject);
				//trace(xml.toXMLString());
				for each (var tags:XMLList in [xml.constant, xml.variable, xml.accessor.(@access != "writeonly")])
				{
					for each (var tag:XML in tags)
					{
						// Only include this property name if it implements ILinkableObject.
						if (ClassUtils.classImplements(tag.attribute("type"), ILinkableObjectQualifiedClassName))
						{
							var propName:String = tag.attribute("name").toString();
							propertyNames.push(propName);
						}
					}
				}
				propertyNames.sort();
				classNameToSessionedPropertyNamesMap[className] = propertyNames;
			}
			return propertyNames;
		}
		// qualified class name of ILinkableObject
		internal static const ILinkableObjectQualifiedClassName:String = getQualifiedClassName(ILinkableObject);
		
		/**
		 * This maps a parent ILinkableObject to a Dictionary, which maps each child ILinkableObject it owns to a value of true.
		 */
		private const ownerToChildDictionaryMap:Dictionary = new Dictionary(true); // use weak links to be GC-friendly
		/**
		 * This maps a child ILinkableObject to its registered owner.
		 */
		private const childToOwnerMap:Dictionary = new Dictionary(true); // use weak links to be GC-friendly
		/**
		 * This maps a child ILinkableObject to a Dictionary, which maps each of its registered parent ILinkableObjects to a value of true.
		 * Example: childToParentDictionaryMap[child][parent] == true
		 */
		private const childToParentDictionaryMap:Dictionary = new Dictionary(true); // use weak links to be GC-friendly
		/**
		 * This maps a parent ILinkableObject to a Dictionary, which maps each of its registered child ILinkableObjects to a value of true.
		 * Example: parentToChildDictionaryMap[parent][child] == true
		 */
		private const parentToChildDictionaryMap:Dictionary = new Dictionary(true); // use weak links to be GC-friendly
		/**
		 * This maps an ILinkableObject to a ICallbackCollection associated with it.
		 */
		private const linkableObjectToCallbackCollectionMap:Dictionary = new Dictionary(true); // use weak links to be GC-friendly

		/**
		 * This function gets the ICallbackCollection associated with an ILinkableObject.
		 * If there is no ICallbackCollection defined for the object, one will be created.
		 * This ICallbackCollection is used for reporting changes in the session state
		 * @param linkableObject An ILinkableObject to get the associated ICallbackCollection for.
		 * @return The ICallbackCollection associated with the given object.
		 */
		public function getCallbackCollection(linkableObject:ILinkableObject):ICallbackCollection
		{
			if (linkableObject == null)
				return null;
			
			if (linkableObject is ICallbackCollection)
				return linkableObject as ICallbackCollection;
			
			var objectCC:ICallbackCollection = linkableObjectToCallbackCollectionMap[linkableObject] as ICallbackCollection;
			if (objectCC == null)
			{
				objectCC = new CallbackCollection();
				linkableObjectToCallbackCollectionMap[linkableObject] = objectCC;
				
				// Make sure UIComponents get registered with linkable owners because MXML developers
				// may forget to do so, since it's not simple or intuitive in MXML.
				if (linkableObject is UIComponent)
				{
					var component:UIComponent = linkableObject as UIComponent;
					if (!_registerUIComponent(component))
						component.addEventListener(Event.ADDED, _registerUIComponentListener);
				}
			}
			return objectCC;
		}
		
		/**
		 * This function is an event listener that in turn calls _registerUIComponent.
		 * @param event The event dispatched by the UIComponent to be passed to _registerUIComponent.
		 */
		private function _registerUIComponentListener(event:Event):void
		{
			if (event.target == event.currentTarget)
			{
				var component:UIComponent = event.currentTarget as UIComponent;
				if (_registerUIComponent(component))
					component.removeEventListener(event.type, _registerUIComponentListener, event.eventPhase == EventPhase.CAPTURING_PHASE);
			}
		}
		
		/**
		 * This function will register a UIComponent/ILinkableObject as a disposable child of an ancestral
		 * DisplayObjectContainer/ILinkableObject if it has no linkable owner yet.  This makes sure that the
		 * component is disposed of when its ancestor is disposed of.
		 * @param linkableComponent A UIComponent that implements ILinkableObject.
		 * @return true if the component has a linkable owner, either before or after this function is called.
		 */
		private function _registerUIComponent(linkableComponent:UIComponent):Boolean
		{
			if (objectWasDisposed(linkableComponent))
			{
				reportError('UIComponent running event listener after being disposed');
				return true; // so the event listener will be removed
			}
			var owner:ILinkableObject = childToOwnerMap[linkableComponent] as ILinkableObject;
			if (owner == null)
			{
				var parent:DisplayObjectContainer = linkableComponent.parent;
				while (parent)
				{
					if (parent is ILinkableObject)
					{
						registerDisposableChild(parent, linkableComponent);
						return true; // component has a linkable owner now
					}
					parent = parent.parent;
				}
				return false; // component does not have a linkable owner yet
			}
			return true; // component already has a linkable owner
		}

		/**
		 * This function is used to detect if callbacks of a linkable object were triggered since the last time detectLinkableObjectChange
		 * was called with the same parameters, likely by the observer.  Note that once this function returns true, subsequent calls will
		 * return false until the callbacks are triggered again, unless clearChangedNow is set to false.  It may be a good idea to specify
		 * a private object as the observer so no other code can call detectLinkableObjectChange with the same observer and linkableObject
		 * parameters.
		 * @param observer The object that is observing the change.
		 * @param linkableObject The object that is being observed.
		 * @param clearChangedNow If this is true, the trigger counter will be reset to the current value now so that this function will
		 *        return false if called again with the same parameters before the next time the linkable object triggers its callbacks.
		 * @return A value of true if the callbacks have triggered since the last time this function was called with the given parameters.
		 */
		public function detectLinkableObjectChange(observer:Object, linkableObject:ILinkableObject, clearChangedNow:Boolean = true):Boolean
		{
			if (!_triggerCounterMap[linkableObject])
				_triggerCounterMap[linkableObject] = new Dictionary(false); // weakKeys=false to allow observers to be Functions
			
			var previousCount:* = _triggerCounterMap[linkableObject][observer]; // untyped to handle undefined value
			var newCount:uint = getCallbackCollection(linkableObject).triggerCounter;
			if (previousCount !== newCount) // no casting to handle 0 !== undefined
			{
				if (clearChangedNow)
					_triggerCounterMap[linkableObject][observer] = newCount;
				return true;
			}
			return false;
		}
		
		/**
		 * This is a two-dimensional dictionary, where _triggerCounterMap[linkableObject][observer]
		 * equals the previous triggerCounter value from linkableObject observed by the observer.
		 */		
		private const _triggerCounterMap:Dictionary = new Dictionary(true);

		/**
		 * This function checks if an object has been disposed of by the ISessionManager.
		 * @param object An object to check.
		 * @return A value of true if disposeObjects() was called for the specified object.
		 */
		public function objectWasDisposed(object:Object):Boolean
		{
			if (object == null)
				return false;
			if (object is ILinkableObject)
			{
				var cc:CallbackCollection = getCallbackCollection(object as ILinkableObject) as CallbackCollection;
				if (cc)
					return cc.wasDisposed;
			}
			return _disposedObjectsMap[object] !== undefined;
		}
		
		private const _disposedObjectsMap:Dictionary = new Dictionary(true); // weak keys to be gc-friendly
		
		private static const DISPOSE:String = "dispose"; // this is the name of the dispose() function.

		/**
		 * This function should be called when an ILinkableObject or IDisposableObject is no longer needed.
		 * @param object An ILinkableObject or an IDisposableObject to clean up.
		 * @param moreObjects More objects to clean up.
		 */
		public function disposeObjects(object:Object, ...moreObjects):void
		{
			if (object != null && !_disposedObjectsMap[object])
			{
				_disposedObjectsMap[object] = true;
				
				try
				{
					// if the object implements IDisposableObject, call its dispose() function now
					if (object is IDisposableObject)
					{
						(object as IDisposableObject).dispose();
					}
					else if (object.hasOwnProperty(DISPOSE))
					{
						// call dispose() anyway if it exists, because it is common to forget to implement IDisposableObject.
						object[DISPOSE]();
					}
				}
				catch (e:Error)
				{
					reportError(e);
				}
				
				var linkableObject:ILinkableObject = object as ILinkableObject;
				if (linkableObject)
				{
					// dispose of the callback collection corresponding to the object.
					// this removes all callbacks, including the one that triggers parent callbacks.
					var objectCC:ICallbackCollection = getCallbackCollection(linkableObject);
					if (objectCC != linkableObject)
						disposeObjects(objectCC);
					
					// unregister from parents
					if (childToParentDictionaryMap[linkableObject] !== undefined)
					{
						// remove the parent-to-child mappings
						for (var parent:Object in childToParentDictionaryMap[linkableObject])
							if (parentToChildDictionaryMap[parent] !== undefined)
								delete parentToChildDictionaryMap[parent][linkableObject];
						// remove child-to-parent mapping
						delete childToParentDictionaryMap[linkableObject];
					}
		
					// unregister from owner
					var owner:ILinkableObject = childToOwnerMap[linkableObject] as ILinkableObject;
					if (owner != null)
					{
						if (ownerToChildDictionaryMap[owner] !== undefined)
							delete ownerToChildDictionaryMap[owner][linkableObject];
						delete childToOwnerMap[linkableObject];
					}
		
					// if the object is an ILinkableVariable, unlink it from all bindable properties that were previously linked
					if (linkableObject is ILinkableVariable)
						for (var bindableParent:* in _watcherMap[linkableObject])
							for (var bindablePropertyName:String in _watcherMap[linkableObject][bindableParent])
								unlinkBindableProperty(linkableObject as ILinkableVariable, bindableParent, bindablePropertyName);
					
					// unlink this object from all other linkable objects
					if (linkedObjectsDictionaryMap[linkableObject] !== undefined)
						for (var otherObject:Object in linkedObjectsDictionaryMap[linkableObject])
							unlinkSessionState(linkableObject, otherObject as ILinkableObject);
					
					// dispose of all registered children that this object owns
					var children:Dictionary = ownerToChildDictionaryMap[linkableObject] as Dictionary;
					if (children != null)
					{
						// clear the pointers to the child dictionaries for this object
						delete ownerToChildDictionaryMap[linkableObject];
						delete parentToChildDictionaryMap[linkableObject];
						// dispose of the children this object owned
						for (var child:Object in children)
							disposeObjects(child);
					}
					
					// FOR DEBUGGING PURPOSES
					if (Capabilities.isDebugger)
						objectCC.addImmediateCallback(null, debugDisposedObject, [linkableObject, new Error("Object was disposed")]);
				}
				
				var displayObject:DisplayObject = object as DisplayObject;
				if (displayObject)
				{
					// remove this DisplayObject from its parent
					var parentContainer:DisplayObjectContainer = displayObject.parent;
					try
					{
						if (parentContainer && parentContainer == displayObject.parent)
							parentContainer.removeChild(displayObject);
					}
					catch (e:Error)
					{
						// an error may occur if removeChild() is called twice.
					}
					parentContainer = displayObject as DisplayObjectContainer;
					if (parentContainer)
					{
						// Removing all children fixes errors that may occur in the next
						// frame related to callLaterDispatcher and validateDisplayList.
						while (parentContainer.numChildren > 0)
						{
							try {
								parentContainer.removeChildAt(parentContainer.numChildren - 1);
							} catch (e:Error) { }
						}
					}
					if (displayObject is UIComponent)
						(displayObject as UIComponent).mx_internal::cancelAllCallLaters();
				}
			}
			
			// dispose of the remaining specified objects
			for (var i:int = 0; i < moreObjects.length; i++)
				disposeObjects(moreObjects[i]);
		}
		
		// FOR DEBUGGING PURPOSES
		private function debugDisposedObject(disposedObject:ILinkableObject, disposedError:Error):void
		{
			// set some variables to aid in debugging
			var obj:* = disposedObject;
			var ownerPath:Array = []; while (obj = getLinkableOwner(obj)) { ownerPath.unshift(obj); }
			var parents:Array = []; for (obj in childToParentDictionaryMap[disposedObject] || []) { parents.push[obj]; }
			var children:Array = []; for (obj in parentToChildDictionaryMap[disposedObject] || []) { children.push[obj]; }
			var sessionState:Object = getSessionState(disposedObject);

			var msg:String = "Disposed object still running callbacks: " + getQualifiedClassName(disposedObject);
			if (disposedObject is ILinkableVariable)
				msg += ' (value = ' + (disposedObject as ILinkableVariable).getSessionState() + ')';
			reportError(disposedError);
			reportError(msg);
		}

//		public function getOwnerPath(root:ILinkableObject, descendant:ILinkableObject):Array
//		{
//			var result:Array = [];
//			while (descendant && root != descendant)
//			{
//				var owner:ILinkableObject = getOwner(descendant);
//				if (!owner)
//					break;
//				var name:String = getChildPropertyName(parent as ILinkableObject, descendant);
//			}
//			return result;
//		}
		
		/**
		 * This function is for debugging purposes only.
		 */
		private function getPaths(root:ILinkableObject, descendant:ILinkableObject):Array
		{
			var results:Array = [];
			for (var parent:Object in childToParentDictionaryMap[descendant])
			{
				var name:String;
				if (parent is ILinkableHashMap)
					name = (parent as ILinkableHashMap).getName(descendant);
				else
					name = getChildPropertyName(parent as ILinkableObject, descendant);
				
				if (name != null)
				{
					// this parent may be the one we want
					var result:Array = getPaths(root, parent as ILinkableObject);
					if (result != null)
					{
						result.push(name);
						results.push(result);
					}
				}
			}
			if (results.length == 0)
				return root == null ? results : null;
			return results;
		}

		/**
		 * internal use only
		 */
		private function getChildPropertyName(parent:ILinkableObject, child:ILinkableObject):String
		{
			// find the property name that returns the child
			for each (var name:String in getLinkablePropertyNames(parent))
				if (parent[name] == child)
					return name;
			return null;
		}
		
		/**
		 * internal use only
		 * @param child A sessioned object to return siblings for.
		 * @param filter A Class to filter by (results will only include objects that are of this type).
		 * @return An Array of ILinkableObjects having the same parent of the given child.
		 */
//		private function getSiblings(child:ILinkableObject, filter:Class = null):Array
//		{
//			// if this child has no parents, it has no siblings.
//			if (childToParentDictionaryMap[child] === undefined)
//				return [];
//			
//			var owner:ILinkableObject = getOwner(child);
//			
//			// get all the children of this owner, minus the given child
//			var siblings:Array = [];
//			for (var sibling:Object in ownerToChildDictionaryMap[owner])
//				if (sibling != child && (filter == null || sibling is filter))
//					siblings.push(sibling);
//			return siblings;
//		}
		
		
		
		
		
		/**************************************
		 * linking sessioned objects together
		 **************************************/





		/**
		 * This will link the session state of two ILinkableObjects.
		 * The session state of 'primary' will be copied over to 'secondary' after linking them.
		 * @param primary An ILinkableObject to give authority over the initial shared value.
		 * @param secondary The ILinkableObject to link with 'primary' via session state.
		 */
		public function linkSessionState(primary:ILinkableObject, secondary:ILinkableObject):void
		{
			if (primary == null || secondary == null)
			{
				reportError("SessionManager.linkObjects(): Parameters to this function cannot be null.");
				return;
			}
			
			// prevent
			if (primary == secondary)
			{
				reportError("Warning! Attempt to link session state of an object with itself");
				return;
			}
			
			if (objectToSetterMap[primary] === undefined)
				objectToSetterMap[primary] = function(source:ILinkableObject):void {
					setSessionState(primary, getSessionState(source), true);
				};
			if (objectToSetterMap[secondary] === undefined)
				objectToSetterMap[secondary] = function(source:ILinkableObject):void {
					setSessionState(secondary, getSessionState(source), true);
				};
			
			var primaryCC:ICallbackCollection = getCallbackCollection(primary);
			var secondaryCC:ICallbackCollection = getCallbackCollection(secondary);
			// when secondary changes, copy from secondary to primary, no callback recursion
			secondaryCC.addImmediateCallback(primary, objectToSetterMap[primary], [secondary]);
			// when primary changes, copy from primary to secondary, no callback recursion
			primaryCC.addImmediateCallback(secondary, objectToSetterMap[secondary], [primary], true); // copy from primary now

			// initialize linkedObjectsDictionaryMap entries if necessary
			if (linkedObjectsDictionaryMap[primary] === undefined)
				linkedObjectsDictionaryMap[primary] = new Dictionary(true);
			if (linkedObjectsDictionaryMap[secondary] === undefined)
				linkedObjectsDictionaryMap[secondary] = new Dictionary(true);
			// remember that these two objects are linked.
			linkedObjectsDictionaryMap[primary][secondary] = true;
			linkedObjectsDictionaryMap[secondary][primary] = true;
		}
		/**
		 * This will unlink the session state of two ILinkableObjects that were previously linked with linkSessionState().
		 * @param first The ILinkableObject to unlink from 'second'
		 * @param second The ILinkableObject to unlink from 'first'
		 */
		public function unlinkSessionState(first:ILinkableObject, second:ILinkableObject):void
		{
			if (first == null || second == null)
			{
				reportError("SessionManager.unlinkObjects(): Parameters to this function cannot be null.");
				return;
			}

			// clear the entries that say these two objects are linked.
			if (linkedObjectsDictionaryMap[first] !== undefined)
				delete linkedObjectsDictionaryMap[first][second];
			if (linkedObjectsDictionaryMap[second] !== undefined)
				delete linkedObjectsDictionaryMap[second][first];
			
			getCallbackCollection(first).removeCallback(objectToSetterMap[second]);
			getCallbackCollection(second).removeCallback(objectToSetterMap[first]);
		}
		/**
		 * This maps an destination ILinkableObject to a function like:
		 *     function(source:ILinkableObject):void { setSessionState(destination, getSessionState(source), true); }
		 * The purpose of having this mapping is to have a different function pointer for each ILinkableObject so addImmediateCallback()
		 * and removeCallback() can be used to link and unlink overlapping pairs of ILinkableObject objects.
		 */
		private const objectToSetterMap:Dictionary = new Dictionary(true);
		/**
		 * This maps a sessioned object to a Dictionary, which maps a linked sessioned object to a value of true.
		 */
		private const linkedObjectsDictionaryMap:Dictionary = new Dictionary(true);





		/******************************************************
		 * linking sessioned objects with bindable properties
		 ******************************************************/
		
		/*private function debugLink(linkVal:Object, bindVal:Object, useLinkableBefore:Boolean, useLinkableAfter:Boolean, callingLater:Boolean):void
		{
			var link:String = (useLinkableBefore && useLinkableAfter ? 'LINK' : 'link') + '(' + ObjectUtil.toString(linkVal) + ')';
			var bind:String = (!useLinkableBefore && !useLinkableAfter ? 'BIND' : 'bind') + '(' + ObjectUtil.toString(bindVal) + ')';
			var str:String = link + ', ' + bind;
			if (useLinkableBefore && !useLinkableAfter)
				str = link + ' = ' + bind;
			if (!useLinkableBefore && useLinkableAfter)
				str = bind + ' = ' + link;
			if (callingLater)
				str += ' (callingLater)';
			
			trace(str);
		}*/
		
		/**
		 * This function will link the session state of an ILinkableVariable to a bindable property of an object.
		 * Prior to linking, the value of the ILinkableVariable will be copied over to the bindable property.
		 * @param linkableVariable An ILinkableVariable to link to a bindable property.
		 * @param bindableParent An object with a bindable property.
		 * @param bindablePropertyName The variable name of the bindable property.
		 * @param delay The delay to use before setting the linkable variable to reflect a change in the bindable property while the bindableParent has focus.
		 * @param onlyWhenFocused If this is set to true and the bindableParent is a UIComponent, the bindable value will only be copied to the linkableVariable when the component has focus.
		 */
		public function linkBindableProperty(linkableVariable:ILinkableVariable, bindableParent:Object, bindablePropertyName:String, delay:uint = 0, onlyWhenFocused:Boolean = false):void
		{
			if (linkableVariable == null || bindableParent == null || bindablePropertyName == null)
			{
				reportError("linkBindableProperty(): Parameters to this function cannot be null.");
				return;
			}
			
			if (!bindableParent.hasOwnProperty(bindablePropertyName))
			{
				reportError('linkBindableProperty(): Unable to access property "'+bindablePropertyName+'" in class '+getQualifiedClassName(bindableParent));
				return;
			}
			
			// unlink in case previously linked
			unlinkBindableProperty(linkableVariable, bindableParent, bindablePropertyName);
			
			// initialize dictionaries
			if (_watcherMap[linkableVariable] === undefined)
				_watcherMap[linkableVariable] = new Dictionary(true);
			if (_watcherMap[linkableVariable][bindableParent] === undefined)
				_watcherMap[linkableVariable][bindableParent] = new Object();
			
			var callbackCollection:ICallbackCollection = getCallbackCollection(linkableVariable);
			var watcher:ChangeWatcher = null;
			var useLinkableValue:Boolean = true;
			var callLaterTime:int = 0;
			var uiComponent:UIComponent = bindableParent as UIComponent;
			var recursiveCall:Boolean = false;
			// a function that takes zero parameters and sets the bindable value.
			var synchronize:Function = function(firstParam:* = undefined, callingLater:Boolean = false):void
			{
				// unlink if linkableVariable was disposed of
				if (objectWasDisposed(linkableVariable))
				{
					unlinkBindableProperty(linkableVariable, bindableParent, bindablePropertyName);
					return;
				}
				
				/*debugLink(
					linkableVariable.getSessionState(),
					firstParam===undefined ? bindableParent[bindablePropertyName] : firstParam,
					useLinkableValue,
					firstParam===undefined,
					callingLater
				);*/
				
				// If bindableParent has focus:
				// When linkableVariable changes, update bindable value only when focus is lost (callLaterTime = int.MAX_VALUE).
				// When bindable value changes, update linkableVariable after a delay.
				
				if (!callingLater)
				{
					// remember which value changed last -- the linkable one or the bindable one
					useLinkableValue = firstParam === undefined; // true when called from linkable variable grouped callback
					// if we're not calling later and there is already a timestamp, just wait for the callLater to trigger
					if (callLaterTime)
					{
						// if there is a callLater waiting to trigger, update the target time
						callLaterTime = useLinkableValue ? int.MAX_VALUE : getTimer() + delay;
						
						//trace('\tdelaying the timer some more');
						
						return;
					}
				}
				
				// if the bindable value is not a boolean and the bindable parent has focus, delay synchronization
				var bindableValue:Object = bindableParent[bindablePropertyName];
				if (!(bindableValue is Boolean))
				{
					if (uiComponent)
					{
						var obj:DisplayObject = uiComponent.getFocus();
						if (obj && uiComponent.contains(obj))
						{
							if (linkableVariable is LinkableVariable)
							{
								if ((linkableVariable as LinkableVariable).verifyValue(bindableValue))
								{
									// clear any existing error string
									if (uiComponent.errorString)
										uiComponent.errorString = '';
								}
								else
								{
									// show error string if not already shown
									if (!uiComponent.errorString)
										uiComponent.errorString = 'Value not accepted.';
								}
							}
							
							var currentTime:int = getTimer();
							
							// if we're not calling later, set the target time (int.MAX_VALUE means delay until focus is lost)
							if (!callingLater)
								callLaterTime = useLinkableValue ? int.MAX_VALUE : currentTime + delay;
							
							// if we haven't reached the target time yet or callbacks are delayed, call later
							if (currentTime < callLaterTime)
							{
								uiComponent.callLater(synchronize, [firstParam, true]);
								return;
							}
						}
						else if (onlyWhenFocused && !callingLater)
						{
							// component does not have focus, so ignore the bindableValue.
							return;
						}
						
						// otherwise, synchronize now
						// clear saved time stamp when we are about to synchronize
						callLaterTime = 0;
					}
				}
				
				// if the linkable variable's callbacks are delayed, delay synchronization
				if (getCallbackCollection(linkableVariable).callbacksAreDelayed)
				{
					WeaveAPI.StageUtils.callLater(linkableVariable, synchronize, [firstParam, true], false);
					return;
				}
				
				// synchronize
				if (useLinkableValue)
				{
					var linkableValue:Object = linkableVariable.getSessionState();
					if ((bindableValue is Number) != (linkableValue is Number))
					{
						try {
							if (linkableValue is Number)
							{
								if (isNaN(linkableValue as Number))
									linkableValue = '';
								else
									linkableValue = '' + linkableValue;
							}
							else
							{
								linkableVariable.setSessionState(Number(linkableValue));
								linkableValue = linkableVariable.getSessionState();
							}
						} catch (e:Error) { }
					}
					if (bindableValue != linkableValue)
						bindableParent[bindablePropertyName] = linkableValue;
					
					// clear any existing error string
					if (uiComponent && linkableVariable is LinkableVariable && uiComponent.errorString)
						uiComponent.errorString = '';
				}
				else
				{
					var prevCount:uint = callbackCollection.triggerCounter;
					linkableVariable.setSessionState(bindableValue);
					// Always synchronize after setting the linkableVariable because there may
					// be constraints on the session state that will prevent the callbacks
					// from triggering if the bindable value does not match those constraints.
					// This makes UIComponents update to the real value after they lose focus.
					if (callbackCollection.triggerCounter == prevCount && !recursiveCall)
					{
						// avoid infinite recursion in the case where the new value is not accepted by a verifier function
						recursiveCall = true;
						synchronize();
						recursiveCall = false;
					}
				}
			};
			// Copy session state over to bindable property now, before calling BindingUtils.bindSetter(),
			// because that will copy from the bindable property to the sessioned property.
			synchronize();
			watcher = BindingUtils.bindSetter(synchronize, bindableParent, bindablePropertyName);
			// save a mapping from the linkableVariable,bindableParent,bindablePropertyName parameters to the watcher for the property
			_watcherMap[linkableVariable][bindableParent][bindablePropertyName] = watcher;
			// when session state changes, set bindable property
			_watcherToSynchronizeFunctionMap[watcher] = synchronize;
			callbackCollection.addImmediateCallback(bindableParent, synchronize);
		}
		/**
		 * This function will unlink an ILinkableVariable from a bindable property that has been previously linked with linkBindableProperty().
		 * @param linkableVariable An ILinkableVariable to unlink from a bindable property.
		 * @param bindableParent An object with a bindable property.
		 * @param bindablePropertyName The variable name of the bindable property.
		 */
		public function unlinkBindableProperty(linkableVariable:ILinkableVariable, bindableParent:Object, bindablePropertyName:String):void
		{
			if (linkableVariable == null || bindableParent == null || bindablePropertyName == null)
			{
				reportError("unlinkBindableProperty(): Parameters to this function cannot be null.");
				return;
			}
			
			try
			{
				var watcher:ChangeWatcher = _watcherMap[linkableVariable][bindableParent][bindablePropertyName];
				var cc:ICallbackCollection = getCallbackCollection(linkableVariable);
				cc.removeCallback(_watcherToSynchronizeFunctionMap[watcher]);
				watcher.unwatch();
				delete _watcherMap[linkableVariable][bindableParent][bindablePropertyName];
			}
			catch (e:Error)
			{
				//trace(SessionManager, getQualifiedClassName(bindableParent), bindablePropertyName, e.getStackTrace());
			}
		}
		/**
		 * This is a multidimensional mapping, such that
		 *     _watcherMap[linkableVariable][bindableParent][bindablePropertyName]
		 * maps to a ChangeWatcher object.
		 */
		private const _watcherMap:Dictionary = new Dictionary(true); // use weak links to be GC-friendly
		/**
		 * This maps a ChangeWatcher object to a function that was added as a callback to the corresponding ILinkableVariable.
		 */
		private const _watcherToSynchronizeFunctionMap:Dictionary = new Dictionary(); // use weak links to be GC-friendly
		
		/**
		 * This function computes the diff of two session states.
		 * @param oldState The source session state.
		 * @param newState The destination session state.
		 * @return A patch that generates the destination session state when applied to the source session state, or undefined if the two states are equivalent.
		 */
		public function computeDiff(oldState:Object, newState:Object):*
		{
			var type:String = typeof(oldState); // the type of null is 'object'
			var diffValue:*;

			// special case if types differ
			if (typeof(newState) != type)
				return newState;
			
			if (type == 'xml')
			{
				throw new Error("XML is not supported as a primitive session state type.");
			}
			else if (type == 'number')
			{
				if (isNaN(oldState as Number) && isNaN(newState as Number))
					return undefined; // no diff
				
				if (oldState != newState)
					return newState;
				
				return undefined; // no diff
			}
			else if (oldState === null || newState === null || type != 'object') // other primitive value
			{
				if (oldState !== newState) // no type-casting
					return newState;
				
				return undefined; // no diff
			}
			else if (oldState is Array && newState is Array)
			{
				// create an array of new DynamicState objects for all new names followed by missing old names
				var i:int;
				var typedState:Object;
				var changeDetected:Boolean = false;
				
				// create oldLookup
				var oldLookup:Object = {};
				var objectName:String;
				var className:String;
				var sessionState:Object;
				for (i = 0; i < oldState.length; i++)
				{
					typedState = oldState[i];
					
					// if we see a string, assume both are String Arrays.
					if (typedState is String || typedState is Array)
					{
						if (StandardLib.arrayCompare(oldState as Array, newState as Array) == 0)
							return undefined; // no diff
						return newState;
					}
					
					//note: there is no error checking here for typedState
					objectName = typedState[DynamicState.OBJECT_NAME];
					oldLookup[objectName] = typedState;
				}
				if (oldState.length != newState.length)
					changeDetected = true;
				
				// create new Array with new DynamicState objects
				var result:Array = [];
				for (i = 0; i < newState.length; i++)
				{
					typedState = newState[i];
					
					// if we see a string, assume both are String Arrays.
					if (typedState is String || typedState is Array)
					{
						if (StandardLib.arrayCompare(oldState as Array, newState as Array) == 0)
							return undefined; // no diff
						return newState;
					}
					
					//note: there is no error checking here for typedState
					objectName = typedState[DynamicState.OBJECT_NAME];
					className = typedState[DynamicState.CLASS_NAME];
					sessionState = typedState[DynamicState.SESSION_STATE];
					var oldTypedState:Object = oldLookup[objectName];
					delete oldLookup[objectName]; // remove it from the lookup because it's already been handled
					
					// If the object specified in newState does not exist in oldState, we don't need to do anything further.
					// If the class is the same as before, then we can save a diff instead of the entire session state.
					// If the class changed, we can't save only a diff -- we need to keep the entire session state.
					// Replace the sessionState in the new DynamicState object with the diff.
					if (oldTypedState != null && oldTypedState[DynamicState.CLASS_NAME] == className)
					{
						className = null; // no change
						diffValue = computeDiff(oldTypedState[DynamicState.SESSION_STATE], sessionState);
						if (diffValue === undefined)
						{
							// Since the class name is the same and the session state is the same,
							// we only need to specify that this name is still present.
							result.push(objectName);
							
							if (!changeDetected && oldState[i][DynamicState.OBJECT_NAME] != objectName)
								changeDetected = true;
							
							continue;
						}
						sessionState = diffValue;
					}
					
					// save in new array and remove from lookup
					result.push(new DynamicState(objectName, className, sessionState));
					changeDetected = true;
				}
				
				// Anything remaining in the lookup does not appear in newState.
				// Add DynamicState entries with an invalid className ("delete") to convey that each of these objects should be removed.
				for (objectName in oldLookup)
				{
					result.push(new DynamicState(objectName, 'delete'));
					changeDetected = true;
				}
				
				if (changeDetected)
					return result;
				
				return undefined; // no diff
			}
			else // nested object
			{
				var diff:* = undefined; // start with no diff
				
				// find old properties that changed value
				for (var oldName:String in oldState)
				{
					diffValue = computeDiff(oldState[oldName], newState[oldName]);
					if (diffValue !== undefined)
					{
						if (!diff)
							diff = {};
						diff[oldName] = diffValue;
					}
				}

				// find new properties
				for (var newName:String in newState)
				{
					if (oldState[newName] === undefined)
					{
						if (!diff)
							diff = {};
						diff[newName] = newState[newName];
					}
				}

				return diff;
			}
		}
	}
}

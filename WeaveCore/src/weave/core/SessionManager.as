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
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.system.Capabilities;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.utils.ObjectUtil;
	
	import avmplus.DescribeType;
	import avmplus.getQualifiedClassName;
	
	import weave.api.reportError;
	import weave.api.core.DynamicState;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableCompositeObject;
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableObjectWithBusyStatus;
	import weave.api.core.ILinkableObjectWithNewProperties;
	import weave.api.core.ILinkableVariable;
	import weave.api.core.ISessionManager;
	import weave.compiler.StandardLib;
	import weave.primitives.Dictionary2D;
	import weave.primitives.Map;
	import weave.primitives.WeakMap;
	import weave.primitives.WeaveTreeItem;
	import weave.utils.WeavePromise;
	
	/**
	 * This is a collection of core functions in the Weave session framework.
	 * 
	 * @author adufilie
	 */
	public class SessionManager implements ISessionManager
	{
		public var debugBusyTasks:Boolean = false;
		
		/**
		 * @inheritDoc
		 */
		public function newLinkableChild(linkableParent:Object, linkableChildType:Class, callback:Function = null, useGroupedCallback:Boolean = false):*
		{
			if (!(linkableParent is ILinkableObject))
				throw new Error("newLinkableChild(): Parent does not implement ILinkableObject.");
			
			if (!linkableChildType)
				throw new Error("newLinkableChild(): Child type parameter cannot be null.");
			
			var childQName:String = getQualifiedClassName(linkableChildType);
			if (!ClassUtils.classImplements(childQName, ILinkableObject_QName))
			{
				if (ClassUtils.hasClassDefinition(childQName))
					throw new Error("newLinkableChild(): Child class does not implement ILinkableObject.");
				else
					throw new Error("newLinkableChild(): Child class inaccessible via qualified class name: " + childQName);
			}
			
			var linkableChild:ILinkableObject = new linkableChildType() as ILinkableObject;
			return registerLinkableChild(linkableParent, linkableChild, callback, useGroupedCallback);
		}
		
		/**
		 * @inheritDoc
		 */
		public function registerLinkableChild(linkableParent:Object, linkableChild:ILinkableObject, callback:Function = null, useGroupedCallback:Boolean = false):*
		{
			if (!(linkableParent is ILinkableObject))
				throw new Error("registerLinkableChild(): Parent does not implement ILinkableObject.");
			if (!(linkableChild is ILinkableObject))
				throw new Error("registerLinkableChild(): Child parameter cannot be null.");
			if (linkableParent == linkableChild)
				throw new Error("registerLinkableChild(): Invalid attempt to register sessioned property having itself as its parent");
			
			// add a callback that will be cleaned up when the parent is disposed.
			// this callback will be called BEFORE the child triggers the parent callbacks.
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
			// registerDisposableChild() also initializes the required Dictionaries.
			registerDisposableChild(linkableParent, linkableChild);
			
			// only continue if the child is not already registered with the parent
			if (d2d_child_parent.get(linkableChild, linkableParent) === undefined)
			{
				// remember this child-parent relationship
				d2d_child_parent.set(linkableChild, linkableParent, true);
				d2d_parent_child.set(linkableParent, linkableChild, true);
				
				// make child changes trigger parent callbacks
				var parentCC:ICallbackCollection = getCallbackCollection(linkableParent as ILinkableObject);
				// set alwaysCallLast=true for triggering parent callbacks, so parent will be triggered after all the other child callbacks
				getCallbackCollection(linkableChild).addImmediateCallback(linkableParent, parentCC.triggerCallbacks, false, true); // parent-child relationship
			}
			
			_treeCallbacks.triggerCallbacks();
			
			return linkableChild;
		}
		
		/**
		 * @inheritDoc
		 */
		public function newDisposableChild(disposableParent:Object, disposableChildType:Class):*
		{
			return registerDisposableChild(disposableParent, new disposableChildType());
		}
		
		/**
		 * @inheritDoc
		 */
		public function registerDisposableChild(disposableParent:Object, disposableChild:Object):*
		{
			if (!disposableParent)
				throw new Error("registerDisposableChild(): Parent parameter cannot be null.");
			if (!disposableChild)
				throw new Error("registerDisposableChild(): Child parameter cannot be null.");
			
			// if this child has no owner yet...
			if (!map_child_owner.has(disposableChild))
			{
				// make this first parent the owner
				map_child_owner.set(disposableChild, disposableParent);
				d2d_owner_child.set(disposableParent, disposableChild, true);
			}
			return disposableChild;
		}
		
		/**
		 * Use this function with care.  This will remove child objects from the session state of a parent and
		 * stop the child from triggering the parent callbacks.
		 * @param parent A parent that the specified child objects were previously registered with.
		 * @param child The child object to unregister from the parent.
		 */
		public function unregisterLinkableChild(parent:ILinkableObject, child:ILinkableObject):void
		{
			if (!parent)
				throw new Error("unregisterLinkableChild(): Parent parameter cannot be null.");
			if (!child)
				throw new Error("unregisterLinkableChild(): Child parameter cannot be null.");
			
			d2d_child_parent.remove(child, parent);
			d2d_parent_child.remove(parent, child);
			getCallbackCollection(child).removeCallback(getCallbackCollection(parent).triggerCallbacks);
			
			_treeCallbacks.triggerCallbacks();
		}
		
		/**
		 * This function will add or remove child objects from the session state of a parent.  Use this function
		 * with care because the child will no longer be "sessioned."  The child objects will continue to trigger the
		 * callbacks of the parent object, but they will no longer be considered a part of the parent's session state.
		 * If you are not careful, this will break certain functionalities that depend on the session state of the parent.
		 * @param parent A parent that the specified child objects were previously registered with.
		 * @param child The child object to remove from the session state of the parent.
		 */
		public function excludeLinkableChildFromSessionState(parent:ILinkableObject, child:ILinkableObject):void
		{
			if (parent == null || child == null)
			{
				reportError("SessionManager.excludeLinkableChildFromSessionState(): Parameters to this function cannot be null.");
				return;
			}
			if (d2d_child_parent.get(child, parent))
				d2d_child_parent.set(child, parent, false);
			if (d2d_parent_child.get(parent, child))
				d2d_parent_child.set(parent, child, false);
		}
		
		/**
		 * @private
		 * This function will return all the child objects that have been registered with a parent.
		 * @param parent A parent object to get the registered children of.
		 * @return An Array containing a list of linkable objects that have been registered as children of the specified parent.
		 *         This list includes all children that have been registered, even those that do not appear in the session state.
		 */
		private function _getRegisteredChildren(parent:ILinkableObject):Array
		{
			return d2d_parent_child.secondaryKeys(parent);
		}

		/**
		 * @inheritDoc
		 */
		public function getLinkableOwner(child:ILinkableObject):ILinkableObject
		{
			return map_child_owner.get(child) as ILinkableObject;
		}
		
		/**
		 * Cached WeaveTreeItems that are auto-generated when they are accessed
		 */
		private const d2d_object_name_tree:Dictionary2D = new Dictionary2D(true, false, WeaveTreeItem);
		
		/**
		 * @param root The linkable object to be placed at the root node of the tree.
		 * @param objectName The label for the root node.
		 * @return A tree of nodes with the properties "data", "label", "children"
		 */
		public function getSessionStateTree(root:ILinkableObject, objectName:String):WeaveTreeItem
		{
			var treeItem:WeaveTreeItem = d2d_object_name_tree.get(root, objectName);
			if (!treeItem.data)
			{
				treeItem.data = root;
				treeItem.children = getTreeItemChildren;
				// dependency is used to determine when to recalculate children array
				var lhm:ILinkableHashMap = root as ILinkableHashMap;
				treeItem.dependency = lhm ? lhm.childListCallbacks : root;
			}
			if (objectName)
				treeItem.label = objectName;
			return treeItem;
		}
		
		private function getTreeItemChildren(treeItem:WeaveTreeItem):Array
		{
			var object:ILinkableObject = treeItem.data as ILinkableObject;
			var children:Array = [];
			var names:Array;
			var childObject:ILinkableObject;
			var ignoreList:WeakMap = new WeakMap();
			var lhm:ILinkableHashMap = object as ILinkableHashMap;
			if (lhm)
			{
				names = lhm.getNames();
				
				var childObjects:Array = lhm.getObjects();
				
				for (var i:int = 0; i < names.length; i++)
				{
					childObject = childObjects[i];
					if (d2d_child_parent.get(childObject, lhm))
					{
						// don't include duplicate siblings
						if (ignoreList.has(childObject))
							continue;
						ignoreList.set(childObject, true);
						
						children.push(getSessionStateTree(childObject, names[i]));
					}
				}
			}
			else
			{
				var deprecatedLookup:Object = null;
				var ldo:ILinkableDynamicObject = object as ILinkableDynamicObject;
				if (ldo)
				{
					// do not include externally referenced objects
					names = ldo.targetPath ? null : [null];
				}
				else if (object)
				{
					names = getLinkablePropertyNames(object);
					var className:String = getQualifiedClassName(object);
					deprecatedLookup = classNameToDeprecatedGetterLookup[className];
				}
				for each (var name:String in names)
				{
					if (ldo)
						childObject = ldo.internalObject;
					else if (!deprecatedLookup[name])
						childObject = object[name];
					if (!childObject)
						continue;
					if (d2d_child_parent.get(childObject, object))
					{
						// don't include duplicate siblings
						if (ignoreList.has(childObject))
							continue;
						ignoreList.set(childObject, true);
						
						children.push(getSessionStateTree(childObject, name));
					}
				}
			}
			
			if (children.length == 0)
				children = null;
			return children;
		}
		
		/**
		 * Gets a session state tree containing type information at each node.
		 */
		public function getTypedStateTree(root:ILinkableObject):Object
		{
			return getTypedStateFromTreeNode(getSessionStateTree(root, null));
		}
		private function getTypedStateFromTreeNode(node:WeaveTreeItem, i:int = 0, a:Array = null):Object
		{
			var state:Object;
			var children:Array = node.children;
			if (node.data is ILinkableVariable || !children)
				state = getSessionState(node.data as ILinkableObject);
			else
				state = children.map(getTypedStateFromTreeNode);
			return DynamicState.create(node.label, getQualifiedClassName(node.data), state);
		}
		
		/**
		 * Adds a grouped callback that will be triggered when the session state tree changes.
		 * USE WITH CARE. The groupedCallback should not run computationally-expensive code.
		 */
		public function addTreeCallback(relevantContext:Object, groupedCallback:Function, triggerCallbackNow:Boolean = false):void
		{
			_treeCallbacks.addGroupedCallback(relevantContext, groupedCallback, triggerCallbackNow);
		}
		public function removeTreeCallback(groupedCallback:Function):void
		{
			_treeCallbacks.removeCallback(groupedCallback);
		}
		private const _treeCallbacks:CallbackCollection = new CallbackCollection();

		/**
		 * @inheritDoc
		 */
		public function copySessionState(source:ILinkableObject, destination:ILinkableObject):void
		{
			var sessionState:Object = getSessionState(source);
			setSessionState(destination, sessionState, true);
		}
		
		private function applyDiffForLinkableVariable(base:Object, diff:Object):Object
		{
			if (base === null || diff === null || typeof(base) != 'object' || typeof(diff) != 'object' || diff is Array)
				return diff; // don't need to make a copy because LinkableVariable makes copies anyway
			
			for (var key:String in diff)
			{
				var value:* = diff[key];
				if (value === undefined)
					delete base[key];
				else
					base[key] = applyDiffForLinkableVariable(base[key], value);
			}
			
			return base;
		}

		/**
		 * @inheritDoc
		 */
		public function setSessionState(linkableObject:ILinkableObject, newState:Object, removeMissingDynamicObjects:Boolean = true):void
		{
			if (linkableObject == null)
			{
				reportError("SessionManager.setSessionState(): linkableObject cannot be null.");
				return;
			}

			// special cases:
			var lv:ILinkableVariable = linkableObject as ILinkableVariable;
			if (lv)
			{
				if (removeMissingDynamicObjects == false && newState && getQualifiedClassName(newState) == 'Object')
				{
					lv.setSessionState(applyDiffForLinkableVariable(copyObject(lv.getSessionState()), newState));
				}
				else
				{
					lv.setSessionState(newState);
				}
				return;
			}
			var lco:ILinkableCompositeObject = linkableObject as ILinkableCompositeObject;
			if (lco)
			{
				if (newState is String)
					newState = [newState];
				
				if (newState != null && !(newState is Array))
				{
					var array:Array = [];
					for (var key:String in newState)
						array.push(DynamicState.create(key, null, newState[key]));
					newState = array;
				}
				
				lco.setSessionState(newState as Array, removeMissingDynamicObjects);
				return;
			}

			if (newState == null)
				return;

			// delay callbacks before setting session state
			var objectCC:ICallbackCollection = getCallbackCollection(linkableObject);
			objectCC.delayCallbacks();

			var name:String;
			
			// cache property names if necessary
			var classQName:String = getQualifiedClassName(linkableObject);
			if (!classNameToSessionedPropertyNames[classQName])
				cacheClassInfo(linkableObject, classQName);
			var deprecatedLookup:Object = classNameToDeprecatedGetterLookup[classQName];
			var propertyNames:Array = classNameToSessionedPropertyNames[classQName];
			
			// set session state
			var foundMissingProperty:Boolean = false;
			for each (name in propertyNames)
			{
				if (!newState.hasOwnProperty(name))
				{
					if (removeMissingDynamicObjects && linkableObject is ILinkableObjectWithNewProperties)
						foundMissingProperty = true;
					continue;
				}
				
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

				// unless it's a deprecated property (for backwards compatibility), skip this property if it should not appear in the session state
				if (!deprecatedLookup[name] && !d2d_child_parent.get(property, linkableObject))
					continue;
					
				setSessionState(property, newState[name], removeMissingDynamicObjects);
			}
			
			// handle properties appearing in session state that do not appear in the linkableObject
			var ilownp:ILinkableObjectWithNewProperties = linkableObject as ILinkableObjectWithNewProperties;
			if (ilownp)
				for (name in newState)
					if (!deprecatedLookup.hasOwnProperty(name))
						ilownp.handleMissingSessionStateProperty(newState, name);
			
			// handle properties missing from absolute session state
			if (foundMissingProperty)
				for each (name in propertyNames)
					if (!newState.hasOwnProperty(name))
						(linkableObject as ILinkableObjectWithNewProperties).handleMissingSessionStateProperty(newState, name);
			
			// pass deprecated session state to deprecated setters
			for each (name in classNameToDeprecatedSetterNames[classQName])
			{
				if (newState.hasOwnProperty(name) && newState[name] !== null)
				{
					_deprecatedSetterShouldRemoveMissingDynamicObjects = removeMissingDynamicObjects;
					linkableObject[name] = newState[name];
				}
			}
			
			// resume callbacks after setting session state
			objectCC.resumeCallbacks();
		}
		
		private var _deprecatedSetterShouldRemoveMissingDynamicObjects:Boolean;
		
		/**
		 * You can check this value when defining deprecated setter functions for backwards compatibility.
		 * @return true if SessionManager is currently applying a diff.
		 */		
		public function get deprecatedSetterShouldRemoveMissingDynamicObjects():Boolean
		{
			return _deprecatedSetterShouldRemoveMissingDynamicObjects;
		}
		
		/**
		 * keeps track of which objects are currently being traversed
		 */
		private const map_obj_getSessionStateIgnore:Object = new WeakMap();
		
		/**
		 * @inheritDoc
		 */
		public function getSessionState(linkableObject:ILinkableObject):Object
		{
			if (linkableObject == null)
			{
				reportError("SessionManager.getSessionState(): linkableObject cannot be null.");
				return null;
			}
			
			var result:Object = null;
			
			// special cases (explicit session state)
			if (linkableObject is ILinkableVariable)
			{
				result = (linkableObject as ILinkableVariable).getSessionState();
			}
			else if (linkableObject is ILinkableCompositeObject)
			{
				result = (linkableObject as ILinkableCompositeObject).getSessionState();
			}
			else
			{
				// implicit session state
				// first pass: get property names
				
				// cache property names if necessary
				var classQName:String = getQualifiedClassName(linkableObject);
				if (!classNameToSessionedPropertyNames[classQName])
					cacheClassInfo(linkableObject, classQName);
				
				var propertyNames:Array = classNameToSessionedPropertyNames[classQName];
				var deprecatedLookup:Object = classNameToDeprecatedGetterLookup[classQName];
				var resultNames:Array = [];
				var resultProperties:Array = [];
				var property:ILinkableObject = null;
				var i:int;
				//trace("getting session state for "+getQualifiedClassName(sessionedObject),"propertyNames="+propertyNames);
				for each (var name:String in propertyNames)
				{
					// exclude deprecated properties from session state
					if (deprecatedLookup[name])
						continue;
					try
					{
						property = null; // must set this to null first because accessing the property may fail
						property = linkableObject[name] as ILinkableObject;
					}
					catch (e:Error)
					{
						reportError('Unable to get property "'+name+'" of class "'+getQualifiedClassName(linkableObject)+'"');
					}
					// first pass: set result[name] to the ILinkableObject
					if (property != null && !map_obj_getSessionStateIgnore.get(property))
					{
						// skip this property if it should not appear in the session state under the parent.
						if (!d2d_child_parent.get(property, linkableObject))
							continue;
						// avoid infinite recursion in implicit session states
						map_obj_getSessionStateIgnore.set(property, true);
						resultNames.push(name);
						resultProperties.push(property);
					}
					else
					{
						/*
						if (property != null)
							trace("ignoring duplicate object:",name,property);
						*/
					}
				}
				// special case if there are no child objects -- return null
				if (resultNames.length > 0)
				{
					// second pass: get values from property names
					result = new Object();
					for (i = 0; i < resultNames.length; i++)
					{
						var value:Object = getSessionState(resultProperties[i]);
						property = resultProperties[i] as ILinkableObject;
						// do not include objects that have a null implicit session state (no child objects)
						if (value == null && !(property is ILinkableVariable) && !(property is ILinkableCompositeObject))
							continue;
						result[resultNames[i]] = value;
						//trace("getState",getQualifiedClassName(sessionedObject),resultNames[i],result[resultNames[i]]);
					}
				}
			}
			
			map_obj_getSessionStateIgnore.set(linkableObject, undefined);
			
			return result;
		}
		
		/**
		 * This maps a qualified class name to an Array of names of sessioned properties contained in that class.
		 */
		private const classNameToSessionedPropertyNames:Object = new Object();
		/**
		 * This maps a qualified class name to an Array of names of deprecated setter functions contained in that class.
		 */
		private const classNameToDeprecatedSetterNames:Object = new Object();
		/**
		 * This maps a qualified class name to an Object mapping sessioned property names to booleans indicating if they are implemented as deprecated getters.
		 */
		private const classNameToDeprecatedGetterLookup:Object = new Object();
		
		private function cacheClassInfo(linkableObject:ILinkableObject, classQName:String):void
		{
			// linkable property names
			var propertyNames:Array = [];
			var deprecatedSetters:Array = [];
			var deprecatedGetterLookup:Object = {}; // deprecated getter name -> true
			// iterate over the public properties, saving the names of the ones that implement ILinkableObject
			var type:Object = DescribeType.getInfo(linkableObject, DescribeType.INCLUDE_TRAITS | DescribeType.INCLUDE_ACCESSORS | DescribeType.INCLUDE_VARIABLES | DescribeType.INCLUDE_METADATA);
			var traits:Object = type.traits;
			for (var i:int = 0; i < 2; i++)
			{
				var variables:Array = i == 0 ? traits.accessors : traits.variables;
				for each (var variable:Object in variables)
				{
					var deprecated:Boolean = false;
					for each (var metadata:Object in variable.metadata)
					{
						if (metadata.name == 'Deprecated')
						{
							deprecated = true;
							break;
						}
					}
					
					if (variable.access == 'writeonly')
					{
						if (deprecated)
							deprecatedSetters.push(variable.name);
					}
					else if (ClassUtils.classImplements(variable.type, ILinkableObject_QName))
					{
						deprecatedGetterLookup[variable.name] = deprecated;
						propertyNames.push(variable.name);
					}
				}
			}
			
			StandardLib.sort(propertyNames);
			StandardLib.sort(deprecatedSetters);
			
			classNameToSessionedPropertyNames[classQName] = propertyNames;
			classNameToDeprecatedSetterNames[classQName] = deprecatedSetters;
			classNameToDeprecatedGetterLookup[classQName] = deprecatedGetterLookup;
		}

		/**
		 * This function gets a list of sessioned property names so accessor functions for non-sessioned properties do not have to be called.
		 * @param linkableObject An object containing sessioned properties.
		 * @param filtered If set to true, filters out deprecated, null, and excluded properties.
		 * @return An Array containing the names of the sessioned properties of that object class.
		 */
		public function getLinkablePropertyNames(linkableObject:ILinkableObject, filtered:Boolean = false):Array
		{
			if (linkableObject == null)
			{
				reportError("SessionManager.getLinkablePropertyNames(): linkableObject cannot be null.");
				return [];
			}

			var className:String = getQualifiedClassName(linkableObject);
			var propertyNames:Array = classNameToSessionedPropertyNames[className] as Array;
			if (propertyNames == null)
			{
				cacheClassInfo(linkableObject, className);
				propertyNames = classNameToSessionedPropertyNames[className] as Array;
			}
			
			if (filtered)
			{
				var filteredNames:Array = [];
				var deprecatedLookup:Object = classNameToDeprecatedGetterLookup[className];
				for each (var name:String in propertyNames)
				{
					try
					{
						if (deprecatedLookup[name])
							continue;
						
						var property:ILinkableObject = linkableObject[name];
						if (property == null || !d2d_child_parent.get(property, linkableObject))
							continue;

						filteredNames.push(name);
					}
					catch (e:Error)
					{
						reportError('Unable to get property "'+name+'" of class "'+getQualifiedClassName(linkableObject)+'"');
					}
				}
				return filteredNames;
			}
			
			return propertyNames;
		}
		
		internal static const ILinkableObject_QName:String = getQualifiedClassName(ILinkableObject);
		
		/**
		 * This maps a child ILinkableObject to its registered owner.
		 */
		private const map_child_owner:WeakMap = new WeakMap();
		/**
		 * This maps a parent ILinkableObject to a Dictionary, which maps each child ILinkableObject it owns to a value of true.
		 * Example: d2d_owner_child.get(owner, child) == true
		 */
		private const d2d_owner_child:Dictionary2D = new Dictionary2D(true, false);
		/**
		 * This maps a child ILinkableObject to a Dictionary, which maps each of its registered parent ILinkableObjects to a value of true if the child should appear in the session state automatically or false if not.
		 * Example: d2d_child_parent.get(child, parent) == true
		 */
		private const d2d_child_parent:Dictionary2D = new Dictionary2D(true, false);
		/**
		 * This maps a parent ILinkableObject to a Dictionary, which maps each of its registered child ILinkableObjects to a value of true if the child should appear in the session state automatically or false if not.
		 * Example: d2d_parent_child.get(parent, child) == true
		 */
		private const d2d_parent_child:Dictionary2D = new Dictionary2D(true, false);
		
		/**
		 * @inheritDoc
		 */
		public function getLinkableDescendants(root:ILinkableObject, filter:Class = null):Array
		{
			var result:Array = [];
			if (root)
				internalGetDescendants(result, root, filter, new WeakMap(), int.MAX_VALUE);
			// don't include root object
			if (result.length > 0 && result[0] == root)
				result.shift();
			return result;
		}
		private function internalGetDescendants(output:Array, root:ILinkableObject, filter:Class, ignoreList:WeakMap, depth:int):void
		{
			if (root == null || ignoreList.has(root))
				return;
			ignoreList.set(root, true);
			if (filter == null || root is filter)
				output.push(root);
			if (--depth <= 0)
				return;
			
			var children:Array = d2d_parent_child.secondaryKeys(root);
			for each (var child:ILinkableObject in children)
				internalGetDescendants(output, child, filter, ignoreList, depth);
		}
		
		private const map_task_stackTrace:Map = new Map();
		private const d2d_owner_task:Dictionary2D = new Dictionary2D(false, false);
		private const d2d_task_owner:Dictionary2D = new Dictionary2D(false, false);
		private const map_busyTraversal:WeakMap = new WeakMap(); // ILinkableObject -> Boolean
		private const array_busyTraversal:Array = [];
		private const map_unbusyTriggerCounts:Map = new Map(); // ILinkableObject -> int
		private const map_unbusyStackTraces:WeakMap = new WeakMap(); // ILinkableObject -> String
		
		private function disposeBusyTaskPointers(disposedObject:ILinkableObject):void
		{
			d2d_owner_task.removeAllPrimary(disposedObject);
			d2d_task_owner.removeAllSecondary(disposedObject);
		}
		
		/**
		 * Returns a mapping from owner debugId to an Array of debugIds for its busy tasks.
		 */
		public function debugBusyObjects():Object
		{
			var result:Object = {};
			for (var owner:* in d2d_owner_task.dictionary)
			{
				var tasks:Array = [];
				for (var task:* in d2d_owner_task.dictionary[owner])
					tasks.push(debugId(task));
				
				result[debugId(owner)] = tasks;
			}
			return result;
		}
		
		/**
		 * @inheritDoc
		 */
		public function assignBusyTask(taskToken:Object, busyObject:ILinkableObject):void
		{
			if (debugBusyTasks)
				map_task_stackTrace.set(taskToken, new Error("Stack trace when task was last assigned").getStackTrace());
			
			// stop if already assigned
			if (d2d_task_owner.get(taskToken, busyObject))
				return;
			
			if (taskToken is AsyncToken && !WeaveAPI.ProgressIndicator.hasTask(taskToken))
			{
				(taskToken as AsyncToken).addResponder(new AsyncResponder(unassignAsyncToken, unassignAsyncToken, taskToken));
			}
			if (taskToken is WeavePromise)
			{
				var remove:Function = function(_:*):* { unassignBusyTask(taskToken); };
				(taskToken as WeavePromise).then(remove, remove);
			}

			d2d_owner_task.set(busyObject, taskToken, true);
			d2d_task_owner.set(taskToken, busyObject, true);
		}
		
		private function unassignAsyncToken(event:Event, token:AsyncToken):void
		{
			unassignBusyTask(token);
		}
		
		/**
		 * @inheritDoc
		 */
		public function unassignBusyTask(taskToken:Object):void
		{
			if (WeaveAPI.ProgressIndicator.hasTask(taskToken))
			{
				WeaveAPI.ProgressIndicator.removeTask(taskToken);
				return;
			}
			
			var owners:Array = d2d_task_owner.secondaryKeys(taskToken);
			d2d_task_owner.removeAllPrimary(taskToken);
			nextOwner: for each (var owner:ILinkableObject in owners)
			{
				d2d_owner_task.remove(owner, taskToken);
				
				// if there are other tasks for this owner, continue to next owner
				for (var task:* in d2d_owner_task.dictionary[owner])
					continue nextOwner;
				
				// when there are no more tasks for this owner, check later to see if callbacks trigger
				map_unbusyTriggerCounts.set(owner, getCallbackCollection(owner).triggerCounter);
				// immediate priority because we want to trigger as soon as possible
				WeaveAPI.StageUtils.startTask(null, unbusyTrigger, WeaveAPI.TASK_PRIORITY_IMMEDIATE);
				
				if (debugBusyTasks)
				{
					var stackTrace:String = new Error("Stack trace when last task was unassigned").getStackTrace();
					map_unbusyStackTraces.set(owner, {
						assigned: map_task_stackTrace.get(taskToken),
						unassigned: stackTrace,
						token: taskToken
					});
				}
			}
		}
		
		/**
		 * Called the frame after an owner's last busy task is unassigned.
		 * Triggers callbacks if they have not been triggered since then.
		 */
		private function unbusyTrigger(stopTime:int):Number
		{
			var owner:*;
			do {
				if (getTimer() > stopTime)
					return 0;
				
				owner = null;
				var owners:Array = Map.keys(map_unbusyTriggerCounts);
				for each (owner in owners)
				{
					var triggerCount:int = map_unbusyTriggerCounts.get(owner);
					map_unbusyTriggerCounts.remove(owner);
					
					var cc:ICallbackCollection = getCallbackCollection(owner);
					if (cc is CallbackCollection ? (cc as CallbackCollection).wasDisposed : objectWasDisposed(owner))
						continue; // already disposed
					
					if (cc.triggerCounter != triggerCount)
						continue; // already triggered
					
					if (linkableObjectIsBusy(owner))
						continue; // busy again
					
					if (debugBusyTasks)
					{
						var stackTraces:Object = map_unbusyStackTraces.get(owner);
						trace('Triggering callbacks because they have not triggered since owner has becoming unbusy:', debugId(owner));
						trace(stackTraces.assigned);
						trace(stackTraces.unassigned);
					}
					
					cc.triggerCallbacks();
				}
			} while (owner);
			
			return 1;
		}
		
		/**
		 * @inheritDoc
		 */
		public function linkableObjectIsBusy(linkableObject:ILinkableObject):Boolean
		{
			// get the ILinkableObject associated with the the ICallbackCollection
			if (linkableObject is ICallbackCollection)
				linkableObject = getLinkableObjectFromCallbackCollection(linkableObject as ICallbackCollection);
			
			if (!linkableObject)
				return false;
			
			var busy:Boolean = false;
			
			array_busyTraversal[array_busyTraversal.length] = linkableObject; // push
			map_busyTraversal.set(linkableObject, true);
			
			outerLoop: for (var i:int = 0; i < array_busyTraversal.length; i++)
			{
				linkableObject = array_busyTraversal[i] as ILinkableObject;
				
				if (linkableObject is ILinkableObjectWithBusyStatus)
				{
					if ((linkableObject as ILinkableObjectWithBusyStatus).isBusy())
					{
						busy = true;
						break;
					}
					// do not check children
					continue;
				}
				
				// if the object is assigned a task, it's busy
				var tasks:Array = d2d_owner_task.secondaryKeys(linkableObject);
				for each (var task:Object in tasks)
				{
					if (debugBusyTasks)
					{
						var stackTrace:String = map_task_stackTrace.get(task);
						//trace(stackTrace);
					}
					busy = true;
					break outerLoop;
				}
				
				// see if children are busy
				var children:Array = d2d_parent_child.secondaryKeys(linkableObject);
				for each (var child:Object in children)
				{
					// queue all the children that haven't been queued yet
					if (!map_busyTraversal.get(child))
					{
						array_busyTraversal[array_busyTraversal.length] = child; // push
						map_busyTraversal.set(child, true);
					}
				}
			}
			
			// reset traversal dictionary for next time
			for each (linkableObject in array_busyTraversal)
				map_busyTraversal.set(linkableObject, false);
			
			// reset traversal queue for next time
			array_busyTraversal.length = 0;
			
			return busy;
		}
		
		
		/**
		 * This maps an ILinkableObject to the ICallbackCollection associated with it.
		 */
		private const map_ILinkableObject_ICallbackCollection:WeakMap = new WeakMap();
		
		/**
		 * This maps an ICallbackCollection to the ILinkableObject associated with it.
		 */
		private const map_ICallbackCollection_ILinkableObject:WeakMap = new WeakMap();

		/**
		 * @inheritDoc
		 */
		public function getCallbackCollection(linkableObject:ILinkableObject):ICallbackCollection
		{
			if (linkableObject == null)
				return null;
			
			if (linkableObject is ICallbackCollection)
				return linkableObject as ICallbackCollection;
			
			var objectCC:ICallbackCollection = map_ILinkableObject_ICallbackCollection.get(linkableObject);
			if (objectCC == null)
			{
				objectCC = registerDisposableChild(linkableObject, new CallbackCollection());
				if (CallbackCollection.debug)
					(objectCC as CallbackCollection)._linkableObject = linkableObject;
				map_ILinkableObject_ICallbackCollection.set(linkableObject, objectCC);
				map_ICallbackCollection_ILinkableObject.set(objectCC, linkableObject);
				
				// Make sure UIComponents get registered with linkable owners because MXML developers
				// may forget to do so, since it's not simple to do in MXML.
				if (linkableObject is UIComponent)
				{
					var component:UIComponent = linkableObject as UIComponent;
					if (!_registerUIComponent(component))
						component.addEventListener(Event.ADDED, _registerUIComponentLater);
				}
			}
			return objectCC;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getLinkableObjectFromCallbackCollection(callbackCollection:ICallbackCollection):ILinkableObject
		{
			return map_ICallbackCollection_ILinkableObject.get(callbackCollection) || callbackCollection;
		}
		
		/**
		 * This function is an event listener that in turn calls _registerUIComponent.
		 * @param event The event dispatched by the UIComponent to be passed to _registerUIComponent.
		 */
		private function _registerUIComponentLater(event:Event):void
		{
			if (event.target == event.currentTarget)
			{
				var component:UIComponent = event.currentTarget as UIComponent;
				if (_registerUIComponent(component))
					component.removeEventListener(event.type, _registerUIComponentLater, event.eventPhase == EventPhase.CAPTURING_PHASE);
			}
		}
		
		/**
		 * This function will register a UIComponent/ILinkableObject as a disposable child of an ancestral
		 * DisplayObjectContainer/ILinkableObject if it has no linkable owner yet.  This makes sure that the
		 * component is disposed when its ancestor is disposed.
		 * @param linkableComponent A UIComponent that implements ILinkableObject.
		 * @return true if the component has a linkable owner, either before or after this function is called, or if the object was disposed.
		 */
		private function _registerUIComponent(linkableComponent:UIComponent):Boolean
		{
			if (objectWasDisposed(linkableComponent))
				return true; // so the event listener will be removed
			
			var owner:ILinkableObject = map_child_owner.get(linkableComponent) as ILinkableObject;
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
		 * @inheritDoc
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
			return map_disposed.has(object);
		}
		
		private const map_disposed:WeakMap = new WeakMap();
		
		private static const DISPOSE:String = "dispose"; // this is the name of the dispose() function.

		/**
		 * @inheritDoc
		 */
		public function disposeObject(object:Object):void
		{
			if (object != null && !map_disposed.get(object))
			{
				map_disposed.set(object, true);
				
				// clean up pointers to busy tasks
				disposeBusyTaskPointers(object as ILinkableObject);
				
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
					// dispose the callback collection corresponding to the object.
					// this removes all callbacks, including the one that triggers parent callbacks.
					var objectCC:ICallbackCollection = getCallbackCollection(linkableObject);
					if (objectCC != linkableObject)
						disposeObject(objectCC);
				}
				
				// unregister from parents
				var parents:Array = d2d_child_parent.secondaryKeys(object);
				for each (var parent:Object in parents)
					d2d_parent_child.remove(parent, object);
				d2d_child_parent.removeAllPrimary(object);
				
				// unregister from owner
				var owner:Object = map_child_owner.get(object);
				if (owner != null)
				{
					d2d_owner_child.remove(owner, object);
					map_child_owner.remove(object);
				}
				
				// if the object is an ILinkableVariable, unlink it from all bindable properties that were previously linked
				if (linkableObject is ILinkableVariable)
				{
					// this technically should not be necessary...
					var bindableParents:Array = _synchronizers.secondaryKeys(linkableObject);
					for each (var bindableParent:* in bindableParents)
						for each (var synchronizer:Synchronizer in _synchronizers.get(linkableObject, bindableParent))
							disposeObject(synchronizer);
					_synchronizers.removeAllPrimary(linkableObject);
				}
				
				// unlink this object from all other linkable objects
				var otherObjects:Array = d2d_lhs_rhs_setState.secondaryKeys(linkableObject);
				for each (var otherObject:Object in otherObjects)
					unlinkSessionState(linkableObject, otherObject as ILinkableObject);
				
				// dispose all registered children that this object owns
				var children:Array = d2d_owner_child.secondaryKeys(object);
				d2d_owner_child.removeAllPrimary(object);
				d2d_parent_child.removeAllPrimary(object);
				for each (var child:Object in children)
					disposeObject(child);
				
				// FOR DEBUGGING PURPOSES
				if (Capabilities.isDebugger && linkableObject)
				{
					var error:Error = new Error("This is the stack trace from when the object was previously disposed.");
					objectCC.addImmediateCallback(null, function():void { debugDisposedObject(linkableObject, error); } );
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
						var n:int = parentContainer.numChildren;
						while (n > 0)
						{
							try {
								parentContainer.removeChildAt(n--);
							} catch (e:Error) { }
						}
					}
					if (displayObject is UIComponent)
						(displayObject as UIComponent).mx_internal::cancelAllCallLaters();
				}
				
				_treeCallbacks.triggerCallbacks();
			}
		}
		
		// FOR DEBUGGING PURPOSES
		private function debugDisposedObject(disposedObject:ILinkableObject, disposedError:Error):void
		{
			// set some variables to aid in debugging - only useful if you add a breakpoint here.
			var obj:*;
			var ownerPath:Array = [];
			do {
				obj = getLinkableOwner(obj);
				if (obj)
					ownerPath.unshift(obj);
			} while (obj);
			var parents:Array = d2d_child_parent.secondaryKeys(disposedObject);
			var children:Array = d2d_parent_child.secondaryKeys(disposedObject);
			var sessionState:Object = getSessionState(disposedObject);

			// ADD A BREAKPOINT HERE TO DIAGNOSE THE PROBLEM
			var msg:String = "WARNING: An object triggered callbacks after previously being disposed. " + debugId(disposedObject);
			if (disposedObject is ILinkableVariable)
				msg += ' (value = ' + (disposedObject as ILinkableVariable).getSessionState() + ')';
			reportError(disposedError);
			reportError(msg);
		}

		/**
		 * @private
		 * For debugging only.
		 */
		public function _getOwnerPath(descendant:ILinkableObject):Array
		{
			var result:Array = [descendant];
			while (descendant && descendant != WeaveAPI.globalHashMap)
				result.unshift(debugId(descendant = getLinkableOwner(descendant)));
			if (!descendant)
				result.unshift(result[result.length - 1] + " is not a descendant of " + debugId(WeaveAPI.globalHashMap));
			return result;
		}
		
		/**
		 * @private
		 * For debugging only.
		 */
		public function _getPaths(root:ILinkableObject, descendant:ILinkableObject):Array
		{
			var results:Array = [];
			var parents:Array = d2d_child_parent.secondaryKeys(descendant);
			for each (var parent:Object in parents)
			{
				var name:String = _getChildPropertyName(parent as ILinkableObject, descendant);
				if (name != null)
				{
					// this parent may be the one we want
					var result:Array = _getPaths(root, parent as ILinkableObject);
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
		private function _getChildPropertyName(parent:ILinkableObject, child:ILinkableObject):String
		{
			if (parent is ILinkableHashMap)
				return (parent as ILinkableHashMap).getName(child);

			// find the property name that returns the child
			var names:Array = getLinkablePropertyNames(parent);
			for each (var name:String in names)
				if (parent[name] == child)
					return name;
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPath(root:ILinkableObject, descendant:ILinkableObject):Array
		{
			if (!descendant)
				return null;
			var tree:WeaveTreeItem = getSessionStateTree(root, null);
			var path:Array = _getPath(tree, descendant);
			return path;
		}
		private function _getPath(tree:WeaveTreeItem, descendant:ILinkableObject):Array
		{
			if (tree.data == descendant)
				return [];
			var children:Array = tree.children;
			for each (var child:WeaveTreeItem in children)
			{
				var path:Array = _getPath(child, descendant);
				if (path)
				{
					path.unshift(child.label);
					return path;
				}
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getObject(root:ILinkableObject, path:Array):ILinkableObject
		{
			var object:ILinkableObject = root;
			for each (var propertyName:Object in path)
			{
				if (object == null || map_disposed.get(object))
					return null;
				if (object is ILinkableHashMap)
				{
					if (propertyName is Number)
						object = (object as ILinkableHashMap).getObjects()[propertyName];
					else
						object = (object as ILinkableHashMap).getObject(String(propertyName));
				}
				else if (object is ILinkableDynamicObject)
				{
					// ignore propertyName and always return the internalObject
					object = (object as ILinkableDynamicObject).internalObject;
				}
				else
				{
					if (getLinkablePropertyNames(object).indexOf(propertyName) < 0)
						return null;
					object = object[propertyName] as ILinkableObject;
				}
			}
			return map_disposed.get(object) ? null : object;
		}
		
		
		
		
		
		
		/**************************************
		 * linking sessioned objects together
		 **************************************/





		/**
		 * This maps destination and source ILinkableObjects to a function like:
		 *     function():void { setSessionState(destination, getSessionState(source), true); }
		 */
		private const d2d_lhs_rhs_setState:Dictionary2D = new Dictionary2D(true, true);
		/**
		 * @inheritDoc
		 */
		public function linkSessionState(primary:ILinkableObject, secondary:ILinkableObject):void
		{
			if (primary == null || secondary == null)
			{
				reportError("SessionManager.linkSessionState(): Parameters to this function cannot be null.");
				return;
			}
			if (primary == secondary)
			{
				reportError("Warning! Attempt to link session state of an object with itself");
				return;
			}
			if (d2d_lhs_rhs_setState.get(primary, secondary) is Function)
				return; // already linked
			
			var setPrimary:Function = function():void { setSessionState(primary, getSessionState(secondary), true); };
			var setSecondary:Function = function():void { setSessionState(secondary, getSessionState(primary), true); };
			
			d2d_lhs_rhs_setState.set(primary, secondary, setPrimary);
			d2d_lhs_rhs_setState.set(secondary, primary, setSecondary);
			
			// when secondary changes, copy from secondary to primary
			getCallbackCollection(secondary).addImmediateCallback(primary, setPrimary);
			// when primary changes, copy from primary to secondary
			getCallbackCollection(primary).addImmediateCallback(secondary, setSecondary, true); // copy from primary now
		}
		/**
		 * @inheritDoc
		 */
		public function unlinkSessionState(first:ILinkableObject, second:ILinkableObject):void
		{
			if (first == null || second == null)
			{
				reportError("SessionManager.unlinkSessionState(): Parameters to this function cannot be null.");
				return;
			}
			
			var setFirst:Function = d2d_lhs_rhs_setState.remove(first, second) as Function;
			var setSecond:Function = d2d_lhs_rhs_setState.remove(second, first) as Function;
			
			getCallbackCollection(second).removeCallback(setFirst);
			getCallbackCollection(first).removeCallback(setSecond);
		}





		/******************************************************
		 * linking sessioned objects with bindable properties
		 ******************************************************/
		
		/**
		 * @inheritDoc
		 */
		public function linkBindableProperty(linkableVariable:ILinkableVariable, bindableParent:Object, bindablePropertyName:String, delay:uint = 0, onlyWhenFocused:Boolean = false, delayWhenFocused:Boolean = true):void
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
			
			// unlink in case previously linked (prevents double-linking)
			unlinkBindableProperty(linkableVariable, bindableParent, bindablePropertyName);
			
			if (objectWasDisposed(linkableVariable))
				return;
			
			var lookup:Object = _synchronizers.get(linkableVariable, bindableParent);
			if (!lookup)
				_synchronizers.set(linkableVariable, bindableParent, lookup = {});
			lookup[bindablePropertyName] = new Synchronizer(linkableVariable, bindableParent, bindablePropertyName, delay, onlyWhenFocused, delayWhenFocused);
			
			// for debugging
			_lastSynchronizer = lookup[bindablePropertyName];
		}
		
		// for debugging
		private static var _lastSynchronizer:Synchronizer;
		public static function debugSynchronizer():void
		{
			_lastSynchronizer.debug = true;
		}
		
		/**
		 * @inheritDoc
		 */
		public function unlinkBindableProperty(linkableVariable:ILinkableVariable, bindableParent:Object, bindablePropertyName:String):void
		{
			if (linkableVariable == null || bindableParent == null || bindablePropertyName == null)
			{
				reportError("unlinkBindableProperty(): Parameters to this function cannot be null.");
				return;
			}
			
			var lookup:Object = _synchronizers.get(linkableVariable, bindableParent);
			if (lookup && lookup[bindablePropertyName])
			{
				disposeObject(lookup[bindablePropertyName])
				delete lookup[bindablePropertyName];
			}
		}
		/**
		 * This is a multidimensional mapping, such that
		 *     _synchronizers.dictionary[linkableVariable][bindableParent][bindablePropertyName]
		 * maps to a Synchronizer object.
		 */
		private const _synchronizers:Dictionary2D = new Dictionary2D(true, true); // use weak links to be GC-friendly
		
		
		
		
		
		/*******************
		 * Computing diffs
		 *******************/
		
		
		public static const DIFF_DELETE:String = 'delete';
		
		private function copyObject(object:Object):Object
		{
			if (object === null || typeof object != 'object') // primitive value
				return object;
			else
				return ObjectUtil.copy(object); // make copies of non-primitives
		}
		
		/**
		 * @inheritDoc
		 */
		public function computeDiff(oldState:Object, newState:Object):*
		{
			var type:String = typeof(oldState); // the type of null is 'object'
			var diffValue:*;

			// special case if types differ
			if (typeof(newState) != type)
				return copyObject(newState); // make copies of non-primitives
			
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
					return copyObject(newState);
				
				return undefined; // no diff
			}
			else if (oldState is Array && newState is Array)
			{
				// If neither is a dynamic state array, don't compare them as such.
				if (!DynamicState.isDynamicStateArray(oldState) && !DynamicState.isDynamicStateArray(newState))
				{
					if (StandardLib.compare(oldState, newState) == 0)
						return undefined; // no diff
					return ObjectUtil.copy(newState);
				}
				
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
					// assume everthing is typed session state
					//note: there is no error checking here for typedState
					typedState = oldState[i];
					objectName = typedState[DynamicState.OBJECT_NAME];
					// use '' instead of null to avoid "null"
					oldLookup[objectName || ''] = typedState;
				}
				if (oldState.length != newState.length)
					changeDetected = true;
				
				// create new Array with new DynamicState objects
				var result:Array = [];
				for (i = 0; i < newState.length; i++)
				{
					// assume everthing is typed session state
					//note: there is no error checking here for typedState
					typedState = newState[i];
					objectName = typedState[DynamicState.OBJECT_NAME];
					className = typedState[DynamicState.CLASS_NAME];
					sessionState = typedState[DynamicState.SESSION_STATE];
					var oldTypedState:Object = oldLookup[objectName || ''];
					delete oldLookup[objectName || '']; // remove it from the lookup because it's already been handled
					
					// If the object specified in newState does not exist in oldState, we don't need to do anything further.
					// If the class is the same as before, then we can save a diff instead of the entire session state.
					// If the class changed, we can't save only a diff -- we need to keep the entire session state.
					if (oldTypedState != null && oldTypedState[DynamicState.CLASS_NAME] == className)
					{
						// Replace the sessionState in the new DynamicState object with the diff.
						className = null; // no change
						diffValue = computeDiff(oldTypedState[DynamicState.SESSION_STATE], sessionState);
						if (diffValue === undefined)
						{
							// Since the class name is the same and the session state is the same,
							// we only need to specify that this name is still present.
							result.push(objectName);
							
							// see if name order changed
							if (!changeDetected && oldState[i][DynamicState.OBJECT_NAME] != objectName)
								changeDetected = true;
							
							continue;
						}
						sessionState = diffValue;
					}
					else
					{
						sessionState = copyObject(sessionState);
					}
					
					// save in new array and remove from lookup
					result.push(DynamicState.create(objectName || null, className, sessionState)); // convert empty string to null
					changeDetected = true;
				}
				
				// Anything remaining in the lookup does not appear in newState.
				// Add DynamicState entries with an invalid className ("delete") to convey that each of these objects should be removed.
				for (objectName in oldLookup)
				{
					result.push(DynamicState.create(objectName || null, DIFF_DELETE)); // convert empty string to null
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
						if (newState.hasOwnProperty(oldName))
							diff[oldName] = diffValue;
						else
							diff[oldName] = undefined; // property was removed
					}
				}

				// find new properties
				for (var newName:String in newState)
				{
					if (oldState[newName] === undefined)
					{
						if (!diff)
							diff = {};
						diff[newName] = copyObject(newState[newName]);
					}
				}

				return diff;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function combineDiff(baseDiff:Object, diffToAdd:Object):Object
		{
			var baseType:String = typeof(baseDiff); // the type of null is 'object'
			var diffType:String = typeof(diffToAdd);

			// special cases
			if (baseDiff == null || diffToAdd == null || baseType != diffType || baseType != 'object')
			{
				baseDiff = copyObject(diffToAdd);
			}
			else if (baseDiff is Array && diffToAdd is Array)
			{
				var i:int;
				
				// If either of the arrays look like DynamicState arrays, treat as such
				if (DynamicState.isDynamicStateArray(baseDiff) || DynamicState.isDynamicStateArray(diffToAdd))
				{
					var typedState:Object;
					var objectName:String;

					// create lookup: objectName -> old diff entry
					// temporarily turn baseDiff into an Array of object names
					var baseLookup:Object = {};
					for (i = 0; i < baseDiff.length; i++)
					{
						typedState = baseDiff[i];
						// note: no error checking for typedState
						if (typedState is String || typedState == null)
							objectName = typedState as String;
						else
							objectName = typedState[DynamicState.OBJECT_NAME] as String;
						baseLookup[objectName] = typedState;
						// temporarily turn baseDiff into an Array of object names
						baseDiff[i] = objectName;
					}
					// apply each typedState diff appearing in diffToAdd
					for (i = 0; i < diffToAdd.length; i++)
					{
						typedState = diffToAdd[i];
						// note: no error checking for typedState
						if (typedState is String || typedState == null)
							objectName = typedState as String;
						else
							objectName = typedState[DynamicState.OBJECT_NAME] as String;
						
						// adjust names list so this name appears at the end
						if (baseLookup.hasOwnProperty(objectName))
						{
							for (var j:int = (baseDiff as Array).indexOf(objectName); j < baseDiff.length - 1; j++)
								baseDiff[j] = baseDiff[j + 1];
							baseDiff[baseDiff.length - 1] = objectName;
						}
						else
						{
							baseDiff.push(objectName);
						}
						
						// apply diff
						var oldTypedState:Object = baseLookup[objectName];
						if (oldTypedState is String || oldTypedState == null)
						{
							baseLookup[objectName] = copyObject(typedState);
						}
						else if (!(typedState is String || typedState == null)) // update dynamic state
						{
							var className:String = typedState[DynamicState.CLASS_NAME];
							// if new className is different and not null, start with a fresh typedState diff
							if (className && className != oldTypedState[DynamicState.CLASS_NAME])
							{
								baseLookup[objectName] = ObjectUtil.copy(typedState);
							}
							else // className hasn't changed, so combine the diffs
							{
								oldTypedState[DynamicState.SESSION_STATE] = combineDiff(oldTypedState[DynamicState.SESSION_STATE], typedState[DynamicState.SESSION_STATE]);
							}
						}
					}
					// change baseDiff back from names to typed states
					for (i = 0; i < baseDiff.length; i++)
						baseDiff[i] = baseLookup[baseDiff[i]];
				}
				else // not typed session state
				{
					// overwrite old Array with new Array's values
					i = baseDiff.length = diffToAdd.length;
					while (i--)
					{
						var value:Object = diffToAdd[i];
						if (value === null || typeof value != 'object')
							baseDiff[i] = value; // avoid function call overhead
						else
							baseDiff[i] = combineDiff(baseDiff[i], value);
					}
				}
			}
			else // nested object
			{
				for (var newName:String in diffToAdd)
					baseDiff[newName] = combineDiff(baseDiff[newName], diffToAdd[newName]);
			}
			
			return baseDiff;
		}
		
		public function testDiff():void
		{
			var states:Array = [
				[
					{objectName: 'a', className: 'aClass', sessionState: 'aVal'},
					{objectName: 'b', className: 'bClass', sessionState: 'bVal1'}
				],
				[
					{objectName: 'b', className: 'bClass', sessionState: 'bVal2'},
					{objectName: 'a', className: 'aClass', sessionState: 'aVal'}
				],
				[
					{objectName: 'a', className: 'aNewClass', sessionState: 'aVal'},
					{objectName: 'b', className: 'bClass', sessionState: null}
				],
				[
					{objectName: 'b', className: 'bClass', sessionState: null}
				]
			];
			var diffs:Array = [];
			var combined:Array = [];
			var baseDiff:* = null;
			for (var i:int = 1; i < states.length; i++)
			{
				var diff:* = computeDiff(states[i - 1], states[i]);
				diffs.push(diff);
				baseDiff = combineDiff(baseDiff, diff);
				combined.push(ObjectUtil.copy(baseDiff));
			}
			trace('diffs',ObjectUtil.toString(diffs));
			trace('combined',ObjectUtil.toString(combined));
		}
	}
}

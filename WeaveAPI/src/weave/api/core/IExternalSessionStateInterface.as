/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package weave.api.core
{
	/**
	 * This interface is a set of functions intended to be exposed as an external JavaScript API.
	 * 
	 * The user interface in Weave is initially generated from a saved session state.
	 * User interactions affect the session state, and changes in the session state affect
	 * the display at runtime.  The API provides a window into the session state so most
	 * interactions that can be made through the GUI can also be made through JavaScript calls.
	 * 
	 * @author adufilie
	 */
	public interface IExternalSessionStateInterface
	{
		/**
		 * This function gets the current session state of a linkable object.  Nested XML objects will be converted to Strings before returning.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return An object containing the values from the sessioned properties.
		 */
		function getSessionState(objectPath:Array):Object;
		
		/**
		 * This function updates the current session state of an object.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @param newState An object containing the new values for sessioned properties in the sessioned object.
		 * @param removeMissingDynamicObjects If true, this will remove any properties from an ILinkableCompositeObject that do not appear in the new session state.
		 * @return true if objectPath refers to an existing object in the session state.
		 */
		function setSessionState(objectPath:Array, newState:Object, removeMissingObjects:Boolean = true):Boolean;

		/**
		 * This function will get the qualified class name of an object appearing in the session state.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return The qualified class name of the object referred to by objectPath.
		 */
		function getObjectType(objectPath:Array):String;

		/**
		 * This function gets a list of names of children of an object appearing in the session state.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return An Array of names of sessioned children of the object referred to by objectPath, or null if the object doesn't exist.
		 */
		function getChildNames(objectPath:Array):Array;

		/**
		 * This function will reorder children of an object implementing ILinkableHashMap.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @param orderedChildNames The new order to use for the children of the object specified by objectPath.
		 * @return true if objectPath refers to the location of an ILinkableHashMap.
		 */
		function setChildNameOrder(hashMapPath:Array, orderedChildNames:Array):Boolean;

		/**
		 * This function will dynamically create an object at the specified location in the session state if its parent implements
		 * ILinkableCompositeObject.  If the object at the specified location already exists and is of the requested type,
		 * this function does nothing.
		 * If the parent of the dynamic object to be created implements ILinkableHashMap, a value of null for the child name
		 * will cause a new name to be generated.
		 * If the parent of the dynamic object to be created implements ILinkableDynamicObject, the name of the child refers to
		 * the name of a static object appearing at the top level of the session state.  A child name equal to null in this case
		 * will create a local object that does not appear at the top level of the session state.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @param objectType The qualified name of a class implementing ILinkableObject.
		 * @return true if, after calling this function, an object of the requested type exists at the requested location.
		 */
		function requestObject(objectPath:Array, objectType:String):Boolean;

		/**
		 * This function will remove a dynamically created object if it is the child of an ILinkableCompositeObject.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @return true if objectPath refers to a valid location where dynamically created objects can exist.
		 */
		function removeObject(objectPath:Array):Boolean;

		/**
		 * This function serializes a session state from Object format to XML String format.
		 * @param sessionState A session state object.
		 * @param tagName The name to use for the root XML tag that gets generated from the session state.
		 * @return An XML serialization of the session state.
		 */
		function convertSessionStateObjectToXML(sessionState:Object, tagName:String = "sessionState"):String;

		/**
		 * This function converts a session state from XML format to Object format.  Nested XML objects will be converted to Strings before returning.
		 * @param sessionState A session state that has been encoded in an XML String.
		 * @return The deserialized session state object.
		 */
		function convertSessionStateXMLToObject(sessionStateXML:String):Object;
		
		/**
		 * This function will evaluate an expression using the compiler. An object path may be passed as the first parameter
		 * to act as the <code>this</code> pointer for the expression, or libraries may be included by passing an array of fully 
		 * qualified names.
		 * 
		 * <br><br>
		 * Examples: 
		 * <br>
		 * <code> document.getElementById('weave').evaluateExpression(['MyScatterPlot'], 'toggleControlPanel()')</code>
		 * <br> 
		 * <code> document.getElementById('weave').evaluateExpression(['MyScatterPlot'], 'move(new_x, new_y)', {new_x : 400, new_y : 300})</code>
		 * <br>
		 * <code> document.getElementById('weave').evaluateExpression(null, 'openDefaultEditor()', null, ['weave.ui::SessionStateEditor'])</code>
		 * <br> <br>
		 * 
		 * Note that any code written for this function depends on the implementation of the ActionScript
		 * code inside Weave, which is subject to change. 
		 *  
		 * @param scopeObjectPath A sequence of child names used to refer to an object appearing in the session state which will be used as the <code>this</code> pointer when evaluating the expression.
		 * @param expression The expression to evaluate.
		 * @param variables A hash map of variable names to values.
		 * @param staticLibraries An array of fully qualified class names which contain static methods to include the expression.
		 * @return The value of the evaluated expression.
		 * @see weave.compiler.Compiler
		 */
		function evaluateExpression(objectPath:Array, methodName:String, variables:Object = null, libraries:Array = null):*;
		
		/**
		 * This function will add a callback that will be delayed except during a scheduled time each frame.  These grouped callbacks use a
		 * central trigger list, meaning that if multiple CallbackCollections trigger the same grouped callback before the scheduled time,
		 * it will behave as if it were only triggered once.  The callback function will not be called recursively as a result of it
		 * triggering callbacks recursively.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @param callback The callback function that will only be allowed to run during a scheduled time each frame.  It must be specified as a String and must not require any parameters.
		 * @param triggerCallbackNow If this is set to true, the callback will be triggered to run during the scheduled time after it is added.
		 * @return true if objectPath refers to an existing object in the session state.
		 * @see weave.api.core.ICallbackInterface#addGroupedCallback
		 */
		function addCallback(objectPath:Array, callback:String, triggerCallbackNow:Boolean = false):Boolean;
		
		/**
		 * This function will remove a callback that was previously added.
		 * @param objectPath A sequence of child names used to refer to an object appearing in the session state.
		 * @param callback The function to remove from the list of callbacks, which must be specified as a String.
		 * @return true if objectPath refers to an existing object in the session state.
		 */
		function removeCallback(objectPath:Array, callback:String):Boolean;
	}
}

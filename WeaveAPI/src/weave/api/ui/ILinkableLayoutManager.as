/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.ui
{
	import mx.core.IVisualElement;
	
	import weave.api.core.ILinkableObject;

	/**
	 * The session state for this object should contain all the layout information for a list of components, but not the components themselves.
	 * Callbacks should trigger when any of the layout settings change.
	 * 
	 * @author adufilie
	 */
	public interface ILinkableLayoutManager extends ILinkableObject
	{
		/**
		 * Adds a component to the layout.
		 * @param id A unique identifier for the component.
		 * @param component The component to add to the layout.
		 */		
		function addComponent(id:String, component:IVisualElement):void;
		
		/**
		 * Removes a component from the layout.
		 * @param id The id of the component to remove.
		 */
		function removeComponent(id:String):void;
		
		/**
		 * Reorders the components. 
		 * @param orderedIds An ordered list of ids.
		 */
		function setComponentOrder(orderedIds:Array):void;
		
		/**
		 * This is an ordered list of ids in the layout.
		 */		
		function getComponentOrder():Array;
		
		/**
		 * This function can be used to check if a component still exists in the layout.
		 */		
		function hasComponent(id:String):Boolean;
	}
}

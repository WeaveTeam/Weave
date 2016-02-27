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

package weavejs.api.data
{
	import weavejs.api.core.ILinkableObject;

	/**
	 * An object with a list of named DynamicColumn and/or ILinkableHashMap objects that an AttributeSelectorPanel can link to.
	 */
	public interface ISelectableAttributes extends ILinkableObject
	{
		/**
		 * This function should be defined with override by subclasses.
		 * @return An Array of names corresponding to the objects returned by getSelectableAttributes().
		 *         These names will be passed to lang() before being displayed to the user.
		 */
		function getSelectableAttributeNames():Array/*/<string>/*/;
		
		/**
		 * This function should be defined with override by subclasses.
		 * @return An Array of DynamicColumn and/or ILinkableHashMap objects that an AttributeSelectorPanel can link to.
		 */
		function getSelectableAttributes():Array/*/<(IColumnWrapper & weavejs.api.core.ILinkableDynamicObject)|weavejs.api.core.ILinkableHashMap>/*/;
	}
}

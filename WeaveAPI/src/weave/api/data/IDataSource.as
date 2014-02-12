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

package weave.api.data
{
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableObject;
	
	/**
	 * This is a simple and generic interface for getting columns of data from a source.
	 * 
	 * @author adufilie
	 */
	public interface IDataSource extends ILinkableObject
	{
		/**
		 * Refreshes the attribute hierarchy.
		 */
		function refreshHierarchy():void
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		function getHierarchyRoot():IWeaveTreeNode;
		
		/**
		 * Populates a LinkableDynamicObject with an IColumnReference corresponding to a node in the attribute hierarchy.
		 * @return true if successful.
		 */
		function getColumnReference(node:IWeaveTreeNode, output:ILinkableDynamicObject):Boolean;

		/**
		 * The parameter to this function used to be pathInHierarchy because old implementations use XML path objects.
		 * The parameter type is now temporarily Object during this transitional phase.
		 * In future versions, the parameter will be an IColumnReference object.
		 * @param columnReference A reference to a column in this IDataSource.
		 * @return An IAttributeColumn object that will be updated when the column data downloads.
		 */
		function getAttributeColumn(columnReference:IColumnReference):IAttributeColumn;
	}
}

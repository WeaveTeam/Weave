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
	import weave.api.core.ILinkableObject;
	
	/**
	 * This is a simple and generic interface for getting columns of data from a source.
	 * 
	 * @author adufilie
	 */
	public interface IDataSource extends ILinkableObject
	{
		/**
		 * TODO: Instead of XML, this should be a hierarchy of IColumnReference objects
		 *       that can be passed to getAttributeColumn().
		 * 
		 * @return An AttributeHierarchy object that will be updated when new pieces of the hierarchy are filled in.
		 */
		function get attributeHierarchy():IAttributeHierarchy;

		/**
		 * initializeHierarchySubtree
		 * @param subtreeNode A node in the hierarchy representing the root of the subtree to initialize, or null to initialize the root of the hierarchy.
		 */
		function initializeHierarchySubtree(subtreeNode:XML = null):void;

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

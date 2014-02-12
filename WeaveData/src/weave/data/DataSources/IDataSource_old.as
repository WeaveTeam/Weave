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

package weave.data.DataSources
{
	import weave.api.data.IDataSource;
	import weave.core.LinkableXML;
	
	/**
	 * This is a simple and generic interface for getting columns of data from a source.
	 * 
	 * @author adufilie
	 */
	public interface IDataSource_old extends IDataSource
	{
		function get attributeHierarchy():LinkableXML;
		function initializeHierarchySubtree(subtreeNode:XML = null):void;
	}
}

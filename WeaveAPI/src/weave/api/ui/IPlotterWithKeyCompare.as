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
	import weave.api.data.IQualifiedKey;
	
	/**
	 * This is an extension of IPlotter that provides a keyCompare function to be used by an IPlotTask to sort keys.
	 * 
	 * @author adufilie
	 */
	public interface IPlotterWithKeyCompare extends IPlotter
	{
		/**
		 * This function will be used by an IPlotTask to sort keys before calling drawPlotAsyncIteration().
		 * @param key1 The first key.
		 * @param key2 The second key.
		 * @return -1 if key1 should appear before key2, 1 if key1 should appear after key2, or 0 if it doesn't matter.
		 */		
		function keyCompare(key1:IQualifiedKey, key2:IQualifiedKey):int;
	}
}

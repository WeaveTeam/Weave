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

package weavejs.api.ui
{
	public interface IInitSelectableAttributes extends ISelectableAttributes
	{
		/**
		 * This will initialize the selectable attributes using a list of columns and/or column references.
		 * Tools can override this function for different behavior.
		 * @param input An Array of IAttributeColumn and/or IColumnReference objects
		 */
		function initSelectableAttributes(input:Array):void;
	}
}

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

package weave.ui
{
	/**
	 * An IndentGroup can be set as the group property of an Indent object.
	 * @see weave.ui.Indent#group
	 * @author adufilie
	 */
	public class IndentGroup
	{
		/**
		 * This is the maximum measuredWidth of all the Indent labels under this group.
		 */		
		[Bindable] public var measuredIndent:Number = 0;
	}
}

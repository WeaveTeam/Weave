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
	import weave.editors.StringDataFilterEditor;

	[ExcludeClass]
	[Deprecated(replacement="weave.ui.DataFilterTool")]
	public class DataFilter extends DataFilterTool
	{
		public function DataFilter()
		{
			var sdfe:StringDataFilterEditor = editor.requestLocalObject(StringDataFilterEditor, false);
			sdfe.layoutMode.value = MenuToolViewStack.LAYOUT_COMBO;
			sdfe.showToggle.value = true;
		}
	}
}

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
	import weave.api.objectWasDisposed;
	import weave.editors.NumberDataFilterEditor;
	import weave.editors.StringDataFilterEditor;

	[Deprecated] [ExcludeClass] public class DataFilter extends DataFilterTool
	{
		public function DataFilter()
		{
			super();
			callLater(init);
		}
		private function init():void
		{
			if (objectWasDisposed(this))
				return;
			
			var sdfe:StringDataFilterEditor = editor.target as StringDataFilterEditor;
			var ndfe:NumberDataFilterEditor = editor.target as NumberDataFilterEditor;
			if (sdfe)
			{
				sdfe.layoutMode.value = MenuToolViewStack.LAYOUT_COMBO;
				sdfe.showToggle.value = true;
			}
			else if (ndfe)
			{
				ndfe.showToggle.value = true;
			}
			else
				callLater(init);
		}
	}
}

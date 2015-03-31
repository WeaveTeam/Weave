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

package
{
	import weave.ui.ErrorLogPanel;

	public function weaveTraceImpl(...args):void
	{
		if ($.initialized)
		{
			var elp:ErrorLogPanel = ErrorLogPanel.getInstance();
			if (!elp.parent)
				ErrorLogPanel.openErrorLog();
			elp.console.consoleTrace.apply(null, args);
		}
		else if ($.backlog)
		{
			$.backlog.push(args);
		}
		else
		{
			$.backlog = [args];
			WeaveAPI.StageUtils.callLater(null, $.flush);
		}
	}
}

internal class $
{
	public static var initialized:Boolean = false;
	public static var backlog:Array = null;
	public static function flush():void
	{
		initialized = true;
		for each (var params:Array in backlog)
			weaveTraceImpl.apply(null, params);
		backlog = null;
	}
}
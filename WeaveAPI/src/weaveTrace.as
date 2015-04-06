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
	import flash.system.Capabilities;
	import flash.utils.getDefinitionByName;

	/**
	 * This function will call a separate implementation under the default package, named weaveTraceImpl.
	 * 
	 * @author adufilie
	 */	
	public function weaveTrace(...args):void
	{
		if ($.weaveTraceImpl == null)
		{
			try
			{
				$.weaveTraceImpl = getDefinitionByName('weaveTraceImpl') as Function;
			}
			catch (e:Error)
			{
				// no need to spam WeaveAPI.externalTrace() with this message
				trace(e.message);
			}
			
			if ($.weaveTraceImpl == null)
				$.weaveTraceImpl = Capabilities.isDebugger ? trace : WeaveAPI.externalTrace;
		}
		$.weaveTraceImpl.apply(null, args);
	}
}

internal class $
{
	public static var weaveTraceImpl:Function;
}

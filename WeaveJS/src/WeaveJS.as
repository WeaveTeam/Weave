/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import weavejs.path.WeavePath;
	import weavejs.util.JS;
	
	public class WeaveJS
	{
		public static const _init:* = JS.fix_is();
		
		public function WeaveJS()
		{
		}
		
		private static const WEAVE_EXTERNAL_TOOLS:String = "WeaveExternalTools";
		public function start():void
		{
			var window:Object = JS.global;
			var weave:Weave = new Weave();
			window.weave = weave;
			
			if (window.opener && window.opener[WEAVE_EXTERNAL_TOOLS] && window.opener[WEAVE_EXTERNAL_TOOLS][window.name])
			{
				// ownerPath is a WeavePath from ActionScript Weave
				var ownerPath:* = window.opener.WeaveExternalTools[window.name].path;
				WeavePath.migrate(ownerPath, weave);
			}
			else
			{
				// TEMPORARY until we read a session state using url params
				WeaveTest.test(weave);
				return;
			}
		}
	}
}
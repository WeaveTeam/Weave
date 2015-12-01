/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import weavejs.utils.JS;
	
	public class WeaveJS
	{
		public static const _init:* = JS.fix_is();
		
		public function WeaveJS()
		{
		}
		
		public function start():void
		{
			// for testing only
			JS.global.weave = new Weave();
			JS.global.weave.test();
		}
	}
}
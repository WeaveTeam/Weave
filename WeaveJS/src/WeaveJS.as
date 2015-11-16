/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import weavejs.Weave;
	import weavejs.utils.Utils;
	
	public class WeaveJS
	{
		public static const _init:* = Utils.fix_is_as();
		
		public function WeaveJS()
		{
		}
		public function start():void
		{
			// make Weave accessible from global scope
			Weave.global.Weave = Weave;
			
			new Weave().test();
		}
	}
}
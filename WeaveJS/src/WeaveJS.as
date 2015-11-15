/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import flash.display.Sprite;
	
	import weavejs.Weave;
	

	public class WeaveJS extends Sprite
	{
		public function WeaveJS()
		{
			super();
		}
		public function start():void
		{
			Weave.global.Weave = Weave;
			new Weave().test();
		}
	}
}
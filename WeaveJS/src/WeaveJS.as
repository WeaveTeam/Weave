/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import weavejs.data.ColumnUtils;
	import weavejs.path.WeavePath;
	import weavejs.util.JS;
	
	public class WeaveJS
	{
		public function WeaveJS()
		{
		}
		
		private static const WEAVE_EXTERNAL_TOOLS:String = "WeaveExternalTools";
		public function start():void
		{
			var window:Object = JS.global;
			
			// TEMPORARY HACK - omit keySet filter
			var joinColumns:Function = ColumnUtils.joinColumns;
			ColumnUtils['joinColumns'] = function(columns:Array, dataType:Object = null, allowMissingData:Boolean = false):Array {
				return joinColumns.call(ColumnUtils, columns, dataType, allowMissingData);
			};
			
			if (window.opener && window.opener[WEAVE_EXTERNAL_TOOLS] && window.opener[WEAVE_EXTERNAL_TOOLS][window.name])
			{
				JS.log('using WeaveJS');
				var weave:Weave = new Weave();
				// ownerPath is a WeavePath from Flash
				var ownerPath:* = window.opener.WeaveExternalTools[window.name].path;
				WeavePath.migrate(ownerPath, weave);
				
				window.weave = weave;
			}
			else
			{
				// TEMPORARY until we read a session state using url params
				//WeaveTest.test(weave);
				WeaveTest;
			}
		}
	}
}
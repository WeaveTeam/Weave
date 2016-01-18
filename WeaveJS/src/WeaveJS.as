/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.IProgressIndicator;
	import weavejs.api.core.IScheduler;
	import weavejs.api.core.ISessionManager;
	import weavejs.api.data.IAttributeColumnCache;
	import weavejs.api.data.ICSVParser;
	import weavejs.api.data.IQualifiedKeyManager;
	import weavejs.api.data.IStatisticsCache;
	import weavejs.api.net.IURLRequestUtils;
	import weavejs.api.ui.IEditorManager;
	import weavejs.core.EditorManager;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.LinkableVariable;
	import weavejs.core.ProgressIndicator;
	import weavejs.core.Scheduler;
	import weavejs.core.SessionManager;
	import weavejs.data.AttributeColumnCache;
	import weavejs.data.CSVParser;
	import weavejs.data.StatisticsCache;
	import weavejs.data.key.QKeyManager;
	import weavejs.net.URLRequestUtils;
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
			WeaveAPI.ClassRegistry['defaultPackages'].push(
				'weavejs',
				'weavejs.api',
				'weavejs.api.core',
				'weavejs.api.data',
				'weavejs.api.service',
				'weavejs.api.ui',
				'weavejs.core',
				'weavejs.data',
				'weavejs.data.bin',
				'weavejs.data.column',
				'weavejs.data.hierarchy',
				'weavejs.data.key',
				'weavejs.data.source',
				'weavejs.geom',
				'weavejs.path',
				'weavejs.util'
			);
			
			WeaveAPI.ClassRegistry.registerImplementation(ILinkableHashMap, LinkableHashMap);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(IURLRequestUtils, URLRequestUtils);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(IAttributeColumnCache, AttributeColumnCache);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(ISessionManager, SessionManager);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(IQualifiedKeyManager, QKeyManager);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(IScheduler, Scheduler);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(IProgressIndicator, ProgressIndicator);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(IStatisticsCache, StatisticsCache);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(IEditorManager, EditorManager);
			WeaveAPI.ClassRegistry.registerSingletonImplementation(ICSVParser, CSVParser);
			Weave.registerClass("FlexibleLayout", LinkableVariable);
			Weave.registerClass("ExternalTool", LinkableHashMap);
			
			var window:Object = JS.global;
			
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
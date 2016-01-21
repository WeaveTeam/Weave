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
	import weavejs.api.core.ILocale;
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
	import weavejs.core.Locale;
	import weavejs.core.ProgressIndicator;
	import weavejs.core.Scheduler;
	import weavejs.core.SessionManager;
	import weavejs.data.AttributeColumnCache;
	import weavejs.data.CSVParser;
	import weavejs.data.ColumnUtils;
	import weavejs.data.StatisticsCache;
	import weavejs.data.key.QKeyManager;
	import weavejs.net.URLRequestUtils;
	
	public class WeaveJS
	{
		public function WeaveJS()
		{
		}
		
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
			WeaveAPI.ClassRegistry.registerSingletonImplementation(ILocale, Locale);
			Weave.registerClass("FlexibleLayout", LinkableVariable);
			Weave.registerClass("ExternalTool", LinkableHashMap);
			
			// TEMPORARY HACK - omit keySet filter
//			var joinColumns:Function = ColumnUtils.joinColumns;
//			ColumnUtils['joinColumns'] = function(columns:Array, dataType:Object = null, allowMissingData:Boolean = false):Array {
//				return joinColumns.call(ColumnUtils, columns, dataType, allowMissingData);
//			};
			
			// TEMPORARY
			//WeaveTest.test(weave);
			WeaveTest;
		}
	}
}
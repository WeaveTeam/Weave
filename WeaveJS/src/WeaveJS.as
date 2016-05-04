/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableDynamicObject;
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.core.ILocale;
	import weavejs.api.core.IProgressIndicator;
	import weavejs.api.core.IScheduler;
	import weavejs.api.core.ISessionManager;
	import weavejs.api.data.IAttributeColumnCache;
	import weavejs.api.data.ICSVParser;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IDataSource_Transform;
	import weavejs.api.data.IQualifiedKeyManager;
	import weavejs.api.data.IStatisticsCache;
	import weavejs.api.net.IURLRequestUtils;
	import weavejs.api.ui.IEditorManager;
	import weavejs.core.EditorManager;
	import weavejs.core.LinkableDynamicObject;
	import weavejs.core.LinkableHashMap;
	import weavejs.core.Locale;
	import weavejs.core.ProgressIndicator;
	import weavejs.core.Scheduler;
	import weavejs.core.SessionManager;
	import weavejs.data.AttributeColumnCache;
	import weavejs.data.CSVParser;
	import weavejs.data.StatisticsCache;
	import weavejs.data.key.QKeyManager;
	import weavejs.data.source.CKANDataSource;
	import weavejs.data.source.CSVDataSource;
	import weavejs.data.source.CensusDataSource;
	import weavejs.data.source.DBFDataSource;
	import weavejs.data.source.ForeignDataMappingTransform;
	import weavejs.data.source.GeoJSONDataSource;
	import weavejs.data.source.GroupedDataTransform;
	import weavejs.data.source.WeaveDataSource;
	import weavejs.geom.SolidFillStyle;
	import weavejs.geom.SolidLineStyle;
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
			
			WeaveAPI.ClassRegistry.registerImplementation(ILinkableHashMap, LinkableHashMap);
			WeaveAPI.ClassRegistry.registerImplementation(ILinkableDynamicObject, LinkableDynamicObject);
			
			// temporary hack
			//TODO - traverse weavejs namespace and register all classes with all their interfaces
			var IDataSource_File:Class = IDataSource;
			var IDataSource_Service:Class = IDataSource;
			var IDataSource_Transform:Class = IDataSource;
			WeaveAPI.ClassRegistry.registerImplementation(IDataSource_File, CSVDataSource, "CSV file");
			WeaveAPI.ClassRegistry.registerImplementation(IDataSource_File, DBFDataSource, "SHP/DBF files");
			WeaveAPI.ClassRegistry.registerImplementation(IDataSource_File, GeoJSONDataSource, "GeoJSON file");
			WeaveAPI.ClassRegistry.registerImplementation(IDataSource_Service, WeaveDataSource, "Weave server");
			WeaveAPI.ClassRegistry.registerImplementation(IDataSource_Service, CKANDataSource, "CKAN server");
			WeaveAPI.ClassRegistry.registerImplementation(IDataSource_Service, CensusDataSource, "Census.gov");
			WeaveAPI.ClassRegistry.registerImplementation(IDataSource_Transform, ForeignDataMappingTransform, "Foreign data mapping");
			WeaveAPI.ClassRegistry.registerImplementation(IDataSource_Transform, GroupedDataTransform, "Grouped data transform");
			
			Weave.registerClass(SolidFillStyle, "ExtendedFillStyle");
			Weave.registerClass(SolidLineStyle, "ExtendedLineStyle");
			
			// TEMPORARY
			//WeaveTest.test(weave);
			WeaveTest;
		}
	}
}
/*
	Weave (Web-based Analysis and Visualization Environment)
	Copyright (C) 2008-2011 University of Massachusetts Lowell
	
	This file is a part of Weave.
	
	Weave is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License, Version 3,
	as published by the Free Software Foundation.
	
	Weave is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package
{
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.ICSVParser;
	import weave.api.data.IProjectionManager;
	import weave.api.data.IQualifiedKeyManager;
	import weave.api.data.IStatisticsCache;
	import weave.api.services.IURLRequestUtils;
	import weave.core.ClassUtils;
	import weave.core.WeaveXMLDecoder;
	import weave.data.AttributeColumnCache;
	import weave.data.CSVParser;
	import weave.data.DataSources.WeaveDataSource;
	import weave.data.ProjectionManager;
	import weave.data.QKeyManager;
	import weave.data.StatisticsCache;
	import weave.services.URLRequestUtils;

	public class _InitializeWeaveData
	{
		[Embed(source="WeavePathData.js", mimeType="application/octet-stream")]
		public static const WeavePathData:Class;
		
		/**
		 * Register singleton implementations for WeaveAPI framework classes
		 */
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IAttributeColumnCache, AttributeColumnCache);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IStatisticsCache, StatisticsCache);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IQualifiedKeyManager, QKeyManager);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IProjectionManager, ProjectionManager);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IURLRequestUtils, URLRequestUtils);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(ICSVParser, CSVParser);
		
		/**
		 * Include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
		 */
		WeaveXMLDecoder.includePackages(
			"weave.data",
			"weave.data.AttributeColumns",
			"weave.data.BinClassifiers",
			"weave.data.BinningDefinitions",
			"weave.data.DataSources",
			"weave.data.KeySets",
			"weave.data.Transforms",
			"weave.primitives",
			"weave.services",
			"weave.services.beans",
			"weave.services.collaboration",
			"weave.services.wms"
		);
		ClassUtils.registerDeprecatedClass("OpenIndicatorsServletDataSource", WeaveDataSource);
		ClassUtils.registerDeprecatedClass("OpenIndicatorsDataSource", WeaveDataSource);
	}
}

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
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumnCache;
	import weave.api.data.ICSVParser;
	import weave.api.data.IProjectionManager;
	import weave.api.data.IQualifiedKeyManager;
	import weave.api.data.IStatisticsCache;
	import weave.api.services.IURLRequestUtils;
	import weave.core.WeaveXMLDecoder;
	import weave.data.AttributeColumnCache;
	import weave.data.CSVParser;
	import weave.data.ProjectionManager;
	import weave.data.QKeyManager;
	import weave.data.StatisticsCache;
	import weave.services.URLRequestUtils;

	public class _InitializeWeaveData
	{
		/**
		 * Register singleton implementations for WeaveAPI framework classes
		 */
		WeaveAPI.registerSingleton(IAttributeColumnCache, AttributeColumnCache);
		WeaveAPI.registerSingleton(IStatisticsCache, StatisticsCache);
		WeaveAPI.registerSingleton(IQualifiedKeyManager, QKeyManager);
		WeaveAPI.registerSingleton(IProjectionManager, ProjectionManager);
		WeaveAPI.registerSingleton(IURLRequestUtils, URLRequestUtils);
		WeaveAPI.registerSingleton(ICSVParser, CSVParser);
		
		/**
		 * Include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
		 */
		WeaveXMLDecoder.includePackages(
			"weave.data",
			"weave.data.AttributeColumns",
			"weave.data.BinClassifiers",
			"weave.data.BinningDefinitions",
			"weave.data.ColumnReferences",
			"weave.data.DataSources",
			"weave.data.KeySets",
			"weave.primitives",
			"weave.Reports",
			"weave.services.wms"
		);
	}
}

/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

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
	import weave.data.KeySets.ColumnDataFilter;
	import weave.data.ProjectionManager;
	import weave.data.QKeyManager;
	import weave.data.StatisticsCache;
	import weave.services.URLRequestUtils;

	public class _InitializeWeaveData
	{
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
			"weave.data.hierarchy",
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
		ClassUtils.registerDeprecatedClass("weave.data.KeySets.StringDataFilter", ColumnDataFilter);
		ClassUtils.registerDeprecatedClass("weave.data.KeySets.NumberDataFilter", ColumnDataFilter);
	}
}

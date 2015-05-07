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

package weave.data.DataSources
{
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.disposeObject;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.hierarchy.ColumnTreeNode;
	import weave.services.JsonCache;
	import weave.services.WeaveRServlet;
	
	public class RDataSource extends AbstractDataSource implements IDataSource_Service
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, RDataSource, "R Data Source");
		
		private var rServlet:WeaveRServlet;

		private const jsonCache:JsonCache = newLinkableChild(this, JsonCache);
	
		public const scriptName:LinkableString = newLinkableChild(this, LinkableString);
		
		public const scriptOptions:LinkableHashMap = newLinkableChild(this, LinkableHashMap); 
		
		public const rServiceURL:LinkableString = newLinkableChild(this, LinkableString);
		
		
		public function runScript():void
		{
			
			// runs the script
			//rServlet.runScript(scriptName.value, scriptOptions);		
		}

		override protected function initialize():void
		{
			// initialize the RSe
			rServiceURL.value = "/WeaveServices/Rservice";
			rServlet = new WeaveRServlet(rServiceURL.value);
			super.initialize();
		}
		
		override protected function refreshHierarchy():void
		{
			
		}
		
		
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			
		}
	}
}

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
	import flash.utils.Dictionary;
	
	import mx.rpc.events.FaultEvent;
	
	import weave.api.data.ColumnMetadata;
	import weave.api.data.DataType;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_Service;
	import weave.api.data.IWeaveTreeNode;
	import weave.api.disposeObject;
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.services.JsonCache;
	import weave.services.WeaveRServlet;
	
	public class RDataSource extends AbstractDataSource implements IDataSource_Service
	{
		private var scriptName:String = "";
		
		private var rService:WeaveRServlet = null;
		
		public const scriptOptions:LinkableHashMap = newLinkableChild(this, LinkableHashMap);

		public function RDataSource()
	    {
			
	    }
			
	    override protected function initialize():void
	    {
			//rService = new WeaveRServlet(Weave.properties.rServiceURL.value);
	        super.initialize();
	    }
	    
		
		public function runScript(data:Object):void
		{
			
		}
	
	
		private function handleFault(event:FaultEvent, token:Object = null):void
		{
	
		}
		
	    override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
	    {   
	
	    }
	}
}
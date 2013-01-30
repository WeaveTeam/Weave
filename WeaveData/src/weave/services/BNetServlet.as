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

package weave.services
{
	import mx.rpc.AsyncToken;

	
	import weave.api.data.IQualifiedKey;
	import weave.api.core.ILinkableObject;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.services.IWeaveDataService;
	import weave.api.services.IWeaveGeometryTileService;
	import weave.utils.HierarchyUtils;
	import weave.services.DelayedAsyncInvocation;
	
	/**
	 * This is a wrapper class for making asynchronous calls to a Weave data servlet.
	 * 
	 * @author adufilie
	 */
	public class BNetServlet implements ILinkableObject
	{
		public function BNetServlet(url:String)
		{
			servlet = new AMF3Servlet(url);
			registerLinkableChild(this, servlet);
		}
		protected var servlet:AMF3Servlet;
		public function listNetworks():DelayedAsyncInvocation
		{
			return servlet.invokeAsyncMethod("listNetworks") as DelayedAsyncInvocation;
		}
		public function listEdges():DelayedAsyncInvocation
		{
			return servlet.invokeAsyncMethod("listEdges") as DelayedAsyncInvocation;
		}
		public function listNodes():DelayedAsyncInvocation
		{
			return servlet.invokeAsyncMethod("listNodes") as DelayedAsyncInvocation;
		}
		public function createNetwork(netName:String):DelayedAsyncInvocation
		{
			return servlet.invokeAsyncMethod("createNetwork", null) as DelayedAsyncInvocation;
		}
		public function destroyNetwork(netName:String):DelayedAsyncInvocation
		{
			return servlet.invokeAsyncMethod("destroyNetwork", arguments) as DelayedAsyncInvocation;
		}
		public function setEvidence(netName:String, nodeName:String, nodeState:String, nodeEvidence:Number):DelayedAsyncInvocation
		{
			return servlet.invokeAsyncMethod("setEvidence", arguments) as DelayedAsyncInvocation;
		}
	}
}

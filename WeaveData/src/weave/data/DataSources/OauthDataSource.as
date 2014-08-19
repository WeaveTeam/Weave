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
package weave.data.DataSources
{
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.detectLinkableObjectChange;
	import weave.api.disposeObject;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.data.IDataSource;
	import weave.api.data.IWeaveTreeNode;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.services.OauthServlet;

	public class OauthDataSource extends AbstractDataSource
	{
		WeaveAPI.ClassRegistry.registerImplementation(IDataSource, OauthDataSource, "Auhtorized Data");
		public function OauthDataSource()
		{
			super();
			url.addImmediateCallback(this, handleURLChange, true);
		}
		
		public const clientID:LinkableString = registerLinkableChild(this, new LinkableString("20a867dd3176481f9d64f409bfbe3df3"));
		public const clientSecret:LinkableString = registerLinkableChild(this, new LinkableString("c624be931e554d25b71095e0b69fd6c6"));
		public const redirectUri:LinkableString = registerLinkableChild(this, new LinkableString('http://localhost:8080/GoogleServices/OauthService'));
		public const authUri:LinkableString = registerLinkableChild(this, new LinkableString("https://runkeeper.com/apps/authorize"));
		public const tokenUri:LinkableString = registerLinkableChild(this, new LinkableString("https://runkeeper.com/apps/token"));
		
		
		public const url:LinkableString = registerLinkableChild(this,new LinkableString("/GoogleServices/OauthService"));
		private var _service:OauthServlet = null;
	
		
		/**
		 * This function prevents url.value from being null.
		 */
		private function handleURLChange():void
		{
			url.delayCallbacks();
			// replace old service
			disposeObject(_service);
			_service = registerLinkableChild(this, new OauthServlet(url.value));
			
			url.resumeCallbacks();
		}
		
		/**
		 * This gets called as a grouped callback.
		 */		
		override protected function initialize():void
		{
			_rootNode = null;
			
			if (detectLinkableObjectChange(initialize,url, clientID, clientSecret,authUri,tokenUri))
			{
				//initiate OuathFlow
				initiateOuathFlow();
				/*if (authUri.value){
					var queryStr:String = 'https://runkeeper.com/apps/authorize?client_id=20a867dd3176481f9d64f409bfbe3df3&redirect_uri=http://localhost:8080/GoogleServices/OauthService&response_type=code';
					WeaveAPI.URLRequestUtils.getURL(this, new URLRequest(queryStr), handleDownload, handleDownloadError, authUri.value, URLLoaderDataFormat.TEXT);
					
				}*/
					
			}
			
			// recalculate all columns previously requested because data may have changed.
			refreshAllProxyColumns();
			
			super.initialize();
		}
		private function handleDownload(event:ResultEvent, requestedUrl:String):void
		{
			trace('hi');
		}
		
		private function handleDownloadError(event:FaultEvent, requestedUrl:String):void
		{
			if (requestedUrl == url.value)
				reportError(event);
		}
		
		private function initiateOuathFlow():void{
			_service.triggerOauthFlow(clientID.value,clientSecret.value,authUri.value,tokenUri.value);
		}
		
		
		
		/**
		 * Gets the root node of the attribute hierarchy.
		 */
		override public function getHierarchyRoot():IWeaveTreeNode
		{
			return null;
		}
		
		override protected function generateHierarchyNode(metadata:Object):IWeaveTreeNode
		{
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function requestColumnFromSource(proxyColumn:ProxyColumn):void
		{
			
		}
		
		
		
	}
	
	
}
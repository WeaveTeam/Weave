package weave.services
{
		import flash.net.FileReference;
		import flash.utils.ByteArray;
		import flash.utils.Dictionary;
		import flash.utils.getDefinitionByName;
		
		import mx.rpc.AsyncToken;
		import mx.rpc.Fault;
		import mx.rpc.events.FaultEvent;
		import mx.rpc.events.ResultEvent;
		import mx.utils.StringUtil;
		
		import weave.api.objectWasDisposed;
		import weave.api.services.IAsyncService;
		import weave.core.CallbackCollection;
		import weave.services.AMF3Servlet;
		import weave.services.AsyncInvocationQueue;
		import weave.services.DelayedAsyncInvocation;
		
		public class InfoMapAdminInterface
		{
			private static function get Alert():Object { return getDefinitionByName('mx.controls.Alert'); }
			private static var _thisInstance:InfoMapAdminInterface = null;
			public static function get instance():InfoMapAdminInterface
			{
				if (_thisInstance == null)
					_thisInstance = new InfoMapAdminInterface("/InfoMapServices");
				return _thisInstance;
			}
			
			public static const messageLog:Array = new Array();
			public static const messageLogCallbacks:CallbackCollection = new CallbackCollection();
			public static function messageDisplay(messageTitle:String, message:String, showPopup:Boolean):void 
			{
				// for errors, both a popupbox and addition in the Log takes place
				// for successes, only addition in Log takes place
				if (showPopup)
					Alert.show(message,messageTitle);
				
				// always add the message to the log
				if (messageTitle == null)
					messageLog.push(message);
				else
					messageLog.push(messageTitle + ": " + message);
				
				messageLogCallbacks.triggerCallbacks();
			}
			
			public function InfoMapAdminInterface(url:String)
			{
				service = new AMF3Servlet(url + "/AdminService");
				queue = new AsyncInvocationQueue();
				getRssFeeds();
			}
			
			private var queue:AsyncInvocationQueue;
			private var service:AMF3Servlet;
			
			private function generateQueryAndAddToQueue(methodName:String, parameters:Array):DelayedAsyncInvocation
			{
				var query:DelayedAsyncInvocation = new DelayedAsyncInvocation(service, methodName, parameters);
				// we want to use a queue so the admin functions will execute in the correct order.
				queue.addToQueue(query);
				// automatically display FaultEvent error messages as alert boxes
				query.addAsyncResponder(null, alertFault, query);
				return query;
			}
			
			private function generateQueryAndRun(methodName:String, parameters:Array):AsyncToken
			{
				var query:AsyncToken = service.invokeAsyncMethod(methodName, parameters);
				return query;
			}
			// this function displays a String response from a server in an Alert box.
			private function alertResult(event:ResultEvent, token:Object = null):void
			{
				messageDisplay(null,String(event.result),false);
			}
			// this function displays an error message from a FaultEvent in an Alert box.
			private function alertFault(event:FaultEvent, token:Object = null):void
			{
				var query:DelayedAsyncInvocation = token as DelayedAsyncInvocation;
				
				var paramDebugStr:String = '';
				if (query.parameters.length > 0)
					paramDebugStr = '"' + query.parameters.join('", "') + '"';
				trace(StringUtil.substitute(
					"Received error on {0}({1}):\n\t{2}",
					query.methodName,
					paramDebugStr,
					event.fault.faultString
				));
				
				//Alert.show(event.fault.faultString, event.fault.name);
				var msg:String = event.fault.faultString;
				if (msg == "ioError")
					msg = "Received no response from the servlet.\nHas the WAR file been deployed correctly?\nExpected servlet URL: "+ service.servletURL;
				messageDisplay(event.fault.name, msg, true);
			}
			
			[Bindable]
			public var rssFeeds:Array = [];
			public function getRssFeeds():void
			{
				rssFeeds = []
				generateQueryAndAddToQueue("getRssFeeds",[]).addAsyncResponder(handleGetRssFeeds);
				function handleGetRssFeeds(event:ResultEvent,token:Object=null):void
				{
					if (event.result != null)
						rssFeeds = event.result as Array || [];
				}
			}
			
			
			public function addRssFeed(title:String,url:String):void
			{
				generateQueryAndAddToQueue("addRssFeed",[title,url]).addAsyncResponder(handler);
				function handler(event:ResultEvent, token:Object=null):void
				{
					Alert.show(event.result.toString());
					getRssFeeds();
				}
			}
			
			public function deleteRssFeed(url:String):void
			{
				generateQueryAndAddToQueue("deleteRssFeed",[url]).addAsyncResponder(handler);
				function handler(event:ResultEvent, token:Object=null):void
				{
					Alert.show(event.result.toString());
					getRssFeeds();
				}
			}
			
			public function deleteRssFeedWithTitle(title:String):void
			{
				generateQueryAndAddToQueue("deleteRssFeedWithTitle",[title]).addAsyncResponder(handler);
				function handler(event:ResultEvent, token:Object=null):void
				{
					Alert.show(event.result.toString());
					getRssFeeds();
				}
			}
			
			// ToDo This is called when the user clicks index now. (Mannually indexing)
			public function indexRssFeeds():void
			{
				generateQueryAndAddToQueue("indexRssFeeds", []);
			}
			
			public function renameFile(filePath:String,newFileName:String,overwrite:Boolean=false):void
			{
				generateQueryAndAddToQueue("renameFile",[filePath,newFileName,overwrite]).addAsyncResponder(handler);
				function handler(event:ResultEvent, token:Object=null):void
				{
					Alert.show(event.result.toString());
				}
			}
			
			public function searchInDocuments(entities:Array, docs:Array):DelayedAsyncInvocation
			{
				var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("searchInDocuments",[entities,docs]);
				return query;
			}
			
			public function addDocumentToSolr(username:String,file:FileReference):void
			{
				generateQueryAndAddToQueue("addTextDocument",[username,file.name,file.data]).addAsyncResponder(resultHandler,errorHandler);
				function resultHandler(event:ResultEvent, token:Object = null):void
				{
//					Alert.show(event.result.toString());
				}
				function errorHandler(event:FaultEvent, token:Object = null):void
				{
					Alert.show(event.fault.toString());
				}
			}
			
//			public function queryMendeley(queryTerms:Array):DelayedAsyncInvocation
//			{
//				var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("queryMendeley",[queryTerms]);
//				return query;
//			}
//			
//			public function queryArxiv(queryTerms:Array):DelayedAsyncInvocation
//			{
//				var query:DelayedAsyncInvocation = generateQueryAndAddToQueue("queryArxiv",[queryTerms]);
//				return query;
//			}
			
			public function getClustersForQueryWithRelatedKeywords(requiredKeywords:Array,relatedKeywords:Array,dateFilter:String,rows:int,
																   operator:String,sources:String,sortBy:String):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getClustersForQueryWithRelatedKeywords",[requiredKeywords,relatedKeywords,
					dateFilter,rows,operator,sources,sortBy]);
				return query;
			}
			
			public function getResultsForQueryWithRelatedKeywords(requiredKeywords:Array,relatedKeywords:Array,dateFilter:String,rows:int,operator:String,sources:String,sortyBy:String):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getResultsForQueryWithRelatedKeywords",[requiredKeywords,
					relatedKeywords,dateFilter,rows,operator,sources,sortyBy]);
				return query;
			}
			
			public function classifyDocumentsForQuery(requiredKeywords:Array,relatedKeywords:Array,dateFilter:String,rows:int,
													  operator:String,sources:String,sortBy:String,numOfTopics:int=5,numOfKeywords:int=5):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("classifyDocumentsForQuery",[requiredKeywords,relatedKeywords,dateFilter,rows,numOfTopics,numOfKeywords,operator,sources,sortBy]);
				return query;
			}
			
			public function getLinksForFilteredQuery(requiredKeywords:Array,relatedKeywords:Array,dateFilter:String,filterTerms:Array,
													 rows:int,operator:String,sources:String,sortBy:String):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getLinksForFilteredQuery",[requiredKeywords,relatedKeywords,
					dateFilter,filterTerms,rows,operator,sources,sortBy]);
				return query;
			}			
			
			public function getNumOfDocumentsForQuery(requiredKeywords:Array,relatedKeywords:Array,dateFilterString:String,operator:String,sources:String):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getNumOfDocumentsForQuery",[requiredKeywords,relatedKeywords,dateFilterString,operator,sources]);
				return query;
			}
			
			public function getEntityDistributionForQuery(requiredKeywords:Array,relatedKeywords:Array, dateFilter:String,entities:Array,rows:int, 
														  operator:String,sources:String,sortBy:String):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getEntityDistributionForQuery",[requiredKeywords,relatedKeywords,dateFilter
					,entities,rows,operator,sources,sortBy]);
				return query;
			}
			
			
			public function getQueryResults(queryTerms:Array,filterQuery:String,sortField:String,rows:int,solrURL:String=null):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getQueryResults",[queryTerms,filterQuery,sortField,rows,solrURL]);
				return query;
			}
			
			public function getNumberOfMatchedDocuments(queryTerms:Array,filterQuery:String,solrURL:String=null):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getNumberOfMatchedDocuments",[queryTerms,filterQuery,solrURL]);
				return query;
			}
			
			public function queryDataSources(requiredQueryTerms:Array,relatedQueryTerms:Array):void
			{
				var query:AsyncToken = generateQueryAndRun("queryDataSources",[requiredQueryTerms,relatedQueryTerms]);
			}
			
			public function getTotalNumberOfQueryResultsFromSource(requiredQueryTerms:Array,relatedQueryTerms:Array):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getTotalNumberOfQueryResults",[requiredQueryTerms,relatedQueryTerms]);
				return query;
			}
			
			
			public function getWordCount(requiredKeywords:Array,relatedKeywords:Array,dateFilter:String,operator:String,sources:String,sortBy:String):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getWordCount",[requiredKeywords,relatedKeywords,dateFilter,operator,sources,sortBy]);
				return query;
			}
			
			public function extractKeywords(text:String):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("extractKeywords",[text]);
				return query;
			}
			public function getDescriptionForURL(url:String,keywords:Array):AsyncToken
			{
				var query:AsyncToken = generateQueryAndRun("getDescriptionForURL",[url,keywords]);
				return query;
			}
			
			
		}
}

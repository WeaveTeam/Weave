package weave.data.DataSources
{
	import com.as3xls.xls.formula.Tokens;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	import mx.graphics.SolidColor;
	import mx.rpc.AsyncResponder;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import org.igniterealtime.xiff.events.BookmarkChangedEvent;
	
	import weave.*;
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IAttributeHierarchy;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.services.IURLRequestToken;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.data.CSVParser;
	import weave.data.KeySets.KeySet;
	import weave.primitives.DateRangeFilter;
	import weave.services.DelayedAsyncInvocation;
	import weave.services.InfoMapAdminInterface;
	import weave.utils.DateUtils;
	import weave.utils.VectorUtils;

	public class InfoMapsDataSource extends CSVDataSource
	{
		public function InfoMapsDataSource()
		{
			solrURL.value = "http://129.63.8.219:8080/solr/research_core/select/?version=2.2";
			csvDataString.value = "url,title,description,imgURL,date_published,date_added";
			keyColName.value = "url";
			keyType.value = "infoMapsDoc";
			
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,csvDataString);
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,keyColName);
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,keyType);
		}
		
		public const solrURL:LinkableString = newLinkableChild(this,LinkableString);
		
		public static const DOC_KEYTYPE:String = "infoMapsDoc";
		
		public static const SOURCE_NAME:String = "InfoMaps Data Source";
		
		public static const defaultNumberOfDocumentsPerRequest:int = 2000;
		
		public function containsDoc(key:IQualifiedKey):Boolean
		{
			var title:String = getTitleForKey(key);
			
			if(title)
				return true;
			else 
				return false;
		}
		
		private function getKeyValueForColumn(csvColumnName:String,key:IQualifiedKey):*
		{
			var col:IAttributeColumn = getColumnByName(csvColumnName);
			
			return col.getValueFromKey(key);
		}
		
		public function getTitleForKey(key:IQualifiedKey):String
		{
			return getKeyValueForColumn("title",key) as String;
		}
		
		public function getDescriptionForKey(key:IQualifiedKey):String
		{
			return getKeyValueForColumn("description",key) as String;
		}
		
		public function getImageURLForKey(key:IQualifiedKey):String
		{
			return getKeyValueForColumn("imgURL",key) as String;
		}
		
		public function getDatePublishedForKey(key:IQualifiedKey):String
		{
			return getKeyValueForColumn("date_published",key) as String;
		}
		
		public function getDateAddedForKey(key:IQualifiedKey):String
		{
			return getKeyValueForColumn("date_added",key) as String;
		}
		
		
		private function getColumnValueForURL(csvColumnName:String,url:String):*
		{
			var col:IAttributeColumn = getColumnByName(csvColumnName);
			
			var key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey(DOC_KEYTYPE,url);
			
			return col.getValueFromKey(key);
		}
		
		public function getTitleForURL(url:String):String
		{
			return getColumnValueForURL("title",url) as String;
		}
		
		public function getDescriptionForURL(url:String):String
		{
			return getColumnValueForURL("description",url) as String;
		}
		
		public function getImageURLForURL(url:String):String
		{
			return getColumnValueForURL("imgURL",url) as String;
		}
		
		public function getDatePublishedForURL(url:String):String
		{
			return getColumnValueForURL("date_published",url) as String;
		}
		
		public function getDateAddedForURL(url:String):String
		{
			return getColumnValueForURL("date_added",url) as String;
		}
		
		
		public function getDocumentsForQuery(docKeySet:KeySet,wordCount:Array,query:String,operator:String='AND',sources:Array=null,
													dateFilter:DateRangeFilter=null,numberOfDocuments:int=2000,partialMatch:Boolean=false):void
		{
			if(query)
			{
				var mendeleyQuery:String = query.replace(/"/g,'');//replacing quotes
//				mendeleyQuery = mendeleyQuery.replace(/ /g,'+');//replacing space with +
//				InfoMapAdminInterface.instance.queryMendeley(mendeleyQuery);
				
				var mendeleyQueryArray:Array = mendeleyQuery.split(' ');
//				trace("CALLING DATA SOURCES");
//				InfoMapAdminInterface.instance.queryMendeley(mendeleyQueryArray);
//				InfoMapAdminInterface.instance.queryArxiv(mendeleyQueryArray);
				
				
				trace("CALLING SOLR");
				var queryTerms:Array = query.replace(/"/g,'').split(' ');//removing quotes completely for now
				createAndSendQuery(docKeySet,wordCount,queryTerms,null,operator,sources,
					dateFilter,numberOfDocuments);
			}
			
		}
		/**
		 * This function takes a query and adds a filter to restrict by field values 
		 * @param query The query string
		 * @param fieldsNames The field names to filter on
		 * @param fieldValues This is a 2D array because each fieldName can have multiple values. Each array in a row corresponds to the field name in the fieldNames array. 
		 * @param operator
		 * @param dateFilter
		 * @param numberOfDocuments
		 * 
		 */		
		public function getDocumentsForQueryWithFieldValues(docKeySet:KeySet,query:String,fieldsNames:Array,fieldValues:Array,sources:Array,operator:String='AND',dateFilter:DateRangeFilter=null,numberOfDocuments:int=2000,partialMatch:Boolean=false):void
		{
			if(fieldsNames.length == 0)
				return;
			
			var filteredQuery:String = "";
			
			for (var i:int=0; i< fieldsNames.length; i++)
			{
				filteredQuery += fieldsNames[i] + ":(";
				for(var j:int=0; j <fieldValues[i].length; j++)
				{
					//replacing $amp; with &
//					var val:String = (fieldValues[i][j] as String).replace( /\&amp\;/g,'&');
					
//					var val:String = (fieldValues[i][j] as String).replace( /\&amp\;/g,'%26');
//					val = val.replace( /\:/g,'\:');
					
					//encoding the fieldValues in case it is a link
					//TODO: need to test how this might affect non-link text
					//val = escape(val);
					
					
					
					filteredQuery += '"' + fieldValues[i][j] + '" ' + "OR" + ' ';
				}
				filteredQuery = filteredQuery.substr(0,filteredQuery.length-(4));
				filteredQuery += ") AND ";
			}
			
			//removing the last AND
			filteredQuery = filteredQuery.substr(0,filteredQuery.length-(5));
			
			var queryTerms:Array = query.split(" ");
			
			createAndSendQuery(docKeySet,null,queryTerms,filteredQuery,operator,sources,dateFilter,numberOfDocuments);
		}
		
		public static function getNumberOfMatchedDocuments(query:String,operator:String="AND",sources:Array=null,
													dateFilter:DateRangeFilter=null):DelayedAsyncInvocation 
		{
		
			var numOfDocs:int;
			
			var queryTerms:Array = query.split(" ");
			
			var filterQuery:String = parseFilterQuery(filterQuery,dateFilter,sources);
			
			var q:DelayedAsyncInvocation = InfoMapAdminInterface.instance.getNumberOfMatchedDocuments(queryTerms,filterQuery);
			
			return q;			
		}
			
		private function createAndSendQuery(docKeySet:KeySet,wordCount:Array,query:Array,filterQuery:String=null,operator:String='AND',sources:Array=null,
											dateFilter:DateRangeFilter=null,numberOfDocuments:int=2000,sortField:String="date_added"):void
		{
			
			filterQuery = parseFilterQuery(filterQuery,dateFilter,sources);
				
			
			var q:DelayedAsyncInvocation = InfoMapAdminInterface.instance.getQueryResults(query,filterQuery,sortField,numberOfDocuments);
			q.addAsyncResponder(handleQueryResults,handleQueryFault,{docKeySet:docKeySet,wordCount:wordCount});
		}
		
		private static function parseFilterQuery(filterQuery:String,dateFilter:DateRangeFilter=null,sources:Array=null):String
		{
			if(!filterQuery)
				filterQuery = "";
			
			var fq:String = "";
			if(sources)
			{
				fq = "source:(";
				
				for each(var sourceName:String in sources)
				{
					fq += '"'+sourceName+'" OR ';
				}
				
				fq = fq.substr(0,fq.length-4);
				fq = fq + ')';	
			}
			
			if(filterQuery && fq)
				filterQuery += ' AND ' + fq;
			else if(fq)
				filterQuery = fq;
			
			
			var dateFilterString:String = "";
			
			//applying date filters if set
			if(dateFilter)
			{
				if(dateFilter.startDate.value != '' && dateFilter.endDate.value != '')
				{
					
					var sDate:Date = DateUtils.getDateFromString(dateFilter.startDate.value);
					var eDate:Date = DateUtils.getDateFromString(dateFilter.endDate.value);
					
					
					//Solr requires the date format to be ISO 8601 Standard Compliant
					//It should be in the form: 1995-12-31T23:59:59Z 
					var sStr:String = DateUtils.getDateInStringFormat(sDate,'YYYY-MM-DD');
					
					//For start date we append 00:00:00 to set time to start of the day
					sStr = sStr + 'T00:00:00Z';
					
					var eStr:String = DateUtils.getDateInStringFormat(eDate,'YYYY-MM-DD');
					
					//For end date we append 23:59:59 to set time to end of day
					eStr = eStr + 'T23:59:59Z';
					
					dateFilterString = "date_added:["+sStr+" TO "+eStr + "]";
				}
			}
			
			if(dateFilterString && filterQuery)
				filterQuery = filterQuery + ' AND ' + dateFilterString;
			else if(dateFilterString)
				filterQuery = dateFilterString;
			
			return filterQuery;
		}
		
		private function handleQueryResults(event:ResultEvent,token:Object=null):void
		{
			var docsArray:Array = event.result.queryResult as Array;
			var docsToAdd:Array = [];
			var keys:Array = [];
			
			var urlCol:IAttributeColumn =getColumnByName('url'); 
			
			for (var i:int = 0; i < docsArray.length; i++)
			{
				var link:String = docsArray[i][0];
				
				var key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey("infoMapsDoc",link);
				
				//if the key is already present in the column, then we only add it to the keys keyset
				//we will not add the currentDoc to the docsArray, this way the rows are not repeated in the csvDataString
				if(urlCol.containsKey(key))
				{
					keys.push(link);
					continue;
				}
				
				docsToAdd.push(docsArray[i]);
				
				keys.push(link);
			}
			
			var dataString:String = parser.createCSV(docsToAdd);
			dataString = csvDataString.value + '\n' + dataString;
			
			csvDataString.value = dataString;
			
			if(!event.result.wordCount || !token)
				return;
			
			VectorUtils.copy(event.result.wordCount,token.wordCount);
			
			
			//			(token.keySet as KeySet).clearKeys();
			(token.docKeySet as KeySet).replaceKeys(WeaveAPI.QKeyManager.getQKeys("infoMapsDoc",keys));
			// we force to trigger callbacks so that if a empty keyset is replaced with empty keys the callbacks are still called
			(token.docKeySet as KeySet).triggerCallbacks(); 
		}
		
		
		private function handleQueryFault(event:FaultEvent,token:Object=null):void
		{
			return;
		}
		public function startIndexing():void
		{
			WeaveAPI.URLRequestUtils.getURL(this,new URLRequest(solrURL.value + "&clean=false&commit=true&qt=%2Fdataimport&command=full-import"));
		}
		
		private function handleSolrResponseError(event:FaultEvent,token:Object):void
		{
			WeaveAPI.ErrorManager.reportError(event.type + token.url);
		}
		
		private var parser:CSVParser = new CSVParser();
		
		private static function removeEmptyStringElementsFromArray(arg:Array):Array
		{
			var result:Array = [];
			for each(var item:String in arg)
			{
				if(item != "")
					result.push(item);
			}
			
			return result;
		}
	}
	
}
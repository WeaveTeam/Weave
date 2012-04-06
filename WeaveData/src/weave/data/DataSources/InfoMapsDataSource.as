package weave.data.DataSources
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.graphics.SolidColor;
	import mx.rpc.AsyncResponder;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
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
	import weave.data.CSVParser;
	import weave.data.KeySets.KeySet;
	import weave.primitives.DateRangeFilter;
	import weave.utils.DateUtils;

	public class InfoMapsDataSource implements IDataSource
	{
		public function InfoMapsDataSource()
		{
			solrURL.value = "http://129.63.8.219:8080/solr/select/?version=2.2";
		}
		
		public const solrURL:LinkableString = newLinkableChild(this,LinkableString);
		
		
		
		private var csvDataSource:CSVDataSource = newLinkableChild(this,CSVDataSource);
		
		/**
		 * @return An AttributeHierarchy object that will be updated when new pieces of the hierarchy are filled in.
		 */
		public function get attributeHierarchy():IAttributeHierarchy
		{
			return csvDataSource.attributeHierarchy;
		}
		
		/**
		 * initializeHierarchySubtree
		 * @param subtreeNode A node in the hierarchy representing the root of the subtree to initialize, or null to initialize the root of the hierarchy.
		 */
		public function initializeHierarchySubtree(subtreeNode:XML = null):void
		{
			return csvDataSource.initializeHierarchySubtree(subtreeNode);
		}
		
		/**
		 * The parameter type is now temporarily Object during this transitional phase.
		 * In future versions, the parameter will be an IColumnReference object.
		 * @param columnReference A reference to a column in this IDataSource.
		 * @return An IAttributeColumn object that will be updated when the column data downloads.
		 */
		public function getAttributeColumn(columnReference:IColumnReference):IAttributeColumn
		{
			return csvDataSource.getAttributeColumn(columnReference);
		}
		
		public function getDocumentsForQuery(docKeySet:KeySet,query:String,operator:String='AND',sources:Array=null,
													numberOfDocuments:int=100,dateFilter:DateRangeFilter=null):void
		{
			var temp:Array = removeEmptyStringElementsFromArray(query.split(" "));	
			
			//after removing the empty strings we check to see if it is a single or empty word.
			//if it is not a single word we add the operator between each keyword
			//spliting the keywords at the spaces. 
			if(temp.length > 1)
				query = temp.join(" "+operator+" ");
			
						
			query += "&fq="
			
			for each(var sourceName:String in sources)
			{
				query += 'source:"'+sourceName+'" OR ';
			}
			
			query = query.substr(0,query.length-4);
			
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
					
					query += "&fq=date_published:["+sStr+" TO "+eStr + "]";
				}
			}
			
			//creating and sending the query to the Solr server
			//TODO: change number of documents from fixed number to a variable
			var url:String = solrURL.value + "&start=0&rows=100&sort=date_published desc&indent=on&q=" + query;
			
			
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(url);
			
			
			WeaveAPI.URLRequestUtils.getURL(request,parseSolrResponse,handleSolrResponseError,docKeySet,URLLoaderDataFormat.TEXT);
			
	
		}
		
		public function getDocumentsWithFieldValues(query:Array,fields:Array,operator:String='AND',numberOfDocuments:int=100,startDate:DateRangeFilter=null,endDate:DateRangeFilter=null):void
		{
			
		}
		
		private function handleSolrResponseError(event:FaultEvent,token:Object):void
		{
			WeaveAPI.ErrorManager.reportError(event.type + token);
		}
		
		private function parseSolrResponse(event:ResultEvent,token:Object):void
		{
			
			var docsArray:Array = [];
			var keys:Array = [];
			var resultInXML:XMLList = new XML(event.result).result[0].doc;
			for each(var doc:XML in resultInXML)
			{
				
				var link:String = doc.str.(@name=="link").text().toXMLString();
				
				var key:IQualifiedKey = WeaveAPI.QKeyManager.getQKey("infoMapsDoc",link);
				
				if(key)
				{
					keys.push(link);
					continue;
				}
				
				var linkLen:int = link.length;
				var linkExtension:String = link.substring(linkLen-3,linkLen);
				var imgExtension:String = ".jpg"
				
				if(linkExtension == "pdf" || "doc"){
					imgExtension = ".png";
				}
				
				var currentDoc:Array = []
				
				currentDoc.push(doc.str.(@name=="title").text().toXMLString());
				
				currentDoc.push(link);
				
				//TODO:right now limiting to 200 characters. Need to change this later to a better solution
				currentDoc.push((doc.str.(@name=="description").text().toXMLString() as String).substr(0,200));
				
				var imgURL:String = doc.str.(@name=="imgName").text().toXMLString();
				
				currentDoc.push("http://129.63.8.219:8080/infomap/thumbnails/"+  imgURL + imgExtension);
				
				currentDoc.push(doc.date.text().toXMLString());
				
				docsArray.push(currentDoc);
				
				keys.push(link);
			}
			
			var csvDataString:String = parser.createCSV(docsArray);
			csvDataString = csvDataSource.csvDataString.value + '\n' + csvDataString;
			
			csvDataSource.csvDataString.value = csvDataString;
			
			(token as KeySet).clearKeys();
			(token as KeySet).addKeys(WeaveAPI.QKeyManager.getQKeys("infoMapsDoc",keys));
			
		}
		
		private var parser:CSVParser = new CSVParser();
		
		private function removeEmptyStringElementsFromArray(arg:Array):Array
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
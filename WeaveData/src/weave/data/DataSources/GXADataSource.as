package weave.data.DataSources
{
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.services.DelayedAsyncResponder;
	import weave.services.WeaveGeneExpressionServlet;
	import weave.services.beans.GXA.Expression;
	import weave.services.beans.GXA.GXAResult;
	import weave.services.beans.GXA.Gene;
	import weave.services.beans.GXA.GeneExpression;

	public class GXADataSource extends CSVDataSource
	{
		public function GXADataSource()
		{
			gxaURL.value = "http://www.ebi.ac.uk:80/gxa/api/vx?";
			queryString.addImmediateCallback(this,callAtlasServer);
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,csvDataString);
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,keyColName);
			(WeaveAPI.SessionManager as SessionManager).excludeLinkableChildFromSessionState(this,keyType);
			
		}
		
		public const gxaURL:LinkableString = newLinkableChild(this,LinkableString);
		public const queryString:LinkableString = newLinkableChild(this,LinkableString);
		
		public static const SOURCE_NAME:String = "GXA Data Source";
		//public const geneExpressionServiceURL:LinkableString = new LinkableString("/WeaveServices/GXAService",);
		private var geneExpService:WeaveGeneExpressionServlet = new WeaveGeneExpressionServlet("/WeaveServices/GXAService");			
		
		private function callAtlasServer():void{
			var query:AsyncToken = geneExpService.getGeneExpressionData(gxaURL.value + queryString.value);
			DelayedAsyncResponder.addResponder(query, handleQueryResult, handleQueryFault);
		}
		
		public  var metaDataMap:Dictionary = new Dictionary();
		private function handleQueryResult(event:ResultEvent, token:Object = null):void
		{
			var gxaResult:GXAResult = new GXAResult(event.result);
			var resultArray:Array = gxaResult.results;
			
			var keys:Array = new Array();
			var columnNames:Array = new Array();
			var columns:Array = new Array();
			var rowCollection:ArrayCollection = new ArrayCollection();
			for(var rowIndex:int = 0 ; rowIndex<resultArray.length;rowIndex++){
				var geneExp:GeneExpression = new GeneExpression(resultArray[rowIndex]);					 
				var gene:Gene = geneExp.gene;
				keys.push(gene.id);
				metaDataMap[gene.id] = gene;
				var expressions:Array = geneExp.expressions;
				var rowObject:Object = new Object();
				rowObject["geneId"] = gene.id;	
				rowObject["organism"] = gene.organism;
				rowObject["name"] = gene.name;
				for (var expIndex:int = 0; expIndex < expressions.length; expIndex++){
					var expression:Expression = new Expression(expressions[expIndex]);
					rowObject[expression.efoTerm + "_upExperiments"] = expression.upExperiments;
					rowObject[expression.efoTerm + "_downExperiments"] = expression.downExperiments;	
					rowObject[expression.efoTerm + "_upPvalue"] = expression.upPvalue;
					rowObject[expression.efoTerm + "_downPvalue"] = expression.downPvalue;	
				} 
				rowCollection.addItem(rowObject);					 
			}
			buildCSVData(rowCollection);
			
		}
		
		private function handleQueryFault(event:FaultEvent, token:Object = null):void
		{
			trace("fault on "+token, event.message);
		}
		
		private function buildCSVData(rowCollection:ArrayCollection):void{
			var rows:Array = rowCollection.source;
			var headers:Array = WeaveAPI.CSVParser.getRecordFieldNames(rows);
			var datas:Array = WeaveAPI.CSVParser.convertRecordsToRows(rows);
			var csvDataString:String = WeaveAPI.CSVParser.createCSV(datas);				
			this.csvDataString.value = csvDataString;
		}
	}
}
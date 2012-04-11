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

package weave.Reports
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import mx.controls.Alert;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.services.IWeaveDataService;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableXML;
	import weave.data.DataSources.*;
	import weave.data.KeySets.KeyFilter;
	
	
	public class WeaveReport implements ILinkableObject
	{
		//types of reports
		//public static const RPT_COMPAREREPORT:int = 0;
		//public static const RPT_CATEGORYREPORT:int = 0;
		//Temporary solution: these strings have to match what the webservices are expecting
		public static const REPORT_TYPE_CATEGORY:String = "CATEGORYREPORT";
		public static const REPORT_TYPE_COMPARE:String = "COMPAREREPORT";
		public static const REPORT_SUCCESS:String = "success"; 
		
		private static const REPORT_FOLDER:String = "WeaveReports";
		//private var reportType:String = REPORT_TYPE_CATEGORY;
		private var reportName:String = "";
		private var reportDefinitionFileName:String = "";
		private var dataSource:String = "";

		/** 
		 * get the report definition from the ObjectRepository and trigger it to
		 * request the report from the server
		 * */ 
		public static function requestReport(report:WeaveReport):void
		{
			//how do we know what datatable these keys are from?  
			//are they a mix?
			//get the keys for the current subset
			var subset:KeyFilter = WeaveAPI.globalHashMap.getObject("defaultSubsetKeyFilter") as KeyFilter;
			var keys:Array = subset.included.keys;

			if (report != null)
				report.requestReport(keys);
		}

		/** 
		 * Constructor, creates a WeaveReport instance from an xml description
		 */
		public function WeaveReport()	
		{
		}

		/*
		<WeaveReport name="global id1">
			<description type="XML">
				<report name="exampleName" dataSource="exampleSource"/>
			</description>
		</WeaveReport>
		<WeaveReport name="global id2">
			<description type="XML">
				<report name="example Category report" dataSource="exampleSource" />
			</description>
		</WeaveReport>
		
		*/

		public const description:LinkableXML = newLinkableChild(this, LinkableXML, handleReportDescriptionChange);
		private function handleReportDescriptionChange():void
		{
			var reportDescription:XML = description.value;
			if (reportDescription == null)
				return;

			reportName = reportDescription.attribute("name");
			reportDefinitionFileName = reportDescription.attribute("reportDefinitionFileName");
			dataSource = reportDescription.attribute("dataSource");
		}
			
		/** 
		 *  Send a request to the server for the report
		 * */ 
		public function requestReport(qkeys:Array):void 
		{
			//we have an upper limit to the number of records we'll handle
			//@TODO this upper limit may be different for different types of reports
			if ((qkeys == null) || (qkeys.length <= 0))
			{
				Alert.show("Weave reports must have at least 1 record.  Please create a subset and try again.");
				return;
			}

			//convert vector of IQualifiedKeys into an array of key Strings
			var keyStrings:Array = [];
			for (var i:int = 0; i < qkeys.length; i++)
			{
				var keyValue:String = (qkeys[i] as IQualifiedKey).localName;
				keyStrings.push(keyValue);
			}

			//request report through the datasource
			//  only supporting WeaveDataSource reports for now
			var oiDataSource:WeaveDataSource = WeaveAPI.globalHashMap.getObject(dataSource) as WeaveDataSource;
			if (oiDataSource == null)
				Alert.show("Data source " + dataSource + " not found");
			else 
				oiDataSource.getReport(reportDefinitionFileName, keyStrings);  
		}
		public static function handleReportResult(event:ResultEvent, dataService:IWeaveDataService):void 
		{
			var result:String = event.result as String;
			if (result.indexOf(WeaveReport.REPORT_SUCCESS) == 0)
			{
				// create report returns the success/fail plus the name of the report
				//get the name of the report
				var reportResultFileName:String = result.substr(WeaveReport.REPORT_SUCCESS.length + 1);
				//get the report url for reportName
				//var rootURL:String = dataService.webService.rootURL;
				//rootURL = rootURL.substr(0, rootURL.lastIndexOf("/") + 1);
				var reportURL:URLRequest = new URLRequest("/WeaveReports/" + reportResultFileName);		//rootURL + relativeURL);
				//open a browser window for this url
				navigateToURL(reportURL);	
			}		
			else
			{
				var msg:String = "Error creating report: " + result;
				Alert.show(msg);
			}			
		}
		
		
		
	}
}

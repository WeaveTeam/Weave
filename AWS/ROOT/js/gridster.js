require.config({
  paths : {
    'jquery' : 'jquery-1.9.1',
    'jquery-ui' : 'jquery-ui-1.10.3.custom'
    
  },
  shim : {
    'jquery.gridster' : [ 'jquery' ],
    'jquery-ui' : [ 'jquery' ]
  }
});

require(
    [ 'jquery', 'jquery.gridster', 'jquery-ui' ],
    function($) {
      $(document)
          .ready(
              $(function() { // DOM Ready

                $(".gridster ul").gridster({
                  widget_margins : [ 10, 10 ],
                  widget_base_dimensions : [ 140, 140 ],
                  max_size_x : 3
                });

                $('#projectButton').button({
                  icons : {
                    secondary : "ui-icon-triangle-1-s"
                  }
                });

                $('#dataDialog').dialog({
                  autoOpen : false,
                  height : 500,
                  width : 750,
                  modal : true,
                  buttons : {
                    Select : function() {
                      $(this).dialog("close");
                    },
                    Cancel : function() {
                      // handleCancelOption();
                      $(this).dialog("close");
                    }
                  }
                });

                $('#dataButton').button().click(function() {
                  $('#dataDialog').dialog("open");
                });
                
                $('#scriptButton').button().click(function() {
                  var scriptType = $('#scriptCombobox').val();
                  if (scriptType == "Normalization.R")
                  {
                	  	scriptOneQuery('getScriptOneResult');
                  }
                  if (scriptType == "obesityCSVRoutine.R")
                  {
                	   testServerQuery('getRResult');
                  }
                  
                  
                });
                
                $('#scriptButton2').button().click(function() {
                  // enter function here for calling weave
//                	scriptOneQuery('getScriptOneResult');
                });

                $('.portlet')
                    .addClass(
                        "ui-widget ui-widget-content ui-helper-clearfix ui-corner-all")
                    .find(".portlet-header")
                    .addClass(
                        "ui-widget-header ui-corner-all")
                    .prepend(
                        "<span class='ui-icon ui-icon-minusthick'></span>")
                    .end().find(".portlet-content");

                $(".portlet-header .ui-icon")
                    .click(
                        function() {
                          $(this)
                              .toggleClass(
                                  "ui-icon-minusthick")
                              .toggleClass(
                                  "ui-icon-plusthick");
                          $(this)
                              .parents(
                                  ".portlet:first")
                              .find(
                                  ".portlet-content")
                              .toggle();
                        });
                    
                var scriptCombobox = $('#scriptCombobox');
                
                scriptCombobox.append($("<option/>").val('Normalization.R').text(
                          "Normalization.R"));
                scriptCombobox.append($("<option/>").val('obesityCSVRoutine.R')
                          .text("obesityCSVRoutine.R"));
                
                
                var dialogOptions = {
                        "autoOpen": false,
                        "width": 950,
                		"height": 700,
                		"modal" : false,
                		buttons : {
                			"Export" : function() {
                				
                			}
                		
                		}
                };
                
                $('#weaveDialog').dialog(dialogOptions);
             
                $('#weaveButton').button().click(function() {
                  $('#weaveDialog').dialog("open");
                });
                
                $('#panel6ImportButton').button().click(function() {
                	
                });
                
                $('#panel6SaveButton').button().click(function() {
                  	
                });
                $('#panel6EditButton').button().click(function() {
                
                });
                
                $('#getHierarchy').button()
                				  .click(function() {getDataHierarchy();});
                				  
                $('#dataTables').change(function() {
                	getDataColumnIds($(this).val());
                	
                });
                
              }));

              
// Disable caching of AJAX responses
$.ajaxSetup({
    cache: false
});

function getDataColumnIds(id) {
	
	queryDataService(
		"getEntityChildIds", // method
		[id],
		handleColumnIdsResults
	);
}

function getDataColumnEntities(ids) {
	queryDataService(
		"getEntitiesById",
		[ids],
		handleEntitiesResults
	
	);	

}


function handleColumnIdsResults(response) {
	if(response.error)
		{
			alert("Error");
			return;
		}
		else
		{
			//console.log(response.result);
			getDataColumnEntities(response.result);
			return;
		}
}

function handleEntitiesResults(response) {
	var dataColumns = [];
	if(response.error)
		{
			alert("Error");
			return;
		}
		else
		{
			$("#columns").empty();
			$("#dataCombobox").empty();
			dataColumns = [];
			for (var i in response.result) {
				var column = response.result[i];
				dataColumns.push(column);
				$("#columns").append($("<option/>").val(column.id.toString())
							.text(column.publicMetadata.title));
				$("#dataCombobox").append($("<option/>").val(column.id.toString())
				.text(column.publicMetadata.title));
			}
			populatePanels(dataColumns);
			return;
		}
}


function getDataHierarchy() {
	$('#scriptResults').html("getDataHierarchy Called");

	queryAdminService(
	   "getEntityHierarchyInfo", //method
	   [$('input[name="ConnectionName"]').val(), $('input[name="Password2"]').val(), 0], //params
	   handleDatabaseResult //callback
	);
	
}

function handleDatabaseResult(response){
	if(response.error)
		alert("connection failed");
	else
	{
		for (var i in response.result)
		{
			var table = response.result[i];
			$('#dataTables').append($("<option/>").val(table.id.toString())
						.text(table.title + " (" + table.numChildren + ")"));
		}
		
	}
	return;
}


function populatePanels(dataColumns) {
	// this function update panels with metadata from database
	console.log(dataColumns);
	for ( var i = 1; i < 7; i++)
	{
		$('#panel'+i).html(dataColumns[i-1].publicMetadata.title);
	}
	
	return;
	
}

function queryAdminService(method, params, callback)
{
	var url = '/WeaveServices/AdminService';
	var request = {
	               jsonrpc:"2.0",
	               id:"no_id",
	               method : method,
	               params : params
	};
	
	$.post(url, JSON.stringify(request), callback, "json");
}

function queryDataService(method, params, callback)
{
	var url = '/WeaveServices/DataService';
	var request = {
	               jsonrpc:"2.0",
	               id:"no_id",
	               method : method,
	               params : params
	};
	
	$.post(url, JSON.stringify(request), callback, "json");
}



//calling Rservice on Weave
function queryRService(method,params,callback,queryID)
{
	console.log('queryRService',method,params);
	var url = '/WeaveServices/RService';
	var request = {
					jsonrpc:"2.0",
					id:queryID || "no_id",
					method : method,
					params : params
	};
	console.log(JSON.stringify(request));
	var check = '"' + JSON.stringify(request) + '"' ;
	$.post(url,request, callback, "json");
	//resulttextarea.value = 'Awaiting Response for ' + method + ' request....';
}

//---------------------------------called by scriptOneButton BEGIN--------------------------

function scriptOneQuery(secondMethodName)
{
	var datasetName = "Obesity.csv";
	var rRoutine = "Normalization.R";
	
	
	var jsqueryObject = new Object();
	jsqueryObject.dataset = datasetName;
	jsqueryObject.rRoutine = rRoutine;
	jsqueryObject.age = 50;
	//these are the columns which will be pulled out from the database
	jsqueryObject.columnsToBeRetrieved = ["PercentObese2002", "PercentObese2004"];
	
	
	var jsConnectionInfo = new Object();
	jsConnectionInfo.user = "root";
	jsConnectionInfo.password = "Tc1Sgp7nFc";//hard coded for now 
	jsConnectionInfo.dbname = "resd";
	jsConnectionInfo.schema = "us";
		
	queryRService(
	//method
	'manageComputation',
	{
		//params
		queryObject : jsqueryObject,
		connectionInfoObject : jsConnectionInfo
		//works
		//queryObject:[dataset,rRoutine],
		
	},
	//callback
	handleScriptOneResult
	);
	
	function handleScriptOneResult(response)
	{
		if(response.error)
		{
			//resulttextarea.value = JSON.stringify(response,null,3);
			return;
		}
		else
		{
			var rResult = response.result;
			console.log("calling set CSVSource");
			setCSV2Source(rResult);
			//console.log("retrieved " + rResult.length + "results");
			return;
		}
		
		
	}
	
	
	function setCSV2Source(rResult)
	{
		
		console.log(rResult[0].value);
		var weave = document.getElementById('weave');
		weave.path('MyNORMDataSource').request('CSVDataSource').vars({data: rResult[0].value}).exec('setCSVDataString(data)');
		
		/*setting up a maptool
		setting the geometry collections from a WeaveDataSource
		setting the color column of the map tool from the results returned by the computation
		*/
		weave.requestObject(['Maptool1'], 'MapTool');
		var mapOne = weave.path.apply(weave,[]).push('worldborders');
		var mapTwo = mapOne.request('ReferencedColumn').push('dynamicColumnReference',null);
		var mapThree = mapTwo.request('HierarchyColumnReference').state('dataSourceName','WeaveDataSource').
						state('hierarchyPath','attribute weaveEntityId ="152" name ="world" title="world" dataType = "geometry"/>').pop().pop();
		
		
		
		//setting up datatable tool
		
		//weave.requestObject(['DTT'], 'DataTableTool');
		/*Method 1*/
		//var one = weave.path.apply(weave,['DTT','columns']).push('x');
		//var two = one.request('ReferencedColumn').push('dynamicColumnReference',null);			
		//var three = two.request('HierarchyColumnReference')
		//			.state('dataSourceName','MyNORMDataSource')
					//.state('hierarchyPath', '<attribute keyType="CSVDataSource" title="PercentObese2002" csvColumn="PercentObese2002"/>')
					//.pop()
					//.pop();
					
		//compare with the next block of code
		
		//weave.setColumn = function(path, csvDataSource)
		//{
				//weave.path.apply(weave,path)
					//.push(null)//should not be null
					//.request('ReferencedColumn')
					//.push('dynamicColumnReference',null)//null works only with linkableDynamicObject
					//.request('HierarchyColumnReference')
					//.state('dataSourceName', csvDataSource)
					//.state('hierarchyPath', '<attribute keyType="CSVDataSource" title="PercentObese2002" csvColumn="PercentObese2002"/>')
					//.pop()
					//.pop();
		//}
		
		
		
		/*Method 2*/
		//weave.setCSVColumn = function(columnPath, csvDataSource, columnNumber) {
		
				//var x = weave.path(csvDataSource);//gets the path object
				//x.vars({i:columnNumber, p:columnPath});//adds the required variables and attributes them
				//var y = x.exec('putColumn(i,p)');//calling funtion putColumn from CSVDataSource.as in Weave 
		//};
		//weave.setCSVColumn(['DTT','columns','x'],'MyNORMDataSource','PercentObese2002');
		//weave.setCSVColumn(['DTT','columns','y'],'MyNORMDataSource','PercentObese2004');
	}
		
		
}
//---------------------------------called by scriptOneButton END---------------------------



//---------------------------------called by scriptOneButton END---------------------------



//calling testServerQuery
function testServerQuery(secondMethodName)
{
	var dataset = "Obesity.csv";
	var rRoutine = "obesityCSVRoutine.R";
	queryRService(
	//method
	'runScriptOnCSVOnServer',
	{
		//params
		queryObject:[dataset,rRoutine]
		//queryStatement: "PercentObese2002,PercentObese2004",
		//schema: "us"
		
	},
	//callback
	handleRResult
	);
	
	function handleRResult(response)
	{
		if(response.error)
		{
			//resulttextarea.value = JSON.stringify(response,null,3);
			return;
		}
		else
		{
			var rResult = response.result;
			console.log("calling set CSVSource");
			setCSVSource(rResult);
			//console.log("retrieved " + rResult.length + "results");
			//resulttextarea.value = "Success";
			return;
		}
		
		
	}
	
	
	function setCSVSource(rResult)
	{
		console.log(rResult[0].value);
		var weave = document.getElementById('weave');
		weave.path('MyDataSource').request('CSVDataSource').vars({data: rResult[0].value}).exec('setCSVDataString(data)');
		weave.requestObject(['SPT'], 'ScatterPlotTool');
		
		/**
		columnPath path of the object in session state in Weave
		csvDataSource the source to use column from
		columnNumber columnIndex or columnName in the csvDatasource
		*/
		weave.setCSVColumn = function(columnPath, csvDataSource, columnNumber) {
		
				//weave
				//.path(csvDataSource)
				//.vars({i: columnNumber, p: columnPath})
				//.exec('putColumn(i, p)');
				
				var x = weave.path(csvDataSource);//gets the path object
				x.vars({i:columnNumber, p:columnPath});//adds the required variables and attributes them
				var y = x.exec('putColumn(i,p)');//calling funtion putColumn from CSVDataSource.as in Weave 
		};
		
		weave.setCSVColumn(['SPT','children','visualization','plotManager','plotters','plot','dataX'],'MyDataSource', 'PercentObese2002');
		weave.setCSVColumn(['SPT','children','visualization','plotManager','plotters','plot','dataY'],'MyDataSource', 'PercentObese2004');
		
		//can also specify the columnIndex
		//weave.setCSVColumn(['SPT','children','visualization','plotManager','plotters','plot','dataY'],'MyDataSource', 'PercentObese2004');
		
		//setting the color column, columnIndex is hardcoded
		weave.setCSVColumn(['defaultColorDataColumn', 'internalDynamicColumn'],'MyDataSource', 'PercentObese2005');
		
		
		
		
		//var scatterPlotX = weave.path("SPT","children","undefinedX","plotManager","plotters","plot","dataX","internalObject","dynamicColumnReference","internalObject");
		//scatterPlotX.state("hierarchyPath", '<hierarchy><attribute keyType="null" csvColumn="PercentObese2002" title="PercentObese2002"/></hierarchy>');
		
		//var scatterPlotX = weave.path("SPT","children","undefinedXY","plotManager","plotters","plot");
		//scatterPlotX.state = ("dataX", '<ReferencedColumn><dynamicColumnReference encoding="dynamic"> <HierarchyColumnReference><dataSourceName>MyDataSource</dataSourceName><hierarchyPath encoding="xml"><hierarchy><attribute csvColumn="PercentObese2002" keyType="null" title="PercentObese2002"/></hierarchy></hierarchyPath></HierarchyColumnReference></dynamicColumnReference></ReferencedColumn>');
		
		//var scatterPlotY = weave.path("SPT","children","undefinedXY","plotManager","plotters","plot");
		//scatterPlotY.state = ("dataY", '<ReferencedColumn><dynamicColumnReference encoding="dynamic"> <HierarchyColumnReference><dataSourceName>MyDataSource</dataSourceName><hierarchyPath encoding="xml"><hierarchy><attribute csvColumn="PercentObese2004" keyType="null" title="PercentObese2004"/></hierarchy></hierarchyPath></HierarchyColumnReference></dynamicColumnReference></ReferencedColumn>');
		//var scatterPlotY = weave.path("SPT", "children", "undefinedY", "plotManager", "plotters", "plot", "dataY", "internalObject", "dynamicColumnReference", "internalObject");
		//scatterPlotY.state("hierarchyPath", '<hierarchy> <attribute keyType="null" csvColumn="PercentObese2004" title="PercentObese2004"/></hierarchy>');
		
		

	}
	
	
}

});

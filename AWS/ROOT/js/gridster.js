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
                      // handleSelectOption();
                      $(this).dialog("close");
                    },
                    Cancel : function() {
                      // handleCancelOption();
                      $(this).dialog("close");
                    },
                  }
                });

                $('#dataButton').button().click(function() {
                  $('#dataDialog').dialog("open");
                });
                
                $('#scriptButton').button().click(function() {
                  // enter run script here
                	testServerQuery('getRResult');
                });
                
                $('#callWeaveButton').button().click(function() {
                  // enter function here for calling weave
                	scriptOneQuery('getScriptOneResult');
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
                
                scriptCombobox.append($("<option/>").val('script1').text(
                          "Script 1"));
                scriptCombobox.append($("<option/>").val('script2')
                          .text("Script 2"));
                
                var dataCombobox = $('#dataCombobox');
                
                dataCombobox.append($("<option/>").val('script1').text(
                          "Obesity.csv"));
                dataCombobox.append($("<option/>").val('script2')
                          .text("Cars.csv"));
                
                var dialogOptions = {
                        "autoOpen": false,
                        "width": 950,
                		"height": 700,
                		"modal" : false,
                		buttons : {
                			"Export" : function() {
                				console.log("Save button clicked");
                			},
                		
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
                
              }));

              
// Disable caching of AJAX responses
$.ajaxSetup({
    cache: false
});

//calling Rservice on Weave
function queryRService(method,params,callback,queryID)
{
	$('#scriptResults').html("<p>" + JSON.stringify('queryRService',method,params));
	var url = '/WeaveServices/RService';
	var request = {
					jsonrpc:"2.0",
					id:queryID || "no_id",
					method : method,
					params : params
	};
	
	$.post(url,JSON.stringify(request), callback, "json");
	//resulttextarea.value = 'Awaiting Response for ' + method + ' request....';
}

//---------------------------------called by scriptOneButton BEGIN--------------------------

function scriptOneQuery(secondMethodName)
{
	var dataset = "obesity.csv";
	var rRoutine = "Normalization.R";
	
	queryRService(
	//method
	'runScriptOnCSVOnServer',
	{
		//params
		queryObject:[dataset,rRoutine],
		
	},
	//callback
	handleScriptOneResult
	);
	
	function handleScriptOneResult(response)
	{
		if(response.error)
		{
			$('#scriptResults').html(JSON.stringify(response,null,3));
			return;
		}
		else
		{
			var rResult = response.result;
			$('#scriptResults').html(JSON.stringify(rResult));
			setCSV2Source(rResult);
			$('#scriptResults').html("retrieved " + rResult.length + "results");
			return;
		}
		
		
	}
	
	
	function setCSV2Source(rResult)
	{
		$('#scriptResults').html(rResult[0].value);
		var weave = document.getElementById('weave');
		weave.path('MyNORMDataSource').request('CSVDataSource').vars({data: rResult[0].value}).exec('setCSVDataString(data)');
		weave.requestObject(['DTT'], 'DataTableTool');
		
		
		
	}
}
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
		queryObject:[dataset,rRoutine],
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
			$('#resultScripts').html("Script succeeded");
			var rResult = response.result;
			$('#resultScripts').html("calling set CSVSource");
			$('#resultScripts').html(JSON.stringify(rResult));
			setCSVSource(rResult);
			//console.log("retrieved " + rResult.length + "results");
			//resulttextarea.value = "Success";
			return;
		}
		
		
	}
	
	
	function setCSVSource(rResult)
	{
		$('#resultScripts').html(rResult[0].value);
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
		weave.setCSVColumn(['defaultColorDataColumn', 'internalDynamicColumn'],'MyDataSource', 0);
		
		
		
		
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

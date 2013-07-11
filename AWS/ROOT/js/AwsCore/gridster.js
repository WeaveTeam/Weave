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


function populatePanels(dataColumns) {
	// this function update panels with metadata from database
	//console.log(dataColumns);
	var demoColumns = [];
	
	for (var obj in dataColumns) {
		//console.log(obj);
		//console.log(obj["id"]);
		
		var column = dataColumns[obj];
		if (column.hasOwnProperty("id")) {
			if (column["id"] === 161214) {
				demoColumns.push(column);
			}
			if (column["id"] === 161264) {
				demoColumns.push(column);
			}
			if (column["id"] === 161276) {
				demoColumns.push(column);
			}
			if (column["id"] === 161265) {
				demoColumns.push(column);
			}
			if (column["id"] === 161614) {
				demoColumns.push(column);
			}
			
		}
		
	}
	
	// here I have my demo Columns. Iterate over, find the categories.
	for (var column in demoColumns) {
		var metadata = demoColumns[column].publicMetadata;
		// find the panel in which the column would of. For now we only have Geography and variable panel.
		if (metadata.hasOwnProperty("category")) {
			if (metadata.category == "geography") {
				$('#geography-content').append(metadata.vartype + ':&nbsp<select> <option>'+metadata.title + ' ' + metadata.varrange +'</option> </select><br>');
				$('#geography-content').append('<br>');
			}
			if (metadata.category == "variable") {
				if (metadata.vartype == "continuous") {
					$('#variable-content').append('<div style="float:left">' + '<input type="checkbox">' + metadata.title + ': &nbsp&nbsp </div>' + '<div style="float:left" id='+metadata.title+'/>');
					$('#'+metadata.title).slider({
						range:true,
						min:metadata.min,
						max:metadata.max,
						values: [15, 75],
						slide:function(ui){
							$('#scriptResults').html("min:"+ ui.values[0] + "max:" + ui.values[1]);
						}
					});
					$('#variable-content').append('<br><br>');
				}
				
				if (metadata.vartype == "categorical") {
					$('#variable-content').append('<input type="checkbox">' + metadata.title + ': <select id='+metadata.title+'/>');
					for (var i = metadata.min; i <= metadata.max; i++) {
						$('#'+metadata.title).append($("<option/>").text(i));
					}
					$('#variable-content').append('<br><br>');
				}
				
			}
			
		}
		
		
	}
	
	//console.log(demoColumns);
	return;
	
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

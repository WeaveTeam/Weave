/**
 * Handle all Analysis Tab related work - Controllers to handle Analysis Tab
 */
'use strict';
var tryParseJSON = function(jsonString){
    try {
        var o = JSON.parse(jsonString);

        // Handle non-exception-throwing cases:
        // Neither JSON.parse(false) or JSON.parse(1234) throw errors, hence the type-checking,
        // but... JSON.parse(null) returns 'null', and typeof null === "object", 
        // so we must check for that, too.
        if (o && typeof o === "object" && o !== null) {
            return o;
        }
    }
    catch (e) { }
    return false;
};


var AnalysisModule = angular.module('aws.AnalysisModule', ['wu.masonry', 'ui.select2', 'ui.slider', 'ui.bootstrap']);

//using value recipes so that these tools could be used elsewhere as well TODO: make them into directives
AnalysisModule.value('indicator_tool', {
												title : 'Indicator',
												template_url : 'src/analysis/indicator/indicator.tpl.html',
												description : 'Choose an Indicator for the Analysis',
												category : 'indicatorfilter'
});

AnalysisModule.value('geoFilter_tool',{
										title : 'Geography Filter',
										template_url : 'src/analysis/data_filters/geography.tpl.html',
										description : 'Filter data by States and Counties',
										category : 'datafilter'
});

AnalysisModule.value('timeFilter_tool', {
											title : 'Time Period Filter',
											template_url : 'src/analysis/data_filters/time_period.tpl.html',
											description : 'Filter data by Time Period',
											category : 'datafilter'
});

AnalysisModule.value('byVariableFilter_tool', {
													title : 'By Variable Filter',
													template_url : 'src/analysis/data_filters/by_variable.tpl.html',
													description : 'Filter data by Variables',
													category : 'datafilter'
});

AnalysisModule.value('BarChartTool',{
										id : 'BarChartTool',
										title : 'Bar Chart Tool',
										template_url : 'src/visualization/tools/barChart/bar_chart.tpl.html'

});

AnalysisModule.value('MapTool', {
									id : 'MapTool',
									title : 'Map Tool',
									template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html'
});

AnalysisModule.value('ScatterPlotTool', {
											id : 'ScatterPlotTool',
											title : 'Scatter Plot Tool',
											template_url : 'src/visualization/tools/scatterPlot/scatter_plot.tpl.html',
											description : 'Display a Scatter Plot in Weave'
});

AnalysisModule.value('DataTableTool', {
											id : 'DataTableTool',
											title : 'Data Table Tool',
											template_url : 'src/visualization/tools/dataTable/data_table.tpl.html',
											description : 'Display a Data Table in Weave'
});

AnalysisModule.value('color_Column', {	
											id : 'color_Column',
											title : 'Color Column',
											template_url : 'src/visualization/tools/color/color_Column.tpl.html',
											description : 'Set the color column in Weave'
});


AnalysisModule.value('key_Column', {
										id : 'Key_Column', 
										title : 'Key Column',
										template_url : 'src/visualization/tools/color/key_Column.tpl.html',
										description : 'Set the key column in Weave'
});




//analysis service
AnalysisModule.service('AnalysisService', ['geoFilter_tool','timeFilter_tool', 'BarChartTool', 'MapTool', 'DataTableTool', 'ScatterPlotTool', 'color_Column', 'key_Column' ,
                                           function(geoFilter_tool, timeFilter_tool,BarChartTool, MapTool, DataTableTool, ScatterPlotTool, color_Column, key_Column ) {
	
	var AnalysisService = {
			
	};
	
	AnalysisService.weaveTools = [MapTool,
	                              BarChartTool,
	                              DataTableTool,
	                              ScatterPlotTool,
	                              color_Column,
	                              key_Column];
	
	AnalysisService.geoFilter_tool = geoFilter_tool;
	AnalysisService.timeFilter_tool = timeFilter_tool;
	
	return AnalysisService;
	
}]);



//main analysis controller
AnalysisModule.controller('AnalysisCtrl', function($scope, $filter, queryService, AnalysisService, WeaveService, QueryHandlerService, $window) {

	setTimeout(loadFlashContent, 100);
	$scope.queryService = queryService;
	$scope.AnalysisService = AnalysisService;
	$scope.WeaveService = WeaveService;
	$scope.QueryHandlerService = QueryHandlerService;
	
	$scope.showToolMenu = false;
	
	$scope.$watch(function() {
		return WeaveService.weave;
	}, function () {
		if(WeaveService.weave) {
			$scope.showToolMenu = true;
		}
	});
	
	//getting the list of datatables
	queryService.getDataTableList(true);
	
//	$scope.$watch('WeaveService.weaveWindow.closed', function() {
//		queryService.dataObject.openInNewWindow = WeaveService.weaveWindow.closed;
//	});
	var expandedNodes = null;
	var scrolledPosition = 0;
	var activeNode = null;
	
	var buildTree = function (node, key) {
		return {
			title : key,
			value : node,
			select : activeNode ? node == activeNode.data.value : false,
			expand : expandedNodes && expandedNodes.indexOf(node) >= 0,
			isFolder : !!(typeof node == 'object' && node),
			children : (typeof node == 'object' && node)
				? Object.keys(node).map(function(key) { return buildTree(node[key], key); })
				: null
		};	
	};
	
	var queryObjectTreeData = buildTree(queryService.queryObject);
	
	$scope.getPath = function(node) {
		var path = [];
		while (node.parent)
		{
			path.unshift(node.data.title);
			node = node.parent;
		}
		return path;
	};
	
	$scope.setValueAtPath = function(obj, path, value)
	{
		path.shift(); // throw away root
		
		for (var i = 0; i < path.length - 1; i++)
	        obj = obj[path[i]];

	    obj[path[i]] = value;
	};
	
	$scope.$watch('queryService.queryObject', function () {
		
		if(expandedNodes) {
			expandedNodes = [];
			scrolledPosition = $(".dynatree-container").scrollTop();
			activeNode = $("#queryObjTree").dynatree("getActiveNode");
			$("#queryObjTree").dynatree("getTree").visit(function(node) {
				if(node.bExpanded)
				{
					expandedNodes.push(node.data.value);
				}
			});
		} else {
			expandedNodes = [];
		}
		
		queryObjectTreeData = buildTree(queryService.queryObject);
		queryObjectTreeData.title = "QueryObject";

		$('#queryObjTree').dynatree({
			minExpandLevel: 1,
			clickFolderMode: 1,
			children : queryObjectTreeData,
			keyBoard : true,
			onPostInit: function(isReloading, isError) {
				this.reactivate();
			},
			onActivate: function(node) {
				$scope.selectedNode = node;
				$scope.selectedValue = node.data;
				$scope.selectedKey = node.data.title;
				$scope.$apply();
			},
			debugLevel: 0
		});
		
		$("#queryObjTree").dynatree("getTree").reload();
		$(".dynatree-container").scrollTop(scrolledPosition);

	}, true);
	
	var convertToTableFormat = function(obj) {
		var data = [];
		for (var key in obj) {
			data.push({property : key, value : obj[key] });
		}
		return data;
	};
	
	$scope.qobjData = convertToTableFormat(queryService.queryObject);
	$scope.selectedItems = [];
	$scope.selectedValue = {};
	
	$scope.$watch('selectedValue.value', function () {
		if($scope.selectedValue.value) {
			if(typeof $scope.selectedValue.value != 'object')
			{
				$scope.isValue = true;
				
				var val = $scope.selectedValue.value;
				//try { val = JSON.parse($scope.selectedValue.value); } catch(e) {}
				$scope.setValueAtPath($scope.queryService.queryObject, $scope.getPath($scope.selectedNode), val);
				$scope.selectedVal = $scope.selectedValue.value;
			} else {
				$scope.isValue = false;
				$scope.qobjData = convertToTableFormat($scope.selectedValue.value);
			}
		} else {
			$scope.isValue = true;
		}
	});
	
	$scope.qobjGridOptions = { 
	        data: 'qobjData',
	        enableRowSelection: true,
	        enableCellEdit: true,
	        columnDefs: [{field: 'property', displayName: 'Property', enableCellEdit: false, enableCellSelection : false}, 
	                     {field:'value', displayName:'Value', enableCellEdit: true}],
	        multiSelect : false,
	        selectedItems : $scope.selectedItems
	 };
	
	$scope.$on('ngGridEventEndCellEdit' , function() {
		if($scope.qobjData.length) {
			var edited = $scope.selectedItems[0];
			if(edited) {
				try {
					edited.value = JSON.parse(edited.value);
				} catch(e) {}
				$scope.selectedValue.value[edited.property] = edited.value;
			}
		}
	});

	 $("#queryObjectPanel" ).draggable().resizable();;
	 $("#queryObjectPanel" ).css({'top' : 10, 'left' : 20});
	
	//**********************************************************REMAPPING**************************************
	 queryService.cache.shouldRemap = [];
	 $scope.newValue= "";
	 queryService.cache.remapValue = [];
	 
	 //checks for object in collection and accordingly updates
	 $scope.setRemapValue= function(originalValue, reMappedValue)
	 {
		 var columnId = queryService.queryObject.Indicator.id;
		 //TODO parameterize columnType
		 var matchFound = false;//used to check if objects exist in queryService.queryObject.IndicatorRemap
		 
		if(reMappedValue)//handles empty or undefined values
			{
				 if(queryService.queryObject.IndicatorRemap.length == 0)//for the first time the array is filled
				 {
				 	queryService.queryObject.IndicatorRemap.push({
						columnsToRemapId : parseInt(columnId),
						originalValue : originalValue,
						reMappedValue : reMappedValue
	
					  });
				 	//console.log("first iteration");
				 }
				 else
				 {
					//checking if the entity exists and update the required object
					 for(var i in queryService.queryObject.IndicatorRemap)
						 {
						 	var oneObject = queryService.queryObject.IndicatorRemap[i];
						 	if( oneObject.originalValue == originalValue)
						 		{
							 		oneObject.reMappedValue = reMappedValue;
							 		matchFound = true;
							 		//console.log("match found, hence overwrote", queryService.queryObject.IndicatorRemap );
						 		}
						 }
					 
				 	if(!matchFound)//if match is not found create new object
				 		{
				 			queryService.queryObject.IndicatorRemap.push({
							columnsToRemapId : parseInt(columnId),
							originalValue : originalValue,
							reMappedValue : reMappedValue

						  });
				 			//console.log("match not found, hence new", queryService.queryObject.IndicatorRemap );
				 		}
				 }
			}
	 };
	 //**********************************************************REMAPPING END**************************************
	
	//select2-sortable handlers
	$scope.getItemId = function(item) {
		return item.id;
	};
	
	$scope.getItemText = function(item) {
		return item.title;
	};
	
	//datatable
	$scope.getDataTable = function(term, done) {
		var values = queryService.cache.dataTableList;
		done($filter('filter')(values, {title:term}, 'title'));
	};
	//Indicator
	 $scope.getIndicators = function(term, done) {
			var columns = queryService.cache.columns;
			done($filter('filter')(columns,{columnType : 'indicator',title:term},'title'));
	};
	
	$scope.$watch(function() {
		return WeaveService.weave;
	}, function() {
		if(WeaveService.weave) 
		{
			WeaveService.weave.path().state(queryService.dataObject.weaveSessionState);
		}
	});
	
	
	//******************************managing weave and its session state**********************************************//
	$scope.$watch(function() {
		return queryService.queryObject.properties.openInNewWindow;
	}, function() {
		if(WeaveService.weave)
			queryService.dataObject.weaveSessionState = WeaveService.weave.path().getState();
	
		if(!!queryService.queryObject.properties.openInNewWindow) {
			if(WeaveService.weaveWindow !== WeaveService.analysisWindow) {
				WeaveService.weaveWindow.close();
				setTimeout(loadFlashContent, 100);
				WeaveService.setWeaveWindow(WeaveService.analysisWindow);
			}
			setTimeout(loadFlashContent, 100); // reload weave object in main window.
			
			// checkweaveready and restore session station into embedded weave.
			QueryHandlerService.waitForWeave(null, function (weave) {
				WeaveService.weave = weave;
				if(queryService.cache.weaveSessionState) {
					setTimeout(function () {
						WeaveService.weave.path().state(queryService.cache.weaveSessionState);
					}, 100);
					
				}
			});
		} else {
			
			// check if there is a result data, meaning there is a current analysis
			// if that's the case, save embedded weave session state
			// open the weave window, checkweaveready and restore the session state.
			//if(queryService.dataObject.resultData)
			//{
				queryService.cache.weaveSessionState = WeaveService.weave.path().getState();
				
				if(!WeaveService.weaveWindow || WeaveService.weaveWindow.closed) {
					WeaveService.weaveWindow = $window.open("/weave.html?",
							"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
					QueryHandlerService.waitForWeave(WeaveService.weaveWindow , function(weave) {
						WeaveService.weave = weave;
						WeaveService.weave.path().state(queryService.cache.weaveSessionState);
						//updates required for updating query object validation and to enable visualization widget controls
						that.displayVizMenu = true;
						that.isValidated = false;
						that.validationUpdate = "Ready for validation";
						
						//scope.$apply();//re-fires the digest cycle and updates the view
					});
				}
			//}
			
		}
	});
	
	$scope.$watchCollection(function() {
		return $('#weave');
	}, function() {
		if($('#weave').length) {
			WeaveService.weave = $('#weave')[0];
		} else {
			WeaveService.weave = null;
		}
	});
	
	//******************************managing weave and its session state END**********************************************//
	
	
	$scope.IndicDescription = "";
	$scope.varValues = [];
	
	$scope.toggle_widget = function(tool) {
		queryService.queryObject[tool.id].enabled = tool.enabled;
	};
	
	$scope.disable_widget = function(tool) {
		tool.enabled = false;
		queryService.queryObject[tool.id].enabled = false;
		WeaveService[tool.id](queryService.queryObject[tool.id]); // temporary because the watch is not triggered
	};
	
	
	$scope.$watch('queryService.queryObject.Indicator', function() {
		
		if(queryService.queryObject.Indicator) {
			$scope.IndicDescription = queryService.queryObject.Indicator.description;
			queryService.getEntitiesById([queryService.queryObject.Indicator.id], true).then(function (result) {
				if(result.length) {
					var resultMetadata = result[0];
					if(resultMetadata.publicMetadata.hasOwnProperty("aws_metadata")) {
						var metadata = angular.fromJson(resultMetadata.publicMetadata.aws_metadata);
						if(metadata.hasOwnProperty("varValues")) {
							queryService.getDataMapping(metadata.varValues).then(function(result) {
								$scope.varValues = result;
							});
						}
					}
				}
			});
		} else {
			// delete description and table if the indicator is clear
			$scope.IndicDescription = "";
			$scope.varValues = [];
		}
	});
	

	$scope.$watch(function () {
		return queryService.queryObject.BarChartTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in AnalysisService.tool_list) {
				var tool = AnalysisService.tool_list[i];
				if(tool.id == "BarCharTool") {
					tool.enabled = newVal;
					break;
				}
			}
		}
	});
	
//	$scope.$watch(function () {
//		return queryService.queryObject.MapTool.enabled;
//	}, function(newVal, oldVal) {
//		if(newVal != oldVal) {
//			for(var i in AnalysisService.tool_list) {
//				var tool = AnalysisService.tool_list[i];
//				if(tool.id == "MapTool") {
//					tool.enabled = newVal;
//					break;
//				}
//			}
//		}
//	});
	
	$scope.$watch(function () {
		return queryService.queryObject.ScatterPlotTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in AnalysisService.tool_list) {
				var tool = AnalysisService.tool_list[i];
				if(tool.id == "ScatterPlotTool") {
					tool.enabled = newVal;
					break;
				}
			}
		}
	});
	
	$scope.$watch(function () {
		return queryService.queryObject.DataTableTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in AnalysisService.tool_list) {
				var tool = AnalysisService.tool_list[i];
				if(tool.id == "DataTableTool") {
					tool.enabled = newVal;
					break;
				}
			}
		}
	});
	
	/************** watches for query validation******************/
	$scope.$watchCollection(function() {
		return [queryService.queryObject.scriptSelected,
		        queryService.queryObject.dataTable,
		        queryService.queryObject.scripOptions,
		        queryService.cache.scriptMetadata
		        ];
	}, function () {
		//if the datatable has not been selected
		if(queryService.queryObject.dataTable == null || queryService.queryObject.dataTable == ""){
			queryService.queryObject.properties.validationStatus = "Data table has not been selected.";
			queryService.queryObject.properties.isQueryValid = false;
		}
		//if script has not been selected
		else if(queryService.queryObject.scriptSelected == null || queryService.queryObject.scriptSelected == "")
		{
			queryService.queryObject.properties.validationStatus = "Script has not been selected.";
			queryService.queryObject.properties.isQueryValid = false;
		}
		//this leaves checking the scriptOptions
		else if (queryService.cache.scriptMetadata) 
		{
			
			$scope.$watch(function() {
				return queryService.queryObject.scriptOptions;
			}, function () {
				var g = 0;
				var counter = Object.keys(queryService.queryObject.scriptOptions).length;
				for(var f in queryService.queryObject.scriptOptions) {
					if(!queryService.queryObject.scriptOptions[f]) {
						queryService.queryObject.properties.validationStatus = "'" + f + "'" + " has not been selected";
						queryService.queryObject.properties.isQueryValid = false;
	
						break;
					}
					else
						g++;
				}
				if(g == counter) {
					queryService.queryObject.properties.validationStatus = "Query is valid";
					queryService.queryObject.properties.isQueryValid = true;
				}
			}, true);
		}
	}, true);
	/************** watches for query validation******************/
	$scope.tool_options = ["MapTool", "BarCharTool", "ScatterPlotTool", "DataTable"];
	
	$scope.addTool = function(name) {
		switch(name) {
			case "MapTool":
				AnalysisService.weaveTools.push({
					title : 'Map Tool',
					template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html'
				});
				break;
			case "BarCharTool":
				AnalysisService.weaveTools.push({
					id : 'BarCharTool',
					title : 'Map Tool',
					template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html'
				});
				break;
			case "ScatterPlotTool":
				AnalysisService.weaveTools.push({
					id : 'ScatterPlotTool',
					title : 'Map Tool',
					template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html'
				});
				break;
			case "DataTable":
				AnalysisService.weaveTools.push({
					id : 'DataTable',
					title : 'Map Tool',
					template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html'
				});
				break;
		}
	};
});


AnalysisModule.config(function($selectProvider) {
	angular.extend($selectProvider.defaults, {
		caretHTML : '&nbsp'
	});
});






//Script Options controller
AnalysisModule.controller("ScriptsSettingsCtrl", function($scope, queryService, $filter) {

	// This sets the service variable to the queryService 
	$scope.service = queryService;
	
	queryService.getListOfScripts(true);
	
	//clears scrip options when script clear button is hit
	$scope.getScriptMetadata = function(scriptSelected,forceUpdate){
		if(scriptSelected)
			$scope.service.getScriptMetadata(scriptSelected, forceUpdate);
		else
			$scope.service.dataObject.scriptMetadata.inputs = [];
	};

	//  clear script options when script changes
	$scope.$watchCollection(function() {
		return [queryService.queryObject.scriptSelected,
                queryService.queryObject.dataTable];
	}, function(newVal, oldVal) {
		
			// this check is necessary because when angular changes tabs, it triggers changes
			// for the script selected or data table even if the user may not have change them.
			if(!angular.equals(newVal[0], oldVal[0]) && !angular.equals(newVal[1], oldVal[1])) {
				queryService.queryObject.scriptOptions = {};
			}
	});
	
	
	//**************************************select2 sortable options handlers*******************************
	//handler for select2sortable for script list
	$scope.getScriptList = function(term, done) {
		var values = queryService.cache.scriptList;
		done($filter('filter')(values, term));
	};
	
	//handlers for select2sortable for script input options
	$scope.getTimeInputOptions = function(term, done){
		var values = queryService.cache.columns;
		done($filter('filter')(values,{columnType : 'time',title:term},'title'));
	};
	
	$scope.getGeographyInputOptions = function(term, done){
		var values = queryService.cache.columns;
		done($filter('filter')(values,{columnType : 'geography',title:term},'title'));
	};
	
	$scope.getAnalyticInputOptions = function(term, done){
		var values = queryService.cache.columns;
		done($filter('filter')(values,{columnType : 'analytic',title:term},'title'));
	};
	
	//TODO try to use parent scope function
	 $scope.getIndicators2 = function(term, done) {
			var columns = queryService.cache.columns;
			done($filter('filter')(columns,{columnType : 'indicator',title:term},'title'));
	};
	
	$scope.getItemDefault = function(item) {
		return item.title;
	};
	
	$scope.getItemText = function(item) {
		return item.title;
	};
	//**************************************select2 sortable options handlers END*******************************
	
	
	//handles the defaults appearing in the script options selection
	$scope.$watchCollection(function() {
		return [queryService.cache.scriptMetadata, queryService.cache.columns];
	}, function(newValue, oldValue) {
		
		if(newValue != oldValue) {
			var scriptMetadata = newValue[0];
			var columns = newValue[1];
			
			if(scriptMetadata && columns) {
				if(scriptMetadata.hasOwnProperty("inputs")) {
					for(var i in scriptMetadata.inputs) {
						var input = scriptMetadata.inputs[i];
						if(input.type == "column") {
							for(var j in columns) {
								var column = columns[j];
								if(input.hasOwnProperty("defaults")) {
									if(column.title == input['defaults']) {
										$scope.service.queryObject.scriptOptions[input.param] = column;
										break;
									}
								}
							}
						}
					}
				}
			}
		}
	});
	
	//handles the indicator in the script options
	$scope.$watch(function() {
		return queryService.queryObject.scriptOptions;
	}, function(newValue, oldValue) {
		if(newValue != oldValue) {
			var scriptOptions = newValue;
			for(var key in scriptOptions) { 
				var option = scriptOptions[key];
				if(option) {
					if(option.hasOwnProperty("columnType")) {
						if(option.columnType.toLowerCase() == "indicator") {
							queryService.queryObject.Indicator = option;
						}
					}
				}
			}
			
		}
	}, true);

	$scope.$watchCollection(function() {
		return [queryService.queryObject.Indicator, queryService.queryObject.scriptSelected, queryService.cache.scriptMetadata];
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			var indicator = newVal[0];
			var scriptSelected = newVal[1];
			var scriptMetadata = newVal[2];
			
			if(indicator && scriptSelected) {
				queryService.queryObject.BarChartTool.title = "Bar Chart of " + scriptSelected.split('.')[0] + " of " + indicator.title;
				queryService.queryObject.MapTool.title = "Map of " + scriptSelected.split('.')[0] + " of " + indicator.title;
				queryService.queryObject.ScatterPlotTool.title = "Scatter Plot of " + scriptSelected.split('.')[0] + " of " + indicator.title;

			}
			
			$scope.$watch(function() {
				return queryService.cache.scriptMetadata;
			}, function(newValue, oldValue) {
				if(newValue) {
					scriptMetadata = newValue;
					if(indicator && scriptMetadata) {
						for(var i in queryService.cache.scriptMetadata.inputs) {
							var metadata = queryService.cache.scriptMetadata.inputs[i];
							if(metadata.hasOwnProperty('type')) {
								if(metadata.type == 'column') {
									if(metadata.hasOwnProperty('columnType')) {
										if(metadata.columnType.toLowerCase() == "indicator") {
											queryService.queryObject.scriptOptions[metadata.param] = indicator;
										}
									}
								}
							}
						}
					}
				}
			}, true);
		}
	}, true);
		
	$scope.toggleButton = function(input) {
		
		if (queryService.queryObject.scriptOptions[input.param] == input.options[0]) {
			queryService.queryObject.scriptOptions[input.param] = input.options[1];
		} else {
			queryService.queryObject.scriptOptions[input.param] = input.options[0];
		}
	};
	
});

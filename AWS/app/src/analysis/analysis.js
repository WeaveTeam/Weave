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
										title : 'Key Column',
										template_url : 'src/visualization/tools/color/key_Column.tpl.html',
										description : 'Set the key column in Weave'
});





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

AnalysisModule.controller('AnalysisCtrl', function($scope, $filter, queryService, AnalysisService, WeaveService, QueryHandlerService, $window) {

	setTimeout(loadFlashContent, 100);
	$scope.queryService = queryService;
	$scope.AnalysisService = AnalysisService;
	$scope.WeaveService = WeaveService;
	$scope.QueryHandlerService = QueryHandlerService;
	
	//getting the list of datatables
	queryService.getDataTableList(true);
	
//	$scope.$watch('WeaveService.weaveWindow.closed', function() {
//		queryService.dataObject.openInNewWindow = WeaveService.weaveWindow.closed;
//	});
	
	var buildTree2 = function (node, key) {
		return {
			title : key || node || '',
			value : node,
			isFolder : !!(typeof node == 'object' && node),
			children : (typeof node == 'object' && node)
				? Object.keys(node).map(function(key) { return buildTree2(node[key], key); })
				: null
		};	
	};
	
	var queryObjectTreeData = buildTree2(queryService.queryObject);

	$('#queryObjTree').dynatree({
		minExpandLevel: 1,
		children : queryObjectTreeData,
		keyBoard : true,
		onPostInit: function(isReloading, isError) {
			this.reactivate();
		},
		onActivate: function(node) {
			$scope.selectedValue = node.data.value;
			console.log(node.data.value);
			$scope.$apply();
		},
		debugLevel: 0
	});
	$scope.$watch('queryService.queryObject', function () {
		queryObjectTreeData = buildTree2(queryService.queryObject);
		queryObjectTreeData.title = "Query Object";
		$('#queryObjTree').dynatree({
			minExpandLevel: 1,
			children : queryObjectTreeData,
			keyBoard : true,
			onPostInit: function(isReloading, isError) {
				this.reactivate();
			},
			onActivate: function(node) {
				$scope.selectedValue = node.data.value;
				console.log(node.data.value);
				$scope.$apply();
			},
			debugLevel: 0
		});
		$("#queryObjTree").dynatree("getTree").reload();
		
	}, true);
	
	 $("#queryObjectPanel" ).draggable().resizable();;
	
	 
	 $scope.shouldRemap = [];
	 $scope.remapValue = [];
	 
	 $scope.setRemapBoolean = function(varValue, boolean)
	 {
		 if( queryService.queryObject.IndicatorRemap[varValue])
		 {
			 queryService.queryObject.IndicatorRemap[varValue].shouldRemap = boolean;
		 } else {
			 queryService.queryObject.IndicatorRemap[varValue] = {};
			 queryService.queryObject.IndicatorRemap[varValue].shouldRemap = boolean;
		 }
	 };
	 
	 $scope.setRemapValue = function(varValue, value)
	 {
		 if(queryService.queryObject.IndicatorRemap[varValue])
		 {
			 queryService.queryObject.IndicatorRemap[varValue].value = value;
		 } else 
		 {
			 queryService.queryObject.IndicatorRemap[varValue] = {};
			 queryService.queryObject.IndicatorRemap[varValue].value = value;
			 
		 }
	 };
	 
	 $scope.getDataTable = function(term, done) {
		var values = queryService.dataObject.dataTableList;
		done($filter('filter')(values, {title:term}, 'title'));
	};
	
	$scope.dataTableId = function(item) {
		return item.id;
	};
	
	$scope.dataTableText = function(item) {
		return item.title;
	};
	
	
	//******************************managing weave and its session state**********************************************//
	$scope.$watch(function() {
		return queryService.dataObject.openInNewWindow;
	}, function() {
		if(!queryService.dataObject.openInNewWindow) {
			if(WeaveService.weaveWindow && !WeaveService.weaveWindow.closed) {
				// save the session state.
				queryService.dataObject.weaveSessionState = WeaveService.weave.path().getState();
				WeaveService.weaveWindow.close();
			}
			setTimeout(loadFlashContent, 100); // reload weave object in main window.
			
			// checkweaveready and restore session station into embedded weave.
			QueryHandlerService.waitForWeave(null, function (weave) {
				WeaveService.weave = weave;
				if(queryService.dataObject.weaveSessionState) {
					setTimeout(function () {
						WeaveService.weave.path().state(queryService.dataObject.weaveSessionState);
					}, 100);
					
				}
			});
		} else {
			
			// check if there is a result data, meaning there is a current analysis
			// if that's the case, save embedded weave session state
			// open the weave window, checkweaveready and restore the session state.
			//if(queryService.dataObject.resultData)
			//{
				queryService.dataObject.weaveSessionState = WeaveService.weave.path().getState();
				
				if(!WeaveService.weaveWindow || WeaveService.weaveWindow.closed) {
					WeaveService.weaveWindow = $window.open("/weave.html?",
							"abc","toolbar=no, fullscreen = no, scrollbars=yes, addressbar=no, resizable=yes");
					QueryHandlerService.waitForWeave(WeaveService.weaveWindow , function(weave) {
						WeaveService.weave = weave;
						WeaveService.weave.path().state(queryService.dataObject.weaveSessionState);
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
	
	//******************************managing weave and its session state**********************************************//
	
	
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
			$scope.IndicDescription = angular.fromJson(queryService.queryObject.Indicator).description;
			queryService.getEntitiesById([angular.fromJson(queryService.queryObject.Indicator).id], true).then(function (result) {
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
	
//	$scope.$watchCollection(function() {
//		return $.map(AnalysisService.tool_list, function(tool) {
//			return tool.enabled;
//		});
//	}, function() {
//		$.map(AnalysisService.tool_list, function(tool) {
//			queryService.queryObject[tool.id].enabled = tool.enabled;
//		});
//	});
	
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
	
	$scope.$watch(function () {
		return queryService.queryObject.MapTool.enabled;
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			for(var i in AnalysisService.tool_list) {
				var tool = AnalysisService.tool_list[i];
				if(tool.id == "MapTool") {
					tool.enabled = newVal;
					break;
				}
			}
		}
	});
	
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
		        queryService.queryObject.scriptOptions
		        ];
	}, function () {
	//if the datatable has not been selected
	if(!queryService.queryObject.dataTable.hasOwnProperty("id")){
		queryService.dataObject.validationStatus = "Data table has not been selected.";
		queryService.dataObject.isQueryValid = false;
	}	
	//if the script has not been selected
	else if(!queryService.queryObject.scriptSelected){
		queryService.dataObject.validationStatus = "Script has not been selected.";
		queryService.dataObject.isQueryValid = false;
	}
	//this leaves checking the scriptOptions
	else {
			$scope.$watch(function() {
				return queryService.queryObject.scriptOptions;
			}, function () {
				var g = 0;
				var counter = Object.keys(queryService.queryObject.scriptOptions).length;
				for(var f in queryService.queryObject.scriptOptions) {
					if(!queryService.queryObject.scriptOptions[f]) {
						queryService.dataObject.validationStatus = "'" + f + "'" + " has not been selected";
						queryService.dataObject.isQueryValid = false;
	
						break;
					}
					else
						g++;
				}
				if(g == counter) {
					queryService.dataObject.validationStatus = "Query is valid";
					queryService.dataObject.isQueryValid = true;
				}
			}, true);
		}
	}, true);
	/************** watches for query validation******************/
});


AnalysisModule.config(function($selectProvider) {
	angular.extend($selectProvider.defaults, {
		caretHTML : '&nbsp'
	});
});

AnalysisModule.controller("ScriptsSettingsCtrl", function($scope, queryService) {

	// This sets the service variable to the queryService 
	$scope.service = queryService;
	
	queryService.getListOfScripts(true);

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
	
	
	$scope.$watchCollection(function() {
		return [queryService.dataObject.scriptMetadata, queryService.dataObject.columns];
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
								if(input.hasOwnProperty("default")) {
									if(column.title == input['default']) {
										queryService.queryObject.scriptOptions[input.param] = angular.toJson(column);
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
	
	$scope.$watch(function() {
		return queryService.queryObject.scriptOptions;
	}, function(newValue, oldValue) {
		if(newValue != oldValue) {
			var scriptOptions = newValue;
			for(var key in scriptOptions) { 
				var option = scriptOptions[key];
				if(option) {
					if(tryParseJSON(option).hasOwnProperty("columnType")) {
						if(angular.fromJson(option).columnType.toLowerCase() == "indicator") {
							queryService.queryObject.Indicator = option;
						}
					}
				}
			}
			
		}
	}, true);

	$scope.$watchCollection(function() {
		return [queryService.queryObject.Indicator, queryService.queryObject.scriptSelected, queryService.dataObject.scriptMetadata];
	}, function(newVal, oldVal) {
		if(newVal != oldVal) {
			var indicator = newVal[0];
			var scriptSelected = newVal[1];
			var scriptMetadata = newVal[2];
			
			if(indicator && scriptSelected) {
				queryService.queryObject.BarChartTool.title = "Bar Chart of " + scriptSelected.split('.')[0] + " of " + angular.fromJson(indicator).title;
				queryService.queryObject.MapTool.title = "Map of " + scriptSelected.split('.')[0] + " of " + angular.fromJson(indicator).title;
				queryService.queryObject.ScatterPlotTool.title = "Scatter Plot of " + scriptSelected.split('.')[0] + " of " + angular.fromJson(indicator).title;

			}
			
			$scope.$watch(function() {
				return queryService.dataObject.scriptMetadata;
			}, function(newValue, oldValue) {
				if(newValue) {
					scriptMetadata = newValue;
					if(indicator && scriptMetadata) {
						for(var i in queryService.dataObject.scriptMetadata.inputs) {
							var metadata = queryService.dataObject.scriptMetadata.inputs[i];
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

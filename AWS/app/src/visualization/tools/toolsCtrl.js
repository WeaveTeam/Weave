AnalysisModule.controller("toolsCtrl", function($scope, $filter,queryService, WeaveService, AnalysisService){
	
	$scope.queryService = queryService;
	$scope.WeaveService = WeaveService;
	$scope.AnalysisService = AnalysisService;
	
	
	$scope.tool_options = ["Map Tool", "BarChart Tool", "ScatterPlot Tool", "DataTable"];

	$scope.fixed_ids = ["MapTool", "BarChartTool", "ScatterPlotTool", "DataTableTool", "key_Column", "color_Column"];
	
	$scope.addTool = function(name) {
		switch(name) {
			case "Map Tool":
				var toolName = WeaveService.MapTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'Map Tool',
					template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html'
				};
				break;
			case "BarChart Tool":
				var toolName = WeaveService.BarChartTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'Bar Chart Tool',
					template_url : 'src/visualization/tools/barChart/bar_chart.tpl.html'
				};
				break;
			case "ScatterPlot Tool":
				var toolName = WeaveService.ScatterPlotTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'ScatterPlot Tool',
					template_url : 'src/visualization/tools/scatterPlot/scatter_plot.tpl.html'
				};
				break;
			case "DataTable":
				var toolName = WeaveService.DataTableTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'DataTable Tool',
					template_url : 'src/visualization/tools/dataTable/data_table.tpl.html'
				};
				break;
		}
	};
	
	$scope.removeTool = function(toolId) {
		WeaveService.weave.path(toolId).remove();
		delete queryService.queryObject.visualizations[toolId];
	};
	
	//for displying all columns in a datatable
	$scope.getAllColumns = function(term, done) {
		var allColumns = queryService.cache.columns;
		done($filter('filter')(allColumns, term));
	};

	//displaying results of a computation
	$scope.resultColumns = function(term, done) {
		var values = WeaveService.resultSet;
		done($filter('filter')(values, {name:term}, 'name'));
	};
});
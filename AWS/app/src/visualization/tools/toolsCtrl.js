AnalysisModule.controller("toolsCtrl", function($scope, $filter,queryService, WeaveService, AnalysisService){
	
	$scope.queryService = queryService;
	$scope.WeaveService = WeaveService;
	$scope.AnalysisService = AnalysisService;
	
	
	$scope.tool_options = ["MapTool", "BarChartTool", "ScatterPlotTool", "DataTable"];

	$scope.fixed_ids = ["MapTool", "BarChartTool", "ScatterPlotTool", "DataTableTool", "KeyColumn", "ColorColumn", "AttributeMenuTool"];
	
	$scope.addTool = function(name) {
		switch(name) {
			case "MapTool":
				var toolName = WeaveService.MapTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'MapTool',
					template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html'
				};
				break;
			case "BarChartTool":
				var toolName = WeaveService.BarChartTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'BarChartTool',
					template_url : 'src/visualization/tools/barChart/bar_chart.tpl.html'
				};
				break;
			case "ScatterPlotTool":
				var toolName = WeaveService.ScatterPlotTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'ScatterPlot Tool',
					template_url : 'src/visualization/tools/scatterPlot/scatter_plot.tpl.html'
				};
				break;
			case "DataTableTool":
				var toolName = WeaveService.DataTableTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'DataTable Tool',
					template_url : 'src/visualization/tools/dataTable/data_table.tpl.html'
				};
				break;
			case "AttributeMenuTool":
				var toolName = WeaveService.AttributeMenuTool(null, "");
				queryService.queryObject.visualizations[toolName] = {
					title : 'AttributeMenu Tool',
					template_url : 'src/visualization/tools/attributeMenu/attribute_Menu.tpl.html'
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
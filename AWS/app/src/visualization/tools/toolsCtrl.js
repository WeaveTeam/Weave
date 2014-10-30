AnalysisModule.controller("toolsCtrl", function($scope, queryService, WeaveService){
	
	$scope.queryService = queryService;
	$scope.WeaveService = WeaveService;
	
//	$scope.tool_list = [
//		         	{
//		        		id : 'BarChartTool',
//		        		title : 'Bar Chart Tool',
//		        		template_url : 'src/visualization/tools/barChart/bar_chart.tpl.html'
//
//		        	}, {
//		        		id : 'MapTool',
//		        		title : 'Map Tool',
//		        		template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html'
//		        	}, {
//		        		id : 'DataTableTool',
//		        		title : 'Data Table Tool',
//		        		template_url : 'src/visualization/tools/dataTable/data_table.tpl.html',
//		        		description : 'Display a Data Table in Weave'
//		        	}, {
//		        		id : 'ScatterPlotTool',
//		        		title : 'Scatter Plot Tool',
//		        		template_url : 'src/visualization/tools/scatterPlot/scatter_plot.tpl.html',
//		        		description : 'Display a Scatter Plot in Weave'
//		        	},
//		        	];
});
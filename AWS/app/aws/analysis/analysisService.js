/*
 *
 * Analysis Service which handle all data services for the analysis tab
 *
 */

angular.module('aws.analysisService', [])
.service('dasboard_widget_service', ['$filter', 'queryService', 
function($filter, queryService) {

	var content_tools = [{
		id : 'Indicator',
		title : 'Indicator',
		template_url : 'aws/analysis/indicator/indicator.tpl.html',
		description : 'Choose an Indicator for the Analysis',
		category : 'indicatorfilter'
	},
	{
		id : 'GeographyFilter',
		title : 'Geography Filter',
		template_url : 'aws/analysis/data_filters/geography.tpl.html',
		description : 'Filter data by States and Counties',
		category : 'datafilter'

	},
	{
		id : 'TimePeriodFilter',
		title : 'Time Period Filter',
		template_url : 'aws/analysis/data_filters/time_period.tpl.html',
		description : 'Filter data by Time Period',
		category : 'datafilter'
	},
	{
		id : 'ByVariableFilter',
		title : 'By Variable Filter',
		template_url : 'aws/analysis/data_filters/by_variable.tpl.html',
		description : 'Filter data by Variables',
		category : 'datafilter'
	}
	/*{
		id : 'Visualization',
		title : 'Configure Visulas',
		template_url : 'aws/analysis/visualization.tpl.html',
		description : 'Configure output chart for Weave',
		category : 'visualization'
	}*/];
	
	
	var tool_list = [
	{
		id : 'BarChartTool',
		title : 'Bar Chart Tool',
		template_url : 'aws/visualization/tools/barChart/bar_chart.tpl.html',
		description : 'Display Bar Chart in Weave',
		category : 'visualization'

	}, {
		id : 'MapTool',
		title : 'Map Tool',
		template_url : 'aws/visualization/tools/mapChart/map_chart.tpl.html',
		description : 'Display Map in Weave',
		category : 'visualization'
	}, {
		id : 'DataTableTool',
		title : 'Data Table Tool',
		template_url : 'aws/visualization/tools/dataTable/data_table.tpl.html',
		description : 'Display a Data Table in Weave',
		category : 'visualization'
	}, {
		id : 'ScatterPlotTool',
		title : 'Scatter Plot Tool',
		template_url : 'aws/visualization/tools/scatterPlot/scatter_plot.tpl.html',
		description : 'Display a Scatter Plot in Weave',
		category : 'visualization'
	}];

	/*Model to hold the widgets that are being displayed in dashboard*/
	var widget_bricks = [];

	this.get_filter_widget_bricks = function(){
		
		return content_tools
	}
	
	this.get_widget_bricks = function() {

		return widget_bricks;
	};

	this.add_widget_bricks = function(element_id) {

		var widget_id = element_id;
		var widget_brick_found = $filter('filter')(widget_bricks, {
			id : widget_id
		})
		if (widget_brick_found.length == 0) {
			var tool = $filter('filter')(tool_list, {
				id : widget_id
			});
			widget_bricks.splice(widget_bricks.length, 0, tool[0]);
		} else {
			//TODO: Hightlight the div if already added to dashboard. Use ScrollSpy
		}
	};

	this.remove_widget_bricks = function(widget_index) {

		widget_bricks.splice(widget_index, 1);

	};

	this.get_tool_list = function(category) {

			return $filter('filter')(tool_list, {
				category : category
			});

	};
	
	this.enable_widget = function(tool_id, enabled){
		queryService.queryObject[tool_id].enabled =  enabled;
	};
}]);


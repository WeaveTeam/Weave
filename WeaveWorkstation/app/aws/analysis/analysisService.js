/*
 *
 * Analysis Service which handle all data services for the analysis tab
 *
 */

angular.module('aws.analysisService', [])
.service('dasboard_widget_service', ['$filter', 'queryService', 
function($filter, queryService) {

	var tool_list = [{
		id : 'IndicatorFilter',
		title : 'Indicator',
		template_url : 'aws/visualization/indicator/indicator.tpl.html',
		description : 'Choose an indicator',
		note: 'The global indicator for this analysis',
		category : 'indicatorfilter'
	},
	{
		id : 'GeographyFilter',
		title : 'Geography Filter',
		template_url : 'aws/visualization/data_filters/geography.tpl.html',
		description : 'Filter data by States and Counties',
		category : 'datafilter'

	},
	{
		id : 'TimePeriodFilter',
		title : 'Time Period Filter',
		template_url : 'aws/visualization/data_filters/time_period.tpl.html',
<<<<<<< HEAD
		description : 'Filter data by time',
		note: 'Choose the year and month columns in the database',
=======
		description : 'Filter data based on time period',
>>>>>>> FETCH_HEAD
		category : 'datafilter'
	},
	{
		id : 'ByVariableFilter',
		title : 'By Variable Filter',
		template_url : 'aws/visualization/data_filters/by_variable.tpl.html',
<<<<<<< HEAD
		description : 'Filter data based on variables',
=======
		description : 'Filter data based on Variables',
>>>>>>> FETCH_HEAD
		category : 'datafilter'
	},
	{
		id : 'BarChartTool',
		title : 'Bar Chart Tool',
		template_url : 'aws/visualization/tools/barChart/bar_chart.tpl.html',
		description : 'Display a Bar Chart in Weave',
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
		if (tool_id == 'IndicatorFilter')
		{
			
		}
		else if (tool_id == 'GeographyFilter')
		{
			
		}
		else if (tool_id == 'TimePeriodFilter')
		{
			//queryService.queryObject.BarChartTool.enabled = enabled;
		}
		else if (tool_id == 'ByVariableFilter')
		{
			//queryService.queryObject.BarChartTool.enabled = enabled;
		}
		else if (tool_id == 'BarChartTool')
		{
			queryService.queryObject.BarChartTool.enabled = enabled;
		}
		else if (tool_id == 'MapTool')
		{
			queryService.queryObject.MapTool.enabled = enabled;
		}
		else if (tool_id == 'DataTableTool')
		{
			queryService.queryObject.DataTableTool.enabled = enabled;
		}
		else if (tool_id == 'ScatterPlotTool')
		{
			queryService.queryObject.ScatterPlotTool.enabled = enabled;
		};
		
	};
}]);


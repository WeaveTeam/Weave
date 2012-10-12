package weave.visualization.tools
{
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableHashMap;
	import weave.visualization.layers.SimpleInteractiveVisualization;

	public class SimpleVisTool implements ILinkableObject
	{
		public function SimpleVisTool()
		{
			//trace(debugId(this));
		}
		hack_init();
		private static function hack_init():void
		{
			var oldToolNames:Array = [
				'BarChartLegendTool',
				'ColorBinLegendTool',
				'ColormapHistogramTool',
				'CompoundBarChartTool',
				'CompoundRadVizTool',
				'CustomTool',
				'GaugeTool',
				'GraphTool',
				'Histogram2DTool',
				'HistogramTool',
				'MapTool',
				'PieChartHistogramTool',
				'PieChartTool',
				'RadVizTool',
				'RamachandranPlotTool',
				'ScatterPlotTool',
				'SizeBinLegendTool',
				'SliderTool',
				'StickFigureGlyphTool',
				'ThermometerTool'
			];
			for each (var oldToolName:String in oldToolNames)
				LinkableHashMap.registerDeprecatedClassReplacement(
					'weave.visualization.tools::' + oldToolName,
					'weave.visualization.tools::SimpleVisTool'
				);
		}
		
		[Deprecated] public function set children(state:Array):void
		{
			var globals:ILinkableHashMap = WeaveAPI.globalHashMap;
			var siv:SimpleInteractiveVisualization = globals.requestObject(globals.getName(this), SimpleInteractiveVisualization, false);
			WeaveAPI.SessionManager.setSessionState(siv, state[0].sessionState);
		}
	}
}

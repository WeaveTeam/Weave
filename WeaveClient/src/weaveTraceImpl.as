package
{
	import weave.ui.Console;
	import weave.ui.ErrorLogPanel;

	public function weaveTraceImpl(...args):void
	{
		if (Internal.initialized)
		{
			var elp:ErrorLogPanel = ErrorLogPanel.getInstance();
			if (!elp.parent)
				ErrorLogPanel.openErrorLog();
			elp.console.consoleTrace.apply(null, args);
		}
		else
		{
			Internal.backlog.push(args);
		}
	}
}
import weave.api.WeaveAPI;

internal class Internal
{
	public static var initialized:Boolean = false;
	public static var backlog:Array = [];
	public static var startup:* = WeaveAPI.StageUtils.callLater(
		null,
		function():void
		{
			initialized = true;
			for each (var params:Array in backlog)
				weaveTraceImpl.apply(null, params);
			backlog = null;
		},
		null,
		WeaveAPI.TASK_PRIORITY_IMMEDIATE
	);
}
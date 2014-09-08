package
{
	import weave.ui.ErrorLogPanel;

	public function weaveTraceImpl(...args):void
	{
		if ($.initialized)
		{
			var elp:ErrorLogPanel = ErrorLogPanel.getInstance();
			if (!elp.parent)
				ErrorLogPanel.openErrorLog();
			elp.console.consoleTrace.apply(null, args);
		}
		else if ($.backlog)
		{
			$.backlog.push(args);
		}
		else
		{
			$.backlog = [args];
			// low priority because we can wait for log messages
			WeaveAPI.StageUtils.callLater(null, $.flush, null, WeaveAPI.TASK_PRIORITY_LOW);
		}
	}
}

internal class $
{
	public static var initialized:Boolean = false;
	public static var backlog:Array = null;
	public static function flush():void
	{
		initialized = true;
		for each (var params:Array in backlog)
			weaveTraceImpl.apply(null, params);
		backlog = null;
	}
}
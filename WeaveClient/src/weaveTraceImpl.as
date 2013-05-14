package
{
	import weave.ui.Console;
	import weave.ui.ErrorLogPanel;

	public function weaveTraceImpl(...args):void
	{
		var elp:ErrorLogPanel = ErrorLogPanel.getInstance();
		if (!elp.parent)
			ErrorLogPanel.openErrorLog();
		elp.console.consoleTrace.apply(null, args);
	}
}

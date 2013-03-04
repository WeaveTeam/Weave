package
{
	import weave.api.WeaveAPI;
	import weave.ui.Console;

	public function weaveTraceImpl(...args):void
	{
		if(WeaveAPI.topLevelApplication.console){
			(WeaveAPI.topLevelApplication.console as Console).consoleTrace.apply(null, args);
		}else{
			
			//log.push(args);
			WeaveAPI.StageUtils.callLater(this,weaveTraceImpl,args);
		}
		
	}
}




package
{
	import flash.utils.getQualifiedClassName;

	public function weaveTraceImpl(...args):void
	{
		MobileConsole.mobileTrace.apply(null, args);
	}
}

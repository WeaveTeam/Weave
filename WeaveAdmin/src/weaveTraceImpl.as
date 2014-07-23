package
{
	import flash.utils.getQualifiedClassName;
	
	import weave.services.WeaveAdminService;

	public function weaveTraceImpl(...args):void
	{
		trace.apply(null, args);
		WeaveAdminService.messageDisplay(null, args.join(' '), false);
	}
}

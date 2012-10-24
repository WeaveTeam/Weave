package
{
	import flash.utils.getQualifiedClassName;
	
	import weave.services.WeaveAdminService;

	public function weaveTraceImpl(...args):void
	{
		WeaveAdminService.messageDisplay(null, args.join('\n'), false);
	}
}

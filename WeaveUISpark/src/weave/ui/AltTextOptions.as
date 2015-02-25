package weave.ui
{
	import weave.api.core.ILinkableObject;
	import weave.api.registerLinkableChild;
	import weave.core.*;

	
	public class AltTextOptions implements ILinkableObject
	{
		public const shortDescription:LinkableString = registerLinkableChild(this, new LinkableString("Weave visualization")); 		
		public const altText:LinkableString = registerLinkableChild(this, new LinkableString());
		public const visTools:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array));
	}
	
}

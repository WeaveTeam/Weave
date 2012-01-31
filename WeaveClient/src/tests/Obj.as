package tests
{
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	
	public class Obj implements ILinkableObject
	{
		public function Obj()
		{
		}
		
		public const num:LinkableNumber = newLinkableChild(this, LinkableNumber);
		public const str:LinkableString = newLinkableChild(this, LinkableString);
		public const bool:LinkableBoolean = newLinkableChild(this, LinkableBoolean);
	}
}

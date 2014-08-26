package weave.services
{
	
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;

	
	public class OAuth2Client  implements ILinkableObject
	{
		
		public const authEndPoint:LinkableString = newLinkableChild(this,LinkableString);
		public const tokenEndPoint:LinkableString = newLinkableChild(this,LinkableString);
		public const tokenContentType:LinkableString = newLinkableChild(this, LinkableString);
		public const redirectURI:LinkableString = newLinkableChild(this,LinkableString);
		
		public const clientID:LinkableString = newLinkableChild(this,LinkableString);
		public const clientSecret:LinkableString = newLinkableChild(this,LinkableString);
		
		public const accessToken:LinkableString = newLinkableChild(this,LinkableString);
		public const tokenType:LinkableString = newLinkableChild(this,LinkableString);
		public const expiresIn:LinkableNumber = registerLinkableChild(this,new LinkableNumber(-1));
		public const refreshtoken:LinkableString = newLinkableChild(this,LinkableString);
		public const scope:LinkableString = newLinkableChild(this,LinkableString);
		public const state:LinkableString = newLinkableChild(this,LinkableString);
		public const accessParams:LinkableVariable = newLinkableChild(this,LinkableVariable);
		
		
		
		public function OAuth2Client()
		{
			super();
			
			
		}
		
				
		
		
	}
	
}

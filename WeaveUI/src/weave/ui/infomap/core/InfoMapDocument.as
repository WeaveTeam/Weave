package weave.ui.infomap.core
{
	import weave.api.core.ILinkableObject;
	import weave.api.newLinkableChild;
	import weave.core.CallbackCollection;
	import weave.core.LinkableString;

	/**
	 * This class represents a single document object in a infomap 
	 * and is uniquely defined by its link. 
	 * TODO: two document objects maybe considered equal if they have the same link
	 * 
	 * */
	public class InfoMapDocument implements IInfoMapDocument
	{
		public function InfoMapDocument()
		{
		}
		
		/**
		 * @public 
		 * The title of the document
		 **/ 
		public const title:LinkableString = newLinkableChild(this,LinkableString);
		/**
		 * @public 
		 * The date the document was published
		 **/ 
		public const date:LinkableString = newLinkableChild(this,LinkableString);
		/**
		 * @public 
		 * A brief summary/description of the document
		 **/ 
		public const summary:LinkableString = newLinkableChild(this,LinkableString);
		/**
		 * @public 
		 * The link to the document
		 **/ 
		public const url:LinkableString = newLinkableChild(this,LinkableString);
		/**
		 * @public 
		 * The link to an image of the document.
		 **/ 
		public const imageURL:LinkableString = newLinkableChild(this,LinkableString);
	}
}
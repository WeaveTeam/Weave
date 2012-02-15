package weave.ui.infomap.core
{
	import weave.api.core.ICallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;

	public class InfoMapNode implements IInfoMapNode
	{
		public function InfoMapNode()
		{
		}
		
		/**
		 * @public 
		 * The keywords is the query made when this node was requested
		 * */ 
		public const keywords:LinkableString = newLinkableChild(this,LinkableString);
		
		/**
		 * @public 
		 * Only two Operators are valid: AND,OR
		 * AND will search for documents containing all the keywords
		 * OR will search for documents containing any of the keywords
		 * */ 
		public const operator:LinkableString = registerLinkableChild(this,new LinkableString('AND',null,false));

		/**
		 * @public 
		 * This holds the value of the maximum number of documents that will be handled by the node
		 * */ 
		public const numberOfDocs:LinkableNumber = registerLinkableChild(this,new LinkableNumber(100,null,false));
		
		
		/**
		 * @public 
		 * This is a hashmap mapping a link to a thumbnail object. 
		 * This conatins all the thumbnails belonging to this node.
		 * */ 
		public const thumbnails:LinkableHashMap = newLinkableChild(this,LinkableHashMap);
		
		/**
		 * @public 
		 * This indicates whether the node is selected or not.
		 * */ 
		public const selected:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(false));
		
	}
}
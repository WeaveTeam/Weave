package weave.ui.infomap.core
{
	import weave.api.newLinkableChild;
	import weave.core.LinkableBoolean;

	/**
	 * This class extends the InfoMapDocument and has an addtional selected boolean variable.
	 * This is useful to keep track of all the documents currently selected.
	 * 
	 * */
	public class SelectableInfoMapDocument extends InfoMapDocument
	{
		public function SelectableInfoMapDocument()
		{
			
		}
		
		/**
		 * @public
		 * This variable will be set to true if the document is currently selected by the user
		 * 
		 * */
		public const selected:LinkableBoolean = newLinkableChild(this,LinkableBoolean);
		
		
	}
}
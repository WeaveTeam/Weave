package weave.api.ui
{
	
	/**
	 * An interface for disability alt text algorithms
	 * 
	 * @author fkamayou
	 * 
	 */
	public interface IAltText
	{
		/**
		 * Performs the algorithms to figure out the best text description of a vis.
		 * @return a textual description of the tool passed in as a parameter.
		 */		
		function getAltText():String;
	}
}
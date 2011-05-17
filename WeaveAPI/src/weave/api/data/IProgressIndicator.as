package weave.api.data
{
	import weave.api.core.ICallbackCollection;

	/**
	 * This interface is used as a central location for reporting the progress of pending asynchronous requests.
	 * 
	 * @author adufilie
	 */
	public interface IProgressIndicator
	{
		/**
		 * This is the number of pending requests.
		 */
		function getPendingRequestCount():int;

		/**
		 * This is the callback collection for the Progress Indicator.
		 */
		function getCallbackCollection():ICallbackCollection;
			
		/**
		 * This function will register a pending request token and increase the pendingRequestCount if necessary.
		 * 
		 * @param token The object whose progress to track.
		 */
		function addPendingRequest(token:Object):void;
		
		/**
		 * This function will report the current progress of a request.
		 * 
		 * @param token The object whose progress to track.
		 * @param percent The current progress of the token's request.
		 */
		function reportPendingRequestProgress(token:Object, percent:Number):void;

		/**
		 * This function will remove a previously registered pending request token and decrease the pendingRequestCount if necessary.
		 * 
		 * @param token The object to remove from the progress indicator.
		 */
		function removePendingRequest(token:Object):void;
		
		/**
		 * This function checks the overall progress of all pending requests.
		 *
		 * @return A Number between 0 and 1.
		 */
		function getNormalizedProgress():Number;
	}
}
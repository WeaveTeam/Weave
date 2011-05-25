package weave.utils
{
	import weave.core.CallbackCollection;

	public class RefinedSpatialIndex extends CallbackCollection
	{
		public function RefinedSpatialIndex(callback:Function = null, callbackParameters:Array = null)
		{
			addImmediateCallback(this, callback, callbackParameters);
		}
	}
}
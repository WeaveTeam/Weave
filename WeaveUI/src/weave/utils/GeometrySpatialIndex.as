package weave.utils
{
	import weave.core.CallbackCollection;

	public class GeometrySpatialIndex extends CallbackCollection
	{
		public function GeometrySpatialIndex(callback:Function = null, callbackParameters:Array = null)
		{
			addImmediateCallback(this, callback, callbackParameters);
		}
	}
}
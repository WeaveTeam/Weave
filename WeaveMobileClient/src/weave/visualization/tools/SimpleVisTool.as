package weave.visualization.tools
{
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.visualization.layers.SimpleInteractiveVisualization;

	public class SimpleVisTool implements ILinkableObject
	{
		public function SimpleVisTool()
		{
			trace(debugId(this));
		}
		
		[Deprecated] public function set visualization(state:Object):void
		{
			var globals:ILinkableHashMap = WeaveAPI.globalHashMap;
			var siv:SimpleInteractiveVisualization = globals.requestObject(globals.getName(this), SimpleInteractiveVisualization, false);
			WeaveAPI.SessionManager.setSessionState(siv, state);
		}
	}
}

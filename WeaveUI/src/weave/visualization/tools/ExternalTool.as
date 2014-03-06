package weave.visualization.tools
{
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.linkBindableProperty;
	import weave.api.registerLinkableChild;
	import weave.api.newLinkableChild;
	import weave.api.ui.IVisTool;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableDynamicObject;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableVariable;
	import weave.core.SessionManager;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.KeySets.FilteredKeySet;
	import weave.data.KeySets.KeyFilter;
	import weave.data.KeySets.KeySet;
	import flash.external.ExternalInterface;

	public class ExternalTool extends LinkableHashMap
	{
		private var toolUrl:LinkableString;
		private var toolPath:Array;

		public function ExternalTool()
		{
			toolUrl = requestObject("toolUrl", LinkableString, true);
			toolUrl.addGroupedCallback(this, toolPropertiesChanged);
		}
		private function toolPropertiesChanged():void
		{
			
			if (toolUrl.value != "")
			{
				launch();
			}
		}
		public function launch():void
		{
			if (toolPath == null)
				toolPath = WeaveAPI.SessionManager.getPath(WeaveAPI.globalHashMap, this);
			var windowFeatures:String = "menubar=no,status=no,toolbar=no";
			ExternalInterface.call(
				"function (weaveID, toolPath, url, features) {\
				 var weave = weaveID ? document.getElementById(weaveID) : document;\
				 var windowName = JSON.stringify(toolPath);\
				 if (weave.external_tools == undefined) weave.external_tools = {};\
				 weave.external_tools[windowName] = window.open(url, windowName, features);\
				 weave.external_tools[windowName].toolPath = toolPath;\
				 weave.external_tools[windowName].weave = weave;\
				}", ExternalInterface.objectID, toolPath, toolUrl.value, windowFeatures);
		}
		override public function dispose():void
		{
			super.dispose();
			ExternalInterface.call(
				"function (weaveID, toolPath) {\
				 var weave = weaveID ? document.getElementById(weaveID) : document;\
				 var windowName = JSON.stringify(toolPath);\
				 if (weave.external_tools[toolname]) weave.external_tools[toolname].close();\
				}", ExternalInterface.objectID, toolPath);
		}
	}
}
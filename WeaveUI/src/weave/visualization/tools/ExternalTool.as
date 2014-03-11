/*
	Weave (Web-based Analysis and Visualization Environment)
	Copyright (C) 2008-2011 University of Massachusetts Lowell
	
	This file is a part of Weave.
	
	Weave is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License, Version 3,
	as published by the Free Software Foundation.
	
	Weave is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/
package weave.visualization.tools
{
	import weave.api.WeaveAPI;
	import weave.compiler.Compiler;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;

	public class ExternalTool extends LinkableHashMap
	{
		private var toolUrl:LinkableString;
		private var toolPath:Array;
		private var windowName:String;

		public function ExternalTool()
		{
			toolUrl = requestObject("toolUrl", LinkableString, true);
			toolUrl.addImmediateCallback(this, toolPropertiesChanged);
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
			{
				toolPath = WeaveAPI.SessionManager.getPath(WeaveAPI.globalHashMap, this);
				windowName = Compiler.stringify(toolPath);
			}
			WeaveAPI.executeJavaScript(
				{
					windowName: windowName,
					toolPath: toolPath,
					url: toolUrl.value,
					features: "menubar=no,status=no,toolbar=no"
				},
				"if (!weave.external_tools) weave.external_tools = {};",
				"weave.external_tools[windowName] = window.open(url, windowName, features);",
				"console.log(toolPath);",
				"weave.external_tools[windowName].toolPath = toolPath;",
				"weave.external_tools[windowName].weave = weave;"
			);
		}
		override public function dispose():void
		{
			super.dispose();
			WeaveAPI.executeJavaScript(
				{windowName: windowName},
				"if (weave.external_tools && weave.external_tools[windowName])\
					weave.external_tools[windowName].close();"
			);
		}
	}
}
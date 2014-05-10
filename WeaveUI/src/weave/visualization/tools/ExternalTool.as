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
	import weave.api.data.IAttributeColumn;
	import weave.api.ui.IVisToolWithSelectableAttributes;
	import weave.compiler.Compiler;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.utils.EventUtils;

	public class ExternalTool extends LinkableHashMap implements IVisToolWithSelectableAttributes 
	{
		private var toolUrl:LinkableString;
		private var toolPath:Array;
		private var windowName:String;

		public function ExternalTool()
		{
			toolUrl = requestObject("toolUrl", LinkableString, true);
			toolUrl.addImmediateCallback(this, EventUtils.generateDelayedCallback(this, toolPropertiesChanged, 0));
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
			if (toolPath == null || windowName == null)
			{
				toolPath = WeaveAPI.SessionManager.getPath(WeaveAPI.globalHashMap, this);
				toolPath.unshift(JavaScript.objectID);
				windowName = Compiler.stringify(toolPath);
			}
			JavaScript.exec(
				{
					windowName: windowName,
					toolPath: toolPath,
					url: toolUrl.value,
					features: "menubar=no,status=no,toolbar=no"
				},
				"if (!this.external_tools) this.external_tools = {};",
				"this.external_tools[windowName] = window.open(url, windowName, features);"
			);
		}
		override public function dispose():void
		{
			super.dispose();
			JavaScript.exec(
				{windowName: windowName},
				"if (this.external_tools && this.external_tools[windowName]) this.external_tools[windowName].close();"
			);
		}
		/**
		 * @return An Array of names corresponding to the objects returned by getSelectableAttributes().
		 */
		public function getSelectableAttributeNames():Array
		{
			return getNames(IAttributeColumn);
		}

		/**
		 * @return An Array of DynamicColumn and/or ILinkableHashMap objects that an AttributeSelectorPanel can link to.
		 */
		public function getSelectableAttributes():Array
		{
			return getObjects(IAttributeColumn);
		}
	}
}
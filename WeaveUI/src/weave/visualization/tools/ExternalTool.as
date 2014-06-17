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

	public class ExternalTool extends LinkableHashMap implements IVisToolWithSelectableAttributes 
	{
		private static const EXTERNAL_TOOLS:String = 'external_tools';
		
		/**
		 * URL for external tool
		 */
		private var toolUrl:LinkableString;
		
		/**
		 * Parameters passed to external window via windowName
		 */
		private var config:ExternalConfig;
		
		/**
		 * Stringified config
		 */
		private var windowName:String;

		public function ExternalTool()
		{
			super();
			
			toolUrl = requestObject("toolUrl", LinkableString, true);
			toolUrl.addGroupedCallback(this, toolPropertiesChanged);
		}
		
		private function toolPropertiesChanged():void
		{
			if (!config)
			{
				config = new ExternalConfig();
				config.id = JavaScript.objectID;
				config.path = WeaveAPI.SessionManager.getPath(WeaveAPI.globalHashMap, this);
				
				windowName = Compiler.stringify(config);
			}
			
			if (toolUrl.value)
			{
				launch();
			}
		}
		
		public function launch():void
		{
			JavaScript.exec(
				{
					EXTERNAL_TOOLS: EXTERNAL_TOOLS,
					windowName: windowName,
					url: toolUrl.value,
					features: "menubar=no,status=no,toolbar=no"
				},
				"if (!this[EXTERNAL_TOOLS])",
				"    this[EXTERNAL_TOOLS] = {};",
				"this[EXTERNAL_TOOLS][windowName] = window.open(url, windowName, features);"
			);
		}
		
		override public function dispose():void
		{
			super.dispose();
			JavaScript.exec(
				{
					EXTERNAL_TOOLS: EXTERNAL_TOOLS,
					windowName: windowName
				},
				"if (this[EXTERNAL_TOOLS] && this[EXTERNAL_TOOLS][windowName])",
				"    this[EXTERNAL_TOOLS][windowName].close();"
			);
		}
		
		/**
		 * @inheritDoc
		 */
		public function getSelectableAttributeNames():Array
		{
			return getNames(IAttributeColumn);
		}

		/**
		 * @inheritDoc
		 */
		public function getSelectableAttributes():Array
		{
			return getObjects(IAttributeColumn);
		}
	}
}

internal class ExternalConfig
{
	public var id:String;
	public var path:Array;
}

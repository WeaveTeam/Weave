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
	import mx.utils.UIDUtil;
	
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.reportError;
	import weave.api.ui.IObjectWithSelectableAttributes;
	import weave.compiler.StandardLib;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;

	public class ExternalTool extends LinkableHashMap implements IObjectWithSelectableAttributes
	{
		/**
		 * The name of the global JavaScript variable which is a mapping from a popup's
		 * window.name to an object containing "path" and "window" properties.
		 */
		public static const WEAVE_EXTERNAL_TOOLS:String = 'WeaveExternalTools';
		
		/**
		 * URL for external tool
		 */
		private var toolUrl:LinkableString;
		
		/**
		 * The popup's window.name
		 */
		public const windowName:String = StandardLib.replace(UIDUtil.createUID(), '-', '');
		
		public function ExternalTool()
		{
			super();
			
			toolUrl = requestObject("toolUrl", LinkableString, true);
			toolUrl.addGroupedCallback(this, toolPropertiesChanged);
		}
		
		private function toolPropertiesChanged():void
		{
			if (toolUrl.value)
			{
				launch();
			}
		}
		
		public function launch():Boolean
		{
			var success:Boolean = JavaScript.exec(
				{
					WEAVE_EXTERNAL_TOOLS: WEAVE_EXTERNAL_TOOLS,
					"url": toolUrl.value,
					"windowName": windowName,
					"features": "menubar=no,status=no,toolbar=no",
					"path": WeaveAPI.SessionManager.getPath(WeaveAPI.globalHashMap, this)
				},
				'if (!window[WEAVE_EXTERNAL_TOOLS]) {',
				'    window[WEAVE_EXTERNAL_TOOLS] = {};',
				'    // when we close this window, close all popups',
				'    if (window.addEventListener)',
				'        window.addEventListener("unload", function(){',
				'            for (var key in window[WEAVE_EXTERNAL_TOOLS])',
				'                try { window[WEAVE_EXTERNAL_TOOLS][key].window.close(); } catch (e) { }',
				'        });',
				'}',
				'var popup = window.open(url, windowName, features);',
				'window[WEAVE_EXTERNAL_TOOLS][windowName] = {"path": this.path(path), "window": popup};',
				'return !!popup;'
			);
			
			if (!success)
				reportError("External tool popup was blocked by the web browser.");
			
			return success;
		}
		
		override public function dispose():void
		{
			super.dispose();
			JavaScript.exec(
				{
					WEAVE_EXTERNAL_TOOLS: WEAVE_EXTERNAL_TOOLS,
					"windowName": windowName,
					"catch": ignoreError
				},
				'window[WEAVE_EXTERNAL_TOOLS][windowName].window.close();',
				'delete window[WEAVE_EXTERNAL_TOOLS][windowName];'
			);
		}
		
		private function ignoreError(error:*):void { }
		
		/**
		 * @inheritDoc
		 */
		public function getSelectableAttributeNames():Array
		{
			return getObjects(IAttributeColumn).map(getLabel);
		}
		
		private function getLabel(obj:ILinkableObject, i:int, a:Array):String
		{
			return WeaveAPI.EditorManager.getLabel(obj);
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

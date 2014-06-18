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
	import com.hurlant.crypto.hash.MD5;
	
	import mx.utils.Base64Encoder;
	import mx.utils.UIDUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IAttributeColumn;
	import weave.api.reportError;
	import weave.api.ui.IObjectWithSelectableAttributes;
	import weave.compiler.Compiler;
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
		public function get windowName():String
		{
			var object:Object = {
				id: JavaScript.objectID,
				path: path
			};
			
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encode(Compiler.stringify(object));
			return StandardLib.replace(encoder.drain(), '+', '_p', '/', '_s', '=', '_e');
		}
		
		public function get path():Array
		{
			return WeaveAPI.SessionManager.getPath(WeaveAPI.globalHashMap, this);
		}
		
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
					"path": path
				},
				'if (!window[WEAVE_EXTERNAL_TOOLS])',
				'    window[WEAVE_EXTERNAL_TOOLS] = {};',
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
				'window[WEAVE_EXTERNAL_TOOLS][windowName].window.close();'
			);
		}
		
		private function ignoreError(error:*):void { }
		
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

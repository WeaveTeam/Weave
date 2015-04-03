/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.visualization.tools
{
	import mx.utils.UIDUtil;
	
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.getLinkableDescendants;
	import weave.api.reportError;
	import weave.api.ui.ISelectableAttributes;
	import weave.compiler.StandardLib;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;

	public class ExternalTool extends LinkableHashMap implements ISelectableAttributes
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
			try
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
			}
			catch (e:Error)
			{
				reportError(e);
			}
			
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
			return getSelectableAttributes().map(getLabel);
		}
		
		private function getLabel(obj:ILinkableObject, i:int, a:Array):String
		{
			var label:String = WeaveAPI.EditorManager.getLabel(obj);
			if (!label)
			{
				var path:Array = WeaveAPI.SessionManager.getPath(this, obj);
				if (path)
					label = path.join('/');
			}
			return label;
		}

		/**
		 * @inheritDoc
		 */
		public function getSelectableAttributes():Array
		{
			var hashMaps:Array = [this].concat(getLinkableDescendants(this, ILinkableHashMap));
			var flatList:Array = [].concat.apply(null, hashMaps.map(function(hm:ILinkableHashMap, i:*, a:*):* { return hm.getObjects(IAttributeColumn); }));
			return flatList.filter(function(item:ILinkableObject, i:*, a:*):Boolean { return getLabel(item, i, a) && true; });
			
			//return getObjects(IAttributeColumn);
		}
	}
}

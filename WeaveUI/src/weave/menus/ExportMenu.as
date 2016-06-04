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

package weave.menus
{
	import weave.Weave;
	import weave.compiler.Compiler;
	import weave.core.LinkableCallbackScript;
	import weave.core.LinkableFunction;
	import weave.visualization.tools.ExternalTool;

	public class ExportMenu extends WeaveMenuItem
	{
		public function ExportMenu()
		{
			super({
				shown: function():Boolean { return ExportMenu.shown; },
				label: lang("Weave 2.x"),
				children: [
					{
						label: lang("Export to HTML5"),
						click: export
					}
				]
			});
		}
		
		private static const windowName:String = ExternalTool.generateWindowName();
		
		public static function get shown():Boolean
		{
			// todo - test if weavejs is available
			return true;
		}
		
		private static function jsVars(catchErrors:Boolean):Object
		{
			return {
				WEAVE_EXTERNAL_TOOLS: ExternalTool.WEAVE_EXTERNAL_TOOLS,
				'windowName': windowName,
				'catch': catchErrors && function():*{}
			};
		}
		
		public static function get exported():Boolean
		{
			return JavaScript.exec(
				jsVars(true),
				'var obj = window[WEAVE_EXTERNAL_TOOLS][windowName];',
				'return !!obj.window.weave;'
			);
		}
		
		public static var url:String = "/weavejs/";
		
		public static function export():void
		{
			ExternalTool.launch(WeaveAPI.globalHashMap, url, windowName);
		}
		
		public static function disableScripts(exportUrl:String = null):void
		{
			LinkableFunction.enabled = false;
			LinkableCallbackScript.enabled = false;
			
			if (exportUrl)
				ExportMenu.url = exportUrl;
			else
				exportUrl = ExportMenu.url;
			
			var names:Array = WeaveAPI.globalHashMap.getNames();
			var lcs:LinkableCallbackScript = WeaveAPI.globalHashMap.requestObject("_disableFlashScripts", LinkableCallbackScript, false);
			//  put new script first
			WeaveAPI.globalHashMap.setNameOrder(names);
			lcs.groupedCallback.value = false;
			lcs.script.value = "if (typeof ExportMenu != 'undefined') {\n" +
				"\tExportMenu.disableScripts(" + Compiler.stringify(exportUrl) + ");\n" +
				"\tExportMenu.export();\n" +
				"\tSessionStateEditor.openDefaultEditor();\n" +
				"}";
		}
		
		/*
		public static function flush():void
		{
			if (!exported)
			{
				export();
				return;
			}
			JavaScript.exec(
				jsVars(false),
				<![CDATA[
					var obj = window[WEAVE_EXTERNAL_TOOLS][windowName];
					var content = atob(obj.path.getValue('btoa(Weave.createWeaveFileContent())'));
					obj.window.weavejs.core.WeaveArchive.loadFileContent(obj.window.weave, content);
				]]>
			);
		}
		*/
	}
}

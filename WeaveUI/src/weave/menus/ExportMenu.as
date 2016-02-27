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
	import flash.events.Event;
	import flash.net.FileReference;
	import flash.system.Capabilities;
	
	import mx.controls.Alert;
	
	import weave.Weave;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.linkableObjectIsBusy;
	import weave.api.reportError;
	import weave.api.data.IDataSource;
	import weave.api.data.IDataSource_File;
	import weave.api.ui.ISelectableAttributes;
	import weave.data.AttributeColumnCache;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.DataSources.CachedDataSource;
	import weave.data.KeySets.KeySet;
	import weave.ui.ExportSessionStateOptions;
	import weave.utils.ColumnUtils;
	import weave.utils.HierarchyUtils;
	import weave.utils.PopUpUtils;
	import weave.visualization.tools.ExternalTool;

	public class ExportMenu extends WeaveMenuItem
	{
		public function ExportMenu()
		{
			super({
				shown: function():Boolean {
					return Weave.properties.version.value == 'Custom';
				},
				label: lang("Weave 2.0"),
				children: [
					{
						label: lang("Export to HTML5"),
						click: function():void {
							var url:String = '/weave-html5/';
							ExternalTool.launch(WeaveAPI.globalHashMap, url, lastHtml5WindowName = ExternalTool.generateWindowName());
						}
					},
					{
						enabled: function():Boolean {
							return JavaScript.exec(
								{
									WEAVE_EXTERNAL_TOOLS: ExternalTool.WEAVE_EXTERNAL_TOOLS,
									'windowName': lastHtml5WindowName,
									'catch': function():*{}
								},
								'return !!window[WEAVE_EXTERNAL_TOOLS][windowName].window.weave;'
							);
						},
						label: lang("Copy layout from HTML5"),
						click: function():void {
							JavaScript.exec(
								{
									WEAVE_EXTERNAL_TOOLS: ExternalTool.WEAVE_EXTERNAL_TOOLS,
									'windowName': lastHtml5WindowName,
									'catch': false
								},
								'var obj = window[WEAVE_EXTERNAL_TOOLS][windowName];',
								'this.path("Layout").request("FlexibleLayout").state(obj.window.weave.path("Layout").getState())'
							);
						}
					}
				]
			});
		}
		
		private var lastHtml5WindowName:String;
	}
}

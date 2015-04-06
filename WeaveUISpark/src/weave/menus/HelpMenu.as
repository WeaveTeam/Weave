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
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import weave.Weave;
	import weave.compiler.StandardLib;

	public class HelpMenu extends WeaveMenuItem
	{
		private function go_to_url(item:WeaveMenuItem):void
		{
			navigateToURL(new URLRequest(item.data as String), "_blank");
		}
		private static const VERSION:String = 'version';
		
		public function HelpMenu()
		{
			super({
				shown: Weave.properties.enableAboutMenu,
				label: lang("Help"),
				children: [
					{
						label: lang("Report a problem"),
						click: go_to_url,
						data: "http://info.oicweave.org/projects/weave/issues/new"
					},{
						label: lang("Visit {0}", "OICWeave.org"),
						click: go_to_url,
						data: "http://www.oicweave.org"
					},{
						label: lang("Visit Weave Wiki"),
						click: go_to_url,
						data: "http://info.oicweave.org/projects/weave/wiki"
					},
					TYPE_SEPARATOR,
					{
						label: function():String {
							var version:String = Weave.properties.version.value;
							var app:Object = WeaveAPI.topLevelApplication;
							if (app && app.hasOwnProperty(VERSION))
								version = StandardLib.substitute("{0} ({1})", version, app[VERSION]);
							return lang("Weave version: {0}", version);
						},
						enabled: false
					}
				]
			});
		}
	}
}

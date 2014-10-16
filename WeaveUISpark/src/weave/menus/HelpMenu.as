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

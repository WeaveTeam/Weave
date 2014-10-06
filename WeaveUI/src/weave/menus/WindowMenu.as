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
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	
	import mx.controls.Alert;
	
	import weave.Weave;
	import weave.api.detectLinkableObjectChange;
	import weave.editors.WeavePropertiesEditor;
	import weave.ui.DraggablePanel;

	public class WindowMenu extends WeaveMenuItem
	{
		private static const notDash:Object = {not: Weave.properties.dashboardMode};
		
		private static function getAllPanels():Array
		{
			return WeaveAPI.globalHashMap.getObjects(DraggablePanel);
		}
		
		private static function panelMenuItem_label(menu:WeaveMenuItem):String
		{
			var panel:DraggablePanel = menu.data as DraggablePanel;
			var menuLabel:String = '';
			if (panel.title && panel.title.replace(" ", "").length > 0) 
				menuLabel = panel.title;
			else
				menuLabel = lang("Untitled Window");
			
			if (panel.minimized.value)
				menuLabel = ">\t" + menuLabel;
			
			return menuLabel;
		}
		
		private static function panelMenuItem_click(menu:WeaveMenuItem):void
		{
			(menu.data as DraggablePanel).restorePanel()
		}
		
		private static function panelMenuItem_toggled(menu:WeaveMenuItem):Boolean
		{
			return menu.data == DraggablePanel.getTopPanel();
		}
		
		private static function get stage():Stage
		{
			return WeaveAPI.StageUtils.stage;
		}
		
		public static const staticItems:Array = createItems([
			{
				shown: {or: [SessionMenu.fn_adminMode, Weave.properties.enableUserPreferences]},
				label: lang("Preferences"),
				click: function():void { DraggablePanel.openStaticInstance(WeavePropertiesEditor); }
			},
			TYPE_SEPARATOR,
			{
				label: function():String {
					var dash:Boolean = Weave.properties.dashboardMode.value;
					return lang((dash ? "Disable" : "Enable") + " dashboard mode");
				},
				click: Weave.properties.dashboardMode
			},
			TYPE_SEPARATOR,
			{
				shown: Weave.properties.showDisabilityOptions,
				label: lang("Disability Options"),
				click: function():void { DraggablePanel.openStaticInstance(DisabilityOptions); }
			},
			TYPE_SEPARATOR,
			{
				shown: Weave.properties.enableFullScreen,
				label: function():String
				{
					if (stage && stage.displayState == StageDisplayState.FULL_SCREEN) 
						return lang('Exit Full-screen mode'); 
					
					return lang('Enter Full-screen mode');
				},
				click: function():void
				{
					if (stage && stage.displayState == StageDisplayState.NORMAL )
					{
						try
						{
							// set full screen display
							stage.displayState = StageDisplayState.FULL_SCREEN;
						}
						catch (e:Error)
						{
							Alert.show(lang("This website has not enabled full-screen mode, so this option will now be disabled."), lang("Full-screen mode not allowed"));
							Weave.properties.enableFullScreen.value = false;
						}
					}
					else if (stage)
					{
						// set normal display
						stage.displayState = StageDisplayState.NORMAL;
					}
				}
			},
			TYPE_SEPARATOR,
			{
				shown: [notDash, Weave.properties.enableTileAllWindows],
				label: lang("Tile all windows"),
				click: DraggablePanel.tileWindows,
				enabled: function():Boolean { return getAllPanels().length > 0; }
			},{
				shown: [notDash, Weave.properties.enableCascadeAllWindows],
				label: lang("Cascade all windows"),
				click: DraggablePanel.cascadeWindows,
				enabled: function():Boolean { return getAllPanels().length > 0; }
			},
			TYPE_SEPARATOR,
			{
				shown: [notDash, Weave.properties.enableMinimizeAllWindows],
				label: lang("Minimize all windows"),
				click: function():void {
					for each (var panel:DraggablePanel in getAllPanels())
						if (panel.minimizable.value && !panel.minimized.value)
							panel.minimizePanel();
				},
				enabled: function():Boolean {
					for each (var panel:DraggablePanel in getAllPanels())
						if (panel.minimizable.value && !panel.minimized.value)
							return true;
					return false;
				}
			},{
				shown: [notDash, Weave.properties.enableRestoreAllMinimizedWindows],
				label: lang("Restore all minimized windows"),
				click: function():void {
					for each (var panel:DraggablePanel in getAllPanels())
						if (panel.minimized.value)
							panel.restorePanel();
				},
				enabled: function():Boolean {
					for each (var panel:DraggablePanel in getAllPanels())
						if (panel.minimized.value)
							return true;
					return false;
				}
			},{
				shown: [notDash, Weave.properties.enableCloseAllWindows],
				label: lang("Close all windows"),
				click: function():void {
					for each (var panel:DraggablePanel in getAllPanels())
						if (panel.closeable.value)
							panel.removePanel();
				},
				enabled: function():Boolean {
					for each (var panel:DraggablePanel in getAllPanels())
						if (panel.closeable.value)
							return true;
					return false;
				}
			}
		]);
		
		public static function get dynamicItems():Array
		{
			return createItems(
				getAllPanels().map(
					function(panel:DraggablePanel, ..._):* {
						return {
							shown: {not: Weave.properties.dashboardMode},
							type: TYPE_RADIO,
							groupName: "activeWindows",
							label: panelMenuItem_label,
							click: panelMenuItem_click,
							toggled: panelMenuItem_toggled,
							data: panel
						};
					}
				)
			);
		}
		
		public function WindowMenu()
		{
			super({
				source: WeaveAPI.globalHashMap.childListCallbacks,
				shown: {or: [SessionMenu.fn_adminMode, Weave.properties.enableWindowMenu]},
				label: lang("Window"),
				children: function():Array {
					return createItems([
						staticItems,
						dynamicItems
					]);
				}
			});
		}
	}
}

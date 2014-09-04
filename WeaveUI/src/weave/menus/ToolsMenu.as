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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import mx.controls.Button;
	import mx.core.IToolTip;
	import mx.core.UIComponent;
	import mx.managers.ToolTipManager;
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.objectWasDisposed;
	import weave.api.ui.IVisTool;
	import weave.api.ui.IVisTool_Basic;
	import weave.api.ui.IVisTool_Utility;
	import weave.compiler.StandardLib;
	import weave.core.ClassUtils;
	import weave.ui.AddExternalTool;
	import weave.ui.ColorController;
	import weave.ui.DraggablePanel;
	import weave.ui.EquationEditor;
	import weave.ui.ProbeToolTipEditor;
	import weave.ui.ProbeToolTipWindow;
	import weave.ui.collaboration.CollaborationEditor;
	import weave.utils.AsyncSort;

	public class ToolsMenu extends WeaveMenuItem
	{
		private static function openStaticInstance(item:WeaveMenuItem):void
		{
			DraggablePanel.openStaticInstance(item.data as Class);
		}
		public static function createGlobalObject(item:WeaveMenuItem):ILinkableObject
		{
			var classDef:Class = item.data is Array ? item.data[0] : item.data as Class;
			var name:String = item.data is Array ? item.data[1] : null;
			
			var className:String = getQualifiedClassName(classDef).split("::").pop();
			
			if (name == null)
				name = WeaveAPI.globalHashMap.generateUniqueName(className);
			var object:ILinkableObject = WeaveAPI.globalHashMap.requestObject(name, classDef, false);
			
			// put panel in front
			WeaveAPI.globalHashMap.setNameOrder([name]);
			
			// open control panel for new tool
			var dp:DraggablePanel = object as DraggablePanel;
			if (dp && dp.controlPanel)
				dp.callLater(handleDraggablePanelAdded, [dp]);
			
			return object;
		}
		private static function handleDraggablePanelAdded(dp:DraggablePanel):void
		{
			if (objectWasDisposed(dp) || !dp.parent)
				return;
			
			dp.validateNow();
			var b:Button = dp.userControlButton;
			var dpc:ICallbackCollection = getCallbackCollection(dp);
			
			var color:uint = 0x0C4785;//0x0b333c;
			var timeout:int = getTimer() + 1000 * 5;
			var tip:UIComponent = ToolTipManager.createToolTip(lang("Start here"), 0, 0, null, dp) as UIComponent;
			Weave.properties.panelTitleTextFormat.copyToStyle(tip);
			tip.setStyle('color', 0xFFFFFF);
			tip.setStyle('fontWeight', 'bold');
			tip.setStyle('borderStyle', "errorTipBelow");
			tip.setStyle("backgroundColor", color);
			tip.setStyle("borderColor", color);
			tip.setStyle('borderSkin', CustomToolTipBorder);
			var callback:Function = function():void {
				var p:Point = b.localToGlobal(new Point(0, b.height + 5));
				tip.move(int(p.x), int(p.y));
				tip.visible = !!b.parent;
				if (getTimer() > timeout)
					removeTip();
			};
			var removeTip:Function = function(..._):void {
				ToolTipManager.destroyToolTip(tip as IToolTip);
				WeaveAPI.StageUtils.removeEventCallback(Event.ENTER_FRAME, callback);
				dpc.removeCallback(removeTip);
				b.removeEventListener(MouseEvent.ROLL_OVER, removeTip);
			};
			b.addEventListener(MouseEvent.ROLL_OVER, removeTip);
			dpc.addDisposeCallback(null, removeTip);
			WeaveAPI.StageUtils.addEventCallback(Event.ENTER_FRAME, dp, callback, true);
		}
		
		private static const notDash:Object = {not: Weave.properties.dashboardMode};
		
		public static const staticItems:Array = createItems(
			{
				shown: [notDash, Weave.properties.showColorController],
				label: lang("Color Controller"),
				click: openStaticInstance,
				data: ColorController
			},{
				shown: [notDash, Weave.properties.showProbeToolTipEditor],
				label: lang("Edit Mouseover Info"),
				click: openStaticInstance,
				data: ProbeToolTipEditor
			},{
				shown: [notDash, Weave.properties.showProbeWindow],
				label: lang("Mouseover Window"),
				click: createGlobalObject,
				data: [ProbeToolTipWindow, "ProbeToolTipWindow"]
			},{
				shown: [notDash, Weave.properties.showEquationEditor],
				label: lang("Equation Column Editor"),
				click: openStaticInstance,
				data: EquationEditor
			},{
				shown: [notDash, Weave.properties.showCollaborationEditor],
				label: lang("Collaboration Settings"),
				click: openStaticInstance,
				data: CollaborationEditor
			},{
				shown: [notDash, Weave.properties.showAddExternalTools],
				label: lang("Add external tool..."),
				click: AddExternalTool.show
			}
		);
		
		public static function getDynamicItems(labelFormat:String = null):Array
		{
			function getToolItemLabel(item:WeaveMenuItem):String
			{
				var displayName:String = WeaveAPI.ClassRegistry.getDisplayName(item.data as Class);
				if (labelFormat)
					return lang(labelFormat, displayName);
				return displayName;
			}
			
			var implementations:Array = WeaveAPI.ClassRegistry.getImplementations(IVisTool);
			var partitions:Array = ClassUtils.partitionClassList(implementations, IVisTool_Basic, IVisTool_Utility);
			var items:Array = [];
			for each (var list:Array in partitions)
			{
				if (items.length)
					items.push(TYPE_SEPARATOR);
				for each (var impl:Class in list)
					items.push({
						shown: [notDash, Weave.properties.getToolToggle(impl)],
						label: getToolItemLabel,
						click: createGlobalObject,
						data: impl
					});
			}
			return createItems(items);
		}
		
		public static const dashboardItem:WeaveMenuItem = new WeaveMenuItem({
			label: function():String {
				var dash:Boolean = Weave.properties.dashboardMode.value;
				return lang((dash ? "Disable" : "Enable") + " dashboard mode");
			},
			click: Weave.properties.dashboardMode
		});
			
		public function ToolsMenu()
		{
			var cachedItems:Array;
			super({
				shown: Weave.properties.enableDynamicTools,
				label: lang("Tools"),
				children: function():Array
				{
					if (detectLinkableObjectChange(this, Weave.properties.toolToggles.childListCallbacks))
						cachedItems = createItems(
							staticItems,
							TYPE_SEPARATOR,
							getDynamicItems("Add {0}"),
							TYPE_SEPARATOR,
							dashboardItem
						);
					return cachedItems;
				}
			});
		}
	}
}

import flash.display.Graphics;

import mx.skins.halo.ToolTipBorder;

/**
 * Modifies behavior of borderStyle="errorTipBelow" so the arrow appears close to the left side.
 */
internal class CustomToolTipBorder extends ToolTipBorder
{
	override protected function updateDisplayList(w:Number, h:Number):void
	{
		super.updateDisplayList(w, h);
		
		var borderStyle:String = getStyle("borderStyle");
		
		if (borderStyle == "errorTipBelow")
		{
			var backgroundColor:uint = getStyle("backgroundColor");
			var backgroundAlpha:Number= getStyle("backgroundAlpha");
			var borderColor:uint = getStyle("borderColor");
			var cornerRadius:Number = getStyle("cornerRadius");
			
			var g:Graphics = graphics;
			g.clear();
			var radius:int = 3;
			// border
			drawRoundRect(0, 11, w, h - 13, radius, borderColor, backgroundAlpha);
			// top pointer 
			g.beginFill(borderColor, backgroundAlpha);
			g.moveTo(radius + 0, 11);
			g.lineTo(radius + 6, 0);
			g.lineTo(radius + 12, 11);
			g.moveTo(radius, 11);
			g.endFill();
		}
	}
}

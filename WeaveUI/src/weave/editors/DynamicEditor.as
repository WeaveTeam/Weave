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

package weave.editors
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.core.IUIComponent;
	import mx.events.FlexEvent;
	
	import weave.api.core.ILinkableDynamicObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.core.ILinkableVariable;
	import weave.api.data.IAttributeColumn;
	import weave.api.linkBindableProperty;
	import weave.api.ui.ISelectableAttributes;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.core.UIUtils;
	import weave.primitives.WeaveTreeItem;
	import weave.ui.CodeEditor;
	import weave.ui.ColumnListComponent;
	import weave.ui.CustomCheckBox;
	import weave.ui.CustomVRule;
	import weave.ui.DynamicColumnComponent;
	import weave.ui.ExpandButton;
	import weave.ui.Indent;
	import weave.ui.IndentTextInput;
	import weave.ui.SessionStateEditor;
	
	public class DynamicEditor
	{
		/**
		 * Creates an editor component for an ILinkableObject.
		 * @param target An ILinkableObject.
		 * @param label A label for the ILinkableObject.
		 * @param indentChildren If true and the object does not have a simple editor, an Indent component will be created with
		 *                       the specified label in front of a vertical list of child editors. If false, the vertical list
		 *                       will not be indented.
		 */
		public static function createComponent(target:ILinkableObject, label:String, indentChildren:Boolean):IUIComponent
		{
			var sm:SessionManager = WeaveAPI.SessionManager as SessionManager;
			var indent:Indent;
			
			var lb:LinkableBoolean = target as LinkableBoolean;
			if (lb)
			{
				var checkBox:CustomCheckBox = new CustomCheckBox();
				checkBox.label = lang(label);
				linkBindableProperty(lb, checkBox, 'selected');
				return checkBox;
			}
			
			var ln:LinkableNumber = target as LinkableNumber;
			if (ln)
			{
				var input:IndentTextInput = new IndentTextInput();
				input.prompt = lang("number");
				input.translate = true;
				input.label = label;
				linkBindableProperty(ln, input, 'text', 250, true);
				return input;
			}
			
			var lv:ILinkableVariable = target as ILinkableVariable;
			if (lv)
			{
				var codeEditor:CodeEditor = new CodeEditor();
				codeEditor.addEventListener(FlexEvent.CREATION_COMPLETE, function(event:Event):void {
					if (lv is LinkableString || lv is LinkableNumber || lv is LinkableBoolean)
						linkBindableProperty(lv, event.target, 'text', 500, true)
					else
						new JsonSynchronizer(lv, codeEditor, 'text');
					
					var eb:ExpandButton = ExpandButton.makeExpandable(codeEditor, false, 24);
					eb.addEventListener(MouseEvent.CLICK, function(e:Event):void {
						indent.setStyle('verticalAlign', eb.expanded ? 'top' : 'middle');
					});
					
					function onchange(event:Event = null):void {
						if (codeEditor.text.indexOf('\r') >= 0 || codeEditor.text.indexOf('\n') >= 0)
							eb.expanded = true;
					}
					codeEditor.addEventListener(Event.CHANGE, onchange);
					onchange();
				});
				
				indent = new Indent();
				indent.translate = true;
				indent.label = label;
				indent.setStyle('verticalAlign', 'top');
				indent.addChild(codeEditor);
				
				return indent;
			}
			
			var column:IAttributeColumn = target as IAttributeColumn;
			var ldo:ILinkableDynamicObject = target as ILinkableDynamicObject;
			if (column && ldo)
			{
				var dcc:DynamicColumnComponent = new DynamicColumnComponent();
				dcc.label = label;
				dcc.dynamicObject = ldo;
				return dcc;
			}
			
			var lhm:ILinkableHashMap = target as ILinkableHashMap;
			if (lhm && lhm.typeRestriction == IAttributeColumn)
			{
				var clc:ColumnListComponent = new ColumnListComponent();
				clc.label = label;
				clc.hashMap = lhm;
				clc.listHeight = 160;
				return clc;
			}
			
			if (ldo)// || lhm)
			{
				var button:Button = new Button();
				button.data = target;
				button.label = lang("Edit session state");
				button.addEventListener(MouseEvent.CLICK, function(event:Event):void {
					SessionStateEditor.openDefaultEditor(event.target.data as ILinkableObject);
				});
				
				indent = new Indent();
				indent.label = label;
				indent.addChild(button);
				
				return indent;
			}
			
			// for everything else, generate editors for each child in the session state
			var vbox:VBox = new ComponentUpdater(target, label).vbox;
			
			if (!indentChildren)
				return vbox;
			
			// indent the child editors
			indent = new Indent();
			indent.translate = true;
			indent.label = label;
			indent.setStyle('verticalAlign', 'top');
			indent.addChild(new CustomVRule());
			indent.addChild(vbox);
			return indent;
		}
	}
}

import flash.display.DisplayObject;
import flash.utils.Dictionary;

import mx.binding.utils.BindingUtils;
import mx.containers.VBox;
import mx.core.IUIComponent;
import mx.core.UIComponent;
import mx.utils.ObjectUtil;

import weave.api.core.ILinkableHashMap;
import weave.api.core.ILinkableObject;
import weave.api.core.ILinkableVariable;
import weave.api.detectLinkableObjectChange;
import weave.api.getCallbackCollection;
import weave.api.ui.ISelectableAttributes;
import weave.compiler.Compiler;
import weave.compiler.StandardLib;
import weave.core.ClassUtils;
import weave.core.SessionManager;
import weave.core.UIUtils;
import weave.editors.DynamicEditor;
import weave.primitives.WeaveTreeItem;
import weave.utils.EventUtils;
import weave.utils.VectorUtils;

internal class ComponentUpdater
{
	public function ComponentUpdater(target:ILinkableObject, label:String)
	{
		var sm:SessionManager = WeaveAPI.SessionManager as SessionManager;
		tree = sm.getSessionStateTree(target, label);
		sm.addTreeCallback(target, update, true);
	}
	
	// create a vbox to contain the child editors
	public const vbox:VBox = new VBox();
	private const cachedComponents:Dictionary = new Dictionary(true); // ILinkableObject -> component
	private var tree:WeaveTreeItem;
	
	private function update():void
	{
		// stop if nothing changed
		if (!detectLinkableObjectChange(update, tree.data as ILinkableObject))
			return;
		
		vbox.label = lang(tree.label);
		vbox.setStyle('verticalGap', 4);
		UIUtils.pad(vbox, 4, 100, 100);
		
		var subtrees:Array = tree.children || [];
		
		if (!(tree.data is ILinkableHashMap))
		{
			// sort by class, then by name
			StandardLib.sort(subtrees, function(st1:WeaveTreeItem, st2:WeaveTreeItem):int {
				var c1:Class = Object(st1.data).constructor;
				var c2:Class = Object(st2.data).constructor;
				var l1:String = st1.label;
				var l2:String = st2.label;
				return ObjectUtil.stringCompare(String(c1), String(c2))
					|| ObjectUtil.stringCompare(l1, l2);
			});
		}
		
		// editors for enumerated selectable attributes should appear first
		var sa:ISelectableAttributes = tree.data as ISelectableAttributes;
		if (sa)
		{
			// this code adds duplicate items to the subtrees array
			var lookup:Dictionary = VectorUtils.createLookup(subtrees, 'data');
			var names:Array = sa.getSelectableAttributeNames();
			subtrees = sa.getSelectableAttributes()
				.map(function(attr:*, i:*, a:*):WeaveTreeItem {
					return subtrees[lookup[attr]]
						|| (WeaveAPI.SessionManager as SessionManager).getSessionStateTree(attr, names[i]);
				})
				.concat(subtrees);
		}
		
		var ignore:Dictionary = new Dictionary(true);
		var i:int;
		var component:IUIComponent;
		var orderedComponents:Array = [];
		for (i = 0; i < subtrees.length; i++)
		{
			var subtree:WeaveTreeItem = subtrees[i] as WeaveTreeItem;
			
			// avoid handling an item twice
			if (ignore[subtree])
				continue;
			ignore[subtree] = true;
			
			var childTarget:ILinkableObject = subtree.data as ILinkableObject;
			
			// create component if necessary
			component = cachedComponents[childTarget];
			if (!component)
				cachedComponents[childTarget] = component = DynamicEditor.createComponent(childTarget, subtree.label, true);
			
			// add to vbox if necessary
			if (component.parent != vbox)
				UIUtils.spark_addChild(vbox, component as DisplayObject);
			
			// remember order
			orderedComponents.push(component);
		}
		
		// set child order
		for (i = 0; i < orderedComponents.length; i++)
			UIUtils.spark_setChildIndex(vbox, orderedComponents[i], i);
		
		// remove extra children
		while (UIUtils.spark_numChildren(vbox) > orderedComponents.length)
			UIUtils.spark_removeChildAt(vbox, orderedComponents.length);
	}
}

internal class JsonSynchronizer
{
	public function JsonSynchronizer(linkableVariable:ILinkableVariable, host:UIComponent, prop:String, delay:uint = 500)
	{
		this.JSON = ClassUtils.getClassDefinition('JSON');
		if (!JSON)
			JSON = {"stringify": Compiler.stringify, "parse": Compiler.parseConstant};

		this.lv = linkableVariable;
		this.host = host;
		this.prop = prop;
		
		getCallbackCollection(lv).addImmediateCallback(host, handleObject, true);
		BindingUtils.bindSetter(EventUtils.generateDelayedCallback(linkableVariable, handleJson, delay, true), this.host, this.prop);
	}
	
	public var JSON:Object;
	public var lv:ILinkableVariable;
	public var host:UIComponent;
	public var prop:String;
	private var refreshPending:Boolean;
	
	private function handleObject():void
	{
		refreshPending = true;
		refreshHostOnFocusOut();
	}
	
	private function refreshHostOnFocusOut():void
	{
		if (!refreshPending)
			return;
		
		if (UIUtils.hasFocus(host))
		{
			host.callLater(refreshHostOnFocusOut);
		}
		else
		{
			refreshPending = false;
			host[prop] = JSON.stringify(lv.getSessionState());
			if (host.errorString)
				host.errorString = null;
		}
	}
	
	private function handleJson(value:* = null):void
	{
		// do nothing if the host component does not have focus
		if (!UIUtils.hasFocus(host))
			return;
		
		if (!refreshPending)
		{
			refreshPending = true;
			refreshHostOnFocusOut();
		}
		
		var string:String = value;
		var object:Object;
		try
		{
			object = JSON.parse(value);
			if (host.errorString)
				host.errorString = null;
		}
		catch (e:Error)
		{
			if (value is String)
			{
				var number:Number = StandardLib.asNumber(value);
				if (isFinite(number))
				{
					lv.setSessionState(number);
					return;
				}
			}
			// do nothing because user input was invalid
			host.errorString = lang("Invalid JSON");
			return;
		}
		
		lv.setSessionState(object);
	}
}

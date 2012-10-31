/*
* Container which holds PodContentBase subclasses.
*/

package com.adobe.devnet.view
{
import com.adobe.devnet.events.PodStateChangeEvent;
import com.adobe.devnet.skins.CustomSkinnableContainer;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;

import mx.events.DragEvent;

import spark.components.Button;
import spark.components.Group;
import spark.components.HGroup;
import spark.components.Panel;
import spark.components.SkinnableContainer;
import spark.components.ToggleButton;
import spark.primitives.Rect;

// Drag events.
[Event(name="dragStart", type="mx.events.DragEvent")]
[Event(name="dragComplete", type="mx.events.DragEvent")]
// Resize events.
[Event(name="minimize", type="com.esria.samples.dashboard.events.PodStateChangeEvent")]
[Event(name="maximize", type="com.esria.samples.dashboard.events.PodStateChangeEvent")]
[Event(name="restore", type="com.esria.samples.dashboard.events.PodStateChangeEvent")]

[SkinState("minimized")];
public class Pod extends SkinnableContainer
{
	public static const MINIMIZED_HEIGHT:Number = 22;
	public static const WINDOW_STATE_DEFAULT:Number = 0;
	public static const WINDOW_STATE_MINIMIZED:Number = 1;
	public static const WINDOW_STATE_MAXIMIZED:Number = 2;
	
	[Bindable]public var button_width:Number = 18;
	[Bindable]public var button_height:Number = 18;
	
	[Bindable]public var title:String = "";
	
	public var windowState:Number; // Corresponds to one of the WINDOW_STATE variables.
	public var index:Number;	   // Index within the layout.
	
  [SkinPart(required="false")]
  public var controlsHolder:HGroup;
	
  [SkinPart(required="false")]
  public var minimizeButton:Button;
  [SkinPart(required="false")]
  public var maximizeRestoreButton:ToggleButton;
  
  [SkinPart(required="false")]
  public var closeButton:Button;
	
  [SkinPart(required="false")]
  public var headerDivider:Rect;
  
  [SkinPart(required="false")]
  public var titleBar:Group;
	
	// Variables used for dragging the pod.
	private var dragStartMouseX:Number;
	private var dragStartMouseY:Number;
	private var dragStartX:Number;
	private var dragStartY:Number;
	private var dragMaxX:Number;
	private var dragMaxY:Number;
	
	private var _showControls:Boolean;
	private var _showControlsChanged:Boolean;
	
	private var _maximize:Boolean;
	private var _maximizeChanged:Boolean;
	
	public function Pod()
	{
		super();
		doubleClickEnabled = true;
		windowState = WINDOW_STATE_DEFAULT;
    	setStyle("skinClass", Class(CustomSkinnableContainer));
	}
	
	override protected function createChildren():void
	{
		super.createChildren();	
		addEventListeners();
	}
		
	private function addEventListeners():void
	{
		titleBar.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownTitleBar);
		titleBar.addEventListener(MouseEvent.DOUBLE_CLICK, onClickMaximizeRestoreButton);
		titleBar.addEventListener(MouseEvent.CLICK, onClickTitleBar);
		
		minimizeButton.addEventListener(MouseEvent.CLICK, onClickMinimizeButton);
		maximizeRestoreButton.addEventListener(MouseEvent.CLICK, onClickMaximizeRestoreButton);
		closeButton.addEventListener(MouseEvent.CLICK, onClickCloseButton);
		
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	}
	
	private function onMouseDown(event:Event):void
	{
		// Moves the pod to the top of the z-index.
    Group(parent).setElementIndex(this, Group(parent).numElements - 1);
	}
	
	private function onClickMinimizeButton(event:MouseEvent):void
	{
		dispatchEvent(new PodStateChangeEvent(PodStateChangeEvent.MINIMIZE));
		// Set the state after the event is dispatched so the old state is still available.
		minimize();
	}
	
	// close functionality added for Weave
	private function onClickCloseButton(event:MouseEvent):void
	{
		close();
	}
	public function close():void
	{
		dispatchEvent(new PodStateChangeEvent(PodStateChangeEvent.CLOSE));
	}
	
	public function minimize():void
	{
		// Hide the bottom border if minimized otherwise the headerDivider and bottom border will be staggered. 
    windowState = WINDOW_STATE_MINIMIZED;
    invalidateSkinState();
    height = MINIMIZED_HEIGHT;
    showControls = false;
  }
	
	private function onClickMaximizeRestoreButton(event:MouseEvent=null):void
	{
		showControls = true;
		if (windowState == WINDOW_STATE_DEFAULT)
		{
			dispatchEvent(new PodStateChangeEvent(PodStateChangeEvent.MAXIMIZE));
			// Call after the event is dispatched so the old state is still available.
			maximize();
		}
		else
		{
			dispatchEvent(new PodStateChangeEvent(PodStateChangeEvent.RESTORE));
			// Set the state after the event is dispatched so the old state is still available.
			windowState = WINDOW_STATE_DEFAULT;
			maximizeRestoreButton.selected = false;
		}
    invalidateSkinState(); 
  }
	
	public function maximize():void
	{
		windowState = WINDOW_STATE_MAXIMIZED;
		
		_maximize = true;
		_maximizeChanged = true;
	}
	
	private function onClickTitleBar(event:MouseEvent):void
	{
		if (windowState == WINDOW_STATE_MINIMIZED)
		{
			// Add the bottom border back in case we were minimized.
			onClickMaximizeRestoreButton();
		}
	}

	private function onMouseDownTitleBar(event:MouseEvent):void
	{
		if (windowState == WINDOW_STATE_DEFAULT) // Only allow dragging if we are in the default state.
		{
			dispatchEvent(new DragEvent(DragEvent.DRAG_START));
			dragStartX = x;
			dragStartY = y;
			dragStartMouseX = parent.mouseX;
			dragStartMouseY = parent.mouseY;
			dragMaxX = parent.width - width;
			dragMaxY = parent.height - height;
			
			// Use the stage so we get mouse events outside of the browser window.
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
	}
	
	private function onMouseMove(e:MouseEvent):void
	{
		// Make sure we don't go off the screen on the right.
		var targetX:Number = Math.min(dragMaxX, dragStartX + (parent.mouseX - dragStartMouseX));
		// Make sure we don't go off the screen on the left.
		x = Math.max(0, targetX);
		
		// Make sure we don't go off the screen on the bottom.
		var targetY:Number = Math.min(dragMaxY, dragStartY + (parent.mouseY - dragStartMouseY));
		// Make sure we don't go off the screen on the top.
		y = Math.max(0, targetY);
	}
	
	private function onMouseUp(event:MouseEvent):void
	{
		dispatchEvent(new DragEvent(DragEvent.DRAG_COMPLETE));
		
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
	}
		
	public function set showControls(value:Boolean):void
	{
		_showControls = value;
		_showControlsChanged = true;
		invalidateProperties();
	}

  override protected function getCurrentSkinState():String {
    var returnState:String = "normal";
    if (windowState == WINDOW_STATE_MINIMIZED) {
      returnState = "minimized";
    }
    return returnState;
  }

	override protected function commitProperties():void
	{
		super.commitProperties();
		
		if (_showControlsChanged)
		{
			controlsHolder.visible = _showControls;
			_showControlsChanged = false;
		}
		
		if (_maximizeChanged)
		{
			maximizeRestoreButton.selected = _maximize;
			_maximizeChanged = false;
		}
	}
}
}
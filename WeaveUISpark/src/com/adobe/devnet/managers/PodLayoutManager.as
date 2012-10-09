/*
* Handles the layout for a group of pods.
*/

package com.adobe.devnet.managers
{	

import com.adobe.devnet.events.PodStateChangeEvent;
import com.adobe.devnet.view.DragHighlight;
import com.adobe.devnet.view.Pod;

import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

import mx.core.FlexGlobals;
import mx.effects.Move;
import mx.effects.Parallel;
import mx.effects.easing.Exponential;
import mx.events.DragEvent;
import mx.events.ResizeEvent;

import spark.components.Group;
import spark.components.NavigatorContent;
import spark.effects.Resize;

// Dispatched whenever the layout changes.
//[Event(name="update", type="com.esria.samples.dashboard.events.LayoutChangeEvent")]

//Modified for Weave 10/4/2012
// url for the original code = http://www.adobe.com/devnet/flex/articles/migrating-flex-apps-part4.html


public class PodLayoutManager extends EventDispatcher
{
	public var effectDuration:int = 10; // added for Weave
	
	public var id:String;
	public var items:Array = new Array();					// Stores the pods which are not minimized.
	public var minimizedItems:Array = new Array();			// Stores the minimized pods.
	public var maximizedPod:Pod;
	
	private var dragHighlightItems:Array = new Array();		// Stores the highlight items used to designate a drop area.
	private var gridPoints:Array = new Array();				// Stores the x,y of each pod in the grid.
	
	private var currentDragPod:Pod;							// The current pod which the user is dragging.
	private var currentVisibleHighlight:DragHighlight;		// The current highlight that is visible while dragging.
	private var currentDropIndex:Number;					// The index of where to drop the pod while dragging.
	private var currentDragPodMove:Move;					// The move effect used to transition the pod after it is released from dragging.
	
	//Weave: changed type to Group from navigator content
	private var _container:Group;							// The container which holds all of the pods.
	
	
	private var parallel:Parallel;							// The main effect container.
	private var maximizeParallel:Parallel;
	
	private var itemWidth:Number;							// Pod width.
	private var itemHeight:Number;							// Pod height.
	
	private static const POD_GAP:Number = 4;				// The vertical and horizontal gap between pods.
	private static const TASKBAR_HEIGHT:Number = 24;		// The height of the area for minimized pods.
	private static const TASKBAR_HORIZONTAL_GAP:Number = 4; // The horizontal gap between minimized pods.
	private static const TASKBAR_ITEM_WIDTH:Number = 150;	// The preferred minimized pod width if there is available space.
	private static const TASKBAR_PADDING_TOP:Number = 4;	// The gap between the taskbar and the bottom of the last row of pods.
	private static const PADDING_RIGHT:Number = 0;			// The right padding within the container when laying out pods.
	
	// Removes null items from the items array.
	// This should be called only once after all of the items have been added.
	// Null items will be present if a pod was saved at an index that is no longer valid
	// because the number of pods has been reduced in the XML.
	public function removeNullItems():void
	{
		var a:Array = new Array();
		var len:Number = items.length;
		for (var i:Number = 0; i < len; i++)
		{
			if (items[i] != null)
				a.push(items[i]);
		}
		
		items = a;
		
		// Weave: resize listener now in "set container"
		//_container.addEventListener(ResizeEvent.RESIZE, updateLayout);
	}
	
	// Sets the canvas which will hold the pods.
	public function set container(canvas:Group):void
	{
		_container = canvas;
		// Weave: added this
		_container.addEventListener(ResizeEvent.RESIZE, reSizeListener);
	}
	// Weave: this fixes slow update bug when container resizes 
	private function reSizeListener(event:ResizeEvent):void{
		updateLayout(false);
		updateLayout(true);
	}
	
	public function get container():Group
	{
		return _container;
	}
	
	public function addMinimizedItemAt(pod:Pod, index:Number):void
	{	
		if (index == -1)
			index = minimizedItems.length;
		
		pod.minimize();
		
		minimizedItems[index] = pod;
		initItem(pod);
	}
	
	//Weave: Added this function to support their index parameter in additemAt
	public function addItem(pod:Pod,  maximized:Boolean):void
	{	
		addItemAt(pod,items.length,maximized);
	}
	
	public function addItemAt(pod:Pod, index:Number, maximized:Boolean):void
	{	
		if (maximized)
		{
			maximizedPod = pod;
			pod.maximize();
		}
		
		items[index] = pod;
		initItem(pod);
	}
	
	private function initItem(pod:Pod):void
	{
    container.addElement(pod);
		
		pod.addEventListener(DragEvent.DRAG_START, onDragStartPod);
		pod.addEventListener(DragEvent.DRAG_COMPLETE, onDragCompletePod);
		pod.addEventListener(PodStateChangeEvent.MAXIMIZE, onMaximizePod);
		pod.addEventListener(PodStateChangeEvent.MINIMIZE, onMinimizePod);
		pod.addEventListener(PodStateChangeEvent.RESTORE, onRestorePod);
		
		// Add a highlight for each pod. Used to show a drop target box.
		var dragHighlight:DragHighlight = new DragHighlight();
		dragHighlight.visible = false;
		dragHighlightItems.push(dragHighlight);
    container.addElement(dragHighlight);
	updateLayout(true);
	}
	
	// Pod has been maximized.
	private function onMaximizePod(e:PodStateChangeEvent):void
	{
		var pod:Pod = Pod(e.currentTarget);
		maximizeParallel = new Parallel();

		maximizeParallel.duration = effectDuration;

		addResizeAndMoveToParallel(pod, maximizeParallel, availablePodWidth, availableMaximizedPodHeight, 0, 0);
		maximizeParallel.play();
		
		maximizedPod = pod;
		//dispatchEvent(new LayoutChangeEvent(LayoutChangeEvent.UPDATE));
	}
	
	// Pod has been minimized
	private function onMinimizePod(e:PodStateChangeEvent):void
	{
		if (maximizeParallel != null && maximizeParallel.isPlaying)
			maximizeParallel.pause();
		
		var pod:Pod = Pod(e.currentTarget);
		items.splice(pod.index, 1);
		
		// Pod was previously maximized so there isn't a minimized pod anymore.
		if (pod.windowState == Pod.WINDOW_STATE_MAXIMIZED)
			maximizedPod = null;
				
		minimizedItems.push(pod);
		
		updateLayout(true);
		
		//dispatchEvent(new LayoutChangeEvent(LayoutChangeEvent.UPDATE));
	}
	
	// Pod has been restored.
	private function onRestorePod(e:PodStateChangeEvent):void
	{
		var pod:Pod = Pod(e.currentTarget);
		if (pod.windowState == Pod.WINDOW_STATE_MAXIMIZED) // Current state is maximized
		{
			if (maximizeParallel != null && maximizeParallel.isPlaying)
				maximizeParallel.pause();
			
			maximizedPod = null;
			maximizeParallel = new Parallel();
			//Weave: Added for Weave to speed up the restore
			maximizeParallel.duration = effectDuration;
			var point:Point = Point(gridPoints[pod.index]);
			addResizeAndMoveToParallel(pod, maximizeParallel, itemWidth, itemHeight, point.x, point.y);
			maximizeParallel.play();
		}
		else if (pod.windowState == Pod.WINDOW_STATE_MINIMIZED) // Current state is minimized so add it back to the display.
		{
			var len:Number = minimizedItems.length;
			for (var i:Number = 0; i < len; i++)
			{
				// Remove the minimized window from the minimized items.
				if (minimizedItems[i] == pod)
				{
					minimizedItems.splice(i, 1);
					break;
				}
			}
			
			if (pod.index < (items.length - 1)) // The pod index is within the range of the number of pods.
				items.splice(pod.index, 0, pod);
			else								// Out of range so add pod at the end.
				items.push(pod);
				
			updateLayout(true);
		}
		
		//dispatchEvent(new LayoutChangeEvent(LayoutChangeEvent.UPDATE));
	}
	
	private function onDragStartPod(e:DragEvent):void
	{
		currentDragPod = Pod(e.currentTarget);
		var len:Number = items.length;
		for (var i:Number = 0; i < len; i++) // Find the current drop index so we have a start point.
		{
			if (Pod(items[i]) == currentDragPod)
			{
				currentDropIndex = i;
				break;
			}
		}
		
		// Use the stage so we get mouse events outside of the browser window.
		FlexGlobals.topLevelApplication.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}
	
	private function onDragCompletePod(e:DragEvent):void
	{
    FlexGlobals.topLevelApplication.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		
		if (currentVisibleHighlight != null)
			currentVisibleHighlight.visible = false;
		
		// The x/y will not change if a user clicked on a header without dragging. In that case, we want to toggle the window state.
		var point:Point = Point(gridPoints[currentDropIndex]);
		if (point.x != currentDragPod.x || point.y != currentDragPod.y)
		{
			currentDragPodMove = new Move(currentDragPod);
			currentDragPodMove.easingFunction = Exponential.easeOut;
			currentDragPodMove.xTo = point.x;
			currentDragPodMove.yTo = point.y;
			currentDragPodMove.play();
			
			//dispatchEvent(new LayoutChangeEvent(LayoutChangeEvent.UPDATE));
		}
	}
	
	// Handles the live resorting of pods as one is dragged.
	private function onMouseMove(e:MouseEvent):void
	{
		var len:Number = items.length;	// Use the items since we can have more pods than highlights when a pod(s) is minimized.
		var dragHighlightItem:DragHighlight;
		var overlapArea:Number = 0; 	// Keeps track of the amount (w *h) of overlap between rectangles.
		var dragPodRect:Rectangle = new Rectangle(currentDragPod.x, currentDragPod.y, currentDragPod.width, currentDragPod.height);
		var dropIndex:Number = -1;		// The new drop index. This will create a range from currentDropIndex to dropIndex for transtions below.
		
		// Loop through the highlights and figure out which one has the greatest amount of overlap with the pod that is being dragged.
		// The highlight with the max overlap will be the drop index.
		for (var i:Number = 0; i < len; i++)
		{
			dragHighlightItem = DragHighlight(dragHighlightItems[i]);
			dragHighlightItem.visible = false;
			if (currentDragPod.hitTestObject(dragHighlightItem))
			{
				var dragHighlightItemRect:Rectangle = new Rectangle(dragHighlightItem.x, dragHighlightItem.y, dragHighlightItem.width, dragHighlightItem.height);
				var intersection:Rectangle = dragHighlightItemRect.intersection(dragPodRect);
				if ((intersection.width * intersection.height) > overlapArea)
				{
					currentVisibleHighlight = dragHighlightItem;
					overlapArea = intersection.width * intersection.height;
					dropIndex = i;
				}
			}
		}
		
		if (currentDropIndex != dropIndex) // Make sure we have a new drop index so we don't create redudant effects.
		{
			if (dropIndex == -1) // User is not over a highlight.
				dropIndex = currentDropIndex;
			
			if (currentDragPodMove != null && currentDragPodMove.isPlaying)
				currentDragPodMove.pause();
			
			if (parallel != null && parallel.isPlaying)
				parallel.pause();
			
			parallel = new Parallel();
			parallel.duration = effectDuration;
			
			var a:Array = new Array(); // Used to re-order the items array.
			a[dropIndex] = currentDragPod;
			currentDragPod.index = dropIndex;
			
			for (i = 0; i < len; i++)
			{
				var targetX:Number;
				var targetY:Number;
				var point:Point;
				var pod:Pod = Pod(items[i]);
				
				var index:Number;
				if (i != currentDropIndex)
				{
					// Find the index to determine the lookup in gridPoints.
					if ((i < currentDropIndex && i < dropIndex) ||
						(i > currentDropIndex && i > dropIndex)) // Below or above the range of dragging.
						index = i;
					else if (i > currentDropIndex && i <= dropIndex) // Drag forwards
						index = i - 1;
					else if (i < currentDropIndex && i >= dropIndex) // Drag backwards
						index = i + 1;
					else
						index = i;
					
					a[index] = pod;
					pod.index = index;
					
					point = Point(gridPoints[index]); // Get the x,y coord from the grid.
					
					targetX = point.x;
					targetY = point.y;
					
					if (targetX != pod.x || targetY != pod.y)
					{
						var move:Move = new Move(pod);
						move.easingFunction = Exponential.easeOut;
						move.xTo = targetX;
						move.yTo = targetY;
						parallel.addChild(move);
					}
				}
			}
			
			if (parallel.children.length > 0)
				parallel.play();
		
			currentDropIndex = dropIndex;
			
			// Reassign the items array so the new order is reflected.
			items = a;
		}
		
		currentVisibleHighlight.visible = true;
	}
	
	// Lays out the pods, minimized pods and drag highlight items.
	public function updateLayout(tween:Boolean=true):void
	{
		var len:Number = items.length;
		var sqrt:Number = Math.floor(Math.sqrt(len));
		var numCols:Number = Math.ceil(len / sqrt);
		var numRows:Number = Math.ceil(len / numCols);
		var col:Number = 0;
		var row:Number = 0;
		var pod:Pod;
		itemWidth = Math.round(availablePodWidth / numCols - ((POD_GAP * (numCols - 1)) / numCols));
		itemHeight = Math.round(availablePodHeight / numRows - ((POD_GAP * (numRows - 1)) / numRows));
		
		if (parallel != null && parallel.isPlaying)
			parallel.pause();
		
		if (tween)
		{
			parallel = new Parallel();
			parallel.duration = effectDuration;
		}
		
		// Layout the pods.
		for (var i:Number = 0; i < len; i++)
		{			
			if(i % numCols == 0 && i > 0)
			{
				row++;
				col = 0;
			}
			else if(i > 0)
			{
				col++;
			}
			
			var targetX:Number = col * itemWidth;
			var targetY:Number = row * itemHeight;
			
			if(col > 0) 
				targetX += POD_GAP * col;
			if(row > 0) 
				targetY += POD_GAP * row;
				
			targetX = Math.round(targetX);
			targetY = Math.round(targetY);
			
			pod = items[i];
			if (pod.windowState == Pod.WINDOW_STATE_MAXIMIZED)// Window is maximized so do not include in the grid
			{
				if (tween)
				{
					addResizeAndMoveToParallel(pod, parallel, availablePodWidth, availableMaximizedPodHeight, 0, 0);
				}
				else
				{
					pod.width = availablePodWidth;
					pod.height = availableMaximizedPodHeight;
				}
				
				// Move the pod to the top of the z-index. It will not be at the top if we are coming from a saved state
				// and the pod is not the last one.
        container.setElementIndex(pod, container.numElements - 1);
			}
			else
			{
				if (tween)
				{
					addResizeAndMoveToParallel(pod, parallel, itemWidth, itemHeight, targetX, targetY);
				}
				else
				{
					pod.width = itemWidth;
					pod.height = itemHeight;
					pod.x = targetX;
					pod.y = targetY;
				}
			}
				
			pod.index = i;
			
			gridPoints[i] = new Point(targetX, targetY);
		}
		
		// Layout the minimized items.
		len = minimizedItems.length;
		if (len > 0)
		{
			// Check to see if all of the minimized items will be too wide.
			var totalMinimizedItemWidth:Number = len * TASKBAR_ITEM_WIDTH + (len -1) * TASKBAR_HORIZONTAL_GAP;
			var minimizedItemWidth:Number;
			if (totalMinimizedItemWidth > availablePodWidth) // Items are too wide so resize.
				minimizedItemWidth = Math.round((availablePodWidth - (len - 1) * TASKBAR_HORIZONTAL_GAP) / len);
			else
				minimizedItemWidth = TASKBAR_ITEM_WIDTH;
			
			for (i = 0; i < len; i++)
			{
				pod = Pod(minimizedItems[i]);
				pod.height = Pod.MINIMIZED_HEIGHT;
				targetX = i * (TASKBAR_HORIZONTAL_GAP + minimizedItemWidth);
				if (tween)
				{
					addResizeAndMoveToParallel(pod, parallel, minimizedItemWidth, Pod.MINIMIZED_HEIGHT, targetX, minimizedPodY);
				}
				else
				{
					pod.width = minimizedItemWidth;
					pod.x = targetX;
					pod.y = minimizedPodY;
				}
			}
		}
		
		if (parallel != null && parallel.children.length > 0)
			parallel.play();
		
		// Layout the drag highlight items.
		len = dragHighlightItems.length;
		for (i = 0; i < len; i++)
		{
			var dragHighlight:DragHighlight = DragHighlight(dragHighlightItems[i]);
			if (i > (items.length - 1)) // The corresponding item is minimized so hide the highlights not being used.
			{
				dragHighlight.visible = false;
				dragHighlight.x = 0;
				dragHighlight.y = 0;
				dragHighlight.width = 0;
				dragHighlight.height = 0;
			}
			else
			{
				var point:Point = Point(gridPoints[i]);
				dragHighlight.x = point.x;
				dragHighlight.y = point.y;
				dragHighlight.width = itemWidth;
				dragHighlight.height = itemHeight;
        container.setElementIndex(dragHighlight, i); // Move the hightlights to the bottom of the z-index.
			}
		}
	}
	
	// Creates a resize and move event and adds them to a parallel effect.
	private function addResizeAndMoveToParallel(target:Pod, parallel:Parallel, widthTo:Number, heightTo:Number, xTo:Number, yTo:Number):void
	{
		var resize:Resize = new Resize(target);
		resize.widthTo = widthTo;
		resize.heightTo = heightTo;
		//resize. = Exponential.easeOut;
		parallel.addChild(resize);
		
		var move:Move = new Move(target);
		move.xTo = xTo;
		move.yTo = yTo;
		move.easingFunction = Exponential.easeOut;
		parallel.addChild(move);
	}
	
	// Returns the available width for all of the pods.
	private function get availablePodWidth():Number
	{
		return container.width - PADDING_RIGHT;
	}
	
	// Returns the available height for all of the pods.
	private function get availablePodHeight():Number
	{
		return container.height - TASKBAR_HEIGHT - TASKBAR_PADDING_TOP;
	}
	
	// Returns the available height for a maximized pod.
	private function get availableMaximizedPodHeight():Number
	{
		return container.height;
	}
	
	// Returns the target y coord for a minimized pod.
	private function get minimizedPodY():Number
	{
		return container.height - TASKBAR_HEIGHT;
	}
}
}
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

package weave.visualization.plotters
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.controls.Image;
	import mx.core.DragSource;
	import mx.managers.DragManager;
	
	import weave.api.getCallbackCollection;		
	import weave.primitives.Bounds2D;
	import weave.primitives.LinkableBounds2D;

	/**
	 * AnchorDisplayObject 
	 * @author kmanohar
	 */	
	public class AnchorDisplayObject extends Image 
	{
		public function AnchorDisplayObject()
		{
			super();
			height = 15;
			width = 15;
			buttonMode = true;
			useHandCursor = true;			
			addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			source = redCircleIcon;
			getCallbackCollection(parentDataBounds).addGroupedCallback(this, drawAnchor );
		}
				
		[Embed(source="/weave/resources/images/radio_button_red.png")]
		private var redCircleIcon:Class;
					
		[Embed(source="/weave/resources/images/green-circle.png")]
		private var greenCircleIcon:Class;
		
		private var tempPoint:Point = new Point(); // reusable object 
		private const tempBounds:Bounds2D = new Bounds2D();// reusable object
		public var screenBounds:Bounds2D = new Bounds2D();
		
		/**
		 * Reference to the ILinkable object in the parent's tool's session state 
		 */		
		public var anchor:AnchorPoint;
		
		/**
		 * Parent visualization's dataBounds 
		 */		
		public const parentDataBounds:LinkableBounds2D = new LinkableBounds2D();
		
		/**
		 * This function projects the data coordinates of the internal AnchorPoint object to screen coordinates
		 * and moves the DisplayObject to that location
		 */		
		public function drawAnchor():void			
		{
			parentDataBounds.copyTo(tempBounds);						
			if( tempBounds.isEmpty() || tempBounds.isUndefined() || screenBounds.isEmpty() || screenBounds.isUndefined() ) return;			
			
			tempPoint.x = anchor.x.value;
			tempPoint.y = anchor.y.value;
			
			tempBounds.projectPointTo(tempPoint,screenBounds);
			
			move(tempPoint.x-7.5, tempPoint.y-7.5);
		}
		
		private function handleMouseMove(event:MouseEvent):void
		{
			var dragInitiator:AnchorDisplayObject=AnchorDisplayObject(event.currentTarget);
			var ds:DragSource = new DragSource();
			ds.addData(dragInitiator, "canv");               
			
			var imageProxy:Image = new Image();
			imageProxy.source = redCircleIcon;
			imageProxy.height=15;
			imageProxy.width=15;                
			DragManager.doDrag(dragInitiator, ds, event, imageProxy, 0, 0, 0.25);
			
		}
	}
}

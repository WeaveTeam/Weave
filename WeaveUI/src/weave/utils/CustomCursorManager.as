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
package weave.utils
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.ui.MouseCursorData;
	
	import mx.core.BitmapAsset;
	import mx.managers.CursorManager;
	
	import weave.api.reportError;

	public class CustomCursorManager
	{
		public function CustomCursorManager()
		{
			super();
		}
		
		public static const LINK_CURSOR:String = "linkCursor";
		[Embed(source="/weave/resources/images/axisLinkCursor.png")]
		private static var linkCursor:Class;
		
		
		public static const HAND_CURSOR:String = "handCursor";
        [Embed(source="/weave/resources/images/cursor_hand.png")]
        private static var handCursor:Class;
		
		
        public static const HAND_GRAB_CURSOR:String = "handGrabCursor";
        [Embed(source="/weave/resources/images/cursor_grab.png")]
        private static var handGrabCursor:Class;
		

		public static const SELECT_REPLACE_CURSOR:String = "selectReplaceCursor";
        [Embed(source="/weave/resources/images/cursor_select_replace.png")]
        private static var selectReplaceCursor:Class;


		public static const SELECT_ADD_CURSOR:String = "selectAddCursor";
        [Embed(source="/weave/resources/images/cursor_select_add.png")]
        private static var selectAddCursor:Class;
		

		public static const SELECT_SUBTRACT_CURSOR:String = "selectSubtractCursor";
        [Embed(source="/weave/resources/images/cursor_select_subtract.png")]
        private static var selectSubtractCursor:Class;
		

		public static const ZOOM_CURSOR:String = "zoomCursor";
        [Embed(source="/weave/resources/images/cursor_zoom.png")]
        private static var zoomCursor:Class;
		

		public static const PEN_CURSOR:String = "penCursor";
		[Embed(source="/weave/resources/images/penpointer.png")]
		private static var penCursor:Class;
		
		public static const RESIZE_TOP_BOTTOM:String = "resizeTopBottom";
		[Embed(source="/weave/resources/images/resize_TB.png")]
		private static var _resizeTBCursor:Class;
		
		
		
		public static const RESIZE_LEFT_RIGHT:String = "resizeLeftRight";
		[Embed(source="/weave/resources/images/resize_LR.png")]
		private static var _resizeLRCursor:Class;
		
		public static const RESIZE_TOPLEFT_BOTTOMRIGHT:String = "resizeTLBR";
		[Embed(source="/weave/resources/images/resize_TL-BR.png")]
		private static var _resizeTLBRCursor:Class;
		
		public static const RESIZE_TOPRIGHT_BOTTOMLEFT:String = "resizeTRBL";
		[Embed(source="/weave/resources/images/resize_TR-BL.png")]
		private static var _resizeTRBLCursor:Class;
		
		
		//registering standard cursors
		//Static block start
		zInitiailizeCursors();
		//Static block end
		
		/**
		 * This function registers all the standard Weave cursors/
		 * 
		 **/
		private static function zInitiailizeCursors():void
		{
			
			//NOTE: the cursor name should not contain a dot. Mouse class gives errors if you use names like 'CustomCursorManager.PEN_CURSOR'
			var linkCursorBitmap:BitmapAsset = new linkCursor() as BitmapAsset;
			registerCursor(LINK_CURSOR,linkCursorBitmap.bitmapData);
			
			var handCursorBitmap:BitmapAsset = new handCursor() as BitmapAsset;
			registerCursor(HAND_CURSOR,handCursorBitmap.bitmapData);
			
			var handGrabCursorBitmap:BitmapAsset = new handGrabCursor() as BitmapAsset;
			registerCursor(HAND_GRAB_CURSOR,handGrabCursorBitmap.bitmapData);
			
			var selectReplaceCursorBitmap:BitmapAsset = new selectReplaceCursor() as BitmapAsset;
			registerCursor(SELECT_REPLACE_CURSOR,selectReplaceCursorBitmap.bitmapData,2,2);
			
			var selectAddCursorBitmap:BitmapAsset = new selectAddCursor() as BitmapAsset;
			registerCursor(SELECT_ADD_CURSOR,selectAddCursorBitmap.bitmapData,2,2);
			
			var selectSubtractCursorBitmap:BitmapAsset = new selectSubtractCursor() as BitmapAsset;
			registerCursor(SELECT_SUBTRACT_CURSOR,selectSubtractCursorBitmap.bitmapData,2,2);
			
			var zoomCursorBitmap:BitmapAsset = new zoomCursor() as BitmapAsset;
			registerCursor(ZOOM_CURSOR,zoomCursorBitmap.bitmapData);
			
			var penCursorBitmap:BitmapAsset = new penCursor() as BitmapAsset;
			registerCursor(PEN_CURSOR,penCursorBitmap.bitmapData,3,22);
			
			var resizeTBBitmap:BitmapAsset = new _resizeTBCursor() as BitmapAsset;
			registerCursor(RESIZE_TOP_BOTTOM,resizeTBBitmap.bitmapData,resizeTBBitmap.width/2,resizeTBBitmap.height/2);
			
			var resizeLRBitmap:BitmapAsset = new _resizeLRCursor() as BitmapAsset;
			registerCursor(RESIZE_LEFT_RIGHT,resizeLRBitmap.bitmapData,resizeLRBitmap.width/2,resizeLRBitmap.height/2);
			
			var resizeTLBRBitmap:BitmapAsset = new _resizeTLBRCursor() as BitmapAsset;
			registerCursor(RESIZE_TOPLEFT_BOTTOMRIGHT,resizeTLBRBitmap.bitmapData,resizeTLBRBitmap.width/2,resizeTLBRBitmap.height/2);
			
			var resizeTRBLBitmap:BitmapAsset = new _resizeTRBLCursor() as BitmapAsset;
			registerCursor(RESIZE_TOPRIGHT_BOTTOMLEFT,resizeTRBLBitmap.bitmapData,resizeTRBLBitmap.width/2,resizeTRBLBitmap.height/2);
		}
		
        private static function registerCursor(name:String, bitmapData:BitmapData,xOffset:int=0,yOffset:int=0):void
		{
			var cursorData:MouseCursorData = new MouseCursorData();
			var bitmapDataVectors:Vector.<BitmapData> = new Vector.<BitmapData>(1,true); 
			
			bitmapDataVectors[0] = bitmapData;
			
			cursorData.data = bitmapDataVectors;
			cursorData.hotSpot = new Point(xOffset,yOffset);
			Mouse.registerCursor(name,cursorData);
			trace("registered " + name);
		}
		
		
        private static var idCounter:int = 0;
		
		private static var idCursorMap:Array = new Array();
		/**
		 * This function is to set the cursor to standard cursor types like hand cursor, link cursor, etc.
		 * Look at the static String constants to get all the types of available cursors.
		 * @param type A string name. Use one of the string constants
		 * @param xOffset the x-coordinate on the bitmap where you want the click to register. (0,0) is the upper left corner of the bitmap image. 
		 * @param yOffset the y-coordinate on the bitmap where you want the click to register. (0,0) is the upper left corner of the bitmap image.
		 * @return An integer mapped to the cursorname.
		 * */
		public static function showCursor(type:String):int
		{
			Mouse.cursor = type;
			idCounter++;
			idCursorMap.push([idCounter,type]);
			return idCounter;	
		}
		
		
		public static function removeCursor(id:int):void
		{
			for(var i:int; i<idCursorMap.length; i++)
			{
				if(idCursorMap[i][0] == id)
				{
					idCursorMap.splice(i,1);
					setToLastCursor();
					return;
				}
			}
			
		}
		
		public static function removeCurrentCursor():void
		{
			if(idCursorMap.length ==0)
				return;

			var currentCursor:Array = idCursorMap.pop();
			
			setToLastCursor();
			
		}
		
		private static function setToLastCursor():void
		{
			//set to last cursor
			if(idCursorMap.length !=0)
				Mouse.cursor = idCursorMap[idCursorMap.length-1][1];
			else
				Mouse.cursor = MouseCursor.AUTO;
		}
		
		public static function removeAllCursors():void
		{
			idCursorMap = [];
			setToLastCursor();
		}
	}
}
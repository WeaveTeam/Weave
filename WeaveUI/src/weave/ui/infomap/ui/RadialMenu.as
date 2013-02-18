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

package weave.ui.infomap.ui
{
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.core.UIComponent;
	
	import weave.utils.BitmapUtils;
	
	/**
	 * This class adds a submenu to any UI Compnent.
	 * Contructor takes a parent UIComponent and a String array of event listeners
	 * Use the addSubMenuItem function to add menu items
	 * 
	 * @author skolman
	 * @author adufilie
	 */
	public class RadialMenu extends Canvas
	{
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			this.width = _radius;
			this.height = _radius *2;
			clipContent = false;
		}
		public var iconSize:int = 12;
		
		private var _menuItems:Array = [];
		public function addMenuItem(bitmap:Bitmap,label:String,listener:Function,params:Array=null):void
		{
			var item:RadialMenuItem = new RadialMenuItem();
			
			item.img = new Image();
			item.img.source = new Bitmap(BitmapUtils.resizeBitmapData(bitmap.bitmapData,iconSize,iconSize));
			
			item.label = label;
			
			item.img.buttonMode = true;
			item.img.addEventListener(MouseEvent.CLICK,listener);
			
			_menuItems.push(item);
		}
		
		private var _radius:int = 50;
		public function showMenu():void
		{
			var numOfItems:Number = _menuItems.length;
			
			var positions:Array = getNPointsOnSemiCircle(_radius,numOfItems);
			
			for (var i:int = 0; i<numOfItems; i++)
			{
				var item:RadialMenuItem = _menuItems[i];
				addChild(item.img);
				item.img.toolTip = item.label;
				item.img.move(positions[i].x,positions[i].y);
			}
		}
		
		public function hideMenu():void
		{
			removeAllChildren();
		}
		
		public function removeMenuitem(label:String):void
		{
			var m:RadialMenuItem;
			for(var i:int; i<_menuItems.length; i++)
			{
				m= _menuItems[i];
				if(m.label == label)
				{
					_menuItems.splice(i,1);
					return;
				}
			}
		}
		
		public function removeAllMenuItems():void
		{
			_menuItems = [];
		}
		
		/**
		 * @private
		 * This function calculates the points on the circle to plot the thumbnails on 
		 * based on the radius and total number of thumnails to draw.
		 * 
		 * @param center The center of the circle
		 * @param radius The raidus of the circle
		 * @param n The total number of documents/thumbnails to plot
		 * 
		 * @return an array of points
		 **/
		private function getNPointsOnSemiCircle(radius:Number, n:Number) : Array
		{	
			var center:Point = new Point(0,0);
			//solution obtained from http://stackoverflow.com/questions/2169656/dynamically-spacing-numbers-around-a-circle
			var p:Number = Math.PI / n;
			var points:Array = new Array( n );				
			var i:int = -1;
			while( ++i < n )				{
				var theta:Number = p * i;
				var pointOnCircle:Point = new Point( Math.cos( theta ) * radius, Math.sin( theta ) * radius );
				points[ i ] = center.add( pointOnCircle );
			}				
			return points;				
		}
	}
}
import mx.controls.Image;

internal class RadialMenuItem
{
	public var img:Image;
	public var label:String;
}

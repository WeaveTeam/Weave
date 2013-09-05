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
	import mx.containers.HBox;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.effects.Fade;
	import mx.events.EffectEvent;
	
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
		/**
		 * Creates a menu using images. The menus shows up when the eventType occurs on the uiParent.
		 * Current works  
		 * @param uiParent
		 * @param eventType
		 * @param style
		 * 
		 */		
		public function RadialMenu(uiParent:UIComponent, openEventType:String,closeEventType:String, style:String)
		{
			if(uiParent == null)
				return;
			
			_uiParent = uiParent;
			
			_uiParent.addEventListener(openEventType,showMenu);
			_uiParent.addEventListener(closeEventType,hideMenu);
			
			_style = style;
			
		}
		
		private var _uiParent:UIComponent = null;
		
		private var _style:String = RADIAL_STYLE;
		
		override protected function childrenCreated():void
		{
			super.childrenCreated();
			clipContent = false;
			
			_fadeIn.duration = 500;
			_fadeOut.duration = 500;
			
			_fadeIn.alphaFrom = _fadeOut.alphaTo = 0.0;
			_fadeIn.alphaTo = _fadeOut.alphaFrom = 1.0;
			
			_fadeIn.addEventListener(EffectEvent.EFFECT_END,handleEffectsEnd);
			
		}
		
		public var iconSize:int = 12;
		
		private var _fadeIn:Fade = new Fade(this);
		private var _fadeOut:Fade = new Fade(this);
		
		private var _menuItems:Array = [];
		public function addMenuItem(bitmap:Bitmap,label:String,listener:Function,params:Array):void
		{
			removeMenuitem(label);
			var item:RadialMenuItem = new RadialMenuItem();
			
			item.img = new Image();
			item.img.source = new Bitmap(BitmapUtils.resizeBitmapData(bitmap.bitmapData,iconSize,iconSize));
			
			item.label = label;
			
			item.img.buttonMode = true;
			item.img.addEventListener(MouseEvent.CLICK,handleImageClick);
			
			item.listener = listener;
			item.params = params;
			_menuItems.push(item);
//			if(!isNaN(postion))
//			{
//				_menuItems.splice(postion,0,item);
//			}
//			else
//			{
//				_menuItems.push(item);
//			}
		}
		
		private function handleImageClick(event:MouseEvent):void
		{
			var item:RadialMenuItem;
			for each(var m:RadialMenuItem in _menuItems)
			{
				if(m.img == event.currentTarget)
				{
					item = m;
					break;
				}
			}
			if(item.params)
			{
				item.listener.apply(null,item.params);
			}
			else
			{
				item.listener.apply();
			}
		}
		
		public static const RADIAL_STYLE:String = "radial";
		public static const LINE_STYLE:String = "line";
		public static const DROP_DOWN_STYLE:String = "dropdown";
		
		private var _radius:int = 50;
		private function showMenu(event:Event):void
		{
			graphics.clear();
			var numOfItems:Number = _menuItems.length;
			
			if(_style == RADIAL_STYLE)
			{
				this.width = _radius;
				this.height = _radius *2;
				var positions:Array = getNPointsOnSemiCircle(_radius,numOfItems);
				var item:RadialMenuItem;
				for (var i:int = 0; i<numOfItems; i++)
				{
					item = _menuItems[i];
					addChild(item.img);
					item.img.toolTip = item.label;
					item.img.move(positions[i].x,positions[i].y);
				}
			}
			else if(_style == LINE_STYLE)
			{
				this.width = iconSize * numOfItems;
				this.height = iconSize;
				var box:HBox = new HBox();
				addChild(box);
				for (var j:int = 0; j<numOfItems; j++)
				{
					item = _menuItems[j];
					box.addChild(item.img);
					item.img.toolTip = item.label;
				}
			}
			graphics.beginFill(0,0);//draw a rectangle to detect this menu even when mouse is hovering between icons.
			graphics.drawRect(0,0,120,height);//hack to use maximum width of 120. 
			graphics.endFill();
			_fadeIn.play();
		}
		
		private function hideMenu(event:Event):void
		{
			_fadeOut.play();
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
		
		private function handleEffectsEnd(event:EffectEvent):void
		{
			if(event.target == _fadeIn)
			{
				enabled = true;
			}
			else
			{
				enabled = false;
			}
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
				var theta:Number = - p * i;
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
	public var listener:Function;
	public var params:Array;
	
}

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
	import flash.text.TextFormat;
	import flash.text.engine.FontPosture;
	import flash.text.engine.FontWeight;
	
	import mx.core.UIComponent;
	
	import weave.api.core.ILinkableObject;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	
	/**
	 * Contains a list of properties for use with a TextFormat object.
	 * 
	 * @author adufilie
	 */
	public class LinkableTextFormat implements ILinkableObject
	{
		public static const defaultTextFormat:LinkableTextFormat = new LinkableTextFormat();
		
		public static const DEFAULT_COLOR:uint = 0x000000;
		public static const DEFAULT_SIZE:uint = 11;
		public static const DEFAULT_FONT:String = "Sophia Nubian";
		
		/**
		 * @see flash.text.TextFormat#font
		 */
		public const font:LinkableString = registerLinkableChild(this, new LinkableString(DEFAULT_FONT, function(value:String):Boolean{ return value ? true : false; }));
		
		/**
		 * @see flash.text.TextFormat#font
		 */
		public const size:LinkableNumber = registerLinkableChild(this, new LinkableNumber(DEFAULT_SIZE, function(value:Number):Boolean{ return value > 2; }));
		
		/**
		 * @see flash.text.TextFormat#size
		 */
		public const color:LinkableNumber = registerLinkableChild(this, new LinkableNumber(DEFAULT_COLOR, isFinite));
		
		/**
		 * @see flash.text.TextFormat#color
		 */
		public const bold:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		/**
		 * @see flash.text.TextFormat#bold
		 */
		public const italic:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		/**
		 * @see flash.text.TextFormat#underline
		 */
		public const underline:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		/**
		 * Copy the properties from a TextFormat object to the linkable properties of this object.
		 * @param source A TextFormat to copy properties from.
		 */
		public function copyFrom(source:TextFormat):void
		{
			font.value = source.font;
			size.value = source.size as Number;
			color.value = source.color as Number;
			bold.value = source.bold;
			italic.value = source.italic;
			underline.value = source.underline;
		}
		
		/**
		 * Copy the linkable properties from this object to the properties of a TextFormat object.
		 * @param source A TextFormat to copy properties from.
		 */
		public function copyTo(destination:TextFormat):void
		{
			destination.font = font.value;
			destination.size = size.value;
			destination.color = color.value;
			destination.bold = bold.value;
			destination.italic = italic.value;
			destination.underline = underline.value;
		}
		
		/**
		 * Copy the linkable properties form this object to the style of a UIComponent.
		 * @param destination A UIComponent whose style will be set.
		 */
		public function copyToStyle(destination:UIComponent):void
		{
			destination.setStyle("fontFamily", font.value);
			destination.setStyle("fontSize", size.value);
			destination.setStyle("color", color.value);
			destination.setStyle("fontWeight", bold.value ? FontWeight.BOLD : FontWeight.NORMAL);
			destination.setStyle("fontStyle", italic.value ? FontPosture.ITALIC : FontPosture.NORMAL);
			destination.setStyle("textDecoration", underline.value ? "underline" : "none");
		}
	}
}

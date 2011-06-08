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
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	
	import mx.rpc.events.ResultEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	
	import weave.api.WeaveAPI;
	import weave.api.services.IURLRequestUtils;

	/**
	 * CSSUtils
	 * 
	 * @author abaumann
	 * @author adufilie
	 */	
	public class CSSUtils
	{
		/**
		 * This function will download a CSS file and load the style information from it.
		 * This function only supports style names that use all lower-case letters.
		 * @param url The URL to a CSS file.
		 */
		public static function loadStyleSheet(url:String):void
		{
			WeaveAPI.URLRequestUtils.getURL(
				new URLRequest(url),
				function(event:ResultEvent, token:Object = null):void
				{
					var styleMap:Object = {};
					var styleName:String;
					// parse each declaration separately to support a selector
					// appearing more than once, accumulating a full list of style properties
					var cssSections:Array = String(event.result).split('}');
					for (var i:int = 0; i < cssSections.length; i++)
					{
						var ss:StyleSheet = new StyleSheet();
						ss.parseCSS(cssSections[i] + '}'); // add in the '}' that was used to split
						for each (styleName in ss.styleNames)
						{
							var styleDecl:CSSStyleDeclaration = styleMap[styleName] || new CSSStyleDeclaration(styleName);
							var style:Object = ss.getStyle(styleName);
							for (var propName:String in style)
							{
								var value:* = style[propName];
								// support for an array of numbers
								if (String(value).indexOf(',') >= 0)
								{
									var array:Array = String(value).split(',');
									for (var j:int = 0; j < array.length; j++)
										array[j] = String(array[j]).replace('#','0x');
									value = array;
								}
								styleDecl.setStyle(propName, value);
							}
							styleMap[styleName] = styleDecl;
						}
					} 
					// apply all styles that appeared in the css file
					for (styleName in styleMap)
						StyleManager.setStyleDeclaration(styleName, styleMap[styleName], true);
				}
			);
		}

		/**
		 * getObjectFromCSS
		 * @param cssProperties A CSS properties string like "first-value: 3; second-value: 6;".
		 * @return An object having properties corresponding to the CSS properties, like {firstValue: 3, secondValue: 6}.
		 */
		public static function getObjectFromCSS(cssProperties:String):Object
		{
			tempStyleSheet.clear();
			tempStyleSheet.parseCSS("temp{"+cssProperties+"}");
			return tempStyleSheet.getStyle("temp");
		}

		/**
		 * getCSSFromObject
		 * @param properties An object having properties like {firstValue: 3, secondValue: 6}.
		 * @return A CSS properties string like "first-value: 3; second-value: 6;"
		 */
		public static function getCSSFromObject(properties:Object):String
		{
			var result:String = "";
			var value:String;
			for (var name:String in properties)
			{
				value = String(properties[name]).replace(escapedCharsRegEx, escapeChar);
				
				if (result != "")
					result += " ";
				if (isCapsForm(name))
					name = capsFormToDashForm(name);
				result += name + ": " + value + ";";
			}
			return result;
		}

		private static const escapedCharsRegEx:RegExp = /[;\;\}\"\\]/;
		private static function escapeChar(matchedString:String, matchIndex:String, i:int):String
		{
			return '\\' + matchedString;
		}


		// tempStyleSheet: reusable temporary object used to reduce GC activity
		private static const tempStyleSheet:StyleSheet = new StyleSheet();
		
		// regular expression to match capital letters
		private static const capsRegEx:RegExp = /[A-Z]/;

		// convert a css string with capitol letters and no spaces (such as borderColor) to no capitals
		// and dashes (such as border-color)
		public static function capsFormToDashForm(propertyString:String):String
		{			
			return propertyString.replace(capsRegEx, capsToDash);	
		}
		
		// return true if this property string contains capital letters
		public static function isCapsForm(propertyString:String):Boolean
		{
			return propertyString.search(capsRegEx) > 0;
		}
		
		// function used in String.replace(..., func)
		private static function capsToDash(matchedString:String, matchIndex:String, i:int):String
		{		
			return "-" + matchedString.toLowerCase();	
		}
		
		
		
		// regular expression to match capital letters
		private static const dashRegEx:RegExp = /(\-.)/;
		
		public static function dashFormToCapsForm(propertyString:String):String
		{
			return propertyString.replace(dashRegEx, dashToCaps);	
		}
		
		// return true if this property string contains capital letters
		public static function isDashForm(propertyString:String):Boolean
		{
			return propertyString.search(dashRegEx) > 0;
		}
		
		// function used in String.replace(..., func)
		private static function dashToCaps(matchedString:String, matchIndex:String, i:int=0, word:String=null):String
		{			
			return matchedString.replace("-", "").toUpperCase();	
		}
	}
}
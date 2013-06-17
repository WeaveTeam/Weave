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

package weave.core
{
	import flash.utils.getQualifiedClassName;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import mx.rpc.xml.SimpleXMLDecoder;
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;
	
	/**
	 * This extension of SimpleXMLDecoder adds support for XML objects encoded with XMLEncoder.
	 * The static methods provided here eliminate the need to create an instance of XMLDecoder.
	 * 
	 * @author adufilie
	 */	
	public class WeaveXMLDecoder extends SimpleXMLDecoder
	{
		/**
		 * This function will include a package in ClassUtils.defaultPackages,
		 * which is consulted when decoding dynamic session states.
		 */
		public static function includePackages(packageOrClass:*, ...others):void
		{
			if (packageOrClass != null)
			{
				if (packageOrClass is Class)
					packageOrClass = getQualifiedClassName(packageOrClass).split("::")[0];
				packageOrClass = String(packageOrClass);
				if (defaultPackages.indexOf(packageOrClass) < 0)
					defaultPackages.push(packageOrClass);
			}
			for each (packageOrClass in others)
				includePackages(packageOrClass);
		}
		/**
		 * The list of packages to check for classes when calling getClassDefinition().
		 */
		internal static const defaultPackages:Array = ["weave.core"];

		/**
		 * This function will check all the packages specified in the static
		 * defaultPackages Array if the specified packageName returns no result.
		 * @param className The name of a class.
		 * @param packageName The package the class exists in.
		 * @return The class definition, or null if the class cannot be resolved.
		 */
		public static function getClassDefinition(className:String, packageName:String = null):Class
		{
			for (var i:int = -1; i < defaultPackages.length; i++)
			{
				var pkg:String = (i < 0) ? packageName : defaultPackages[i];
				var classDef:Class = ClassUtils.getClassDefinition(pkg ? (pkg + "::" + className) : className) as Class;
				if (classDef != null)
					return classDef;
			}

			return null;
		}

		/**
		 * This static function eliminates the need to create an instance of XMLDecoder.
		 * @param xml An XML to decode.
		 * @return A vector of TypedSessionState objects derived from the XML, which is assumed to be encoded properly.
		 */
		public static function decodeDynamicState(xml:XML):Array
		{
			var tempString:String = xml.toXMLString().replace(/(\r\n)|\r/gm, "\n");
			_encodedXML.parseXML(tempString);
			return _xmlDecoder.decodeDynamicStateXMLNode(_encodedXML.firstChild);
		}

		/**
		 * This static function eliminates the need to create an instance of XMLDecoder.
		 * @param xml An XML to decode.
		 * @return An object derived from the XML.
		 */
		public static function decode(xml:XML):Object
		{
			var tempString:String = xml.toXMLString().replace(/(\r\n)|\r/gm, "\n");
			_encodedXML.parseXML(tempString);
			var result:Object = _xmlDecoder.decodeXML(_encodedXML.firstChild);
			return result;
		}

		// reusable objects for static decodeTypedSessionState() method
		private static const _encodedXML:XMLDocument = new XMLDocument();
		private static const _xmlDecoder:WeaveXMLDecoder = new WeaveXMLDecoder();


		/**
		 * end of static section
		 */


		/**
		 * This function modifies the XMLNode.  It should not be used on XMLNode objects you want to keep.
		 * @param dataNode An XMLNode containing typed session state information.
		 * @return An Array of TypedSessionState objects containing the session state information in dataNode.
		 */
		private function decodeDynamicStateXMLNode(dataNode:XMLNode):Array
		{
			var result:Array = [];
//			var objectNames:Object = new Object();
			if (dataNode == null)
				return result;
			for (var i:int = 0; i < dataNode.childNodes.length; i++)
			{
				var childNode:XMLNode = dataNode.childNodes[i];
				var className:String = childNode.nodeName;
				var packageName:String = childNode.attributes["package"] as String;
				// ignore child nodes that do not have tag names (whitespace)
				if (className == null)
					continue;
				var qualifiedClassName:String = getQualifiedClassName(getClassDefinition(className, packageName));
				if (qualifiedClassName == null || qualifiedClassName == "")
				{
					trace("Class not found: " + packageName + "::" + className +" in "+dataNode.toString());
					continue;
				}
				var name:String = childNode.attributes["name"] as String;
				
				if (name == '')
					name = null;
				
				// clear the attributes so they won't be included in the object returned.
				delete childNode.attributes["name"];
				delete childNode.attributes["package"];
				//trace("decoding property of dynamic session state xml:",name,qualifiedClassName,childNode);
				result.push(new DynamicState(name, qualifiedClassName, decodeXML(childNode)));
	    	}
	    	return result;
	    }
		
		/**
		 * This implementation adds support for a special attribute named 'encoding' which tells the decoder how it should be decoded.
		 */	    
		override public function decodeXML(dataNode:XMLNode):Object
		{
			// handle special cases indicated by the 'encoding' attribute
			var encoding:String = String(dataNode.attributes.encoding).toLowerCase();
			if (encoding == WeaveXMLEncoder.JSON_ENCODING)
			{
				var str:String = dataNode.firstChild.nodeValue;
				var object:Object = null;
				var json:Object = ClassUtils.getClassDefinition('JSON');
				if (json)
					object = json.parse(str);
				else
					reportError("JSON encoding is not supported by your version of Flash Player.");
				return object;
			}
			else if (encoding == WeaveXMLEncoder.XML_ENCODING)
			{
				var children:XMLList = XML(dataNode).children();
				if (children.length() == 0)
					return null;
				// return String instead of XML
				return (children[0] as XML).toXMLString();
				
				// make a copy to get rid of the parent node
				//return children[0].copy();
			}
			else if (encoding == WeaveXMLEncoder.CSV_ENCODING || encoding == WeaveXMLEncoder.CSVROW_ENCODING)
			{
				// distinguish between null (<tag/>) and "" (<tag>""</tag>)
				if (dataNode.firstChild == null)
					return null;
				var csvString:String = dataNode.firstChild.nodeValue;
				var rows:Array = WeaveAPI.CSVParser.parseCSV(csvString);
				if (encoding == WeaveXMLEncoder.CSV_ENCODING)
					return rows;
				return rows.length == 0 ? rows : rows[0]; // single row
			}
			else if (ObjectUtil.stringCompare(encoding, WeaveXMLEncoder.DYNAMIC_ENCODING, true) == 0)
			{
				return decodeDynamicStateXMLNode(dataNode);
			}
			else
			{
				return super.decodeXML(dataNode);
			}
		}
	}
}

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

package weave.core
{
	import flash.utils.getQualifiedClassName;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import mx.rpc.xml.SimpleXMLDecoder;
	import mx.utils.ObjectUtil;
	
	import weave.api.core.DynamicState;
	import weave.api.reportError;
	import weave.compiler.Compiler;
	
	/**
	 * This extension of SimpleXMLDecoder adds support for XML objects encoded with XMLEncoder.
	 * The static methods provided here eliminate the need to create an instance of XMLDecoder.
	 * 
	 * @author adufilie
	 */	
	public class WeaveXMLDecoder extends SimpleXMLDecoder
	{
		/**
		 * This function will include a package in Compiler.defaultPackages,
		 * which is consulted when decoding dynamic session states.
		 * @param packageOrClass Either a qualified class name as a String, or a pointer to a Class.
		 * @param others More qualified class names or Class objects.
		 */
		public static function includePackages(packageOrClass:*, ...others):void
		{
			others.unshift(packageOrClass);
			for each (packageOrClass in others)
			{
				if (packageOrClass is Class)
				{
					var qname:String = getQualifiedClassName(packageOrClass);
					if (qname.indexOf('::') < 0)
						continue; // no package
					// get package from qname
					packageOrClass = qname.split('::')[0];
				}
				if (!packageOrClass)
					continue; // no package
				packageOrClass = String(packageOrClass);
				if (packageOrClass && Compiler.defaultPackages.indexOf(packageOrClass) < 0)
					Compiler.defaultPackages.push(packageOrClass);
			}
		}

		/**
		 * This function will check all the packages specified in the static
		 * defaultPackages Array if the specified packageName returns no result.
		 * @param className The name of a class.
		 * @param packageName The package the class exists in.
		 * @return The qualified class name, or null if the class cannot be found.
		 */
		public static function getClassName(className:String, packageName:String = null):String
		{
			// backwards compatibility
			const oldPkg:String = "org.openindicators";
			if (packageName && packageName.substr(0, oldPkg.length) === oldPkg)
				packageName = 'weave' + packageName.substr(oldPkg.length);
			
			var qname:String = packageName + "::" + className;
			if (ClassUtils.hasClassDefinition(qname))
				return qname;
			if (ClassUtils.hasClassDefinition(className))
				return className;
			for each (var pkg:String in Compiler.defaultPackages)
			{
				qname = pkg + "::" + className;
				if (ClassUtils.hasClassDefinition(qname))
					return qname;
			}
			return packageName ? packageName + "::" + className : className;
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
				
				// hack - skip ByteArray nodes
				if (className == "ByteArray")
					continue;
				
				var packageName:String = childNode.attributes["package"] as String;
				// ignore child nodes that do not have tag names (whitespace)
				if (className == null)
					continue;
				var qualifiedClassName:String = getClassName(className, packageName);
				
				var name:String = childNode.attributes["name"] as String;
				if (name == '')
					name = null;
				
				// clear the attributes so they won't be included in the object returned.
				delete childNode.attributes["name"];
				delete childNode.attributes["package"];
				//trace("decoding property of dynamic session state xml:",name,qualifiedClassName,childNode);
				result.push(DynamicState.create(name, qualifiedClassName, decodeXML(childNode)));
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
				var str:String = dataNode.firstChild ? dataNode.firstChild.nodeValue : '';
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

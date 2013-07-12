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
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	
	import mx.rpc.xml.SimpleXMLEncoder;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;
	
	/**
	 * This extension of SimpleXMLEncoder adds support for encoding TypedSessionState objects, XML values, and null values.
	 * The static encode() method eliminates the need to create an instance of XMLEncoder.
	 * 
	 * @author adufilie
	 */	
	public class WeaveXMLEncoder extends SimpleXMLEncoder
	{
		/**
		 * encoding types
		 */
		public static const JSON_ENCODING:String = "json";
		public static const XML_ENCODING:String = "xml";
		public static const CSV_ENCODING:String = "csv";
		public static const CSVROW_ENCODING:String = "csv-row";
		public static const DYNAMIC_ENCODING:String = "dynamic";
		
		/**
		 * This static function eliminates the need to create an instance of XMLEncoder.
		 * @param object An object to encode in xml.
		 * @return The xml encoding of the object.
		 */
		public static function encode(object:Object, tagName:*):XML
		{
			var result:XMLNode = _xmlEncoder.encodeValue(object, QName(tagName), _encodedXML);
			result.removeNode();
			return XML(result);
		}

		// reusable objects for static encode() method
		private static const _encodedXML:XMLDocument = new XMLDocument();
		private static const _xmlEncoder:WeaveXMLEncoder = new WeaveXMLEncoder(_encodedXML);


		/**
		 * end of static section
		 */


	    public function WeaveXMLEncoder(myXML:XMLDocument)
	    {
	        super(myXML);
	    }
		
		override public function encodeValue(obj:Object, qname:QName, parentNode:XMLNode):XMLNode
		{
			if (DynamicState.objectHasProperties(obj) && obj[DynamicState.CLASS_NAME])
			{
				var className:String = obj[DynamicState.CLASS_NAME];
				var objectName:String = obj[DynamicState.OBJECT_NAME];
				var sessionState:Object = obj[DynamicState.SESSION_STATE];
				var qualifiedClassName:Array = className.split("::");
				var typedNode:XMLNode = encodeValue(sessionState, new QName("", qualifiedClassName[1]), parentNode);
				if (objectName != null)
					typedNode = setAttributeAndReplaceNode(typedNode, "name", objectName);
				if (WeaveXMLDecoder.defaultPackages.indexOf(qualifiedClassName[0]) < 0)
					typedNode = setAttributeAndReplaceNode(typedNode, "package", qualifiedClassName[0]);
				return typedNode;
			}
			if (obj is Array)
			{
				var array:Array = obj as Array;
				var encoding:String = DYNAMIC_ENCODING;
				
				// if there is a nested Array or String item in the Array, encode as CSV or CSVROW
				for each (var item:* in array)
				{
					if (item is Array)
					{
						encoding = CSV_ENCODING;
						break;
					}
					if (item is String)
					{
						array = [array];
						encoding = CSVROW_ENCODING;
						break;
					}
				}
				
				var arrayNode:XMLNode = new XMLNode(XMLNodeType.ELEMENT_NODE, qname.localName);
				arrayNode.attributes["encoding"] = encoding;
				
				if (encoding != DYNAMIC_ENCODING) // CSV or CSVROW
				{
					var csvString:String = WeaveAPI.CSVParser.createCSV(array);
					var textNode:XMLNode = new XMLNode(XMLNodeType.TEXT_NODE, csvString);
					arrayNode.appendChild(textNode);
				}
				else
				{
					for (var i:int = 0; i < array.length; i++)
						encodeValue(array[i], null, arrayNode);
				}
				parentNode.appendChild(arrayNode);
				return arrayNode;
			}
			try
			{
				if (obj.hasOwnProperty(LinkableXML.XML_STRING))
					obj = XML(obj[LinkableXML.XML_STRING]);
			}
			catch (e:Error)
			{
				// do nothing if xml parsing fails
			}
			if (obj is XML)
	        {
				// super.encodeValue() does not use the variable name when encoding
				// an XMLDocument, so put the variable name as the tag name here.
				var tag:XML = <tag/>;
				tag["@encoding"] = XML_ENCODING;
				tag.setLocalName(qname.localName);
				tag.appendChild((obj as XML).copy()); // IMPORTANT: append a COPY of the xml.  Do not append the original XML, because that will set its parent!
				obj = new XMLDocument(tag.toXMLString());
	        }
			if (obj == null)
			{
				var nullNode:XMLNode = new XMLNode(XMLNodeType.ELEMENT_NODE, qname.localName);
				parentNode.appendChild(nullNode);
				return nullNode;
			}
			// avoid SimpleXMLEncoder's "INF" representation of Infinity
			if (obj === Number.POSITIVE_INFINITY || obj === Number.NEGATIVE_INFINITY)
				obj = obj.toString();
			
			var node:XMLNode = super.encodeValue(obj, qname, parentNode);
			try
			{
				XML(node);
			}
			catch (e:Error)
			{
				// bad xml
				node.removeNode();
				
				var str:String = '';
				var json:Object = ClassUtils.getClassDefinition('JSON');
				if (json)
					str = json.stringify(obj, null, 4);
				else
					reportError("XMLEncoder: Unable to convert XMLNode to XML: " + node.toString());
				
				node = super.encodeValue(str, qname, parentNode);
				node.attributes["encoding"] = JSON_ENCODING;
			}
			return node;
		}
		
		/**
		 * This function provides a workaround for a bug that occurs when setting an attribute in an XMLNode.
		 * If you try to do node.attributes.attributeName = "value", sometimes node.toString() will
		 * return something like  'attributeName="value" <nodeName />'.
		 * @param node An XMLNode, possibly a child of another XMLNode.  This will be replaced with a new XMLNode.
		 * @param attributeName The name of the attribute to set.
		 * @param attributeValue The new value for the specified attribute.
		 * @return A new XMLNode object containing the new attribute value, made a child of the parent of the given node if applicable.
		 */
		private function setAttributeAndReplaceNode(node:XMLNode, attributeName:String, attributeValue:String):XMLNode
		{
			if (node == null)
				return null;
			var parent:XMLNode = node.parentNode;
			if (parent != null)
				node.removeNode();
			var xml:XML = new XML(node.toString());
			xml["@"+attributeName] = attributeValue;
			node = new XMLDocument(xml.toXMLString()).firstChild;
			if (parent != null)
				parent.appendChild(node);
			return node;
		}
	}
}

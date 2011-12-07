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
	import mx.utils.ObjectUtil;
	
	import weave.api.WeaveAPI;
	import weave.api.reportError;
	
	/**
	 * XMLEncoder
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
		public static const XML_ENCODING:String = "xml";
		//public static const CSV_ENCODING:String = "csv";
		public static const DYNAMIC_ENCODING:String = "dynamic";
		
		/**
		 * encode
		 * This static function eliminates the need to create an instance of XMLEncoder.
		 * @param object An object to encode in xml.
		 * @return The xml encoding of the object.
		 */
		public static function encode(object:Object, tagName:*):XML
		{
			var result:XMLNode = _xmlEncoder.encodeValue(object, QName(tagName), _encodedXML);
			result.removeNode();
			try
			{
				return XML(result);
			}
			catch (e:Error)
			{
				reportError(e, "XMLEncoder: Unable to convert XMLNode to XML: "+ObjectUtil.toString(result));
			}
			return null; // unreachable
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
			var typedState:DynamicState = DynamicState.cast(obj);
			if (typedState)
			{
				if (typedState.className == null)
				{
					reportError("invalid TypedSessionState: class="+typedState.className+", name="+typedState.objectName);
				}
				//trace(ObjectUtil.toString(typedState));
				var qualifiedClassName:Array = typedState.className.split("::");
				var typedNode:XMLNode = encodeValue(typedState.sessionState, new QName("", qualifiedClassName[1]), parentNode);
				if (typedState.objectName != null)
					typedNode = setAttributeAndReplaceNode(typedNode, "name", typedState.objectName);
				if (WeaveXMLDecoder.defaultPackages.indexOf(qualifiedClassName[0]) < 0)
					typedNode = setAttributeAndReplaceNode(typedNode, "package", qualifiedClassName[0]);
				return typedNode;
			}
			/*
			 *
			
			<LinkableVariable name="var">
			<x>3</x>
			</LinkableVariable>
			*/
			if (obj is Array)
			{
				var array:Array = obj as Array;
				var arrayNode:XMLNode = new XMLNode(XMLNodeType.ELEMENT_NODE, qname.localName);
				arrayNode.attributes["encoding"] = DYNAMIC_ENCODING;
				for (var i:int = 0; i < array.length; i++)
					encodeValue(array[i], null, arrayNode);
				parentNode.appendChild(arrayNode);
				return arrayNode;
			}
			/* if (obj is CSV || obj is CSVRow)
			{
				var childNode:XMLNode = super.encodeValue(obj.toString(), qname, parentNode);
				return setAttributeAndReplaceNode(childNode, "encoding", CSV_ENCODING);
			} */
			try
			{
				var str:String = obj as String;
				// if the string looks like it may be XML, attempt to parse it as XML
				if (str && str.charAt(0) == '<' && str.charAt(str.length - 1) == '>')
					obj = XML(str);
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
			
			return super.encodeValue(obj, qname, parentNode);
		}
		
		/**
		 * setAttributeAndReplaceNode
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

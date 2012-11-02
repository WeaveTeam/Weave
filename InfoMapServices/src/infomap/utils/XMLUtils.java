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

package infomap.utils;

import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.io.Writer;
import java.util.List;
import java.util.Vector;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;

import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.w3c.dom.Text;
import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

/**
 * XMLUtils
 * This class contains functions to convert between String and XML Document objects.
 *
 * @author Andy Dufilie
 */

public class XMLUtils
{
	/**
	 * @param str A String that will be inserted into XML.
	 * @return The String with special characters escaped. 
	 */
	public static String escapeSpecialCharacters(String str)
	{
		str = str.replace("&", "&amp;"); // & must be replaced first
		str = str.replace("<", "&lt;");
		str = str.replace(">", "&gt;");
		str = str.replace("\"", "&quot;");
		return str;
	}
	
	/**
	 * getStringFromXPath
	 * Gets a string from an xml.
	 * @param expression The XPath expression to evaluate, returns a string
	 * @return The result of evaluating the given XPath expression.
	 */
	public static String getStringFromXPath(Document doc, XPath xpath, String expression)
	{
		synchronized (xpath)
		{
			try
			{
			    return xpath.evaluate(expression, doc);
			}
			catch (Exception e)
			{
				System.err.println("Error evaluating xpath expression: "+expression);
				e.printStackTrace();
			}
			return "";
		}
	}
	
	/**
	 * getStringListFromXPath
	 * Gets a list of strings from an xml.
	 * @param rootNodeExpression Evaluated on the root of the sqlconfig document to get a single Node.
	 * @param listExpression Evaluated on the Node returned by rootNodeExpression, gets a NodeList.
	 * @return A list of the text contents of the NodeList returned by evaluating the listExpression.
	 */
	public static List<String> getStringListFromXPath(Document doc, XPath xpath, String rootNodeExpression, String listExpression)
	{
		synchronized (xpath)
		{
			try {
				return getStringListFromXPath(
						(Node)xpath.evaluate(rootNodeExpression, doc, XPathConstants.NODE),
						xpath,
						listExpression
					);
			}
			catch (Exception e)
			{
				System.err.println("Error evaluating xpath expression: "+rootNodeExpression);
				e.printStackTrace();
			}
			return new Vector<String>();
		}
	}

	/**
	 * getStringListFromXPath
	 * Gets a list of strings from an xml.
	 * @param rootNode The root node to perform the listExpression on. 
	 * @param listExpression Evaluated on the rootNode, gets a NodeList.
	 * @return A list of the text contents of the nodes returned by evaluating the listExpression.
	 */
	public static List<String> getStringListFromXPath(Node rootNode, XPath xpath, String listExpression)
	{
		synchronized (xpath)
		{
			if (rootNode instanceof Document)
				rootNode = ((Document)rootNode).getDocumentElement();
			Vector<String> result = new Vector<String>();
			try
			{
				NodeList nodes = (NodeList) xpath.evaluate(listExpression, rootNode, XPathConstants.NODESET);
				for (int i = 0; i < nodes.getLength(); i++)
				{
					result.addElement(nodes.item(i).getTextContent());
				}
			}
			catch (Exception e)
			{
				System.err.println("Error evaluating xpath expression: "+listExpression);
				e.printStackTrace();
			}
			return result;
		}
	}

	public static Node insertTextNodeBefore(String text, Node sibling)
	{
		Text newNode = sibling.getOwnerDocument().createTextNode(text);
		return sibling.getParentNode().insertBefore(newNode, sibling);
	}
	public static Node insertTextNodeAfter(String text, Node sibling)
	{
		Text newNode = sibling.getOwnerDocument().createTextNode(text);
		return sibling.getParentNode().insertBefore(newNode, sibling.getNextSibling());
	}
	public static Node appendTextNode(Node parent, String child)
	{
		if (parent == null)
			System.out.println("parent null 0");
		if (parent instanceof Document)
			parent = ((Document)parent).getDocumentElement();
		if (parent == null)
			System.out.println("parent null 1");
		if (parent.getOwnerDocument() == null)
			System.out.println("parent ownerdoc null");
		if (child == null)
			System.out.println("child null");
		Text newNode = parent.getOwnerDocument().createTextNode(child);
		return parent.appendChild(newNode);
	}
	public static Node prependXMLChildFromString(Node parent, String child) throws ParserConfigurationException, SAXException, IOException
	{
		if (parent instanceof Document)
			parent = ((Document)parent).getDocumentElement();
		Document newDoc = getXMLFromString(child);
		Node newNode = parent.getOwnerDocument().importNode(newDoc.getDocumentElement(), true);
		return parent.insertBefore(newNode, parent.getFirstChild());
	}
	public static Node appendXMLChildFromString(Node parent, String child) throws ParserConfigurationException, SAXException, IOException
	{
		if (parent instanceof Document)
			parent = ((Document)parent).getDocumentElement();
		Document newDoc = getXMLFromString(child);
		Node newNode = parent.getOwnerDocument().importNode(newDoc.getDocumentElement(), true);
		return parent.appendChild(newNode);
	}
	private static class SimpleErrorHandler implements ErrorHandler {
	    public void warning(SAXParseException e) throws SAXException { throw e; }
	    public void error(SAXParseException e) throws SAXException { throw e; }
	    public void fatalError(SAXParseException e) throws SAXException { throw e; }
	}
	public static Document getValidatedXMLFromStream(InputStream is) throws ParserConfigurationException, SAXException, IOException
	{
		// http://www.ibm.com/developerworks/library/x-javaxpathapi.html
		DocumentBuilderFactory domFactory = DocumentBuilderFactory.newInstance();
		domFactory.setValidating(true);
		domFactory.setNamespaceAware(true); // never forget this!
		DocumentBuilder builder = domFactory.newDocumentBuilder();
		builder.setErrorHandler(new SimpleErrorHandler());
		Document doc = builder.parse(is);
		return doc;
	}
	public static Document getValidatedXMLFromString(String str) throws ParserConfigurationException, SAXException, IOException
	{
		return getValidatedXMLFromStream(new ByteArrayInputStream(str.getBytes()));
	}
	public static Document getValidatedXMLFromFile(String xmlFile) throws ParserConfigurationException, SAXException, IOException
	{
		String workingPath = System.setProperty("user.dir", new File(xmlFile).getAbsoluteFile().getParent());
		Document doc;
		try
		{
			doc = getValidatedXMLFromStream(new FileInputStream(xmlFile));
		}
		finally
		{
			System.setProperty("user.dir", workingPath);
		}
		return doc;
	}
	public static void validate(Node node, String dtdFilename) throws ParserConfigurationException, SAXException, IOException, TransformerException
	{
		XMLUtils.getValidatedXMLFromString(XMLUtils.getStringFromXML(node, dtdFilename));
	}
	/**
	 * This function does not support validation via DTD.
	 */
	public static Document getXMLFromString(String str) throws ParserConfigurationException, SAXException, IOException
	{
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setNamespaceAware(true);
		DocumentBuilder builder = factory.newDocumentBuilder();
		return builder.parse(new ByteArrayInputStream(str.getBytes()));
	}
	public static String getStringFromXML(Node node) throws TransformerException
	{
		return getStringFromXML(node, null);
	}
	public static String getStringFromXML(Node node, String dtdFilename) throws TransformerException
	{
		StringWriter sw = new StringWriter();
		getStringFromXML(node, dtdFilename, sw);
		return sw.getBuffer().toString();
	}
	public static void getStringFromXML(Node node, String dtdFilename, String outputFileName) throws TransformerException, IOException
	{
		File file = new File(outputFileName);
		if (!file.isFile())
			file.createNewFile();
		BufferedWriter out = new BufferedWriter(new FileWriter(file));
		
		String workingPath = System.setProperty("user.dir", file.getAbsoluteFile().getParent());
		try
		{
			getStringFromXML(node, dtdFilename, out);
		}
		finally
		{
			System.setProperty("user.dir", workingPath);
		}
		
		out.flush();
		out.close();
	}
	public static void getStringFromXML(Node node, String dtdFilename, Writer outputWriter) throws TransformerException
	{
		File dtdFile = null;
		String workingPath = null;
		if (dtdFilename != null)
		{
			dtdFile = new File(dtdFilename);
			workingPath = System.setProperty("user.dir", dtdFile.getAbsoluteFile().getParent());
		}
		try
		{
			if (node instanceof Document)
				node = ((Document)node).getDocumentElement();
			
			TransformerFactory tranFact = TransformerFactory.newInstance();
			Transformer tf = tranFact.newTransformer();
			if (dtdFile != null)
			{
				tf.setOutputProperty(OutputKeys.DOCTYPE_SYSTEM, dtdFile.getName());
				tf.setOutputProperty(OutputKeys.INDENT, "yes");
			}
			
			Source src = new DOMSource(node);
			Result dest = new StreamResult(outputWriter);
			
			tf.transform(src, dest);
		}
		finally
		{
			if (workingPath != null)
				System.setProperty("user.dir", workingPath);
		}
	}
}

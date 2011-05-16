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
package weave.reports;

import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

/**
 * @author Mary Beth
 *
 */
public class ReportDefinition {
	public String reportType = null;
	public String reportDataTable = null;
	public ArrayList<String> indicatorsA = null;
	public ArrayList<String> indicatorsB = null;
	public ArrayList<String> yearsA = null;
	public ArrayList<String> yearsB = null;

	private File _templateFile = null;
	private XPath _xpath = null;
	private Document _doc = null;
	public String _reportDefinitionFileName = null;
	public String _path = null;

	public ReportDefinition(String path, String reportDefinitionFileName)
	{
		_reportDefinitionFileName = reportDefinitionFileName;
		_path = path;
	}
	
	public String readDefinition()
	{
		String result = "";
		try 
		{
			String dir = _path;
			String templateFilePath = String.format("%s\\%s\\%s", dir, WeaveReport.REPORTS_DIRECTORY, _reportDefinitionFileName);
			_templateFile = new File(templateFilePath);
			if (! _templateFile.exists())
			{
				result = WeaveReport.REPORT_FAIL + ": report definition file does not exist " + templateFilePath; 
				return result;
			}
			initXPath();
			reportType = getAttrValue("//weavedata/report", "type");
			reportDataTable = getAttrValue("//weavedata/report/hierarchy/category", "name");
			
			//get the indicators
			NodeList indicatorNodes = getNodes("//weavedata/report/hierarchy/category/attribute");
			indicatorsA = new ArrayList<String>();
			indicatorsB = new ArrayList<String>();
			yearsA = new ArrayList<String>();
			yearsB = new ArrayList<String>();
			
			for (int i = 0; i < indicatorNodes.getLength(); i++)
			{
				Node node = indicatorNodes.item(i);
				String indicatorName = getAttr("name", node);
				String indicatorType = getAttr("type", node);
				String indicatorTime = getAttr("year", node);
				if ((indicatorType != null) && (indicatorType.equals("category")))
				{
					indicatorsA.add(indicatorName);
					if (indicatorTime != null)
						yearsA.add(indicatorTime);
				}
				else
				{
					indicatorsB.add(indicatorName);
					if (indicatorTime != null)
						yearsB.add(indicatorTime);
				}
			}
			result = WeaveReport.REPORT_SUCCESS;
		} 
		catch (Exception e) 
		{
			result = String.format("%s: error reading report definition file %s %s", 
					WeaveReport.REPORT_FAIL, _reportDefinitionFileName, e.getMessage());
		}
		finally
		{
		}
		return result;		
	}
	

	private void initXPath() throws ParserConfigurationException, SAXException, IOException, XPathExpressionException
	{
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setNamespaceAware(true); // never forget this!
		DocumentBuilder builder = factory.newDocumentBuilder();
		_doc = builder.parse(_templateFile);
		XPathFactory xpathFactory = XPathFactory.newInstance();
		_xpath = xpathFactory.newXPath();		
	}
	
	private NodeList getNodes(String path) throws XPathExpressionException
	{
		javax.xml.xpath.XPathExpression expr = _xpath.compile(path);
		Object result = expr.evaluate(_doc, XPathConstants.NODESET);
		NodeList rptNodes = (NodeList) result;
		assertTrue("No nodes found at path: " + path, rptNodes != null);
		assertTrue("No nodes found at path: " + path, rptNodes.getLength() > 0);
		return rptNodes;
	}
	
	private Node getNode(String path) throws XPathExpressionException
	{
		NodeList list = getNodes(path);
		assertTrue("No nodes found at path: " + path, list != null);
		assertTrue("No nodes found at path: " + path, list.getLength() > 0);
		Node node = list.item(0);
		return node;
	}

	private String getAttr(String attr, Node node)
	{
		NamedNodeMap attrs = node.getAttributes();
		assertTrue(attrs != null);
		Node attrNode = attrs.getNamedItem(attr);
		String attrValue = null;
		if (attrNode != null)
			attrValue = attrNode.getNodeValue();
		return attrValue;
	}
	
	private String getAttrValue(String path, String attr) throws XPathExpressionException
	{
		Node node = getNode(path);
		String attrValue = getAttr(attr, node);
		return attrValue;
	}

}

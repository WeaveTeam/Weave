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

package weave.config;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URL;
import java.rmi.RemoteException;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import weave.config.ISQLConfig.AttributeColumnInfo.Metadata;
import weave.utils.FileUtils;
import weave.utils.ListUtils;
import weave.utils.XMLUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

/**
 * SQLConfigXML This class reads an .XML configuration file and provides an
 * interface to retrieve strings.
 * 
 * @author Andy Dufilie
 */

public class SQLConfigXML implements ISQLConfig
{
	public static void copyEmbeddedDTD(String configPath)
	{
		try
		{
			OutputStream out = new FileOutputStream(configPath + '/' + DTD_FILENAME);
			FileUtils.copy(SQLConfigXML.DTD_EMBEDDED.openStream(), out);
		}
		catch (IOException e)
		{
			e.printStackTrace();
		}
	}
	
	public static final String XML_FILENAME = "sqlconfig.xml";
	public static final String DTD_FILENAME = "sqlconfig.dtd";
	public static final URL DTD_EMBEDDED = SQLConfigXML.class.getResource("/weave/config/" + DTD_FILENAME);

	private Document doc = null;
	private XPath xpath = null;

	private long lastModifiedTime = 0L;

	synchronized public long getLastModifiedTime()
	{
		return lastModifiedTime;
	}

	String serverName = "";
	String accessLogConnectionName = "";
	String accessLogSchema = "";
	String accessLogTable = "";

	synchronized public Document getDocument()
	{
		return doc;
	}

	private String fileName = null;

	synchronized public String getFileName()
	{
		return fileName;
	}

	// blank configuration file for in-memory use only
	public SQLConfigXML() throws ParserConfigurationException, SAXException, IOException
	{
		fileName = null;
		lastModifiedTime = 0L;
		doc = XMLUtils.getXMLFromString("<sqlConfig/>");
		XPathFactory factory = XPathFactory.newInstance();
		xpath = factory.newXPath();
	}

	// load xml configuration file
	public SQLConfigXML(String xmlFile) throws Exception
	{
		fileName = xmlFile;
		try
		{
			doc = XMLUtils.getValidatedXMLFromFile(xmlFile);

			// save file modification time
			lastModifiedTime = (new File(xmlFile)).lastModified();
			XPathFactory factory = XPathFactory.newInstance();
			xpath = factory.newXPath();

			serverName = XMLUtils.getStringFromXPath(doc, xpath, "/sqlConfig/@serverName");
			accessLogConnectionName = XMLUtils.getStringFromXPath(doc, xpath, "/sqlConfig/accessLog/@connection");
			accessLogSchema = XMLUtils.getStringFromXPath(doc, xpath, "/sqlConfig/accessLog/@schema");
			accessLogTable = XMLUtils.getStringFromXPath(doc, xpath, "/sqlConfig/accessLog/@table");

			removeDuplicateEntries();
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw e;
		}
	}

	/**
	 * This function removes any child tags having the same tag name and name
	 * attribute value as a tag appearing earlier.
	 */
	synchronized private void removeDuplicateEntries()
	{
		Node parent = doc.getDocumentElement();
		Map<String, String> checklist = new HashMap<String, String>();
		NodeList children = parent.getChildNodes();
		for (int i = 0; i < children.getLength(); i++)
		{
			Node child = children.item(i);
			if (child.getNodeType() != Node.ELEMENT_NODE)
				continue;

			String nameAttr = "";
			try
			{
				nameAttr = child.getAttributes().getNamedItem("name").getTextContent();
			}
			catch (Exception e)
			{
			}

			String key = child.getNodeName() + "/" + nameAttr;
			if (checklist.containsKey(key))
			{
				parent.removeChild(child);
				i--; // decrease i because children NodeList has been updated.
			}
			else
				checklist.put(key, key);
		}
	}

	private Map<String, Map<String, String>> connectionCache = null;
	private Map<String, Map<String, String>> dataTableCache = null;
	private Map<String, Map<String, String>> geometryCollectionCache = null;

	synchronized private void validateCache()
	{
		if (connectionCache == null)
			connectionCache = getInfoCache("/sqlConfig/" + ENTRYTYPE_CONNECTION);
		if (dataTableCache == null)
			dataTableCache = getInfoCache("/sqlConfig/" + ENTRYTYPE_DATATABLE);
		if (geometryCollectionCache == null)
			geometryCollectionCache = getInfoCache("/sqlConfig/" + ENTRYTYPE_GEOMETRYCOLLECTION);
	}

	synchronized private Map<String, Map<String, String>> getInfoCache(String path)
	{
		Map<String, Map<String, String>> cache = new HashMap<String, Map<String, String>>();
		try
		{
			NodeList nodes = (NodeList) xpath.evaluate(path, doc, XPathConstants.NODESET);
			for (int i = 0; i < nodes.getLength(); i++)
			{
				Node node = nodes.item(i);
				NamedNodeMap attrs = node.getAttributes();
				String entryName = attrs.getNamedItem("name").getTextContent();
				Map<String, String> entryInfo = new HashMap<String, String>();
				cache.put(entryName, entryInfo);
				for (int j = 0; j < attrs.getLength(); j++)
				{
					Node attr = attrs.item(j);
					String attrName = attr.getNodeName();
					String attrValue = attr.getTextContent();

					// backwards compatibility with old sqlconfig.xml format --
					// use keyUnitType in place of keyType if specified
					if (attrName.equals("keyUnitType") && attrValue.length() != 0)
						attrName = "keyType";

					entryInfo.put(attrName, attrValue);
				}
				// System.out.println(node.getNodeName()+" "+entryName+entryInfo);
			}
		}
		catch (XPathExpressionException e)
		{
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		return cache;
	}

	synchronized public String getServerName()
	{
		return serverName;
	}

	synchronized public String getAccessLogConnectionName()
	{
		return accessLogConnectionName;
	}

	synchronized public String getAccessLogSchema()
	{
		return accessLogSchema;
	}

	synchronized public String getAccessLogTable()
	{
		return accessLogTable;
	}

	synchronized public void setDatabaseConfigInfo(DatabaseConfigInfo newInfo) throws IOException, ParserConfigurationException, SAXException
	{
		String tag = String.format(
				"\n\t<databaseConfig connection=\"%s\" schema=\"%s\" geometryConfigTable=\"%s\" dataConfigTable=\"%s\"/>\n",
				XMLUtils.escapeSpecialCharacters(newInfo.connection), XMLUtils.escapeSpecialCharacters(newInfo.schema),
				XMLUtils.escapeSpecialCharacters(newInfo.geometryConfigTable),
				XMLUtils.escapeSpecialCharacters(newInfo.dataConfigTable));
		XMLUtils.prependXMLChildFromString(doc, tag);
	}

	/**
	 * Returns null if the config information is not stored in a database (when
	 * it is stored in an XML file).
	 */
	synchronized public DatabaseConfigInfo getDatabaseConfigInfo()
	{
		DatabaseConfigInfo info = new DatabaseConfigInfo();

		String prefix = "/sqlConfig/databaseConfig/@";
		info.connection = XMLUtils.getStringFromXPath(doc, xpath, prefix + "connection");
		info.schema = XMLUtils.getStringFromXPath(doc, xpath, prefix + "schema");
		info.geometryConfigTable = XMLUtils.getStringFromXPath(doc, xpath, prefix + "geometryConfigTable");
		info.dataConfigTable = XMLUtils.getStringFromXPath(doc, xpath, prefix + "dataConfigTable");

		if (info.schema.equals(""))
			return null;
		else
			return info;
	}

	synchronized public void addConnection(ConnectionInfo info)
	{
		Element tag = doc.createElement(ENTRYTYPE_CONNECTION);
		if (info.name != null)
			tag.setAttribute(ConnectionInfo.NAME, info.name);
		if (info.dbms != null)
			tag.setAttribute(ConnectionInfo.DBMS, info.dbms);
		if (info.ip != null)
			tag.setAttribute(ConnectionInfo.IP, info.ip);
		if (info.port != null)
			tag.setAttribute(ConnectionInfo.PORT, info.port);
		if (info.database != null)
			tag.setAttribute(ConnectionInfo.DATABASE, info.database);
		if (info.user != null)
			tag.setAttribute(ConnectionInfo.USER, info.user);
		if (info.pass != null)
			tag.setAttribute(ConnectionInfo.PASS, info.pass);
		if (info.privileges != null)
			tag.setAttribute(ConnectionInfo.PRIVILEGES, info.privileges);

		// add to document with formatting
		Node parent = doc.getDocumentElement();
		XMLUtils.insertTextNodeBefore("\n\t", parent.insertBefore(tag, parent.getFirstChild()));

		connectionCache = null;
		removeDuplicateEntries();
	}

	synchronized public void removeConnection(String name)
	{
		connectionCache = null;
		removeEntry(ENTRYTYPE_CONNECTION, name);
	}

	synchronized public void removeGeometryCollection(String name)
	{
		geometryCollectionCache = null;
		removeEntry(ENTRYTYPE_GEOMETRYCOLLECTION, name);
	}

	synchronized public void removeDataTable(String name)
	{
		dataTableCache = null;
		removeEntry(ENTRYTYPE_DATATABLE, name);
	}

	synchronized private void removeEntry(String entryType, String entryName)
	{
		try
		{
			Node node = (Node) xpath.evaluate(
					String.format("/sqlConfig/%s[@name=\"%s\"]", entryType, XMLUtils.escapeSpecialCharacters(entryName)), doc,
					XPathConstants.NODE);
			if (node == null)
				return;
			node.getParentNode().removeChild(node);
		}
		catch (XPathExpressionException e)
		{
			e.printStackTrace();
		}
	}

	synchronized public List<String> getConnectionNames(String connectionName)
	{
		// TODO handle connectionName
		validateCache();
		return Arrays.asList(connectionCache.keySet().toArray(new String[0]));
	}

	// list all geometryCollections
	synchronized public List<String> getGeometryCollectionNames(String connectionName)
	{
		// TODO handle connectionName
		validateCache();
		List<String> names = Arrays.asList(geometryCollectionCache.keySet().toArray(new String[0]));
		Collections.sort(names, String.CASE_INSENSITIVE_ORDER);
		return names;
	}

	// list all dataTables
	synchronized public List<String> getDataTableNames(String connectionName)
	{
		// TODO handle connectionName
		validateCache();
		List<String> names = Arrays.asList(dataTableCache.keySet().toArray(new String[0]));
		Collections.sort(names, String.CASE_INSENSITIVE_ORDER);
		return names;
	}

	synchronized public ConnectionInfo getConnectionInfo(String connectionName) throws RemoteException
	{
		validateCache();
		
		Map<String, String> map = connectionCache.get(connectionName);
		if (map == null)
			throw new RemoteException(String.format("Connection named \"%s\" does not exist.", connectionName));

		// System.out.println("connection "+connectionName+map);
		ConnectionInfo info = new ConnectionInfo();
		info.name = connectionName;
		info.dbms = getNonNullValue(map, ConnectionInfo.DBMS);
		info.ip = getNonNullValue(map, ConnectionInfo.IP);
		info.port = getNonNullValue(map, ConnectionInfo.PORT);
		info.database = getNonNullValue(map, ConnectionInfo.DATABASE);
		info.user = getNonNullValue(map, ConnectionInfo.USER);
		info.pass = getNonNullValue(map, ConnectionInfo.PASS);
		info.privileges = getNonNullValue(map, ConnectionInfo.PRIVILEGES);
		return info;
	}

	synchronized public GeometryCollectionInfo getGeometryCollectionInfo(String geometryCollectionName, String connectionName)
	{
		validateCache();
		// TODO: handle connectionName
		try
		{
			Map<String, String> map = geometryCollectionCache.get(geometryCollectionName);
			if (map == null)
			{
				System.out.println(String.format("Geometry collection named \"%s\" does not exist.", geometryCollectionName));
				return null;
			}

			// System.out.println("geometryCollection "+geometryCollectionName+map);
			GeometryCollectionInfo info = new GeometryCollectionInfo();
			info.name = geometryCollectionName;
			info.connection = getNonNullValue(map, GeometryCollectionInfo.CONNECTION);
			info.schema = getNonNullValue(map, GeometryCollectionInfo.SCHEMA);
			info.tablePrefix = getNonNullValue(map, GeometryCollectionInfo.TABLEPREFIX);
			info.keyType = getNonNullValue(map, GeometryCollectionInfo.KEYTYPE);
			info.projection = getNonNullValue(map, GeometryCollectionInfo.PROJECTION);
			info.importNotes = getNonNullValue(map, GeometryCollectionInfo.IMPORTNOTES);
			return info;
		}
		catch (Exception e)
		{
			e.printStackTrace();
			return null;
		}
	}

	private static String getNonNullValue(Map<String, String> map, String key)
	{
		if (map == null)
			return "";
		String value = map.get(key);
		if (value == null)
			return "";
		return value;
	}

	synchronized public void addGeometryCollection(GeometryCollectionInfo info)
	{
		Element tag = doc.createElement(ENTRYTYPE_GEOMETRYCOLLECTION);
		if (info.name != null)
			tag.setAttribute(GeometryCollectionInfo.NAME, info.name);
		if (info.connection != null)
			tag.setAttribute(GeometryCollectionInfo.CONNECTION, info.connection);
		if (info.schema != null)
			tag.setAttribute(GeometryCollectionInfo.SCHEMA, info.schema);
		if (info.tablePrefix != null)
			tag.setAttribute(GeometryCollectionInfo.TABLEPREFIX, info.tablePrefix);
		if (info.keyType != null)
			tag.setAttribute(GeometryCollectionInfo.KEYTYPE, info.keyType);
		if (info.projection != null)
			tag.setAttribute(GeometryCollectionInfo.PROJECTION, info.projection);
		if (info.importNotes != null)
			tag.setAttribute(GeometryCollectionInfo.IMPORTNOTES, info.importNotes);

		// add to document with formatting
		Node parent = doc.getDocumentElement();
		XMLUtils.insertTextNodeBefore("\n\t", parent.insertBefore(tag, parent.getFirstChild()));

		geometryCollectionCache = null;
		removeDuplicateEntries();
	}

	synchronized public void addAttributeColumn(AttributeColumnInfo info)
	{
		try
		{
			// make a copy of the metadata
			Map<String, String> metadata = new HashMap<String, String>(info.metadata);
			String dataTableName = metadata.remove(Metadata.DATATABLE.toString());
			if (dataTableName == null)
				return;
			// create dataTable tag if it doesn't exist
			if (ListUtils.findString(dataTableName, getDataTableNames(null)) < 0)
			{
				// create dataTable tag with formatting
				Element tag = doc.createElement(ENTRYTYPE_DATATABLE);
				tag.setAttribute("name", dataTableName);
				XMLUtils.appendTextNode(tag, "\n\t");

				// add to document with formatting
				Node parent = doc.getDocumentElement();
				XMLUtils.insertTextNodeBefore("\n\t", parent.insertBefore(tag, parent.getFirstChild()));

				dataTableCache = null;
				removeDuplicateEntries();
			}

			// get dataTable tag
			String query = String.format("/sqlConfig/dataTable[@name=\"%s\"]", XMLUtils.escapeSpecialCharacters(dataTableName));
			Node dataTableNode = (Node) xpath.evaluate(query, doc, XPathConstants.NODE);
			if (dataTableNode == null)
			{
				throw new RuntimeException(String.format("Unable to find dataTable entry: \"%s\"", dataTableName));
			}
			// create new attributeColumn tag
			Element tag = doc.createElement("attributeColumn");

			// set sql properties
			tag.setAttribute("connection", info.connection);
			tag.setAttribute("dataWithKeysQuery", info.sqlQuery);
			// set metadata properties
			for (Metadata property : Metadata.values())
				if (metadata.containsKey(property.toString()))
					tag.setAttribute(property.toString(), metadata.get(property.toString()));

			// add to dataTable node with formatting
			XMLUtils.appendTextNode(dataTableNode, "\t");
			dataTableNode.appendChild(tag);
			XMLUtils.appendTextNode(dataTableNode, "\n\t");

			removeDuplicateEntries();
		}
		catch (XPathExpressionException e)
		{
			e.printStackTrace();
		}
	}

	synchronized public List<AttributeColumnInfo> getAttributeColumnInfo(String dataTableName)
	{
		Map<String, String> metadataQueryParams = new HashMap<String, String>();
		metadataQueryParams.put(Metadata.DATATABLE.toString(), dataTableName);
		return getAttributeColumnInfo(metadataQueryParams);
	}

	synchronized private NodeList getAttributeColumnNodes(Map<String, String> metadataQueryParams)
	{
		try
		{
			// make a copy of the metadata
			Map<String, String> metadata = new HashMap<String, String>(metadataQueryParams);
			// pull out dataTableName
			String dataTableName = metadata.remove(Metadata.DATATABLE.toString());

			// generate table params
			String tableParams = "";
			if (dataTableName != null)
				tableParams = String.format("[@name=\"%s\"]", XMLUtils.escapeSpecialCharacters(dataTableName));

			// generate column params
			String columnParams = "";
			if (metadata != null)
			{
				for (String key : metadata.keySet())
				{
					if (columnParams.length() > 0)
						columnParams += " and ";
					String escapedKey = XMLUtils.escapeSpecialCharacters(key);
					String escapedValue = XMLUtils.escapeSpecialCharacters(metadata.get(key));
					columnParams += String.format("@%s=\"%s\"", escapedKey, escapedValue);
				}
			}
			if (columnParams.length() > 0)
				columnParams = "[" + columnParams + "]";
			// get column tags
			String path = String.format("/sqlConfig/dataTable%s/attributeColumn%s", tableParams, columnParams);
			// System.out.println("path "+path);
			NodeList nodes = (NodeList) xpath.evaluate(path, doc, XPathConstants.NODESET);
			return nodes;
		}
		catch (XPathExpressionException e)
		{
			e.printStackTrace();
		}
		return null;
	}

	synchronized public List<AttributeColumnInfo> getAttributeColumnInfo(Map<String, String> metadataQueryParams)
	{
		validateCache();
		NodeList columnNodes = getAttributeColumnNodes(metadataQueryParams);
		List<AttributeColumnInfo> columnInfoList = new Vector<AttributeColumnInfo>(columnNodes.getLength());
		// copy tag info
		for (int i = 0; i < columnNodes.getLength(); i++)
		{
			Node columnNode = columnNodes.item(i);
			NamedNodeMap columnNodeProperties = columnNode.getAttributes();

			// get dataTable name
			Node tableNameProperty = columnNodeProperties.getNamedItem(Metadata.DATATABLE.toString());
			String tableName = "";
			if (tableNameProperty == null || tableNameProperty.getTextContent().length() == 0)
				tableNameProperty = columnNode.getParentNode().getAttributes().getNamedItem("name");
			if (tableNameProperty != null)
				tableName = tableNameProperty.getTextContent();

			// get dataTable properties
			Map<String, String> tableProperties = dataTableCache.get(tableName);

			// get connection (first from column node, then from dataTable node
			// if missing)
			String connection = getCascadedAttribute(columnNodeProperties, "connection", tableProperties, "connection");
			String sqlQuery = columnNodeProperties.getNamedItem("dataWithKeysQuery").getTextContent();
			// get attributeColumn metadata properties
			Map<String, String> columnMetadataResult = new HashMap<String, String>();
			columnMetadataResult.put(Metadata.DATATABLE.toString(), tableName);
			for (Metadata property : Metadata.values())
			{
				if (property == Metadata.DATATABLE)
					continue;
				String propertyName = property.toString();
				String parentPropertyName = propertyName;
				String value = getCascadedAttribute(columnNodeProperties, propertyName, tableProperties, parentPropertyName);
				// if keyType missing, get it from geometryCollection
				if (property == Metadata.KEYTYPE && value.length() == 0)
				{
					// if keyType still missing, grab keyType from the
					// geometryCollection.
					if (value.length() == 0)
					{
						String geomAttr = Metadata.GEOMETRYCOLLECTION.toString();
						String geomName = getCascadedAttribute(columnNodeProperties, geomAttr, tableProperties, geomAttr);
						if (geometryCollectionCache.containsKey(geomName))
							value = geometryCollectionCache.get(geomName).get(GeometryCollectionInfo.KEYTYPE);
					}
				}
				// save metadata value in result
				columnMetadataResult.put(property.toString(), value);
			}
			// System.out.println(resultMetadata);
			columnInfoList.add(new AttributeColumnInfo(connection, sqlQuery, columnMetadataResult));
		}
		return columnInfoList;
	}

	private String getCascadedAttribute(NamedNodeMap attrMap, String attrName, Map<String, String> parentAttrMap, String parentAttrName)
	{
		String result = "";
		// try on node itself
		try
		{
			result = attrMap.getNamedItem(attrName).getTextContent();
		}
		catch (Exception e)
		{
		}

		if (result == null || result.length() == 0)
		{
			// if attr missing on node, try its parent
			result = parentAttrMap.get(parentAttrName);
		}

		if (result == null)
		{
			result = "";
		}

		return result;
	}

	// </dataTable>
	synchronized public List<String> getKeyTypes()
	{
		validateCache();

		Set<String> uniqueValues = new HashSet<String>();
		for (String name : dataTableCache.keySet())
			uniqueValues.add(dataTableCache.get(name).get("keyType"));
		for (String name : geometryCollectionCache.keySet())
			uniqueValues.add(geometryCollectionCache.get(name).get("keyType"));

		Vector<String> result = new Vector<String>(uniqueValues);
		Collections.sort(result, String.CASE_INSENSITIVE_ORDER);
		return result;
	}

	synchronized public String getConfigEntryXML(EntryInfo entryInfo)
	{
		return getConfigEntryXML(entryInfo.type, entryInfo.name);
	}

	synchronized public String getConfigEntryXML(String entryType, String entryName)
	{
		Node node;
		try
		{
			String escapedEntryName = XMLUtils.escapeSpecialCharacters(entryName);
			node = (Node) xpath.evaluate(String.format("/sqlConfig/%s[@name=\"%s\"]", entryType, escapedEntryName), doc,
					XPathConstants.NODE);
			return XMLUtils.getStringFromXML(node);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			return "";
		}
	}

	// returns info about the entry that was overwritten
	synchronized public EntryInfo overwriteConfigEntryXML(String entryXML) throws ParserConfigurationException, SAXException, IOException, TransformerException
	{
		// add node with formatting
		System.out.println("NEW ENTRY: " + entryXML);
		Node newNode = XMLUtils.prependXMLChildFromString(doc, entryXML);
		Node nameNode = newNode.getAttributes().getNamedItem("name");
		EntryInfo info = new EntryInfo(newNode.getNodeName(), nameNode == null ? "" : nameNode.getTextContent());
		XMLUtils.insertTextNodeBefore("\t", newNode);
		XMLUtils.insertTextNodeAfter("\n\t", newNode);

		// verify that the xml still conforms to the dtd
		XMLUtils.validate(doc, new File(fileName).getAbsoluteFile().getParent() + '/' + DTD_FILENAME);

		if (info.type.equals(ENTRYTYPE_CONNECTION))
			connectionCache = null;
		if (info.type.equals(ENTRYTYPE_GEOMETRYCOLLECTION))
			geometryCollectionCache = null;
		if (info.type.equals(ENTRYTYPE_DATATABLE))
			dataTableCache = null;
		removeDuplicateEntries();

		return info;
	}

	public class EntryInfo
	{
		public EntryInfo(String type, String name)
		{
			this.type = type;
			this.name = name;
		}

		public String type;
		public String name;
	}
	// </sqlConfig>
}

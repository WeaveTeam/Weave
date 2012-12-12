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
import java.net.URL;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import weave.utils.FileUtils;
import weave.utils.MapUtils;
import weave.utils.ProgressManager;
import weave.utils.SQLUtils;
import weave.utils.XMLUtils;

/**
 * ISQLConfig An interface to retrieve strings from a configuration file.
 * 
 * @author Andy Dufilie
 */
public class ConnectionConfig
{
	public static final String XML_FILENAME = "sqlconfig.xml";
	public static final String DTD_FILENAME = "sqlconfig.dtd";
	public static final URL DTD_EMBEDDED = ConnectionConfig.class.getResource("/weave/config/" + DTD_FILENAME);
	
	public ConnectionConfig(File file)
	{
		_file = file;
	}
	
	private boolean _temporaryDataConfigPermission = false;
	private boolean _oldVersionDetected = false;
	private long _lastMod = 0L;
	private File _file;
	private DatabaseConfigInfo _databaseConfigInfo;
	private Map<String,ConnectionInfo> _connectionInfoMap = new HashMap<String,ConnectionInfo>();
	private Connection _adminConnection = null;
	
	public long getLastModified() throws RemoteException
	{
		_load();
		return _lastMod;
	}
	
	/**
	 * This function must be called before making any modifications to the config.
	 */
	@SuppressWarnings("deprecation")
	public DataConfig initializeNewDataConfig(ProgressManager progress) throws RemoteException
	{
		if (migrationPending())
		{
			try
			{
				DataConfig dataConfig;
				
				synchronized (this)
				{
					// momentarily give DataConfig permission to initialize
					_temporaryDataConfigPermission = true;
					dataConfig = new DataConfig(this);
					_temporaryDataConfigPermission = false;
				}
				
				DeprecatedConfig.migrate(this, dataConfig, progress);
				
				// after everything has successfully been migrated, save under new connection config format
				_oldVersionDetected = false;
				_save();
				return dataConfig;
			}
			finally
			{
				_temporaryDataConfigPermission = false;
			}
		}
		else
		{
			return new DataConfig(this);
		}
	}
	
	public boolean allowDataConfigInitialize() throws RemoteException
	{
		return _temporaryDataConfigPermission || !migrationPending();
	}
	
	public boolean migrationPending() throws RemoteException
	{
		_load();
		return _oldVersionDetected;
	}

	/**
	 * This function gets a connection to the database containing the configuration information. This function will reuse a previously created
	 * Connection if it is still valid.
	 * 
	 * @return A Connection to the SQL database.
	 */
	public Connection getAdminConnection() throws RemoteException, SQLException
	{
		_load();
		
		// if old version is detected, don't run test query
		boolean isValid = _oldVersionDetected ? _adminConnection != null : SQLUtils.connectionIsValid(_adminConnection);
		// use previous connection if still valid
		if (isValid)
			return _adminConnection;
		
		DatabaseConfigInfo dbInfo = _databaseConfigInfo;

		if (dbInfo == null)
			throw new RemoteException("databaseConfig has not been specified.");
		
		if (dbInfo.schema == null || dbInfo.schema.length() == 0)
			throw new RemoteException("databaseConfig schema has not been specified.");
		
		ConnectionInfo connInfo = getConnectionInfo(dbInfo.connection);
		
		if (connInfo == null)
			throw new RemoteException(String.format("Connection named \"%s\" doead not exist.", dbInfo.connection));
		
		return _adminConnection = connInfo.getConnection();
	}
	
	private void resetAdminConnection()
	{
		SQLUtils.cleanup(_adminConnection);
		_adminConnection = null;
	}
	
	private void _setXMLAttributes(Element tag, Map<String,String> attrs)
	{
		for (Entry<String,String> entry : attrs.entrySet())
			tag.setAttribute(entry.getKey(), entry.getValue());
	}
	
	private Map<String,String> _getXMLAttributes(Node node)
	{
		NamedNodeMap attrs = node.getAttributes();
		Map<String, String> attrMap = new HashMap<String, String>();
		for (int j = 0; j < attrs.getLength(); j++)
		{
			Node attr = attrs.item(j);
			String attrName = attr.getNodeName();
			String attrValue = attr.getTextContent();
			attrMap.put(attrName, attrValue);
		}
		return attrMap;
	}
	
	private void _load() throws RemoteException
	{
		long lastMod = _file.lastModified();
		if (_lastMod != lastMod)
		{
			try
			{
				// read file as XML
				Document doc = XMLUtils.getValidatedXMLFromFile(_file);
				XPath xpath = XPathFactory.newInstance().newXPath();
				
				// read all ConnectionInfo
				Map<String,ConnectionInfo> connectionInfoMap = new HashMap<String,ConnectionInfo>();
				NodeList nodes = (NodeList) xpath.evaluate("/sqlConfig/connection", doc, XPathConstants.NODESET);
				for (int i = 0; i < nodes.getLength(); i++)
				{
					ConnectionInfo info = new ConnectionInfo();
					info.copyFrom(_getXMLAttributes(nodes.item(i)));
					connectionInfoMap.put(info.name, info);
				}
				
				// read DatabaseConfigInfo
				Node node = (Node) xpath.evaluate("/sqlConfig/databaseConfig", doc, XPathConstants.NODE);
				DatabaseConfigInfo databaseConfigInfo = new DatabaseConfigInfo();
				Map<String,String> attrs = _getXMLAttributes(node);
				databaseConfigInfo.copyFrom(attrs);
				
				// detect old version
				_oldVersionDetected = databaseConfigInfo.dataConfigTable != null;
				
				// commit values only after everything succeeds
				_connectionInfoMap = connectionInfoMap;
				_databaseConfigInfo = databaseConfigInfo;
				_lastMod = lastMod;
				// reset admin connection when config changes
				resetAdminConnection();
			}
			catch (Exception e)
			{
				throw new RemoteException("Unable to load connection config file", e);
			}
		}
	}
	
	private void _save() throws RemoteException
	{
		// we can't save until the old data has been migrated
		if (_oldVersionDetected)
			throw new RemoteException("Unable to save connection config because old data hasn't been migrated yet.");
		
		try
		{
			// reset admin connection when config changes
			resetAdminConnection();
			
			Document doc = XMLUtils.getXMLFromString("<sqlConfig/>");
			Node rootNode = doc.getDocumentElement();

			// write DatabaseConfigInfo
			Element element = doc.createElement("databaseConfig");
			_setXMLAttributes(element, _databaseConfigInfo.getPropertyMap());
			rootNode.appendChild(element);

			// write all ConnectionInfo, sorted by name
			List<String> names = new LinkedList<String>(getConnectionInfoNames());
			Collections.sort(names);
			for (String name : names)
			{
				element = doc.createElement("connection");
				_setXMLAttributes(element, _connectionInfoMap.get(name).getPropertyMap());
				rootNode.appendChild(element);
			}
			
			// get file paths
			String dtdPath = _file.getParentFile().getAbsolutePath() + '/' + DTD_FILENAME;
			String filePath = _file.getAbsolutePath();
			
			if (_oldVersionDetected)
			{
				// save backup of old files
				FileUtils.copy(dtdPath, dtdPath + ".old");
				FileUtils.copy(filePath, filePath + ".old");
				
				_oldVersionDetected = false;
			}
			
			// save new files
			FileUtils.copy(DTD_EMBEDDED.openStream(), new FileOutputStream(dtdPath));
			XMLUtils.getStringFromXML(rootNode, DTD_FILENAME, filePath);
		}
		catch (Exception e)
		{
			throw new RemoteException("Unable to save connection config file", e);
		}
	}
	
	public ConnectionInfo getConnectionInfo(String name) throws RemoteException
	{
		_load();
		ConnectionInfo original = _connectionInfoMap.get(name);
		if (original == null)
			return null;
		ConnectionInfo copy = new ConnectionInfo();
		copy.copyFrom(original);
		return copy;
	}
	public void saveConnectionInfo(ConnectionInfo connectionInfo) throws RemoteException
	{
		connectionInfo.validate();
		
		_load();
		ConnectionInfo copy = new ConnectionInfo();
		copy.copyFrom(connectionInfo);
		_connectionInfoMap.put(connectionInfo.name, copy);
		_save();
	}
	public void removeConnectionInfo(String name) throws RemoteException
	{
		_load();
		_connectionInfoMap.remove(name);
		_save();
	}
	public Collection<String> getConnectionInfoNames() throws RemoteException
	{
		_load();
		return _connectionInfoMap.keySet();
	}
	public DatabaseConfigInfo getDatabaseConfigInfo() throws RemoteException
	{
		_load();
		if (_databaseConfigInfo == null)
			return null;
		DatabaseConfigInfo copy = new DatabaseConfigInfo();
		copy.copyFrom(_databaseConfigInfo);
		return copy;
	}
	public void setDatabaseConfigInfo(DatabaseConfigInfo info) throws RemoteException
	{
		if (!_connectionInfoMap.containsKey(info.connection))
			throw new RemoteException(String.format("Connection named \"%s\" does not exist.", info.connection));
		if (info.schema == null || info.schema.length() == 0)
			throw new RemoteException("Schema must be specified.");
		
		_load();
		if (_databaseConfigInfo == null)
			_databaseConfigInfo = new DatabaseConfigInfo();
		_databaseConfigInfo.copyFrom(info);
		_save();
	}
    
	/**
	 * This class contains all the information related to where the
	 * configuration should be stored in a database.
	 */
	static public class DatabaseConfigInfo
	{
		public DatabaseConfigInfo()
		{
		}
		
		public void copyFrom(Map<String,String> other)
		{
			this.connection = other.get("connection");
			this.schema = other.get("schema");
			geometryConfigTable = other.get("geometryConfigTable");
			dataConfigTable = other.get("dataConfigTable");
		}
		public void copyFrom(DatabaseConfigInfo other)
		{
			this.connection = other.connection;
			this.schema = other.schema;
			this.geometryConfigTable = other.geometryConfigTable;
			this.dataConfigTable = other.dataConfigTable;
		}
		public Map<String,String> getPropertyMap()
		{
			return MapUtils.fromPairs(
				"connection", connection,
				"schema", schema
			);
		}
		
		/**
		 * The name of the connection (in the xml configuration) which allows
		 * connection to the database which contains the configurations
		 * (columns->SQL queries, and geometry collections).
		 */
		public String connection;
		public String schema;
		
		@Deprecated public String geometryConfigTable;
		@Deprecated public String dataConfigTable;
	}

	/**
	 * This class contains all the information needed to connect to a SQL
	 * database.
	 */
	static public class ConnectionInfo
	{
		public ConnectionInfo()
		{
		}
		
		private boolean isEmpty(String str) { return str == null || str.length() == 0; }
		
		public void validate() throws RemoteException
		{
			String missingField = null;
			if (isEmpty(name))
				missingField = "name";
			else if (isEmpty(dbms))
				missingField = "dbms";
			else if (isEmpty(pass))
				missingField = "password";
			else if (isEmpty(connectString))
				missingField = "connectString";
			if (missingField != null)
				throw new RemoteException(String.format("Connection %s must be specified", missingField));
		}

		public void copyFrom(Map<String,String> other)
		{
			this.name = other.get("name");
			this.dbms = other.get("dbms");
			this.pass = other.get("pass");
			this.folderName = other.get("folderName");
			this.connectString = other.get("connectString");
			this.is_superuser = other.get("is_superuser").equalsIgnoreCase("true");
			
			// backwards compatibility
			if (connectString == null || connectString.length() == 0)
			{
				String ip = other.get("ip");
				String port = other.get("port");
				String database = other.get("database");
				String user = other.get("user");
				this.connectString = SQLUtils.getConnectString(dbms, ip, port, database, user, pass);
			}
		}
		public void copyFrom(ConnectionInfo other)
		{
			this.name = other.name;
			this.dbms = other.dbms;
			this.pass = other.pass;
			this.folderName = other.folderName;
			this.connectString = other.connectString;
			this.is_superuser = other.is_superuser;
		}
		public Map<String,String> getPropertyMap()
		{
			return MapUtils.fromPairs(
				"name", name,
				"dbms", dbms,
				"pass", pass,
				"folderName", folderName,
				"connectString", connectString,
				"is_superuser", is_superuser ? "true" : "false"
			);
		}
		
		public String name = "";
		public String dbms = "";
		public String pass = "";
		public String folderName = "";
		public String connectString = "";
		public boolean is_superuser = false;

		public Connection getStaticReadOnlyConnection() throws RemoteException
		{
			return SQLUtils.getStaticReadOnlyConnection(SQLUtils.getDriver(dbms), connectString);
		}

		public Connection getConnection() throws RemoteException
		{
			return SQLUtils.getConnection(SQLUtils.getDriver(dbms), connectString);
		}
	}
}

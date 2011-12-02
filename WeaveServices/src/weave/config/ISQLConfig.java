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

import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.Types;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.w3c.dom.Document;

import weave.utils.ListUtils;
import weave.utils.SQLUtils;

/**
 * ISQLConfig An interface to retrieve strings from a configuration file. TODO:
 * needs documentation
 * 
 * @author Andy Dufilie
 */
public interface ISQLConfig
{
	/**
	 * Gets the entire ISQLconfig content as a DOM structure. When
	 * DatabaseConfig is used, this DOM only contains connection information.
	 * When SQLConfigXML is used, this returns the connection information as
	 * well as column configurations.
	 */
	Document getDocument() throws RemoteException;

	/**
	 * Gets the display name of for the server in which this configuration
	 * lives.
	 */
	@Deprecated
	String getServerName() throws RemoteException;

	/**
	 * Returns the name of the SQL table which stores the access log.
	 */
	@Deprecated
	String getAccessLogConnectionName() throws RemoteException;

	/**
	 * Returns the name of the SQL table which stores the access log.
	 */
	@Deprecated
	String getAccessLogSchema() throws RemoteException;

	/**
	 * Returns the name of the SQL table which stores the access log.
	 */
	@Deprecated
	String getAccessLogTable() throws RemoteException;

	/**
	 * Lists all keyTypes stored in this configuration
	 */
	List<String> getKeyTypes() throws RemoteException;

	/**
	 * Gets the names of all connections in this configuration
	 */
	List<String> getConnectionNames() throws RemoteException;

	/**
	 * Gets the names of all geometry collections in this configuration
	 * @param connectionName A connection used as a filter, or null for no filter.
	 */
	@Deprecated
	List<String> getGeometryCollectionNames(String connectionName) throws RemoteException;

	/**
	 * Gets the names of all data tables in this configuration
	 * @param connectionName A connection used as a filter, or null for no filter.
	 */
	List<String> getDataTableNames(String connectionName) throws RemoteException;

	/**
	 * Removes the connection with the given name from this configuration
	 */
	void removeConnection(String name) throws RemoteException;

	/**
	 * Removes the geometry collection with the given name from this
	 * configuration
	 */
	@Deprecated
	void removeGeometryCollection(String name) throws RemoteException;

	/**
	 * Removes the data table with the given name from this configuration
	 */
	void removeDataTable(String name) throws RemoteException;

	/**
	 * This adds a connection to the configuration.
	 * 
	 * @param connectionInfo
	 *            The definition of the connection entry.
	 */
	void addConnection(ConnectionInfo connectionInfo) throws RemoteException;

	/**
	 * Looks up a connection in this configuration by name.
	 * 
	 * @param connectionName
	 *            The name of a connection configuration entry.
	 * @return An object containing the configuration for the specified
	 *         connection.
	 * @throws RemoteException
	 *             if the info could not be retrieved.
	 */
	ConnectionInfo getConnectionInfo(String connectionName) throws RemoteException;

	/**
	 * This adds a geometryCollection tag to the configuration.
	 * 
	 * @param geometryCollectionInfo
	 *            The definition of the geometryCollection entry.
	 */
	@Deprecated
	void addGeometryCollection(GeometryCollectionInfo geometryCollectionInfo) throws RemoteException;

	/**
	 * Looks up a geometry collection in this configuration by name
	 * 
	 * @param geometryCollection
	 *            The name of a geometryCollection configuration entry.
	 * @return An object containing the configuration for the specified
	 *         geometryCollection.
	 * @throws RemoteException
	 *             if the info could not be retrieved.
	 */
	GeometryCollectionInfo getGeometryCollectionInfo(String geometryCollectionName) throws RemoteException;

	/**
	 * This adds an attributeColumn tag to a dataTable tag.
	 * 
	 * @param attributeColumnInfo
	 *            The definition of the attributeColumn entry.
	 */
	void addAttributeColumn(AttributeColumnInfo attributeColumnInfo) throws RemoteException;

	/**
	 * list all attributeColumn entries in a dataTable matching given metadata
	 * values. This metadata may include "name" and "dataTable".
	 */
	List<AttributeColumnInfo> getAttributeColumnInfo(Map<String, String> metadataQueryParams) throws RemoteException;

	/**
	 * Looks up the list of all attributeColumn entries in a dataTable by name.
	 * This is a shortcut for calling getAttributeColumnInfo(Map<String,String>)
	 * with a dataTable name specified.
	 */
	@Deprecated
	List<AttributeColumnInfo> getAttributeColumnInfo(String dataTableName) throws RemoteException;

	
	/**
	 * @return true if this ISQLConfig object is successfully connected to the database using DatabaseConfigInfo.
	 */
	boolean isConnectedToDatabase();
	
	/**
	 * @return A DatabaseConfigInfo object, or null if this ISQLConfig is not configured to store info in a database.
	 */
	DatabaseConfigInfo getDatabaseConfigInfo() throws RemoteException;

	/**
	 * This class contains all the information related to where the
	 * configuration should be stored in a database.
	 */
	static public class DatabaseConfigInfo
	{
		public DatabaseConfigInfo()
		{
		}

		/**
		 * The name of the connection (in the xml configuration) which allows
		 * connection to the database which contains the configurations
		 * (columns->SQL queries, and geometry collections).
		 */
		public String connection;
		public String schema;
		
		public String geometryConfigTable, dataConfigTable; // not used in new implementation
		
		public String dataCategoryTable; // to be used with server-side hierarchy
	}

	/**
	 * This class contains all the information needed to connect to a SQL
	 * database.
	 */
	static public class ConnectionInfo
	{
		public static final String NAME = "name";
		public static final String DBMS = "dbms";
		public static final String IP = "ip";
		public static final String PORT = "port";
		public static final String DATABASE = "database";
		public static final String USER = "user";
		public static final String PASS = "pass";
		public static final String IS_SUPERUSER = "is_superuser";		
		public static final String FOLDERNAME = "folderName"; 

		public ConnectionInfo()
		{
		}

		public String name = "", dbms = "", ip = "", port = "", database = "", user = "", pass = "", folderName = "";
		public boolean is_superuser = false;

		public String getConnectString()
		{
			return SQLUtils.getConnectString(dbms, ip, port, database, user, pass);
		}

		public Connection getStaticReadOnlyConnection() throws RemoteException
		{
			return SQLUtils.getStaticReadOnlyConnection(SQLUtils.getDriver(dbms), getConnectString());
		}

		public Connection getConnection() throws RemoteException
		{
			return SQLUtils.getConnection(SQLUtils.getDriver(dbms), getConnectString());
		}
	}
	
	static public class PrivateMetadata
	{
		static public final String CONNECTION = "connection"; // required to retrieve data from sql, not visible to client
		static public final String SQLQUERY = "sqlQuery"; // required to retrieve data from sql, not visible to client
		static public final String SQLPARAMS = "sqlParams"; // only transmitted from client to server, never stored in the database
		static public final String SQLRESULT = "sqlResult"; // only transmitted from server to client, never stored in the database
		static public final String SCHEMA = "schema"; // used for geometry column
		static public final String TABLEPREFIX = "tablePrefix"; // used for geometry column
		@Deprecated static public final String IMPORTNOTES = "importNotes"; // used for geometry column
		
		static public boolean isPrivate(String propertyName)
		{
			String[] names = {CONNECTION, SQLQUERY, SQLPARAMS, SQLRESULT, SCHEMA, TABLEPREFIX, IMPORTNOTES};
			return ListUtils.findString(propertyName, names) >= 0;
		}
	}

	static public class PublicMetadata
	{
		static public final String NAME = "name";
		static public final String KEYTYPE = "keyType";
		static public final String DATATYPE = "dataType";
		static public final String DATATABLE = "dataTable";
		@Deprecated static public final String GEOMETRYCOLLECTION = "geometryCollection";
		static public final String PROJECTION = "projection";
		static public final String YEAR = "year";
		static public final String CATEGORY_ID = "category_id";
		static public final String MIN = "min";
		static public final String MAX = "max";
		static public final String TITLE = "title";
		static public final String NUMBER = "number";
		static public final String STRING = "string";
		
		/**
		 * This is a list of metadata property names used in the old implementation of ISQLConfig
		 */
		static public final String[] names = {
			NAME, KEYTYPE, DATATYPE, DATATABLE, GEOMETRYCOLLECTION, YEAR, CATEGORY_ID, MIN, MAX, TITLE, NUMBER, STRING
		};
	}
	
	@Deprecated
	static public class GeometryCollectionInfo
	{
		public String name = "", connection = "", schema = "", tablePrefix = "", keyType = "", projection = "", importNotes = "";
	}
	
	static public class DataType
	{
		static public final String NUMBER = "number";
		static public final String STRING = "string";
		static public final String GEOMETRY = "geometry";
		
		/**
		 * This function determines the corresponding DataType constant for a SQL type defined in java.sql.Types.
		 * @param sqlType A SQL data type defined in java.sql.Types.
		 * @return The corresponding constant NUMBER or STRING.
		 */
		static public String fromSQLType(int sqlType)
		{
			switch (sqlType)
			{
			case Types.TINYINT:
			case Types.SMALLINT:
			case Types.BIGINT:
			case Types.DECIMAL:
			case Types.INTEGER:
			case Types.FLOAT:
			case Types.DOUBLE:
			case Types.REAL:
			case Types.NUMERIC:
				/* case Types.ROWID: // produces compiler error in some environments */
				return NUMBER;
			default:
				return STRING;
			}
		}
	}

	/**
	 * This class contains metadata for an attributeColumn entry.
	 */
	static public class AttributeColumnInfo
	{
		public int id;
		public String description;
		public Map<String,String> privateMetadata;
		public Map<String,String> publicMetadata;
		
		public AttributeColumnInfo(int id, String description, Map<String, String> privateMetadata, Map<String, String> publicMetadata)
		{
			this.id = id;
			this.description = description;
			this.privateMetadata = privateMetadata;
			this.publicMetadata = publicMetadata;
		}
		
		public String getConnectionName()
		{
			return privateMetadata.get(PrivateMetadata.CONNECTION);
		}

		public String getSqlQuery()
		{
			return privateMetadata.get(PrivateMetadata.SQLQUERY);
		}
		
		@Deprecated
		public AttributeColumnInfo(int id, String description, Map<String, String> metadata)
		{
			this.id = id;
			this.description = description;
			this.privateMetadata = new HashMap<String,String>();
			this.publicMetadata = new HashMap<String,String>();
			for (Entry<String, String> entry : metadata.entrySet())
			{
				if (PrivateMetadata.isPrivate(entry.getKey()))
					privateMetadata.put(entry.getKey(), entry.getValue());
				else
					publicMetadata.put(entry.getKey(), entry.getValue());
			}
		}

		// returns a non-null value
		@Deprecated
		public String getMetadata(String propertyName)
		{
			String value;
			if (PrivateMetadata.isPrivate(propertyName))
				value = privateMetadata.get(propertyName);
			else
				value = publicMetadata.get(propertyName);
			if (value == null)
				return "";
			return value;
		}
		
		@Deprecated
		public Map<String,String> getAllMetadata()
		{
			Map<String,String> result = new HashMap<String, String>();
			result.putAll(privateMetadata);
			result.putAll(publicMetadata);
			return result;
		}
	}
}

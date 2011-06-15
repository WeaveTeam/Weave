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
import java.util.List;
import java.util.Map;

import weave.utils.SQLUtils;
import org.w3c.dom.Document;

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
	String getServerName() throws RemoteException;

	/**
	 * Returns the name of the SQL table which stores the access log.
	 */
	String getAccessLogConnectionName() throws RemoteException;

	/**
	 * Returns the name of the SQL table which stores the access log.
	 */
	String getAccessLogSchema() throws RemoteException;

	/**
	 * Returns the name of the SQL table which stores the access log.
	 */
	String getAccessLogTable() throws RemoteException;

	/**
	 * Lists all keyTypes stored in this configuration
	 */
	List<String> getKeyTypes() throws RemoteException;

	public final String ENTRYTYPE_CONNECTION = "connection";
	public final String ENTRYTYPE_DATATABLE = "dataTable";
	public final String ENTRYTYPE_GEOMETRYCOLLECTION = "geometryCollection";

	/**
	 * Gets the names of all connections in this configuration
	 * @param connectionName A connection used as a filter, or null for no filter.
	 */
	List<String> getConnectionNames(String connectionName) throws RemoteException;

	/**
	 * Gets the names of all geometry collections in this configuration
	 * @param connectionName A connection used as a filter, or null for no filter.
	 */
	List<String> getGeometryCollectionNames(String connectionName) throws RemoteException;

	/**
	 * Gets the names of all data tables in this configuration
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
	void addGeometryCollection(GeometryCollectionInfo geometryCollectionInfo) throws RemoteException;

	/**
	 * Looks up a geometry collection in this configuration by name
	 * 
	 * @param geometryCollection
	 *            The name of a geometryCollection configuration entry.
	 * @param connectionName
	 *        The name of the connection which this geometry resides. If this is null, then this
	 *        function will return the info for any geometry collection.
	 * @return An object containing the configuration for the specified
	 *         geometryCollection.
	 * @throws RemoteException
	 *             if the info could not be retrieved.
	 */
	GeometryCollectionInfo getGeometryCollectionInfo(String geometryCollectionName, String connectionName) throws RemoteException;

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
	List<AttributeColumnInfo> getAttributeColumnInfo(String dataTableName) throws RemoteException;

	/**
	 * Returns the information to connect to a configuration database. If the
	 * "databaseConfig" tag is missing, this returns an object which is
	 * populated with empty strings for all fields.
	 */
	DatabaseConfigInfo getDatabaseConfigInfo() throws RemoteException;

	/**
	 * This class contains all the information related to where the
	 * configuration should be stored in a database.
	 */
	public static class DatabaseConfigInfo
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
		public String schema, geometryConfigTable, dataConfigTable;
	}

	/**
	 * This class contains all the information needed to connect to a SQL
	 * database.
	 */
	public static class ConnectionInfo
	{
		public static final String NAME = "name";
		public static final String DBMS = "dbms";
		public static final String IP = "ip";
		public static final String PORT = "port";
		public static final String DATABASE = "database";
		public static final String USER = "user";
		public static final String PASS = "pass";
		public static final String PRIVILEGES = "privileges";
		

		public ConnectionInfo()
		{
		}

		public String name = "", dbms = "", ip = "", port = "", database = "", user = "", pass = "", privileges="";

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

	/**
	 * This class contains metadata for a geometryCollection entry.
	 */
	public static class GeometryCollectionInfo
	{
		public static final String NAME = "name";
		public static final String CONNECTION = "connection";
		public static final String SCHEMA = "schema";
		public static final String TABLEPREFIX = "tablePrefix";
		public static final String KEYTYPE = "keyType";
		public static final String PROJECTION = "projection";
		public static final String IMPORTNOTES = "importNotes";

		public GeometryCollectionInfo()
		{
		}

		public String name = "", connection = "", schema = "", tablePrefix = "", keyType = "", projection = "",
				importNotes = "";
	}

	/**
	 * This class contains metadata for an attributeColumn entry.
	 */
	public static class AttributeColumnInfo
	{
		// connection name and query are required to retrieve the data
		// this information should not be made available to client programs
		public static final String CONNECTION = "connection";
		public static final String SQLQUERY = "sqlQuery";

		// Metadata includes everything that end-users are allowed to see.
		// Metadata should not contain any information related to the SQL
		// database.
		public static enum Metadata
		{
			NAME("name"),
			KEYTYPE("keyType"),
			DATATYPE("dataType"),
			DATATABLE("dataTable"),
			GEOMETRYCOLLECTION("geometryCollection"),
			YEAR("year"),
			MIN("min"),
			MAX("max");

			Metadata(String name)
			{
				this.name = name;
			}

			private String name;

			public String toString()
			{
				return name;
			}
		}

		public static enum DataType
		{
			NUMBER("number"), STRING("string");

			DataType(String type)
			{
				this.type = type;
			}

			private String type;

			public String toString()
			{
				return type;
			}

			/**
			 * This function determines the corresponding DataType for a SQL
			 * type defined in java.sql.Types.
			 * 
			 * @param sqlType
			 *            A SQL data type defined in java.sql.Types.
			 * @return The corresponding DataType enum value.
			 */
			public static DataType fromSQLType(int sqlType)
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
						// case Types.ROWID: // produces compiler error in some
						// environments
						return DataType.NUMBER;
					default:
						return DataType.STRING;
				}
			}
		}

		public AttributeColumnInfo(String connection, String sqlQuery, Map<String, String> metadata)
		{
			this.connection = connection;
			this.sqlQuery = sqlQuery;
			this.metadata = metadata;
		}

		// returns a non-null value
		public String getMetadata(String propertyName)
		{
			String value = metadata.get(propertyName);
			if (value == null)
				return "";
			return value;
		}

		public String connection, sqlQuery;
		public Map<String, String> metadata;
	}
}

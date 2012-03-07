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
import java.util.Collection;
import java.util.Map;

import org.w3c.dom.Document;

import weave.utils.ListUtils;
import weave.utils.SQLUtils;

/**
 * ISQLConfig An interface to retrieve strings from a configuration file.
 * 
 * @author Andy Dufilie
 */
/**
 * @author user
 *
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
	 * Gets the names of all connections in this configuration
	 */
	List<String> getConnectionNames() throws RemoteException;

	/**
	 * Removes the connection with the given name from this configuration
	 */
	void removeConnection(String name) throws RemoteException;

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
	 * This will create a new attribute column entry.
	 * @param info The definition of the attributeColumn entry.  The id property will be ignored.
	 * @return The id of the new attributeColumn entry.
	 */
	int addAttributeColumnInfo(AttributeColumnInfo info) throws RemoteException;

	/**
	 * This will overwrite an existing attribute column entry with the same id.
	 * @param info The id and definition of the attributeColumn entry.
	 */
	void overwriteAttributeColumnInfo(AttributeColumnInfo info) throws RemoteException;
	
	/**
	 * @return A list of AttributeColumnInfo objects that match the specified filter criteria.
	 */
	List<AttributeColumnInfo> findAttributeColumnInfo(AttributeColumnInfo info) throws RemoteException;
	
	/**
	 * @param id The ID of an attribute column.
	 * @return The AttributeColumnInfo object identified by the id, or null if it doesn't exist.
	 * @throws RemoteException
	 */
	AttributeColumnInfo getAttributeColumnInfo(int id) throws RemoteException;
	
	/**
	 * @param id The ID of the attribute column entry to remove.
	 * @throws RemoteException
	 */
	void removeAttributeColumnInfo(int id) throws RemoteException;

	
	/**
	 * @return true if this ISQLConfig object is successfully connected to the database using DatabaseConfigInfo.
	 */
	boolean isConnectedToDatabase();
	
	/**
	 * @return A DatabaseConfigInfo object, or null if this ISQLConfig is not configured to store info in a database.
	 */
	DatabaseConfigInfo getDatabaseConfigInfo() throws RemoteException;

        /**
         * Methods for the category system
         */
        public void addChild(int parent, int child) throws RemoteException;
        public void removeChild(int parent, int child) throws RemoteException;
        public int addTag(String tagtitle) throws RemoteException;
        public void removeTag(int tag_id) throws RemoteException;
        public Collection<Integer> getChildren(Integer parent_id) throws RemoteException;
        public Collection<Integer> getRoots() throws RemoteException;
        
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
		
		@Deprecated static public boolean isPrivate(String propertyName)
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
		static public final String PROJECTION = "projection";
		static public final String YEAR = "year";
		static public final String CATEGORY_ID = "category_id";
		static public final String MIN = "min";
		static public final String MAX = "max";
		static public final String TITLE = "title";
		static public final String NUMBER = "number";
		static public final String STRING = "string";
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
		public int id = -1;
		public Map<String,String> privateMetadata;
		public Map<String,String> publicMetadata;
		
		public String getConnectionName()
		{
			return privateMetadata.get(PrivateMetadata.CONNECTION);
		}
		
		public String getSqlQuery()
		{
			return privateMetadata.get(PrivateMetadata.SQLQUERY);
		}
		
		@Deprecated
		public Map<String,String> getPrivateAndPublicMetadata()
		{
			Map<String,String> result = new HashMap<String, String>();
			result.putAll(privateMetadata);
			result.putAll(publicMetadata);
			return result;
		}
	}
}

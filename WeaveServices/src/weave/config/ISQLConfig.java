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
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.w3c.dom.Document;

import weave.utils.ListUtils;
import weave.utils.SQLUtils;

/**
 * ISQLConfig An interface to retrieve strings from a configuration file.
 * 
 * @author Andy Dufilie
 */
public abstract class ISQLConfig
{
	/**
	 * Gets the entire ISQLconfig content as a DOM structure. When
	 * DatabaseConfig is used, this DOM only contains connection information.
	 * When SQLConfigXML is used, this returns the connection information as
	 * well as column configurations.
	 */
    public abstract Document getDocument() throws RemoteException;

	/**
	 * Gets the names of all connections in this configuration
	 */
	public abstract List<String> getConnectionNames() throws RemoteException;

	/**
	 * Removes the connection with the given name from this configuration
	 */
	public abstract void removeConnection(String name) throws RemoteException;

	/**
	 * This adds a connection to the configuration.
	 * 
	 * @param connectionInfo
	 *            The definition of the connection entry.
	 */
	public abstract void addConnection(ConnectionInfo connectionInfo) throws RemoteException;

	public abstract ConnectionInfo getConnectionInfo(String connectionName) throws RemoteException;

	public abstract boolean isConnectedToDatabase();
	public abstract DatabaseConfigInfo getDatabaseConfigInfo() throws RemoteException;
	public abstract Integer addEntity(Integer type_id, DataEntityMetadata properties) throws RemoteException;
	public Integer copyEntity(Integer id) throws RemoteException
	{
		throw new RemoteException("copyEntity() not implemented");
	}
	public abstract void removeEntity(Integer id) throws RemoteException;
	public abstract void updateEntity(Integer id, DataEntityMetadata properties) throws RemoteException;
	public Collection<DataEntity> findEntities(DataEntityMetadata properties) throws RemoteException
	{
	    return findEntities(properties, -1);
	}
	public abstract Collection<DataEntity> findEntities(DataEntityMetadata properties, Integer manifestType) throws RemoteException;
	public abstract Collection<DataEntity> getEntities(Collection<Integer> ids) throws RemoteException;
	public abstract Collection<DataEntity> getEntitiesByType(Integer id) throws RemoteException;
	public abstract void addChild(Integer child_id, Integer parent_id) throws RemoteException;
	public abstract void removeChild(Integer child_id, Integer parent_id) throws RemoteException;
	public abstract Collection<DataEntity> getChildren(Integer parent_id) throws RemoteException;
	public abstract Collection<String> getUniqueValues(String property) throws RemoteException;
	
	public DataEntity getEntity(Integer id) throws RemoteException
	{
	    for (DataEntity de : getEntities(Arrays.asList(id)))
	        return de; /* Return the first hit. Should be the only hit. If not we're in trouble. */
	    return null;
	}
    /**
     * Methods for the category system
     */
    /* Former residents of SQLConfigUtils */
    public boolean userCanModifyAttributeColumn(String connectionName, int id) throws RemoteException
    {
        ConnectionInfo connInfo = getConnectionInfo(connectionName);
        if (connInfo == null)
            return false;
        if (connInfo.is_superuser)
            return true;
        DataEntity attrInfo = getEntity(id);
        return (attrInfo == null) || (attrInfo.privateMetadata.get(PrivateMetadata.CONNECTION) == connectionName);
    }
    @Deprecated public boolean userCanModifyDataTable(String connectionName, String dataTableName) throws RemoteException
    {
        DataEntityMetadata metadataFilter = new DataEntityMetadata();
        Map<String,String> publicMetadataFilter = new HashMap<String,String>();
        publicMetadataFilter.put(PublicMetadata.DATATABLE, dataTableName);
        metadataFilter.publicMetadata = publicMetadataFilter;
        Collection<DataEntity> entries = findEntities(metadataFilter);
        
        for (DataEntity result : entries)
            if (!userCanModifyAttributeColumn(connectionName, result.id))
                throw new RemoteException(String.format("User \"%s\" does not have permission to remove DataTable \"%s\".", connectionName, dataTableName));
        
        return true;    
    }
    public Connection getNamedConnection(String connectionName) throws RemoteException
    {
        return getNamedConnection(connectionName, false);
    }
    public Connection getNamedConnection(String connectionName, boolean readOnly) throws RemoteException
    {
        Connection conn;
        ConnectionInfo info = getConnectionInfo(connectionName);

        if (info == null)
            throw new RemoteException(String.format("Connection named \"%s\" doead not exist.", connectionName));
        if (readOnly)
            conn = info.getStaticReadOnlyConnection();
        else
            conn = info.getConnection();
        return conn;
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
		public static final String CONNECTSTRING = "connectString"; 

		public ConnectionInfo()
		{
		}

		public String name = "", dbms = "", ip = "", port = "", database = "", user = "", pass = "", folderName = "";
		public String connectString = "";
		public boolean is_superuser = false;

		public String getConnectString()
		{
			if (connectString.length() > 0)
				return connectString;
			else
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
		static public final String DATATABLE = "dataTable"; /* Deprecated */
		static public final String PROJECTION = "projection";
		static public final String YEAR = "year";
		static public final String CATEGORY_ID = "category_id";
		static public final String MIN = "min";
		static public final String MAX = "max";
		static public final String TITLE = "title";
		static public final String NUMBER = "number";
		static public final String STRING = "string";
		static public final String DATATABLE_ID = "dataTableID";
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
	 * This class contains public and private metadata for an entity.
	 */
	static public class DataEntityMetadata
	{
	    private static final String PUBLIC_METADATA = "publicMetadata";
	    private static final String PRIVATE_METADATA = "privateMetadata";
	    
		public static DataEntityMetadata fromMap(Map<String,Map<String,String>> object)
		{
        	DataEntityMetadata dem = new DataEntityMetadata();
        	
        	if (object.get(PRIVATE_METADATA) != null)
        		dem.privateMetadata = object.get(PRIVATE_METADATA);
        	
        	if (object.get(PUBLIC_METADATA) != null)
        		dem.publicMetadata = object.get(PUBLIC_METADATA);
        	
        	return dem;
		}
		
		public Map<String,String> privateMetadata = new HashMap<String, String>();
		public Map<String,String> publicMetadata = new HashMap<String, String>();
	}

	/**
	 * This class contains metadata for an attributeColumn entry.
	 */
	static public class DataEntity extends DataEntityMetadata
	{
		public static final Integer MAN_TYPE_DATATABLE = 0;
		public static final Integer MAN_TYPE_COLUMN = 1;
		public static final Integer MAN_TYPE_TAG = 2;
		public int id = -1;
		public int type;
        /* For cases where the config API isn't sufficient. TODO */
        public static List<DataEntity> filterEntities(Collection<DataEntity> entities, Map<String,String> params)
        {
            return filterEntities(entities, params, -1);
        }
        public static List<DataEntity> filterEntities(Collection<DataEntity> entities, Map<String,String> params, Integer manifestType)
        {
            List<DataEntity> result = new LinkedList<DataEntity>();
            for (DataEntity entity : entities)
            {
                if (manifestType != -1 && manifestType != entity.type)
                    continue;
                boolean match = true;
                for (Entry<String,String> entry : params.entrySet())
                {
                    if (params.get(entry.getKey()) != entry.getValue())
                    {
                        match = false;
                        break;
                    }
                }
                if (match)
                    result.add(entity);
            }
            return result;
        }
        public DataEntity()
        {
        }
		public String getConnectionName()
		{
			return privateMetadata.get(PrivateMetadata.CONNECTION);
		}
		
		public String getSqlQuery()
		{
			return privateMetadata.get(PrivateMetadata.SQLQUERY);
		}
		
		public String getSqlParams()
		{
			return privateMetadata.get(PrivateMetadata.SQLPARAMS);
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
	public class ImmortalConnection
	{
	    private Connection _lastConnection = null;
	    private ISQLConfig cfg = null;
	    private DatabaseConfigInfo dbInfo = null;
	    public ImmortalConnection(ISQLConfig newcfg)  throws RemoteException
	    {
	        cfg = newcfg; 
	        dbInfo = cfg.getDatabaseConfigInfo();
	    }
	    public Connection getConnection() throws RemoteException
	    {
	        if (SQLUtils.connectionIsValid(_lastConnection))
	            return _lastConnection;
	        return _lastConnection = cfg.getNamedConnection(dbInfo.connection);
	    }
}
}

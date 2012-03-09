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
import java.sql.SQLException;
import java.sql.Savepoint;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import weave.config.ISQLConfig.AttributeColumnInfo;
import weave.config.ISQLConfig.ConnectionInfo;
import weave.config.ISQLConfig.DataType;
import weave.config.ISQLConfig.PrivateMetadata;
import weave.config.ISQLConfig.PublicMetadata;
import weave.utils.DebugTimer;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;

/**
 * SQLConfigUtils
 * 
 * @author Andy Dufilie
 */
public class SQLConfigUtils
{
	/**
	 * This function returns a Connection that should stay open to avoid connection setup overhead.
	 * The Connection returned by this function should not be closed.
	 * @param config An ISQLConfig interface to a config file
	 * @param connectionName The name of a connection in the config file.
	 * @return A new SQL connection using the specified connection.
	 */
	public static Connection getStaticReadOnlyConnection(ISQLConfig config, String connectionName) throws RemoteException
	{
		ConnectionInfo info = config.getConnectionInfo(connectionName);
		if (info == null)
			throw new RemoteException(String.format("Connection named \"%s\" does not exist", connectionName));
		return info.getStaticReadOnlyConnection();
	}
	
	/**
	 * getConnection: Returns a new SQL connection 
	 * @param config An ISQLConfig interface to a config file
	 * @param connectionName The name of a connection in the config file.
	 * @return A new SQL connection using the specified connection.
	 */
	public static Connection getConnection(ISQLConfig config, String connectionName) throws SQLException, RemoteException
	{
		ConnectionInfo info = config.getConnectionInfo(connectionName);
		if (info == null)
			throw new RemoteException(String.format("Connection named \"%s\" does not exist", connectionName));
		return info.getConnection();
	}
	
	/**
	 * @param config An ISQLConfig interface to a config file
	 * @param connectionName The name of a connection in the config file
	 * @param query An SQL Query
	 * @return A SQLResult object containing the result of the SQL query
	 * @throws RemoteException
	 * @throws SQLException
	 */
        @Deprecated public static SQLResult getRowSetFromQuery(ISQLConfig config, String connectionName, String query) throws SQLException, RemoteException
	{
		Connection conn = getStaticReadOnlyConnection(config, connectionName);
		return SQLUtils.getRowSetFromQuery(conn, query);
	}

	/**
	 * @param config An ISQLConfig interface to a config file
	 * @param connectionName The name of a connection in the config file
	 * @param query An SQL Query with '?' place holders for parameters
	 * @param params Parameters for all '?' place holders in the SQL query
	 * @return A SQLResult object containing the result of the SQL query
	 * @throws RemoteException
	 * @throws SQLException
	 */
	@Deprecated public static SQLResult getRowSetFromQuery(ISQLConfig config, String connectionName, String query, String[] params) throws SQLException, RemoteException
	{
		Connection conn = getStaticReadOnlyConnection(config, connectionName);
		return SQLUtils.getRowSetFromQuery(conn, query, params);
	}
	
	/**
	 * This function constructs a new query from two existing Weave queries and joins the results using the keys.
	 * @param config
	 * @param metadataQueryParams1
	 * @param metadataQueryParams2
	 * @return
	 * @throws RemoteException
	 * @throws SQLException
	 */
	@Deprecated public static String getJoinQueryForAttributeColumns(ISQLConfig config, int id1, int id2)
		throws RemoteException, SQLException
	{
		// get column info
		AttributeColumnInfo info1 = config.getAttributeColumnInfo(id1);
		AttributeColumnInfo info2 = config.getAttributeColumnInfo(id2);
		if (info1 == null)
			throw new RemoteException("No match for first joined attribute column.");
		if (info2 == null)
			throw new RemoteException("No match for second joined attribute column.");
		
		ConnectionInfo connInfo = config.getConnectionInfo(info1.getConnectionName());
		if (info1.getConnectionName() != info2.getConnectionName())
			throw new RemoteException("SQL connection for two columns must be the same to join them.");
		if (connInfo == null)
			throw new RemoteException(String.format("The SQL connection for the columns does not exist.", info1.getConnectionName()));
		if (connInfo.dbms != SQLUtils.MYSQL)
			throw new RemoteException("getJoinQueryForAttributeColumns() only supports MySQL.");
		Connection conn = getStaticReadOnlyConnection(config, info1.getConnectionName());
		
		SQLResult crs1, crs2;
		String keyCol1, dataCol1, query1;
		String keyCol2, dataCol2, query2;
		
		query1 = info1.getSqlQuery();
		query1 = query1.trim();
		if (query1.endsWith(";"))
			query1 = query1.substring(0, query1.length() - 1);
		crs1 = SQLUtils.getRowSetFromQuery(conn, query1);
		keyCol1 = crs1.columnNames[0];
		dataCol1 = crs1.columnNames[1];

		query2 = info2.getSqlQuery();
		query2 = query2.trim();
		if (query2.endsWith(";"))
			query2 = query2.substring(0, query2.length() - 1);
		crs2 = SQLUtils.getRowSetFromQuery(conn, query2);
		keyCol2 = crs2.columnNames[0];
		dataCol2 = crs2.columnNames[1];

		String combinedQuery = String.format(
				"select a.`%s` as keyCode, a.`%s` as data1, b.`%s` as data2"
				+ " from (%s) as a join (%s) as b"
				+ " on a.`%s` = b.`%s`",
				keyCol1, dataCol1, dataCol2,
				query1, query2,
				keyCol1, keyCol2
			);
		return combinedQuery;
	}

	public static SQLResult getRowSetFromJoinedAttributeColumns(ISQLConfig config, int id1, int id2)
		throws RemoteException, SQLException
	{
		String combinedQuery = getJoinQueryForAttributeColumns(config, id1, id2);

		AttributeColumnInfo info1 = config.getAttributeColumnInfo(id1);
		
		SQLResult result = getRowSetFromQuery(config, info1.getConnectionName(), combinedQuery);
		
		/*
		//for debugging
		String result = "keyCode, data1, data2\n";
		try
		{
			while (crs.next())
			{
				result += String.format("%s, %s, %s\n", crs.getString(1), crs.getString(2), crs.getString(3));
			}
			System.out.println(result);
		}
		catch (SQLException e)
		{
			e.printStackTrace();
		}
		*/
		
		return result;
	}

	@Deprecated public static String[] getKeyTypes(ISQLConfig config) throws RemoteException
	{
		Map<String,String> publicParams = new HashMap<String,String>();
		Map<String,String> privateParams = new HashMap<String,String>();
		
                AttributeColumnInfo info = new AttributeColumnInfo();
                info.privateMetadata = privateParams;
                info.publicMetadata = publicParams;
                List<AttributeColumnInfo> infoList = config.findAttributeColumnInfo(info);
		
		Set<String> set = new HashSet<String>();
		for (AttributeColumnInfo tmpinfo : infoList)
			set.add(tmpinfo.publicMetadata.get(PublicMetadata.KEYTYPE));
		String[] array = set.toArray(new String[0]);
		Arrays.sort(array, String.CASE_INSENSITIVE_ORDER);
		return array;
	}
	
	@Deprecated public static String[] getGeometryCollectionNames(ISQLConfig config, String connectionName) throws RemoteException
	{
		Map<String,String> publicParams = new HashMap<String,String>();
		publicParams.put(PublicMetadata.DATATYPE, DataType.GEOMETRY);
		
		Map<String,String> privateParams = new HashMap<String,String>();

                AttributeColumnInfo info = new AttributeColumnInfo();
                info.privateMetadata = privateParams;
                info.publicMetadata = publicParams;

		if (connectionName != null)
			privateParams.put(PrivateMetadata.CONNECTION, connectionName);
		
		List<AttributeColumnInfo> infoList = config.findAttributeColumnInfo(info);
		
		Set<String> nameSet = new HashSet<String>();
		for (AttributeColumnInfo tmpinfo : infoList)
			nameSet.add(tmpinfo.publicMetadata.get(PublicMetadata.NAME));
		String[] names = nameSet.toArray(new String[0]);
		Arrays.sort(names, String.CASE_INSENSITIVE_ORDER);
		return names;
	}
	
	@Deprecated public static String[] getDataTableNames(ISQLConfig config, String connectionName) throws RemoteException
	{
                AttributeColumnInfo info = new AttributeColumnInfo();
		Map<String,String> publicParams = new HashMap<String,String>();
		
		Map<String,String> privateParams = new HashMap<String,String>();
		if (connectionName != null)
			privateParams.put(PrivateMetadata.CONNECTION, connectionName);
		
                info.publicMetadata = publicParams;
                info.privateMetadata = privateParams; 
		List<AttributeColumnInfo> infoList = config.findAttributeColumnInfo(info);

		Set<String> nameSet = new HashSet<String>();
		for (AttributeColumnInfo tmpinfo : infoList)
			nameSet.add(tmpinfo.publicMetadata.get(PublicMetadata.DATATABLE));
                nameSet.remove(null);
		String[] names = nameSet.toArray(new String[0]);
                for (String name : names)
                {
                    System.out.println(name);
                }
		Arrays.sort(names, String.CASE_INSENSITIVE_ORDER);
		return names;
	}
	
	// shortcut for calling the Map<String,String> version of this function
	@SuppressWarnings("unchecked")
	@Deprecated public static List<AttributeColumnInfo> getDataTableInfo(ISQLConfig config, String dataTableName) throws RemoteException
	{
		Map<String, String> metadataQueryParams = new HashMap<String, String>(1);
                AttributeColumnInfo info = new AttributeColumnInfo();
		metadataQueryParams.put(PublicMetadata.DATATABLE, dataTableName);
                info.publicMetadata = metadataQueryParams;
                info.privateMetadata = Collections.EMPTY_MAP;
		return config.findAttributeColumnInfo(info);
	}

	@Deprecated public static void removeDataTableInfo(ISQLConfig config, String dataTableName) throws RemoteException
	{
		List<AttributeColumnInfo> info = getDataTableInfo(config, dataTableName);
		for (int i = 0; i < info.size(); i++)
			config.removeAttributeColumnInfo(info.get(i).id);
	}
	
	/**
	 * This function copies all connections, dataTables, and geometryCollections from one ISQLConfig to another.
	 * @param source A configuration to copy from.
	 * @param destination A configuration to copy to.
	 * @return The total number of items that were migrated.
	 * @throws Exception If migration fails.
	 * 
	 * @author Andrew Wilkinson
	 * @author Andy Dufilie
	 */
	@SuppressWarnings({ "deprecation", "unchecked" })
	public synchronized static int migrateSQLConfig(ISQLConfig source, SQLConfig destination) throws RemoteException, SQLException
	{
		System.out.println(String.format("Migrating from %s to %s", source.getClass().getCanonicalName(), destination.getClass().getCanonicalName()));
		
		DebugTimer timer = new DebugTimer();
		Connection conn = destination.getConnection();
		Savepoint savePoint = null;
		int count = 0;
		try
		{
			if (conn != null)
			{
				conn.setAutoCommit(false);
				savePoint = conn.setSavepoint("migrateSQLConfig");
			}

			if (source instanceof IDeprecatedSQLConfig)
			{
				IDeprecatedSQLConfig depSource = (IDeprecatedSQLConfig)source;
				// add geometry collections
				List<String> geoNames = depSource.getGeometryCollectionNames(null);
				timer.report("begin "+geoNames.size()+" geom names");
				int printInterval = Math.max(1, geoNames.size() / 50);
				for (int i = 0; i < geoNames.size(); i++)
				{
					if (i % printInterval == 0)
						System.out.println("Migrating geometry collection " + (i+1) + "/" + geoNames.size());
					AttributeColumnInfo info = depSource.getGeometryCollectionInfo(geoNames.get(i)).getAttributeColumnInfo();
					destination.addAttributeColumnInfo(info);
				}
				timer.report("done migrating geom collections");
			}

			// add columns
			List<AttributeColumnInfo> infoList = source.findAttributeColumnInfo(new AttributeColumnInfo());
			timer.report("begin "+infoList.size()+" columns");
			int printInterval = Math.max(1, infoList.size() / 50);
			for( int i = 0; i < infoList.size(); i++)
			{
				AttributeColumnInfo info = infoList.get(i);
				if (i % printInterval == 0)
					System.out.println(String.format(
						"Migrating column %s/%s, privateMetadata: %s, publicMetadata: %s",
						i + 1, infoList.size(), info.privateMetadata, info.publicMetadata
					));
				destination.addAttributeColumnInfo(info);
			}
			count += infoList.size();
			timer.report("done migrating columns");
			
			if (conn != null)
			{
				if (!SQLUtils.isOracleServer(conn))
					conn.releaseSavepoint(savePoint);
				conn.setAutoCommit(true);
			}
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			try
			{
				conn.rollback(savePoint);
				conn.setAutoCommit(true);
			}
			catch (SQLException se)
			{
				se.printStackTrace();
			}
			throw e;
		}
		return count;
	}
	
	/**
	 * This will return true if the specified connection has permission to modify the specified dataTable entry.
	 */
	@SuppressWarnings("unchecked")
	@Deprecated public static boolean userCanModifyDataTable(ISQLConfig config, String connectionName, String dataTableName) throws RemoteException
	{
		Map<String,String> publicMetadataFilter = new HashMap<String,String>();
		publicMetadataFilter.put(PublicMetadata.DATATABLE, dataTableName);
                AttributeColumnInfo tmpinfo = new AttributeColumnInfo();
                tmpinfo.publicMetadata = publicMetadataFilter;
                tmpinfo.privateMetadata = Collections.EMPTY_MAP;
		List<AttributeColumnInfo> info = config.findAttributeColumnInfo(tmpinfo);
		
		for (int i = 0; i < info.size(); i++)
			if (!userCanModifyAttributeColumn(config, connectionName, info.get(i).id))
				throw new RemoteException(String.format("User \"%s\" does not have permission to remove DataTable \"%s\".", connectionName, dataTableName));
		
		return true;
	}
	/**
	 * This will return true if the specified connection has permission to modify the specified attribute column entry.
	 */
	public static boolean userCanModifyAttributeColumn(ISQLConfig config, String connectionName, int id) throws RemoteException
	{
		// true if entry doesn't exist or if user has permission
		ConnectionInfo connInfo = config.getConnectionInfo(connectionName);
		if (connInfo == null)
			return false;
		if (connInfo.is_superuser)
			return true;
		AttributeColumnInfo attrInfo = config.getAttributeColumnInfo(id);
		return (attrInfo == null) || (attrInfo.privateMetadata.get(PrivateMetadata.CONNECTION) == connectionName);
	}
	
	public static class InvalidParameterException extends Exception
	{
		private static final long serialVersionUID = 6290284095499981871L;
		public InvalidParameterException(String msg) { super(msg); }
	}
}

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
import java.util.Collections;
import java.util.List;
import java.util.Map;

import weave.config.ISQLConfig.AttributeColumnInfo;
import weave.config.ISQLConfig.ConnectionInfo;
import weave.config.ISQLConfig.GeometryCollectionInfo;
import weave.utils.DebugTimer;
import weave.utils.ListUtils;
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
	public static SQLResult getRowSetFromQuery(ISQLConfig config, String connectionName, String query) throws SQLException, RemoteException
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
	public static SQLResult getRowSetFromQuery(ISQLConfig config, String connectionName, String query, String[] params) throws SQLException, RemoteException
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
	public static String getJoinQueryForAttributeColumns(ISQLConfig config, Map<String, String> metadataQueryParams1, Map<String, String> metadataQueryParams2)
		throws RemoteException, SQLException
	{
		// get column info
		List<AttributeColumnInfo> infoList1 = config.getAttributeColumnInfo(metadataQueryParams1);
		List<AttributeColumnInfo> infoList2 = config.getAttributeColumnInfo(metadataQueryParams2);
		if (infoList1.size() == 0)
			throw new RemoteException("No match for first joined attribute column.");
		if (infoList2.size() == 0)
			throw new RemoteException("No match for second joined attribute column.");
		if (infoList1.size() > 1)
			throw new RemoteException("Multiple matches for first joined attribute column.");
		if (infoList2.size() > 1)
			throw new RemoteException("Multiple matches for second joined attribute column.");
		
		AttributeColumnInfo info1 = infoList1.get(0);
		AttributeColumnInfo info2 = infoList2.get(0);
		ConnectionInfo connInfo = config.getConnectionInfo(info1.connection);
		if (info1.connection != info2.connection)
			throw new RemoteException("SQL connection for two columns must be the same to join them.");
		if (connInfo == null)
			throw new RemoteException(String.format("The SQL connection for the columns does not exist.", info1.connection));
		if (connInfo.dbms != SQLUtils.MYSQL)
			throw new RemoteException("getJoinQueryForAttributeColumns() only supports MySQL.");
		Connection conn = getStaticReadOnlyConnection(config, info1.connection);
		
		SQLResult crs1, crs2;
		String keyCol1, dataCol1, query1;
		String keyCol2, dataCol2, query2;
		
		query1 = info1.sqlQuery;
		query1 = query1.trim();
		if (query1.endsWith(";"))
			query1 = query1.substring(0, query1.length() - 1);
		crs1 = SQLUtils.getRowSetFromQuery(conn, query1);
		keyCol1 = crs1.columnNames[0];
		dataCol1 = crs1.columnNames[1];

		query2 = info2.sqlQuery;
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

	public static SQLResult getRowSetFromJoinedAttributeColumns(ISQLConfig config, Map<String, String> metadataQueryParams1, Map<String, String> metadataQueryParams2)
		throws RemoteException, SQLException
	{
		String combinedQuery = getJoinQueryForAttributeColumns(config, metadataQueryParams1, metadataQueryParams2);

		List<AttributeColumnInfo> infoList1 = config.getAttributeColumnInfo(metadataQueryParams1);
		
		SQLResult result = getRowSetFromQuery(config, infoList1.get(0).connection, combinedQuery);
		
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
	@SuppressWarnings("unchecked")
	public synchronized static int migrateSQLConfig( ISQLConfig source, ISQLConfig destination) throws RemoteException, SQLException
	{
		DebugTimer timer = new DebugTimer();
		Connection conn = null;
		if (destination instanceof DatabaseConfig)
			conn = ((DatabaseConfig)destination).getConnection();
		Savepoint savePoint = null;
		int count = 0;
		try
		{
			if (conn != null)
			{
				conn.setAutoCommit(false);
				savePoint = conn.setSavepoint("migrateSQLConfig");
			}

			// add connections
//			List<String> connNames = source.getConnectionNames();
//			for (int i = 0; i < connNames.size(); i++)
//				count += migrateSQLConfigEntry(source, destination, ISQLConfig.ENTRYTYPE_CONNECTION, connNames.get(i));

			// add geometry collections
			List<String> geoNames = source.getGeometryCollectionNames(null);
			timer.report("begin "+geoNames.size()+" geom names");
			int printInterval = Math.max(1, geoNames.size() / 50);
			for (int i = 0; i < geoNames.size(); i++)
			{
				if (i % printInterval == 0)
					System.out.println("Migrating geometry collection " + (i+1) + "/" + geoNames.size());
				count += migrateSQLConfigEntry(source, destination, ISQLConfig.ENTRYTYPE_GEOMETRYCOLLECTION, geoNames.get(i));
			}
			timer.report("done migrating geom collections");

			// add columns
			List<AttributeColumnInfo> columnInfo = source.getAttributeColumnInfo(Collections.EMPTY_MAP);
			timer.report("begin "+columnInfo.size()+" columns");
			printInterval = Math.max(1, columnInfo.size() / 50);
			for( int i = 0; i < columnInfo.size(); i++)
			{
				if (i % printInterval == 0)
					System.out.println("Migrating column " + (i+1) + "/" + columnInfo.size());
				destination.addAttributeColumn(columnInfo.get(i));
			}
			count += columnInfo.size();
			timer.report("done migrating columns");
			
			if (conn != null)
			{
				if (SQLUtils.isOracleServer(conn))
				{
					conn.setAutoCommit(true);
				}
				else
				{
					conn.releaseSavepoint(savePoint);
					conn.setAutoCommit(true);					
				}
			}
		}
		catch (Exception e)
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
			throw new RemoteException(e.getMessage(), e);
		}
		return count;
	}
	public synchronized static int migrateSQLConfigEntry( ISQLConfig source, ISQLConfig destination, String entryType, String entryName) throws InvalidParameterException, RemoteException
	{
		if (entryType.equalsIgnoreCase(ISQLConfig.ENTRYTYPE_CONNECTION))
		{
			// do nothing if entry doesn't exist in source
			if (ListUtils.findString(entryName, source.getConnectionNames()) < 0)
				return 0;
			// save info from source before removing from destination, just in case source==destination
			ConnectionInfo info = source.getConnectionInfo(entryName);
			destination.removeConnection(entryName);
			destination.addConnection(info);
			return 1;
		}
		else if (entryType.equalsIgnoreCase(ISQLConfig.ENTRYTYPE_GEOMETRYCOLLECTION))
		{
			// do nothing if entry doesn't exist in source
			if (ListUtils.findString(entryName, source.getGeometryCollectionNames(null)) < 0)
				return 0;
			// save info from source before removing from destination, just in case source==destination
			DebugTimer timer = new DebugTimer();
			GeometryCollectionInfo info = source.getGeometryCollectionInfo(entryName);
			timer.lap("getGeometryCollectionInfo "+entryName);
			destination.removeGeometryCollection(entryName);
			timer.lap("removeGeometryCollection "+entryName);
			destination.addGeometryCollection(info);
			timer.report("addGeometryCollection "+entryName);
			return 1;
		}
		else if (entryType.equalsIgnoreCase(ISQLConfig.ENTRYTYPE_DATATABLE))
		{
			// do nothing if entry doesn't exist in source
			if (ListUtils.findString(entryName, source.getDataTableNames(null)) < 0)
				return 0;
			// save info from source before removing from destination, just in case source==destination
			DebugTimer timer = new DebugTimer();
			List<AttributeColumnInfo> columns = source.getAttributeColumnInfo(entryName);
			timer.lap("getAttributeColumnInfo "+entryName +": "+columns.size());
			destination.removeDataTable(entryName);
			timer.lap("removeDataTable "+entryName);
			for( int i = 0; i < columns.size(); i++ )
			{
				destination.addAttributeColumn(columns.get(i));
				timer.report("addAttributeColumn "+i+"/"+columns.size());
			}
			return columns.size();
		}
		else
			throw new InvalidParameterException(String.format("Unable to save configuration entry of type \"%s\".", entryType));
	}

	public static class InvalidParameterException extends Exception
	{
		private static final long serialVersionUID = 6290284095499981871L;
		public InvalidParameterException(String msg) { super(msg); }
	}

	
	/**
	 * This will return true if the specified connection has permission to modify the specified dataTable entry.
	 */
	public static boolean userCanModifyDataTable(ISQLConfig config, String connectionName, String dataTableName) throws RemoteException
	{
		// true if entry doesn't exist or if user has permission
		ConnectionInfo info = config.getConnectionInfo(connectionName);
		if (info == null)
			return false;
		return info.is_superuser
			|| ListUtils.findIgnoreCase(dataTableName, config.getDataTableNames(null)) < 0
			|| ListUtils.findIgnoreCase(dataTableName, config.getDataTableNames(connectionName)) >= 0;
	}
	
	/**
	 * This will return true if the specified connection has permission to modify the specified dataTable entry.
	 */
	public static boolean userCanModifyGeometryCollection(ISQLConfig config, String connectionName, String geometryCollectionName) throws RemoteException
	{
		// true if entry doesn't exist or if user has permission
		ConnectionInfo info = config.getConnectionInfo(connectionName);
		if (info == null)
			return false;
		return info.is_superuser
		|| ListUtils.findIgnoreCase(geometryCollectionName, config.getGeometryCollectionNames(null)) < 0
		|| ListUtils.findIgnoreCase(geometryCollectionName, config.getGeometryCollectionNames(connectionName)) >= 0;
	}
}

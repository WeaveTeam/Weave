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
import java.security.InvalidParameterException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

import weave.config.ConnectionConfig.DatabaseConfigInfo;
import weave.config.DataConfig.DataEntity;
import weave.config.DataConfig.DataEntityMetadata;
import weave.config.DataConfig.DataType;
import weave.config.DataConfig.PrivateMetadata;
import weave.config.DataConfig.PublicMetadata;
import weave.utils.ListUtils;
import weave.utils.ProgressManager;
import weave.utils.SQLUtils;

/**
 * This class is responsible for migrating from the old SQL config format to a DataConfig object.
 * 
 * @author Andy Dufilie
 */

@Deprecated public class DeprecatedConfig
{
	public static void migrate(ConnectionConfig connConfig, DataConfig dataConfig, ProgressManager progress) throws RemoteException
	{
		DeprecatedConfig dc = new DeprecatedConfig();
		dc.connConfig = connConfig;
		dc.dataConfig = dataConfig;
		dc.progress = progress;
		dc.migrate();
	}
	
	private DeprecatedConfig() { }
	
	private final long ONE_SECOND = 1000000000;
	private final long FLUSH_INTERVAL = ONE_SECOND * 10;
	private long lastFlush = System.nanoTime();
	
	private ConnectionConfig connConfig;
	private DataConfig dataConfig;
	private ProgressManager progress;
	Map<String,String> geomKeyTypeLookup;
	Map<String,Integer> tableIdLookup;
	Map<String,DataEntityMetadata> tableMetadataLookup;
	
	private void migrate() throws RemoteException
	{
		int fetchSize = 1024;
		int order = 0;
		String[] columnNames;
		Connection conn = null;
		Statement stmt = null;
		ResultSet resultSet = null;
		boolean prevAutoCommit = true;
		try
		{
			conn = connConfig.getAdminConnection(); // this will fail if DatabaseConfigInfo is missing
			prevAutoCommit = conn.getAutoCommit();
			DatabaseConfigInfo dbInfo = connConfig.getDatabaseConfigInfo();
			stmt = conn.createStatement();
			conn.setAutoCommit(false);
			
			/////////////////////////////
			
			// check for problems
			if (dbInfo == null)
				throw new InvalidParameterException("databaseConfig missing");
			if (dbInfo.schema == null || dbInfo.schema.length() == 0)
				throw new InvalidParameterException("DatabaseConfig: Schema not specified.");
			if (dbInfo.geometryConfigTable == null || dbInfo.geometryConfigTable.length() == 0)
				throw new InvalidParameterException("DatabaseConfig: Geometry metadata table name not specified.");
			if (dbInfo.dataConfigTable == null || dbInfo.dataConfigTable.length() == 0)
				throw new InvalidParameterException("DatabaseConfig: Column metadata table name not specified.");
			
			String quotedOldMetadataTable = SQLUtils.quoteSchemaTable(conn, dbInfo.schema, OLD_METADATA_TABLE);
			String quotedDataConfigTable = SQLUtils.quoteSchemaTable(conn, dbInfo.schema, dbInfo.dataConfigTable);
			String quotedGeometryConfigTable = SQLUtils.quoteSchemaTable(conn, dbInfo.schema, dbInfo.geometryConfigTable);
			
			/////////////////////////////
			// get dublin core metadata for data tables
			
			progress.beginStep("Retrieving old dataset metadata", 0, 0, 0);
			
			int geomTotal = getSingleIntFromQuery(stmt, String.format("SELECT COUNT(*) FROM %s", quotedGeometryConfigTable));
			int attrTotal = getSingleIntFromQuery(stmt, String.format("SELECT COUNT(*) FROM %s", quotedDataConfigTable));
			
			// initialize lookup tables
			geomKeyTypeLookup = new HashMap<String,String>(geomTotal); // we will never have more entries than geomTotal
			tableIdLookup = new HashMap<String,Integer>(geomTotal); // rough estimate for initial capacity, may be totally inaccurate
			tableMetadataLookup = new HashMap<String,DataEntityMetadata>(geomTotal);
			
			if (SQLUtils.tableExists(conn, dbInfo.schema, OLD_METADATA_TABLE))
			{
				resultSet = stmt.executeQuery(String.format("SELECT * FROM %s", quotedOldMetadataTable));
                resultSet.setFetchSize(fetchSize);
				while (resultSet.next())
				{
					String tableName = resultSet.getString(OLD_METADATA_COLUMN_ID);
					String property = resultSet.getString(OLD_METADATA_COLUMN_PROPERTY);
					String value = resultSet.getString(OLD_METADATA_COLUMN_VALUE);
					
					if (!tableMetadataLookup.containsKey(tableName))
						tableMetadataLookup.put(tableName, new DataEntityMetadata());
					DataEntityMetadata metadata = tableMetadataLookup.get(tableName);
					metadata.publicMetadata.put(property, value);
				}
				SQLUtils.cleanup(resultSet);
			}
			
			progress.beginStep("Migrating to new config format", 0, 0, geomTotal + attrTotal);
			
			/////////////////////////////
			// migrate geometry collections
			
			resultSet = stmt.executeQuery(String.format("SELECT * FROM %s", quotedGeometryConfigTable));
            resultSet.setFetchSize(fetchSize);
			columnNames = SQLUtils.getColumnNamesFromResultSet(resultSet);
			while (resultSet.next())
			{
				Map<String,String> geomRecord = getRecord(resultSet, columnNames);
				
				// save name-to-keyType mapping for later
				String name = geomRecord.get(PublicMetadata_NAME);
				String keyType = geomRecord.get(PublicMetadata.KEYTYPE);
				geomKeyTypeLookup.put(name, keyType);
				
				// copy "name" to "title"
				geomRecord.put(PublicMetadata.TITLE, name);
				// set dataType appropriately
				geomRecord.put(PublicMetadata.DATATYPE, DataType.GEOMETRY);
				// rename "schema" to "sqlSchema"
				geomRecord.put(PrivateMetadata.SQLSCHEMA, geomRecord.remove(PrivateMetadata_SCHEMA));
				// rename "tablePrefix" to "sqlTablePrefix"
				geomRecord.put(PrivateMetadata.SQLTABLEPREFIX, geomRecord.remove(PrivateMetadata_TABLEPREFIX));
				
				// create an entity for the geometry column
				DataEntityMetadata geomMetadata = toDataEntityMetadata(geomRecord);
				int tableId = getTableId(name);
				int columnId = dataConfig.addEntity(DataEntity.TYPE_COLUMN, geomMetadata);
				dataConfig.addChild(tableId, columnId, order++);
				
				progress.tick();
				autoFlush();
			}
			SQLUtils.cleanup(resultSet);
			
			/////////////////////////////
			// migrate columns
			
			resultSet = stmt.executeQuery(String.format("SELECT * FROM %s", quotedDataConfigTable));
            resultSet.setFetchSize(fetchSize);
			columnNames = SQLUtils.getColumnNamesFromResultSet(resultSet);
			while (resultSet.next())
			{
				Map<String,String> columnRecord = getRecord(resultSet, columnNames);
				
				// if key type isn't specified but geometryCollection is, use the keyType of the geometry collection.
				String keyType = columnRecord.get(PublicMetadata.KEYTYPE);
				String geom = columnRecord.get(PublicMetadata_GEOMETRYCOLLECTION);
				if (isEmpty(keyType) && !isEmpty(geom))
					columnRecord.put(PublicMetadata.KEYTYPE, geomKeyTypeLookup.get(geom));
				
				// make sure title is set
				if (isEmpty(columnRecord.get(PublicMetadata.TITLE)))
				{
					String name = columnRecord.get(PublicMetadata_NAME);
					String year = columnRecord.get(PublicMetadata_YEAR);
					String title = isEmpty(year) ? name : String.format("%s (%s)", name, year);
					columnRecord.put(PublicMetadata.TITLE, title);
				}
				
				// get the id corresponding to the table
				String dataTableName = columnRecord.get(PublicMetadata_DATATABLE);
                if (dataTableName == null)
                {
                    throw new RemoteException("Datatable field missing on column " + columnRecord.toString());
                }
				
                // create the column entity as a child of the table
                DataEntityMetadata columnMetadata = toDataEntityMetadata(columnRecord);
                int tableId = getTableId(dataTableName);
				int columnId = dataConfig.addEntity(DataEntity.TYPE_COLUMN, columnMetadata);
				dataConfig.addChild(tableId, columnId, order++);
				progress.tick();
				autoFlush();
			}
			SQLUtils.cleanup(resultSet);
		    dataConfig.flushInserts();
			/////////////////////////////
			
			conn.commit();
		}
		catch (OutOfMemoryError e)
		{
			e.printStackTrace();
		}
		catch (RemoteException e)
		{
			try {
				conn.rollback();
			} catch (SQLException ex) { }
			
			throw e;
		}
		catch (Exception e)
		{
			try {
				conn.rollback();
			} catch (SQLException ex) { }
			
			throw new RemoteException("Unable to migrate old SQL config to new format.", e);
		}
		finally
		{
			SQLUtils.cleanup(resultSet);
			SQLUtils.cleanup(stmt);
			try {
				conn.setAutoCommit(prevAutoCommit);
			} catch (SQLException e) { }
		}
	}
	
	private void autoFlush() throws RemoteException
	{
		long time = System.nanoTime();
		if (time - lastFlush > FLUSH_INTERVAL)
		{
			dataConfig.flushInserts();
			lastFlush = time;
		}
	}
	
	private int getTableId(String tableName) throws RemoteException
	{
		// pause progress calculation because we don't want the occasional table initialization to affect the time estimate.
		progress.pause();
		
		// lazily create table entries
		int tableId;
		if (tableIdLookup.containsKey(tableName))
		{
			tableId = tableIdLookup.get(tableName);
		}
		else
		{
			// lazily create table metadata
			DataEntityMetadata metadata = tableMetadataLookup.get(tableName);
			if (metadata == null)
				metadata = new DataEntityMetadata();
			
			// copy tableName to "title" property if missing
			if (!metadata.publicMetadata.containsKey(PublicMetadata.TITLE))
				metadata.publicMetadata.put(PublicMetadata.TITLE, tableName);
			
			// create the data table entity and remember the new id
			tableId = dataConfig.addEntity(DataEntity.TYPE_DATATABLE, metadata);
			tableIdLookup.put(tableName, tableId);
		}
		
		progress.resume();
		return tableId;
	}
	
	private static int getSingleIntFromQuery(Statement stmt, String query) throws SQLException
	{
		ResultSet resultSet = null;
		try
		{
			resultSet = stmt.executeQuery(query);
	        resultSet.next();
	        return resultSet.getInt(1);
		}
		finally
		{
			SQLUtils.cleanup(resultSet);
		}
	}
	
	private static boolean isEmpty(String str)
	{
		return str == null || str.length() == 0;
	}
	
	private static Map<String,String> getRecord(ResultSet rs, String[] columnNames) throws SQLException
	{
		Map<String,String> record = new HashMap<String,String>();
		for (String name : columnNames)
			record.put(name, rs.getString(name));
		return record;
	}
	
	private static DataEntityMetadata toDataEntityMetadata(Map<String,String> record)
	{
		DataEntityMetadata result = new DataEntityMetadata();
		for (String field : record.keySet())
		{
			String value = record.get(field);
			if (isEmpty(value))
				continue;
			if (fieldIsPrivate(field))
				result.privateMetadata.put(field, value);
			else
				result.publicMetadata.put(field, value);
		}
		return result;
	}

	private static final String OLD_METADATA_TABLE = "weave_dataset_metadata";
	private static final String OLD_METADATA_COLUMN_ID = "dataTable";
	private static final String OLD_METADATA_COLUMN_PROPERTY = "element";
	private static final String OLD_METADATA_COLUMN_VALUE = "value";
	private static final String PublicMetadata_NAME = "name";
	private static final String PublicMetadata_YEAR = "year";
	private static final String PublicMetadata_DATATABLE = "dataTable";
	private static final String PublicMetadata_GEOMETRYCOLLECTION = "geometryCollection";
	private static final String PrivateMetadata_SCHEMA = "schema";
	private static final String PrivateMetadata_TABLEPREFIX = "tablePrefix";
	private static final String PrivateMetadata_IMPORTNOTES = "importNotes";
	private static boolean fieldIsPrivate(String propertyName)
	{
		String[] names = {
				PrivateMetadata.CONNECTION,
				PrivateMetadata.SQLQUERY,
				PrivateMetadata.SQLPARAMS,
				PrivateMetadata.SQLSCHEMA,
				PrivateMetadata.SQLTABLEPREFIX,
				PrivateMetadata_SCHEMA,
				PrivateMetadata_TABLEPREFIX,
				PrivateMetadata_IMPORTNOTES
		};
		return ListUtils.findString(propertyName, names) >= 0;
	}
}

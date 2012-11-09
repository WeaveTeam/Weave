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

import java.io.PrintStream;
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
import weave.utils.SQLUtils;

/**
 * This class is responsible for migrating from the old SQL config format to a DataConfig object.
 * 
 * @author Andy Dufilie
 */

@Deprecated public class DeprecatedConfig
{
	public static void migrate(ConnectionConfig connConfig, DataConfig dataConfig, PrintStream out)
			throws RemoteException, SQLException, InvalidParameterException
	{
		Connection conn = connConfig.getAdminConnection(); // this will fail if DatabaseConfigInfo is missing
		DatabaseConfigInfo dbInfo = connConfig.getDatabaseConfigInfo();
		Statement stmt = conn.createStatement();
		ResultSet resultSet = null;
		try
		{
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
			
			// init temporary lookup tables
			Map<String,String> geomKeyTypeLookup = new HashMap<String,String>();
			Map<String,Integer> tableIdLookup = new HashMap<String,Integer>();
			Map<String,DataEntityMetadata> tableMetadataLookup = new HashMap<String,DataEntityMetadata>();
			
			String quotedOldMetadataTable = SQLUtils.quoteSchemaTable(conn, dbInfo.schema, OLD_METADATA_TABLE);
			String quotedDataConfigTable = SQLUtils.quoteSchemaTable(conn, dbInfo.schema, dbInfo.dataConfigTable);
			String quotedGeometryConfigTable = SQLUtils.quoteSchemaTable(conn, dbInfo.schema, dbInfo.geometryConfigTable);
			
			/////////////////////////////
			// get dublin core metadata for data tables
			
			out.println("Step 1 of 4. Retrieving old dataset metadata...");
			if (SQLUtils.tableExists(conn, dbInfo.schema, OLD_METADATA_TABLE))
			{
				resultSet = stmt.executeQuery(String.format("SELECT * FROM %s", quotedOldMetadataTable));
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
			
			/////////////////////////////
			// get the set of unique dataTable names, create entities for them and remember the corresponding id numbers
			
			out.println("Step 2 of 4. Generating table entities...");
			resultSet = stmt.executeQuery(String.format("SELECT DISTINCT %s FROM %s", PublicMetadata_DATATABLE, quotedDataConfigTable));
			while (resultSet.next())
			{
				String tableName = resultSet.getString(PublicMetadata_DATATABLE);
				
				// get or create metadata
				DataEntityMetadata metadata = tableMetadataLookup.get(tableName);
				if (metadata == null)
					metadata = new DataEntityMetadata();
				
				// copy tableName to "title" property if missing
				if (!metadata.publicMetadata.containsKey(PublicMetadata.TITLE))
					metadata.publicMetadata.put(PublicMetadata.TITLE, tableName);
				
				// create the data table entity and remember the new id
				int tableId = dataConfig.addEntity(DataEntity.TYPE_DATATABLE, metadata, -1);
				tableIdLookup.put(tableName, tableId);
			}
			SQLUtils.cleanup(resultSet);
			
			/////////////////////////////
			// migrate geometry collections
			
			out.println("Step 3 of 4. Migrating geometry collections");
			resultSet = stmt.executeQuery(String.format("SELECT * FROM %s", quotedGeometryConfigTable));
			String[] columnNames = SQLUtils.getColumnNamesFromResultSet(resultSet);
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
				
				// if there is a dataTable with the same title, add the geometry as a column under that table.
				Integer parentId = tableIdLookup.get(name);
				if (parentId == null)
					parentId = -1;
				
				// create an entity for the geometry column
				DataEntityMetadata geomMetadata = toDataEntityMetadata(geomRecord);
				dataConfig.addEntity(DataEntity.TYPE_COLUMN, geomMetadata, parentId);
			}
			SQLUtils.cleanup(resultSet);
			
			/////////////////////////////
			// migrate columns
			
			out.println("Step 4 of 4. Migrating attribute columns...");
			resultSet = stmt.executeQuery(String.format("SELECT * FROM %s", quotedDataConfigTable));
			columnNames = SQLUtils.getColumnNamesFromResultSet(resultSet);
			while (resultSet.next())
			{
				Map<String,String> columnRecord = getRecord(resultSet, columnNames);
				
				// if key type isn't specified but geometryCollection is, use the keyType of the geometry collection.
				String keyType = columnRecord.get(PublicMetadata.KEYTYPE);
				String geom = columnRecord.get(PublicMetadata_GEOMETRYCOLLECTION);
				if (isEmpty(keyType) && !isEmpty(geom))
					columnRecord.put(PublicMetadata.KEYTYPE, geomKeyTypeLookup.get(geom));
				
				String title = columnRecord.get(PublicMetadata.TITLE);
				String name = columnRecord.get(PublicMetadata_NAME);
				String year = columnRecord.get(PublicMetadata_YEAR);
				// make sure title is set
				if (isEmpty(title))
				{
					title = isEmpty(year) ? name : String.format("%s (%s)", name, year);
					columnRecord.put(PublicMetadata.TITLE, title);
				}
				
				// get the id corresponding to the table
				String dataTableName = columnRecord.get(PublicMetadata_DATATABLE);
				int tableId = tableIdLookup.get(dataTableName);
				
				// create the column entity as a child of the table
				DataEntityMetadata columnMetadata = toDataEntityMetadata(columnRecord);
				dataConfig.addEntity(DataEntity.TYPE_COLUMN, columnMetadata, tableId);
			}
			SQLUtils.cleanup(resultSet);
			
			/////////////////////////////
			
			conn.setAutoCommit(true);
			
			out.println("Done.");
		}
		catch (Exception e)
		{
			SQLUtils.cleanup(resultSet);
			SQLUtils.cleanup(stmt);
			SQLUtils.cleanup(conn);
			throw new RemoteException("Unable to migrate old SQL config data.", e);
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
	private static final String PrivateMetadata_IMPORTNOTES = "importNotes";
	private static boolean fieldIsPrivate(String propertyName)
	{
		String[] names = {
				PrivateMetadata.CONNECTION,
				PrivateMetadata.SQLQUERY,
				PrivateMetadata.SQLPARAMS,
				PrivateMetadata.SQLRESULT,
				PrivateMetadata.SCHEMA,
				PrivateMetadata.TABLEPREFIX,
				PrivateMetadata_IMPORTNOTES
		};
		return ListUtils.findString(propertyName, names) >= 0;
	}
}

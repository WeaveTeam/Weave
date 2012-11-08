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
import java.sql.SQLException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import weave.config.ConnectionConfig.DatabaseConfigInfo;
import weave.config.ConnectionConfig.ImmortalConnection;
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

public class DeprecatedConfig
{
	@SuppressWarnings("deprecation")
	public static void migrate(ConnectionConfig connectionConfig, DataConfig dataConfig)
			throws RemoteException, SQLException, InvalidParameterException
	{
		Connection conn = null;
		try
		{
			DatabaseConfigInfo dbInfo = connectionConfig.getDatabaseConfigInfo();
			
			// check for problems
			if (dbInfo == null)
				throw new InvalidParameterException("databaseConfig missing");
			if (dbInfo.schema == null || dbInfo.schema.length() == 0)
				throw new InvalidParameterException("DatabaseConfig: Schema not specified.");
			if (dbInfo.geometryConfigTable == null || dbInfo.geometryConfigTable.length() == 0)
				throw new InvalidParameterException("DatabaseConfig: Geometry metadata table name not specified.");
			if (dbInfo.dataConfigTable == null || dbInfo.dataConfigTable.length() == 0)
				throw new InvalidParameterException("DatabaseConfig: Column metadata table name not specified.");
			
			// open sql connection
			conn = new ImmortalConnection(connectionConfig).getConnection();
			
			// init temporary lookup tables
			Map<String,String> geomKeyTypeLookup = new HashMap<String,String>();
			Map<String,Integer> dataTableIdLookup = new HashMap<String,Integer>();
			
			// get the set of unique dataTable names, create entities for them and remember the corresponding id numbers
			Set<String> dataTableNames = new HashSet<String>(SQLUtils.getColumn(conn, dbInfo.schema, dbInfo.dataConfigTable, PublicMetadata_DATATABLE));
			for (String tableName : dataTableNames)
			{
				DataEntityMetadata tableMetadata = new DataEntityMetadata();
				tableMetadata.publicMetadata.put(PublicMetadata.TITLE, tableName);
				int tableId = dataConfig.addEntity(DataEntity.TYPE_DATATABLE, tableMetadata, -1);
				dataTableIdLookup.put(tableName, tableId);
			}
			dataTableNames = null;
			
			// migrate geometry collections
			List<Map<String,String>> geomRecords = SQLUtils.getRecordsFromQuery(conn, null, dbInfo.schema, dbInfo.geometryConfigTable, null, String.class);
			for (Map<String,String> geomRecord : geomRecords)
			{
				// change "name" to "title"
				geomRecord.put(PublicMetadata.TITLE, geomRecord.remove(PublicMetadata_NAME));
				
				// save title-to-keyType mapping for later
				String title = geomRecord.get(PublicMetadata.TITLE);
				String keyType = geomRecord.get(PublicMetadata.KEYTYPE);
				geomKeyTypeLookup.put(title, keyType);
				
				// set dataType appropriately
				geomRecord.put(PublicMetadata.DATATYPE, DataType.GEOMETRY);
				
				// if there is a dataTable with the same title, add the geometry as a column under that table.
				Integer parentId = dataTableIdLookup.get(title);
				if (parentId == null)
					parentId = -1;
				
				// create an entity for the geometry column
				DataEntityMetadata geomMetadata = toDataEntityMetadata(geomRecord);
				dataConfig.addEntity(DataEntity.TYPE_COLUMN, geomMetadata, parentId);
			}
			geomRecords = null;
			
			// migrate columns
			List<Map<String,String>> columnRecords = SQLUtils.getRecordsFromQuery(conn, null, dbInfo.schema, dbInfo.dataConfigTable, null, String.class);
			for (Map<String,String> columnRecord : columnRecords)
			{
				// if key type isn't specified but geometryCollection is, use the keyType of the geometry collection.
				String keyType = columnRecord.get(PublicMetadata.KEYTYPE);
				String geom = columnRecord.remove(PublicMetadata_GEOMETRYCOLLECTION); // remove it
				if (isEmpty(keyType) && !isEmpty(geom))
					columnRecord.put(PublicMetadata.KEYTYPE, geomKeyTypeLookup.get(geom));
				
				// if title is missing, use "name (year)"
				String title = columnRecord.get(PublicMetadata.TITLE);
				String name = columnRecord.get(PublicMetadata_NAME);
				String year = columnRecord.get(PublicMetadata_YEAR);
				if (isEmpty(title))
				{
					if (isEmpty(year))
					{
						// if no year is specified, remove the "name" property and use it as the title
						title = columnRecord.remove(PublicMetadata_NAME);
					}
					else
					{
						title = String.format("%s (%s)", name, year);
					}
					columnRecord.put(PublicMetadata.TITLE, title);
				}
				
				String dataTableName = columnRecord.remove(PublicMetadata_DATATABLE); // remove it
				int tableId = dataTableIdLookup.get(dataTableName);
				DataEntityMetadata columnMetadata = toDataEntityMetadata(columnRecord);
				dataConfig.addEntity(DataEntity.TYPE_COLUMN, columnMetadata, tableId);
			}
			columnRecords = null;
			
			// migrate metadata
			DublinCoreUtils.migrate(conn, dataTableIdLookup, dataConfig);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
	}
	
	private static boolean isEmpty(String str)
	{
		return str == null || str.length() == 0;
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

	private static final String PublicMetadata_NAME = "name";
	private static final String PublicMetadata_YEAR = "name";
	private static final String PublicMetadata_DATATABLE = "dataTable";
	private static final String PublicMetadata_GEOMETRYCOLLECTION = "geometryCollection";
	private static boolean fieldIsPrivate(String propertyName)
	{
		String[] names = {
				PrivateMetadata.CONNECTION,
				PrivateMetadata.SQLQUERY,
				PrivateMetadata.SQLPARAMS,
				PrivateMetadata.SQLRESULT,
				PrivateMetadata.SCHEMA,
				PrivateMetadata.TABLEPREFIX,
				"importNotes"
		};
		return ListUtils.findString(propertyName, names) >= 0;
	}
}

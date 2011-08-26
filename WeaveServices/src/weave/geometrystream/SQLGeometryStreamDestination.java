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

package weave.geometrystream;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;


import weave.utils.SQLUtils;
import weave.utils.SerialIDGenerator;

/**
 * This class writes a geometry stream to a SQL table.
 * 
 * @author adufilie
 */
public class SQLGeometryStreamDestination implements GeometryStreamDestination
{
	/**
	 * @param conn The SQL connection to use to create tables.
	 * @param sqlSchema The schema to use when creating a table.
	 * @param sqlTablePrefix The prefix that will be used when generating table names for metadata and geometry tiles.
	 * @param overwriteTables If true and the sql tables exist, an SQLException will be thrown.
	 * @throws SQLException Thrown if the sql tables could not be created.
	 */
	public SQLGeometryStreamDestination(Connection conn, String sqlSchema, String sqlTablePrefix, boolean overwriteTables) throws SQLException
	{
		super();
		this.conn = conn;
		conn.setAutoCommit(false);
		this.dbms = conn.getMetaData().getDatabaseProductName();
		this.sqlSchema = sqlSchema;
		this.sqlMetadataTable = sqlTablePrefix + SQL_TABLE_METADATA_SUFFIX;
		this.sqlGeometryTable = sqlTablePrefix + SQL_TABLE_GEOMETRY_SUFFIX;
		this.overwriteTables = overwriteTables;

		if (!overwriteTables)
			if (SQLUtils.tableExists(conn, sqlSchema, sqlMetadataTable) || SQLUtils.tableExists(conn, sqlSchema, sqlGeometryTable))
				throw new SQLException("SQL Tables already exist.");
		createTileTable(sqlMetadataTable);
		createTileTable(sqlGeometryTable);
	}
	
	public static final String SQL_TABLE_METADATA_SUFFIX = "_metadata";
	public static final String SQL_TABLE_GEOMETRY_SUFFIX = "_geometry";
	public static final String MIN_IMPORTANCE = "minImportance";
	public static final String MAX_IMPORTANCE = "maxImportance";
	public static final String X_MIN_BOUNDS = "xMinBounds";
	public static final String Y_MIN_BOUNDS = "yMinBounds";
	public static final String X_MAX_BOUNDS = "xMaxBounds";
	public static final String Y_MAX_BOUNDS = "yMaxBounds";
	public static final String TILE_ID = "tileID";
	public static final String TILE_DATA = "tileData";
	private Connection conn;
	private String dbms;
	private String sqlSchema;
	private String sqlMetadataTable;
	private String sqlGeometryTable;
	private boolean overwriteTables;
	protected SerialIDGenerator metadataTileIDGenerator = new SerialIDGenerator();
	protected SerialIDGenerator geometryTileIDGenerator = new SerialIDGenerator();

	public String getMetadataTableName()
	{
		return sqlMetadataTable;
	}
	
	public String getGeometryTableName()
	{
		return sqlGeometryTable;
	}

	protected void createTileTable(String sqlTable) throws SQLException
	{
		// create schema if it doesn't exist
		if (!SQLUtils.schemaExists(conn, sqlSchema))
			SQLUtils.createSchema(conn, sqlSchema);

		// overwrite table
		if (overwriteTables)
			SQLUtils.dropTableIfExists(conn, sqlSchema, sqlTable);
		
		String doubleType = SQLUtils.getDoubleTypeString(conn);
		String[] def = new String[]{
				MIN_IMPORTANCE, doubleType,
				MAX_IMPORTANCE, doubleType,
				X_MIN_BOUNDS, doubleType,
				Y_MIN_BOUNDS, doubleType,
				X_MAX_BOUNDS, doubleType,
				Y_MAX_BOUNDS, doubleType,
				TILE_ID, "BIGINT PRIMARY KEY",
				TILE_DATA, SQLUtils.binarySQLType(dbms)
		};
		
		List<String> colNames = new Vector<String>();
		List<String> colTypes = new Vector<String>();
		for (int i = 0; i < def.length; i += 2)
		{
			colNames.add(def[i]);
			colTypes.add(def[i + 1]);
		}
		SQLUtils.createTable(conn, sqlSchema, sqlTable, colNames, colTypes);
		SQLUtils.createIndex(conn, sqlSchema, sqlTable, new String[]{X_MIN_BOUNDS,Y_MIN_BOUNDS,X_MAX_BOUNDS,Y_MAX_BOUNDS});
	}

	public void writeMetadataTiles(List<StreamTile> tiles) throws Exception
	{
		writeTilesToSQL(tiles, sqlMetadataTable, metadataTileIDGenerator);
	}
	
	public void writeGeometryTiles(List<StreamTile> tiles) throws Exception
	{
		writeTilesToSQL(tiles, sqlGeometryTable, geometryTileIDGenerator);
	}

	public void commit() throws Exception
	{
		conn.commit();
		SQLUtils.cleanup(conn);
	}
	
	protected void writeTilesToSQL(List<StreamTile> streamTiles, String sqlTable, SerialIDGenerator tileIDGenerator)
		throws IOException, SQLException
	{
		// loop through tiles, adding entries to sql table
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		DataOutputStream data = new DataOutputStream(baos);
		for (int i = 0; i < streamTiles.size(); i++)
		{
			int tileID = tileIDGenerator.getNext();
			// reset temp output stream
			baos.reset();
			// copy tile data to temp output stream
			StreamTile tile = streamTiles.get(i);
			tile.writeStream(data, tileID);

			// save tile data in sql table
			Map<String, Object> values = new HashMap<String, Object>();
			values.put(MIN_IMPORTANCE, tile.minImportance);
			values.put(MAX_IMPORTANCE, tile.maxImportance);
			values.put(X_MIN_BOUNDS, tile.queryBounds.xMin);
			values.put(Y_MIN_BOUNDS, tile.queryBounds.yMin);
			values.put(X_MAX_BOUNDS, tile.queryBounds.xMax);
			values.put(Y_MAX_BOUNDS, tile.queryBounds.yMax);
			values.put(TILE_ID, tileID);
			values.put(TILE_DATA, baos.toByteArray());
			SQLUtils.insertRow(conn, sqlSchema, sqlTable, values);
		}
	}
}

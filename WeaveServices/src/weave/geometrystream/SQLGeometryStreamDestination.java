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
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

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
				throw new SQLException("SQL Tables already exist and overwriteTables is false.");
		createTileTable(sqlMetadataTable);
		createTileTable(sqlGeometryTable);
	}
	
	public static final String SQL_TABLE_METADATA_SUFFIX = "_metadata";
	public static final String SQL_TABLE_GEOMETRY_SUFFIX = "_geometry";
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
		// create sql table
		String quotedSchemaTable = SQLUtils.quoteSchemaTable(dbms, sqlSchema, sqlTable);
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();

			// create schema if it doesn't exist
			if (!SQLUtils.schemaExists(conn, sqlSchema))
				stmt.executeUpdate("CREATE SCHEMA " + sqlSchema);

			// overwrite table
			if (overwriteTables)
				stmt.executeUpdate("DROP TABLE IF EXISTS " + quotedSchemaTable);
    		String query = "CREATE TABLE "+quotedSchemaTable+" ("
    			+ " minImportance DOUBLE PRECISION, maxImportance DOUBLE PRECISION,"
    			+ " xMinBounds DOUBLE PRECISION, yMinBounds DOUBLE PRECISION, xMaxBounds DOUBLE PRECISION, yMaxBounds DOUBLE PRECISION,"
    			+ " tileID INT, tileData " + SQLUtils.binarySQLType(dbms) + ","
    			+ " PRIMARY KEY (tileID)"
    			+ ")";
    		stmt.executeUpdate(query);
			query = "CREATE INDEX " + SQLUtils.quoteSymbol(dbms, sqlTable + "_index")
				+ " ON " + quotedSchemaTable + " (xMinBounds,yMinBounds,xMaxBounds,yMaxBounds)";
			stmt.executeUpdate(query);
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
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
		String quotedSchemaTable = SQLUtils.quoteSchemaTable(dbms, sqlSchema, sqlTable);
		
		CallableStatement cstmt = null;
		try
		{
			// loop through tiles, adding entries to sql table
			cstmt = conn.prepareCall("insert into "+quotedSchemaTable+" values (?,?, ?,?,?,?, ?,?);");
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			DataOutputStream data = new DataOutputStream(baos);
			StreamTile tile;
			int paramIndex, tileID;
			for (int i = 0; i < streamTiles.size(); i++)
			{
				tileID = tileIDGenerator.getNext();
				// reset temp output stream
				baos.reset();
				// copy tile data to temp output stream
				tile = streamTiles.get(i);
				tile.writeStream(data, tileID);
				// save tile data in sql table
				paramIndex = 1;
				cstmt.setDouble(paramIndex++, tile.minImportance);
				cstmt.setDouble(paramIndex++, tile.maxImportance);
				cstmt.setDouble(paramIndex++, tile.queryBounds.xMin);
				cstmt.setDouble(paramIndex++, tile.queryBounds.yMin);
				cstmt.setDouble(paramIndex++, tile.queryBounds.xMax);
				cstmt.setDouble(paramIndex++, tile.queryBounds.yMax);
				cstmt.setInt(paramIndex++, tileID);
				cstmt.setBytes(paramIndex++, baos.toByteArray());
				cstmt.executeUpdate();
			}
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		finally
		{
			SQLUtils.cleanup(cstmt);
		}
	}
}

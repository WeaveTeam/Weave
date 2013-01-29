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

package weave.utils;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.rmi.RemoteException;
import java.security.InvalidParameterException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;

import org.postgresql.PGConnection;

/**
 * @author Andy Dufilie
 */
public abstract class BulkSQLLoader
{
	public static BulkSQLLoader newInstance(Connection conn, String schema, String table, String[] fieldNames) throws RemoteException
	{
		if (SQLUtils.isOracleServer(conn) || SQLUtils.isSQLServer(conn))
			return new BulkSQLLoader_Direct(conn, schema, table, fieldNames);
		else
			return new BulkSQLLoader_CSV(conn, schema, table, fieldNames);
	}
	
	////////////////////////////////
	////////////////////////////////
	
	protected Connection conn;
	protected String schema;
	protected String table;
	protected String[] fieldNames;
	
	private BulkSQLLoader(Connection conn, String schema, String table, String[] fieldNames)
	{
		this.conn = conn;
		this.schema = schema;
		this.table = table;
		this.fieldNames = fieldNames;
	}
	public abstract void addRow(Object ... values) throws RemoteException;
	public abstract void flush() throws RemoteException;
	
	////////////////////////////////
	////////////////////////////////
	
	public static class BulkSQLLoader_Direct extends BulkSQLLoader
	{
		private PreparedStatement stmt = null;
		private boolean prevAutoCommit;
		
		public BulkSQLLoader_Direct(Connection conn, String schema, String table, String[] fieldNames) throws RemoteException
		{
			super(conn, schema, table, fieldNames);
			
			try
			{
				prevAutoCommit = conn.getAutoCommit();
				if (prevAutoCommit)
					conn.setAutoCommit(false);
				
				String quotedTable = SQLUtils.quoteSchemaTable(conn, schema, table);
				String query = String.format(
						"INSERT INTO %s values (%s)",
						quotedTable,
						StringUtils.mult(",", "?", fieldNames.length)
					);
				stmt = conn.prepareStatement(query);
			}
			catch (SQLException e)
			{
				throw new RemoteException("Error initializing SQLBulkLoader_Direct", e);
			}
		}
		
		@Override
		public void addRow(Object... values) throws RemoteException
		{
			if (stmt == null)
				throw new RemoteException("Bulk loader unable to continue after failure");
			
			try
			{
				SQLUtils.setPreparedStatementParams(stmt, values);
				stmt.execute();
			}
			catch (SQLException e)
			{
				SQLUtils.cleanup(stmt);
				try {
					conn.rollback();
				} catch (SQLException ex) { }
				try {
					conn.setAutoCommit(prevAutoCommit);
				} catch (SQLException ex) { }
				
				stmt = null;
				conn = null;
				throw new RemoteException("Unable to insert record", e);
			}
		}
		
		@Override
		public void flush() throws RemoteException
		{
			try
			{
				conn.commit();
			}
			catch (SQLException e)
			{
				throw new RemoteException("Unable to flush records", e);
			}
		}
		
		@Override
		protected void finalize() throws Throwable
		{
			SQLUtils.cleanup(stmt);
			
			try {
				conn.setAutoCommit(prevAutoCommit);
			} catch (SQLException ex) { }
			
			super.finalize();
		}
	}
	
	////////////////////////////////
	////////////////////////////////
	
	public static class BulkSQLLoader_CSV extends BulkSQLLoader
	{
		protected CSVParser parser;
		protected String outputNullValue;
		protected boolean quoteEmptyStrings;
		protected File file;
		protected FileWriter writer;
		protected Object[][] tempRows = new Object[1][];

		public BulkSQLLoader_CSV(Connection conn, String schema, String table, String[] fieldNames) throws RemoteException
		{
			super(conn, schema, table, fieldNames);
			
			try
			{
				this.tempRows[0] = new Object[fieldNames.length];
				outputNullValue = SQLUtils.getCSVNullValue(conn);
				quoteEmptyStrings = outputNullValue.length() > 0;
				
				String dbms = conn.getMetaData().getDatabaseProductName();
				// special case for Microsoft SQL Server because it does not support quotes.
				if (SQLUtils.SQLSERVER.equalsIgnoreCase(dbms))
					parser = new CSVParser(SQL_SERVER_CSV_DELIMETER);
				else
					parser = CSVParser.defaultParser;
				
				file = File.createTempFile("Weave", ".csv");
				file.deleteOnExit();
				writer = new FileWriter(file);
				
				addRow((Object[])fieldNames); // header
			}
			catch (Exception e)
			{
				throw new RemoteException("Unable to initialize bulk loader", e);
			}
		}
		
		public void addRow(Object ... values) throws RemoteException
		{
			if (file == null)
				throw new RemoteException("Bulk loader unable to continue after failure");
			
			try
			{
				if (values.length != fieldNames.length)
					throw new InvalidParameterException("Number of values does not match number of fields");
				
				int i = 0;
				for (Object value : values)
					tempRows[0][i++] = value == null ? outputNullValue : value;
				
				parser.createCSV(tempRows, quoteEmptyStrings, writer, true);
			}
			catch (Exception e)
			{
				file.delete();
				file = null;
				throw new RemoteException("Unable to add row", e);
			}
		}
		
		public void flush() throws RemoteException
		{
			if (file == null)
				throw new RemoteException("Bulk loader unable to continue after failure");
			
			try
			{
				// finalize data
				writer.flush();
				writer.close();
				writer = null;
				
				copyCsvToDatabase(conn, file.getAbsolutePath(), schema, table);
				
				// start from the beginning
				writer = new FileWriter(file);
				addRow((Object[])fieldNames); // header
			}
			catch (Exception e)
			{
				file.delete();
				file = null;
				throw new RemoteException("Unable to flush rows", e);
			}
		}
	}

	public static final char SQL_SERVER_CSV_DELIMETER = (char)8;
	
	public static void copyCsvToDatabase(Connection conn, String csvPath, String sqlSchema, String sqlTable) throws SQLException, IOException
	{
		String query = null;
		String formatted_CSV_path = csvPath.replace('\\', '/');
		String dbms = conn.getMetaData().getDatabaseProductName();
		Statement stmt = null;
		String quotedTable = SQLUtils.quoteSchemaTable(conn, sqlSchema, sqlTable);

		try
		{
			if (dbms.equalsIgnoreCase(SQLUtils.MYSQL))
			{
				stmt = conn.createStatement();
				//ignoring 1st line so that we don't put the column headers as the first row of data
				query = String.format(
						"load data local infile '%s' into table %s fields terminated by ',' enclosed by '\"' lines terminated by '\\n' ignore 1 lines",
						formatted_CSV_path, quotedTable
					);
				stmt.executeUpdate(query);
				stmt.close();
			}
			else if (dbms.equalsIgnoreCase(SQLUtils.ORACLE))
			{
				// Insert each row repeatedly
				boolean prevAutoCommit = conn.getAutoCommit();
				if (prevAutoCommit)
					conn.setAutoCommit(false);
				
				String[][] rows = CSVParser.defaultParser.parseCSV(new File(formatted_CSV_path), true);
				query = String.format("INSERT INTO %s values (%s)", quotedTable, StringUtils.mult(",", "?", rows[0].length));
				
				PreparedStatement pstmt = null;
				try
				{
					pstmt = conn.prepareStatement(query);
					for (int row = 1; row < rows.length; row++) //Skip header line
					{
						SQLUtils.setPreparedStatementParams(pstmt, rows[row]);
						pstmt.execute();
					}
				}
				catch (SQLException e)
				{
					conn.rollback();
					throw new RemoteException(e.getMessage(), e);
				}
				finally
				{
					SQLUtils.cleanup(pstmt);
					try {
						conn.setAutoCommit(prevAutoCommit);
					} catch (SQLException e) { }
				}
			}
			else if (dbms.equalsIgnoreCase(SQLUtils.POSTGRESQL))
			{
				query = String.format("COPY %s FROM STDIN WITH CSV HEADER", quotedTable);
				((PGConnection) conn).getCopyAPI().copyIn(query, new FileInputStream(formatted_CSV_path));
			}
			else if (dbms.equalsIgnoreCase(SQLUtils.SQLSERVER))
			{
				stmt = conn.createStatement();

				// sql server expects the actual EOL character '\n', and not the textual representation '\\n'
				query = String.format(
						"BULK INSERT %s FROM '%s' WITH ( FIRSTROW = 2, FIELDTERMINATOR = '%s', ROWTERMINATOR = '\n', KEEPNULLS )",
						quotedTable, formatted_CSV_path, BulkSQLLoader_CSV.SQL_SERVER_CSV_DELIMETER
					);
				stmt.executeUpdate(query);
			}
		}
		catch (SQLException e)
		{
			throw new SQLExceptionWithQuery(query, e);
		}
		finally 
		{
			SQLUtils.cleanup(stmt);
		}
	}
}

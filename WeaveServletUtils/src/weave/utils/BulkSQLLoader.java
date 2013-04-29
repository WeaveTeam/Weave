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
import java.util.Arrays;
import java.util.Vector;

import org.postgresql.PGConnection;

/**
 * @author Andy Dufilie
 */
public abstract class BulkSQLLoader
{
	public static File temporaryFilesDirectory = null;
	
	public static BulkSQLLoader newInstance(Connection conn, String schema, String table, String[] fieldNames) throws RemoteException
	{
		// BulkSQLLoader_CSV doesn't work for mysql unless LOAD DATA LOCAL feature is enabled...
		
		String dbms = SQLUtils.getDbmsFromConnection(conn);
		if (dbms.equals(SQLUtils.POSTGRESQL))
			return new BulkSQLLoader_CSV(conn, schema, table, fieldNames);
		else
			return new BulkSQLLoader_Direct(conn, schema, table, fieldNames);
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
		public static int DEFAULT_BUFFER_SIZE = 100;
		private String baseQuery;
		private String rowQuery;
		private PreparedStatement stmt;
		private boolean prevAutoCommit;
		private Vector<Object[]> rowBuffer = null;
		private int _queryRowCount = 0;
		
		public BulkSQLLoader_Direct(Connection conn, String schema, String table, String[] fieldNames) throws RemoteException
		{
			super(conn, schema, table, fieldNames);
			
			try
			{
				prevAutoCommit = conn.getAutoCommit();
				if (prevAutoCommit)
					conn.setAutoCommit(false);
				
				String quotedTable = SQLUtils.quoteSchemaTable(conn, schema, table);
				
				String[] columns = new String[fieldNames.length];
				for (int i = 0; i < fieldNames.length; i++)
					columns[i] = SQLUtils.quoteSymbol(conn, fieldNames[i]);
			    
				baseQuery = String.format("INSERT INTO %s(%s) VALUES ", quotedTable, StringUtils.join(",", columns));
			    
			    rowQuery = "(" + StringUtils.mult(",", "?", fieldNames.length) + ")";
			    
			    rowBuffer = new Vector<Object[]>(setQueryRowCount(DEFAULT_BUFFER_SIZE));
			}
			catch (SQLException e)
			{
				throw new RemoteException("Error initializing BulkSQLLoader_Direct", e);
			}
		}
		
		private int setQueryRowCount(int rowCount) throws SQLException
		{
			// only update query if required
			if (_queryRowCount != rowCount)
			{
				// workaround for limitation in SQLServer driver
	            int[] attemptedLimits = new int[]{Integer.MAX_VALUE, 2000, 1000, 255, 1};
				for (int i = 0; i < attemptedLimits.length; i++)
				{
					if (rowCount * fieldNames.length > attemptedLimits[i])
						rowCount = (int)Math.floor(attemptedLimits[i] / fieldNames.length);
					if (rowCount < 1)
						rowCount = 1;
					
					try
					{
						String query = baseQuery + StringUtils.mult(",", rowQuery, rowCount);
						stmt = conn.prepareStatement(query);
						_queryRowCount = rowCount;
						break; // success
					}
					catch (SQLException e)
					{
						// fail only on last attempt or after rowBuffer has been created.
						if (rowBuffer != null || i == attemptedLimits.length - 1 || rowCount == 1)
						{
							_queryRowCount = 0;
							throw e;
						}
					}
				}
			}
			return _queryRowCount;
		}
		
		@Override
		public void addRow(Object... values) throws RemoteException
		{
			if (stmt == null)
				throw new RemoteException("Bulk loader unable to continue after failure");
			if (values.length != fieldNames.length)
				throw new RemoteException(String.format("Number of values does not match number of fields (Expected %s, received %s)", fieldNames.length, values.length));
			
			try
			{
				rowBuffer.add(values);
				if (rowBuffer.size() == rowBuffer.capacity())
					flushBuffer();
			}
			catch (SQLException e)
			{
				throw new RemoteException("Unable to insert record", e);
			}
		}
		
		private void flushBuffer() throws SQLException
		{
			if (rowBuffer.size() == 0)
				return;
			
			// flatten rows into a single params list
			Object[] queryParams = new Object[rowBuffer.size() * fieldNames.length];
			int i = 0;
			for (Object[] row : rowBuffer)
				for (Object value : row)
					queryParams[i++] = value;
			
			setQueryRowCount(rowBuffer.size());
			
			try
			{
				SQLUtils.setPreparedStatementParams(stmt, queryParams);
				stmt.execute();
			}
			catch (SQLException e)
			{
				try {
					conn.rollback();
				} catch (SQLException ex) { }
				
				try { 
					finalize();
				} catch (Throwable thrown) { }
				
				stmt = null;
				conn = null;
				
				System.err.println("Failed to insert values: " + Arrays.deepToString(rowBuffer.toArray()));
				e = new SQLExceptionWithQuery(baseQuery + "(...)", e);
				throw e;
			}
			finally
			{
				rowBuffer.removeAllElements();
			}
		}
		
		@Override
		public void flush() throws RemoteException
		{
			try
			{
				flushBuffer();
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
				String dbms = conn.getMetaData().getDatabaseProductName();
				if (!dbms.equalsIgnoreCase(SQLUtils.MYSQL) && !dbms.equalsIgnoreCase(SQLUtils.POSTGRESQL))
					throw new RemoteException("BulkSQLLoader_CSV does not support " + dbms);
			}
			catch (SQLException e)
			{
				throw new RemoteException("Unable to initialize bulk loader", e);
			}

			try
			{
				this.tempRows[0] = new Object[fieldNames.length];
				outputNullValue = SQLUtils.getCSVNullValue(conn);
				quoteEmptyStrings = outputNullValue.length() > 0;
				
				file = File.createTempFile("Weave", ".csv", temporaryFilesDirectory);
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
				
				CSVParser.defaultParser.createCSV(tempRows, quoteEmptyStrings, writer, true);
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
			else if (dbms.equalsIgnoreCase(SQLUtils.POSTGRESQL))
			{
				query = String.format("COPY %s FROM STDIN WITH CSV HEADER", quotedTable);
				((PGConnection) conn).getCopyAPI().copyIn(query, new FileInputStream(formatted_CSV_path));
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

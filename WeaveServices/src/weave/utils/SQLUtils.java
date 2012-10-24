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
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.rmi.RemoteException;
import java.security.InvalidParameterException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Vector;

import org.postgresql.PGConnection;


/**
 * SQLUtils
 * 
 * @author Andy Dufilie
 * @author Andrew Wilkinson
 * @author Kyle Monico
 * @author Yen-Fu Luo
 * @author Philip Kovac
 */
public class SQLUtils
{
	public static String MYSQL = "MySQL";
	public static String POSTGRESQL = "PostgreSQL";
	public static String SQLSERVER = "Microsoft SQL Server";
	public static String ORACLE = "Oracle";
	
	public static String ORACLE_SERIAL_TYPE = "ORACLE_SERIAL_TYPE"; // used internally in createTable(), not an actual valid type
	
	/**
	 * @param dbms The name of a DBMS (MySQL, PostGreSQL, ...)
	 * @return A driver name that can be used in the getConnection() function.
	 */
	public static String getDriver(String dbms)
	{
		if (dbms.equalsIgnoreCase(MYSQL))
			return "com.mysql.jdbc.Driver";
		if (dbms.equalsIgnoreCase(POSTGRESQL))
			return "org.postgresql.Driver";
		if (dbms.equalsIgnoreCase(SQLSERVER))
			return "net.sourceforge.jtds.jdbc.Driver";
		if (dbms.equalsIgnoreCase(ORACLE))
			return "oracle.jdbc.OracleDriver";
		return "";
	}

	/**
	 * @param dbms The name of a DBMS (MySQL, PostGreSQL, Microsoft SQL Server)
	 * @param ip The IP address of the DBMS.
	 * @param port The port the DBMS is on (optional, can be "" to use default).
	 * @param database The name of a database to connect to (can be "" for MySQL)
	 * @param user The username to use when connecting.
	 * @param pass The password associated with the username.
	 * @return A connect string that can be used in the getConnection() function.
	 */
	public static String getConnectString(String dbms, String ip, String port, String database, String user, String pass)
	{
		String host;
		if (port == null || port.length() == 0)
			host = ip; // default port for specific dbms will be used
		else
			host = ip + ":" + port;
		
		String format = null;
		if (SQLSERVER.equalsIgnoreCase(dbms))
		{
			dbms = "sqlserver"; // this will be put in the format string
			format = "jdbc:jtds:%s://%s/;instance=%s;user=%s;password=%s";
		}
		else if (ORACLE.equalsIgnoreCase(dbms))
		{
			format = "jdbc:%s:thin:%s/%s@%s:%s";
			//"jdbc:oracle:thin:<user>/<password>@<host>:<port>:<instance>"
		}
		else // MySQL or PostGreSQL
		{
			format = "jdbc:%s://%s/%s?user=%s&password=%s";
		}

		// MySQL connect string uses % as an escape character, so we must use URLEncoder.
		// PostGreSQL does not support % as an escape character, and does not work with the & character.
		if (dbms.equalsIgnoreCase(MYSQL))
		{
			try
			{
				String utf = "UTF-8";
				database = URLEncoder.encode(database, utf);
				user = URLEncoder.encode(user, utf);
				pass = URLEncoder.encode(pass, utf);
			}
			catch (UnsupportedEncodingException e)
			{
				// this should never happen
				throw new RuntimeException(e);
			}
		}
		
		String result = "";
		if (dbms.equalsIgnoreCase(ORACLE))
			result = String.format(format, dbms.toLowerCase(), user, pass, host, database);
		else
			result = String.format(format, dbms.toLowerCase(), host, database, user, pass);

		return result;
	}
	
	/**
	 * This maps a driver name to a Driver instance.
	 * The purpose of this map is to avoid instantiating extra Driver objects unnecessarily.
	 */
	private static Map<String, Driver> _driverMap = new HashMap<String, Driver>();

	/**
	 * This maps a connection string to a Connection object.  Used by getStaticReadOnlyConnection().
	 */
	private static Map<String, Connection> _staticReadOnlyConnections = new HashMap<String, Connection>();
	
	/**
	 * This function will test a connection by running a simple test query.
	 * @param conn A SQL Connection.
	 * @throws SQLException Thrown if the test query fails.
	 */
	public static void testConnection(Connection conn) throws SQLException
	{
		PreparedStatement stmt = null;
		try
		{
			// run test query to see if connection is valid
			if (SQLUtils.isOracleServer(conn))
				stmt = conn.prepareStatement("SELECT 0 FROM DUAL");
			else
				stmt = conn.prepareStatement("SELECT 0;");
			stmt.execute(); // this will throw an exception if the connection is invalid
		}
		catch (RuntimeException e) // This is important for catching unexpected errors.
		{
			/*
				java.lang.NullPointerException
				at com.mysql.jdbc.PreparedStatement.fillSendPacket(PreparedStatement.java:2484)
				at com.mysql.jdbc.PreparedStatement.fillSendPacket(PreparedStatement.java:2460)
				at com.mysql.jdbc.PreparedStatement.execute(PreparedStatement.java:1298)
				at weave.utils.SQLUtils.testConnection(SQLUtils.java:173)
				[...]
			 */
			throw new SQLException("Connection is invalid", e);
		}
		finally
		{
			cleanup(stmt);
		}
	}

	/**
	 * This function tests if a given Connection is valid, and closes the connection if it is not.
	 * @param conn A Connection object which may or may not be valid.
	 * @return A value of true if the given Connection is still connected.
	 */
	public static boolean connectionIsValid(Connection conn)
	{
		if (conn == null)
			return false;
		
		try
		{
			testConnection(conn);
			return true;
		}
		catch (SQLException e)
		{
			SQLUtils.cleanup(conn);
		}
		
		return false;
	}
	
	/**
	 * This function returns a read-only connection that can be reused.  The connection should not be closed.
	 * @param driver An SQL driver to use.
	 * @param connectString The connect string used to create the Connection.
	 * @return A static read-only Connection.
	 */
	public static Connection getStaticReadOnlyConnection(String driver, String connectString) throws RemoteException
	{
		synchronized (_staticReadOnlyConnections)
		{
			Connection conn = null;
			if (_staticReadOnlyConnections.containsKey(connectString))
			{
				conn = _staticReadOnlyConnections.get(connectString);
				if (connectionIsValid(conn))
					return conn;
				// if connection is not valid, remove this entry from the Map
				_staticReadOnlyConnections.remove(connectString);
			}
			
			// get a new connection, throwing an exception if this fails
			conn = getConnection(driver, connectString);
			
			// try to set readOnly.. if this fails, continue anyway.
			try
			{
				conn.setReadOnly(true);
			}
			catch (SQLException e)
			{
				e.printStackTrace();
			}
			
			// remember this static, read-only connection.
			if (conn != null)
				_staticReadOnlyConnections.put(connectString, conn);

			return conn;
		}
	}
	
	/**
	 * @param driver The JDBC driver to use.
	 * @param connectString The connect string to use.
	 * @return A new SQL connection using the specified driver & connect string 
	 */
	public static Connection getConnection(String driver, String connectString) throws RemoteException
	{
		Connection conn = null;
		try
		{
			// only call newInstance once per driver
			if (!_driverMap.containsKey(driver))
				_driverMap.put(driver, (Driver)Class.forName(driver).newInstance());

			conn = DriverManager.getConnection(connectString);
		}
		catch (SQLException ex)
		{
			System.out.println(String.format("driver: %s\nconnectString: %s", driver, connectString));
			throw new RemoteException("Unable to connect to SQL database", ex);
		}
		catch (Exception ex)
		{
			throw new RemoteException("Failed to load driver: \"" + driver + "\"", ex);
		}
		return conn;
	}

	/**
	 * @param dbms The name of a DBMS (MySQL, PostGreSQL, ...)
	 * @param symbol The symbol to quote.
	 * @return The symbol surrounded in quotes, usable in queries for the specified DBMS.
	 */
	public static String quoteSymbol(String dbms, String symbol) throws IllegalArgumentException
	{
		//the quote symbol is required for names of variables that include spaces or special characters

		String openQuote, closeQuote;
		if (dbms.equalsIgnoreCase(MYSQL))
		{
			openQuote = closeQuote = "`";
		}
		else if (dbms.equalsIgnoreCase(POSTGRESQL) || dbms.equalsIgnoreCase(ORACLE))
		{
			openQuote = closeQuote = "\"";
		}
		else if (dbms.equalsIgnoreCase(SQLSERVER))
		{
			openQuote = "[";
			closeQuote = "]";
		}
		else
			throw new IllegalArgumentException("Unsupported DBMS type: "+dbms);
		
		if (symbol.contains(openQuote) || symbol.contains(closeQuote))
			throw new IllegalArgumentException(String.format("Unable to surround SQL symbol with quote marks (%s%s) because it already contains one: %s", openQuote, closeQuote, symbol));
		
		return openQuote + symbol + closeQuote;
	}
	
	/**
	 * @param conn An SQL connection.
	 * @param symbol The symbol to quote.
	 * @return The symbol surrounded in quotes, usable in queries for the specified connection.
	 */
	public static String quoteSymbol(Connection conn, String symbol) throws SQLException, IllegalArgumentException
	{
		String dbms = conn.getMetaData().getDatabaseProductName();
		return quoteSymbol(dbms, symbol);
	}
	
	/**
	 * @param dbms The name of a DBMS (MySQL, PostGreSQL, ...)
	 * @param symbol The quoted symbol.
	 * @return The symbol without its dbms-specific quotes.
	 */
	public static String unquoteSymbol(String dbms, String symbol)
	{
		char openQuote, closeQuote;
		int length = symbol.length();
		if (dbms.equalsIgnoreCase(MYSQL))
		{
			openQuote = closeQuote = '`';
		}
		else if (dbms.equalsIgnoreCase(POSTGRESQL) || dbms.equalsIgnoreCase(ORACLE))
		{
			openQuote = closeQuote = '"';
		}
		else if (dbms.equalsIgnoreCase(SQLSERVER))
		{
			openQuote = '[';
			closeQuote = ']';
		}
		else
			throw new IllegalArgumentException("Unsupported DBMS type: "+dbms);

		String result = symbol;
		if (length > 2 && symbol.charAt(0) == openQuote && symbol.charAt(length - 1) == closeQuote)
			result = symbol.substring(1, length - 1);
		if (result.indexOf(openQuote) >= 0 || result.indexOf(closeQuote) >= 0)
			throw new IllegalArgumentException("Cannot unquote symbol: "+symbol);
		
		return result;
	}

	/**
	 * @param conn An SQL connection.
	 * @param symbol The quoted symbol.
	 * @return The symbol without its dbms-specific quotes.
	 */
	public static String unquoteSymbol(Connection conn, String symbol) throws SQLException
	{
		char quote = conn.getMetaData().getIdentifierQuoteString().charAt(0);
		int length = symbol.length();
		String result = symbol;
		if (length > 2 && symbol.charAt(0) == quote && symbol.charAt(length - 1) == quote)
			result = symbol.substring(1, length - 1);
		if (result.indexOf(quote) >= 0)
			throw new IllegalArgumentException("Cannot unquote symbol: "+symbol);
		
		return symbol;
	}

	/**
	 * This will build a case sensitive compare expression out of two sql query expressions.
	 * @param conn An SQL Connection.
	 * @param expr1 The first SQL expression to be used in the comparison.
	 * @param expr2 The second SQL expression to be used in the comparison.
	 * @return A SQL expression comparing the two expressions using case-sensitive string comparison.
	 */
	public static String caseSensitiveCompare(Connection conn, String expr1, String expr2) throws SQLException
	{
		String operator;
		if (conn.getMetaData().getDatabaseProductName().equalsIgnoreCase(MYSQL))
			operator = "= BINARY";
		else
			operator = "=";
		
		return String.format(
				"%s %s %s",
				stringCast(conn, expr1),
				operator,
				stringCast(conn, expr2)
			);
	}
	
	/**
	 * This will wrap a query expression in a string cast.
	 * @param conn An SQL Connection.
	 * @param queryExpression An expression to be used in a SQL Query.
	 * @return The query expression wrapped in a string cast.
	 */
	private static String stringCast(Connection conn, String queryExpression) throws SQLException
	{
		if (conn.getMetaData().getDatabaseProductName().equalsIgnoreCase(MYSQL))
			return String.format("cast(%s as char)", queryExpression);
		if (conn.getMetaData().getDatabaseProductName().equalsIgnoreCase(POSTGRESQL))
			return String.format("cast(%s as varchar)", queryExpression);
		
		// dbms type not supported by this function yet
		return queryExpression;
	}
	
	/**
	 * This function returns the name of a binary data type that can be used in SQL queries.
	 * @param dbms The name of a DBMS (MySQL, PostGreSQL, ...)
	 * @return The name of the binary SQL type to use for the given DBMS.
	 */
	public static String binarySQLType(String dbms)
	{
		if (POSTGRESQL.equalsIgnoreCase(dbms))
			return "bytea";
		else if (SQLSERVER.equalsIgnoreCase(dbms))
			return "image";
			
		//if (dbms.equalsIgnoreCase(MYSQL))
		return "BLOB";
	}
	
	/**
	 * Returns quoted schema & table to use in SQL queries for the given DBMS.
	 * @param dbms The name of a DBMS (MySQL, PostGreSQL, ...)
	 * @param schema The schema the table resides in.
	 * @param table The table.
	 * @return The schema & table name surrounded in quotes, usable in queries for the specified DBMS.
	 */
	public static String quoteSchemaTable(String dbms, String schema, String table)
	{
		if (schema.length() == 0)
			return quoteSymbol(dbms, table);
		return quoteSymbol(dbms, schema) + "." + quoteSymbol(dbms, table);
	}
	
	/**
	 * Returns quoted schema & table to use in SQL queries for the given Connection.
	 * @param conn An SQL connection.
	 * @param schema The schema the table resides in.
	 * @param table The table.
	 * @return The schema & table name surrounded in quotes, usable in queries for the specified connection.
	 */
	public static String quoteSchemaTable(Connection conn, String schema, String table) throws SQLException
	{
		if (schema.length() == 0)
			return quoteSymbol(conn, table);
		
		if (SQLUtils.isOracleServer(conn))
			return quoteSymbol(conn, schema).toUpperCase() + "." + quoteSymbol(conn, table);
		else
			return quoteSymbol(conn, schema) + "." + quoteSymbol(conn, table);
	}

	/**
	 * @param connection An SQL Connection
	 * @param query An SQL query
	 * @return A SQLResult object containing the result of the query
	 * @throws SQLException
	 */
	public static SQLResult getRowSetFromQuery(Connection connection, String query)
	throws SQLException
	{
		return getRowSetFromQuery(connection, query, false);
	}
	
	/**
	 * @param connection An SQL Connection
	 * @param query An SQL query
	 * @param convertToStrings Set this to true to convert all result values to Strings.
	 * @return A SQLResult object containing the result of the query
	 * @throws SQLException
	 */
	public static SQLResult getRowSetFromQuery(Connection connection, String query, boolean convertToStrings) throws SQLException
	{
		Statement stmt = null;
		ResultSet rs = null;
		SQLResult result = null;
		try
		{
			stmt = connection.createStatement();
			rs = stmt.executeQuery(query);
			
			// make a copy of the query result
			result = new SQLResult(rs, convertToStrings);
		}
		catch (SQLException e)
		{
			//e.printStackTrace();
			throw e;
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
		}
		
		// return the copy of the query result
		return result;
	}
	
	/**
	 * @param connection An SQL Connection
	 * @param query An SQL Query with '?' place holders for parameters
	 * @param params Parameters for the SQL query for all '?' place holders.
	 * @return A SQLResult object containing the result of the query
	 * @throws SQLException
	 */
	public static SQLResult getRowSetFromQuery(Connection connection, String query, String[] params)
	throws SQLException
	{
		CallableStatement cstmt = null;
		ResultSet rs = null;
		SQLResult result = null;
		try
		{
			cstmt = prepareCall(connection, query, params);
			rs = cstmt.executeQuery();
			
			// make a copy of the query result
			result = new SQLResult(rs);
		}
		catch (SQLException e)
		{
			//e.printStackTrace();
			throw e;
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(cstmt);
		}
		
		// return the copy of the query result
		return result;
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param fromSchema The schema containing the table to perform the SELECT statement on.
	 * @param fromTable The table to perform the SELECT statement on.
	 * @param whereParams A map of column names to String values used to construct a WHERE clause.
	 * @return The resulting rows returned by the query.
	 * @throws SQLException If the query fails.
	 */
	public static <VALUE_TYPE> List<Map<String,String>> getRecordsFromQuery(
			Connection conn,
			String fromSchema,
			String fromTable,
			Map<String,VALUE_TYPE> whereParams
		) throws SQLException
	{
		return getRecordsFromQuery(conn, null, fromSchema, fromTable, whereParams);
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param fromSchema The schema containing the table to perform the SELECT statement on.
	 * @param fromTable The table to perform the SELECT statement on.
	 * @param whereParams A map of column names to String values used to construct a WHERE clause.
	 * @return The resulting rows returned by the query.
	 * @throws SQLException If the query fails.
	 */
	public static List<Map<String,String>> getRecordsFromResultSet(ResultSet rs) throws SQLException
	{
		// list the column names in the result
		String[] columnNames = new String[rs.getMetaData().getColumnCount()];
		for (int i = 0; i < columnNames.length; i++)
			columnNames[i] = rs.getMetaData().getColumnName(i + 1);
		// create a Map from each row
		List<Map<String,String>> records = new Vector<Map<String,String>>();
		while (rs.next())
		{
			Map<String,String> record = new HashMap<String,String>(columnNames.length);
			for (int i = 0; i < columnNames.length; i++)
			{
				String columnName = columnNames[i];
				String columnValue = rs.getString(columnName);
				record.put(columnName, columnValue);
			}
			records.add(record);
		}
		return records;
	}
	/**
	 * @param conn An existing SQL Connection
	 * @param fromSchema The schema containing the table to perform the SELECT statement on.
	 * @param fromTable The table to perform the SELECT statement on.
	 * @param whereParams A map of column names to String values used to construct a WHERE clause.
	 * @return The resulting rows returned by the query.
	 * @throws SQLException If the query fails.
	 */
	public static SQLResult getRowSetFromQuery(
			Connection conn,
			String fromSchema,
			String fromTable,
			Map<String,String> whereParams
		) throws SQLException
	{
		return getRowSetFromQuery(conn, null, fromSchema, fromTable, new HashMap<String,Object>(whereParams));
	}	
	
	/**
	 * @param conn An existing SQL Connection
	 * @param selectColumns The list of column names 
	 * @param fromSchema The schema containing the table to perform the SELECT statement on.
	 * @param fromTable The table to perform the SELECT statement on.
	 * @param whereParams A map of column names to String values used to construct a WHERE clause.
	 * @return The resulting rows returned by the query.
	 * @throws SQLException If the query fails.
	 */
	public static <VALUE_TYPE> List<Map<String,String>> getRecordsFromQuery(
			Connection conn,
			List<String> selectColumns,
			String fromSchema,
			String fromTable,
			Map<String,VALUE_TYPE> whereParams
		) throws SQLException
	{
		CallableStatement cstmt = null;
		ResultSet rs = null;
		String query = null;
		try
		{
			// create list of columns to use in SELECT statement
			String columnQuery = "";
			for (int i = 0; selectColumns != null && i < selectColumns.size(); i++)
			{
				if (i > 0)
					columnQuery += ",";
				columnQuery += quoteSymbol(conn, selectColumns.get(i));
			}
			if (columnQuery.length() == 0)
				columnQuery = "*"; // select all columns
			
			// build WHERE clause
			List<Entry<String,VALUE_TYPE>> whereEntries = imposeMapOrdering(whereParams);
			String whereQuery = buildWhereClause(conn, getEntryKeys(whereEntries));
			
			// build complete query
			query = String.format(
					"SELECT %s FROM %s %s",
					columnQuery,
					quoteSchemaTable(conn, fromSchema, fromTable),
					whereQuery
				);
			cstmt = prepareCall(conn, query, getEntryValues(whereEntries));
			rs = cstmt.executeQuery();
			
			return getRecordsFromResultSet(rs);
		}
		catch (SQLException e)
		{
			System.out.println(query);
			throw e;
		}
		finally
		{
			// close everything in reverse order
			cleanup(rs);
			cleanup(cstmt);
		}
	}
	/**
	 * @param conn An existing SQL Connection
	 * @param selectColumns The list of columns in the SELECT statement.
	 * @param fromSchema The schema containing the table to perform the SELECT statement on.
	 * @param fromTable The table to perform the SELECT statement on.
	 * @param whereParams A map of column names to String values used to construct a WHERE clause.
	 * @return The resulting rows returned by the query.
	 * @throws SQLException If the query fails.
	 */
	public static SQLResult getRowSetFromQuery(
			Connection conn,
			List<String> selectColumns,
			String fromSchema,
			String fromTable,
			Map<String,Object> whereParams
		) throws SQLException
	{
		CallableStatement cstmt = null;
		ResultSet rs = null;
		SQLResult result = null;
		String query = null;
		try
		{
			// create list of columns to use in SELECT statement
			String columnQuery = "";
			for (int i = 0; selectColumns != null && i < selectColumns.size(); i++)
			{
				if (i > 0)
					columnQuery += ",";
				columnQuery += quoteSymbol(conn, selectColumns.get(i));
			}
			if (columnQuery.length() == 0)
				columnQuery = "*"; // select all columns
			
			// build WHERE clause
			List<Entry<String,Object>> whereEntries = imposeMapOrdering(whereParams);
			String whereQuery = buildWhereClause(conn, getEntryKeys(whereEntries));
			
			// build complete query
			query = String.format(
					"SELECT %s FROM %s %s",
					columnQuery,
					quoteSchemaTable(conn, fromSchema, fromTable),
					whereQuery
				);
			cstmt = prepareCall(conn, query, getEntryValues(whereEntries));
			rs = cstmt.executeQuery();
			
			// make a copy of the query result
			result = new SQLResult(rs);
		}
		catch (SQLException e)
		{
			System.out.println("Query: "+query);
			throw e;
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(cstmt);
		}
		
		// return the copy of the query result
		return result;
	}
	

	/**
	 * @param connection An SQL Connection
	 * @param query An SQL query
	 * @return A SQLResult object containing the result of the query
	 * @throws SQLException
	 */
	public static int getRowCountFromUpdateQuery(Connection connection, String query)
		throws SQLException
	{
		Statement stmt = null;
		int result = 0;
		
		try
		{
			stmt = connection.createStatement();
			result = stmt.executeUpdate(query);
		}
		catch (SQLException e)
		{
			throw e;
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(stmt);
		}
		
		// return the copy of the query result
		return result;
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @return A List of schema names
	 * @throws SQLException If the query fails.
	 */
	public static List<String> getSchemas(Connection conn) throws SQLException
	{
	    List<String> schemas = new Vector<String>();
	    ResultSet rs = null;
		try
		{
			DatabaseMetaData md = conn.getMetaData();
			
			// MySQL "doesn't support schemas," so use catalogs.
			if (conn.getMetaData().getDatabaseProductName().equalsIgnoreCase(MYSQL))
			{
				rs = md.getCatalogs();
				// use column index instead of name because sometimes the names are lower case, sometimes upper.
				while (rs.next())
					schemas.add(rs.getString(1)); // table_catalog
			}
			else
			{
				rs = md.getSchemas();
				// use column index instead of name because sometimes the names are lower case, sometimes upper.
				while (rs.next())
					schemas.add(rs.getString(1)); // table_schem
			}
			
			Collections.sort(schemas, String.CASE_INSENSITIVE_ORDER);
		}
		finally
		{
			SQLUtils.cleanup(rs);
		}
	    return schemas;
	}

	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @return A List of table names in the given schema
	 * @throws SQLException If the query fails.
	 */
	public static List<String> getTables(Connection conn, String schemaName)
		throws SQLException
	{
		List<String> tables = new Vector<String>();
		ResultSet rs = null;
		try
		{
			DatabaseMetaData md = conn.getMetaData();
			String[] types = new String[]{"TABLE", "VIEW"};
			
			// MySQL uses "catalogs" instead of "schemas"
			if (conn.getMetaData().getDatabaseProductName().equalsIgnoreCase(MYSQL))
				rs = md.getTables(schemaName, null, null, types);
			else if (SQLUtils.isOracleServer(conn))
				rs = md.getTables(null, schemaName.toUpperCase(), null, types);
			else
				rs = md.getTables(null, schemaName, null, types);
			
			// use column index instead of name because sometimes the names are lower case, sometimes upper.
			// column indices: 1=table_cat,2=table_schem,3=table_name,4=table_type,5=remarks
			while (rs.next())
				tables.add(rs.getString(3)); // table_name
			
			Collections.sort(tables, String.CASE_INSENSITIVE_ORDER);
		}
		finally
		{
			// close everything in reverse order
			cleanup(rs);
		}
		return tables;
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName A table name existing in the given schema
	 * @return A List of column names in the given table
	 * @throws SQLException If the query fails.
	 */
	public static List<String> getColumns(Connection conn, String schemaName, String tableName)
		throws SQLException
	{
		List<String> columns = new Vector<String>();
		CallableStatement cstmt = null;
		ResultSet rs = null;
		try
		{
			DatabaseMetaData md = conn.getMetaData();

			tableName = escapeSearchString(conn, tableName);
			
			// MySQL uses "catalogs" instead of "schemas"
			if (conn.getMetaData().getDatabaseProductName().equalsIgnoreCase(MYSQL))
				rs = md.getColumns(schemaName, null, tableName, null);
			else if (isOracleServer(conn))
				rs = md.getColumns(null, schemaName.toUpperCase(), tableName, null);
			else
				rs = md.getColumns(null, schemaName, tableName, null);
			
			// use column index instead of name because sometimes the names are lower case, sometimes upper.
			while (rs.next())
				columns.add(rs.getString(4)); // column_name
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(cstmt);
		}
		return columns;
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param SchemaArg The value to be used as the Schema name
	 * @throws SQLException If the query fails.
	 */
	public static void createSchema(Connection conn, String schema)
		throws SQLException
	{
		if (SQLUtils.schemaExists(conn, schema))
			return;

		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate("CREATE SCHEMA " + schema);
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}
	/**
	 * @param conn An existing SQL Connection
	 * @param SchemaName A schema name accessible through the given connection
	 * @param tableName The value to be used as the table name
	 * @param columnNames The values to be used as the column names
	 * @param columnTypes The SQL types to use when creating the ctable
	 * @throws IllegalArgumentException 
	 * @throws SQLException If the query fails.
	 */
	public static void createTable( Connection conn, String schemaName, String tableName, List<String> columnNames, List<String> columnTypes, String key) throws IllegalArgumentException, SQLException
	{
		if (columnNames.size() != columnTypes.size())
			throw new IllegalArgumentException(String.format("columnNames length (%s) does not match columnTypes length (%s)", columnNames.size(), columnTypes.size()));
		
		//if table exists return
		if( tableExists(conn, schemaName, tableName) )
			return;
		Statement stmt = null;
		
		String query = "CREATE TABLE " + 
			quoteSchemaTable(conn, schemaName, tableName) + " ( ";
		
		for(int i = 0; i < columnNames.size(); i++)
		{
			if( i > 0 )
				query += ", ";
			query += quoteSymbol(conn, columnNames.get(i)) + " " + columnTypes.get(i);
		}
		query += ");";
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
		}
		catch (SQLException e)
		{
			System.out.println(query);
			throw e;
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}
	/**
	 * @param conn An existing SQL Connection
	 * @param SchemaName A schema name accessible through the given connection
	 * @param tableName The value to be used as the table name
	 * @param columnNames The values to be used as the column names
	 * @param columnTypes The SQL types to use when creating the ctable
	 * @throws SQLException If the query fails.
	 */
	public static void createTable( Connection conn, String schemaName, String tableName, List<String> columnNames, List<String> columnTypes)
		throws SQLException
	{
		if (columnNames.size() != columnTypes.size())
			throw new IllegalArgumentException(String.format("columnNames length (%s) does not match columnTypes length (%s)", columnNames.size(), columnTypes.size()));
		
		//if table exists return
		if( tableExists(conn, schemaName, tableName) )
			return;
		
		Statement stmt = null;
		
		String query = "CREATE TABLE " + quoteSchemaTable(conn, schemaName, tableName) + " ( ";
		
		int oraclePrimaryKeyColumn = -1;
		for (int i = 0; i < columnNames.size(); i++)
		{
			if( i > 0 )
				query += ", ";
			String type = columnTypes.get(i);
			if (ORACLE_SERIAL_TYPE.equals(type))
			{
				type = "integer not null";
				oraclePrimaryKeyColumn = i;
			}
			query += quoteSymbol(conn, columnNames.get(i)) + " " + type;
		}
		query += ")";
		
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
			
			if (oraclePrimaryKeyColumn >= 0)
			{
				// Create a sequence and trigger for each table?
				//stmt.executeUpdate("create sequence " + schemaName + "_" + tableName + "_AUTOID start with 1 increment by 1");
				// Identifier is too long
				//stmt.executeUpdate("create trigger " + schemaName + "_" + tableName + "_IDTRIGGER before insert on " + tableName + " for each row begin select " + schemaName + "_" + tableName + "_AUTOID.nextval into :new.the_geom_id from dual; end;");
				
				if (sequenceExists(conn, schemaName, tableName + "_AUTOID"))
				{
					stmt.executeUpdate("drop sequence " + tableName + "_AUTOID");
					stmt.executeUpdate("create sequence " + tableName + "_AUTOID start with 1 increment by 1");
				}
				else
					stmt.executeUpdate("create sequence " + tableName + "_AUTOID start with 1 increment by 1");
				
				stmt.executeUpdate("create or replace trigger " + tableName + "_IDTRIGGER before insert on \"" + tableName + "\" for each row begin select " + tableName + "_AUTOID.nextval into :new.\"the_geom_id\" from dual; end;");
			}
		}
		catch (SQLException e)
		{
			System.out.println(query);
			throw e;
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}
	public static void addForeignKey( Connection conn, String schemaName, String tableName, String keyName, String targetTable, String targetKey) throws IllegalArgumentException, SQLException
	{
		// TODO: Check for cross-DB portability
		Statement stmt = null;
		String query = String.format("ALTER TABLE %s ADD FOREIGN KEY (%s) REFERENCES %s(%s)", 
				quoteSchemaTable(conn, schemaName, tableName),
				quoteSymbol(conn, keyName),
				quoteSchemaTable(conn, schemaName, targetTable),
				quoteSymbol(conn, targetKey));
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
		}
		catch (SQLException e)
		{
			System.out.println(query);
			throw e;
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}
	private static String buildWhereClause(Connection conn, List<String> whereFields) throws IllegalArgumentException, SQLException
	{
		if (whereFields.size() == 0)
			return "";
		
		String whereQuery = "";
		for (String field : whereFields)
		{
			if (whereQuery.length() > 0)
				whereQuery += " AND ";
			whereQuery += caseSensitiveCompare(conn, quoteSymbol(conn, field), "?");
		}
		return "WHERE " + whereQuery;
	}
	private static <TYPE> CallableStatement prepareCall(Connection conn, String query, List<TYPE> params) throws SQLException
	{
		CallableStatement cstmt = conn.prepareCall(query);
		setCallableStatementParams(cstmt, params);
		return cstmt;
	}
	private static <TYPE> CallableStatement prepareCall(Connection conn, String query, TYPE[] params) throws SQLException
	{
		CallableStatement cstmt = conn.prepareCall(query);
		setCallableStatementParams(cstmt, params);
		return cstmt;
	}
	private static <TYPE> void setCallableStatementParams(CallableStatement cstmt, List<TYPE> params) throws SQLException
	{
		int i = 1;
		for (TYPE param : params)
			cstmt.setObject(i++, param);
	}
	private static <TYPE> void setCallableStatementParams(CallableStatement cstmt, TYPE[] params) throws SQLException
	{
		int i = 1;
		for (TYPE param : params)
			cstmt.setObject(i++, param);
	}
/* Service methods for maintaining my sanity and saving me keystrokes. -pkovac */
        private static String stringJoin(String separator, Collection<String> items)
        {
            StringBuilder result = new StringBuilder((separator.length()+1)*items.size());
            int i = 0;
            for (String item : items)
            {
                if (i > 0)
                	result.append(separator);
                result.append(item);
                i++;
            }
            return result.toString();
        }
        private static String stringMult(String separator, String item, Integer repeat)
        {
            ArrayList<String> items = new ArrayList<String>(repeat);
            for (int i = 0; i < repeat; i++)
            {
                items.add(item);
            }
            return stringJoin(separator, items);
        }
        private static String buildPredicate(Connection conn, Entry<String, String> pair) throws SQLException
        {
            return "(" + caseSensitiveCompare(conn, pair.getKey(), pair.getValue()) + ")";
        }
        private static String buildDisjunctiveNormalForm(Connection conn, List<List<Entry<String,String>>> arguments) throws SQLException
        {
            List<String> conjunctions = new LinkedList<String>();
            for (List<Entry<String,String>> conjMap : arguments)
            {
                List<String> conjList = new LinkedList<String>();
                for (Entry<String,String> predEntry : conjMap)
                {
                    String pred = buildPredicate(conn, predEntry);
                    conjList.add(pred);
                }
                conjunctions.add("(" + stringJoin(" AND ", conjList) + ")");
            }
            return stringJoin(" OR ", conjunctions);
        }
        private static <KEY,VALUE> List<Entry<KEY,VALUE>> imposeMapOrdering(Map<KEY,VALUE> inputMap)
        {
            List<Entry<KEY,VALUE>> orderedEntries = new LinkedList<Entry<KEY,VALUE>>();
            for (Entry<KEY,VALUE> pair : inputMap.entrySet())
            {
                orderedEntries.add(pair);
            }
            return orderedEntries;
        }
        private static <KEY,VALUE> List<KEY> getEntryKeys(List<Entry<KEY,VALUE>> orderedEntries)
        {
        	List<KEY> result = new LinkedList<KEY>();
        	for (Entry<KEY,VALUE> entry : orderedEntries)
        		result.add(entry.getKey());
        	return result;
        }
        private static <KEY,VALUE> List<VALUE> getEntryValues(List<Entry<KEY,VALUE>> orderedEntries)
        {
        	List<VALUE> result = new LinkedList<VALUE>();
        	for (Entry<KEY,VALUE> entry : orderedEntries)
        		result.add(entry.getValue());
        	return result;
        }

        public static int updateRows(Connection conn, String fromSchema, String fromTable, Map<String,Object> whereParams, Map<String,Object> dataUpdate) throws SQLException
		{
			String query, updateBlock, whereBlock;
			/* Build the update block */
			List<String> updateBlockList = new LinkedList<String>();
			List<Object> argList = new LinkedList<Object>();
			for (Entry<String,Object> data : dataUpdate.entrySet())
			{
		        updateBlockList.add(String.format("%s=?", data.getKey()));
		        argList.add(data.getValue());
		    }
		    List<String> whereFields = new LinkedList<String>();
		    for (Entry<String,Object> where : whereParams.entrySet())
		    {
		        argList.add(where.getValue());
		        whereFields.add(where.getKey());
		    }
		    whereBlock = buildWhereClause(conn, whereFields);
		    updateBlock = stringJoin(",", updateBlockList);
		    query = String.format("UPDATE %s SET %s WHERE %s", fromTable, updateBlock, whereBlock);
		    PreparedStatement stmt = conn.prepareStatement(query);
		    int i = 1;
		    for (Object o : argList)
		    {
		        stmt.setObject(i++, o);
		    }
		    i = stmt.executeUpdate();
		    return i;
		}
        public static Map<Integer,Map<String,String>> idInSelect(Connection conn, String schemaName, String table, String idColumn, String propColumn, String dataColumn, Collection<Integer> ids, Collection<String> props) throws SQLException
        {
        	String query = "";
        	try
        	{
	            //TODO: Clean this up, make it more generic.
	            Map<Integer,Map<String,String>> results = new HashMap<Integer,Map<String,String>>();
	            if (ids.size() == 0)
	            	return results;
	            String qIdColumn = quoteSymbol(conn, idColumn);
	            String qPropColumn = quoteSymbol(conn, propColumn);
	            String qDataColumn = quoteSymbol(conn, dataColumn);
	            String qSchemaTable = quoteSchemaTable(conn, schemaName, table);
	            String whereClause = String.format("WHERE %s IN (%s)", qIdColumn, stringMult(",", "?", ids.size()));
	            if (props != null && props.size() > 0)
	            	whereClause += String.format(" AND %s IN (%s)", qPropColumn, stringMult(",", "?", props.size()));
	            query = String.format(
            		"SELECT %s,%s,%s FROM %s %s ORDER BY %s",
            		qIdColumn, qPropColumn, qDataColumn,
            		qSchemaTable, whereClause, qIdColumn
	            );
	            PreparedStatement stmt = conn.prepareStatement(query);
	            int i = 1;
	            for (Integer val : ids)
	            {
	                results.put(val, new HashMap<String,String>());
	                stmt.setInt(i,val);
	                i++;
	            }
	            if (props != null)
	            {
	                for (String val : props)
	                {
	                    stmt.setString(i,val);
	                    i++;
	                }
	            }
	            ResultSet rs = stmt.executeQuery();
	            while (rs.next())
	            {
	                Integer id = rs.getInt(idColumn);
	                String prop = rs.getString(propColumn);
	                String value = rs.getString(dataColumn);
	                results.get(id).put(prop, value);
	            }
	
	            return results;
        	}
        	catch (SQLException e)
        	{
        		System.out.println(query);
        		throw e;
        	}
        }
        /**
         * Takes a list of maps, each of which corresponds to one rowmatch criteria; in the case it is being used for,
         * this will only be two entries long, but this covers the general case.
         * @param conn
         * @param schemaName
         * @param table
         * @param column The name of the column to return.
         * @param queryParams A list of where parameters specified as Map entries.
         * @return The values from the specified column.
         * @throws SQLException
         */
        public static List<Integer> crossRowSelect(Connection conn, String schemaName, String table, String column, List<Map<String,String>> queryParams) throws SQLException
        {
            PreparedStatement stmt = null;
            List<Integer> results = new LinkedList<Integer>();
            List<String> values = new LinkedList<String>();
            ResultSet rs;
            List<List<Entry<String,String>>> flattenedMap = new LinkedList<List<Entry<String,String>>>();
            // Flatten the list of maps to a list of entries; this ensures that value ordering is preserved when we go to make the query. Replace the entry element values with the placeholder character.
            for (Map<String,String> columnData : queryParams)
            {
                List<Entry<String,String>> pairs = imposeMapOrdering(columnData);
                for (Entry<String,String> keyValPair : pairs)
                {
                    values.add(keyValPair.getValue());
                    keyValPair.setValue(" ?");
                }
                flattenedMap.add(pairs);
            }
            // Construct the query with placeholders.
            String query;
            String qColumn = quoteSymbol(conn, column);
            String qTable = quoteSchemaTable(conn, schemaName, table);
            if (queryParams.size() == 0)
            {
            	query = String.format("SELECT %s from %s group by %s", qColumn, qTable, qColumn);
            }
            else
            {
	            query = String.format(
	            	"SELECT %s FROM (SELECT %s, count(*) c FROM %s WHERE %s group by %s) result WHERE c = %s",
	                qColumn,
	                qColumn,
	                qTable,
	                buildDisjunctiveNormalForm(conn, flattenedMap),
	                qColumn,
	                queryParams.size()
	            );
            }
            stmt = conn.prepareStatement(query);

            int i = 1;
            for (String value : values)
            {
                stmt.setString(i,value);
                i+=1;
            }

            rs = stmt.executeQuery();
            while (rs.next())
            {
                 results.add(rs.getInt(column));
            }
            return results;
        }
        public static Integer insertRowReturnID(Connection conn, String schemaName, String tableName, Map<String,Object> data) throws SQLException
        {
            PreparedStatement stmt = null;
            List<String> columns = new LinkedList<String>();
            List<Object> values = new LinkedList<Object>();
            for (Entry<String,Object> entry : data.entrySet())
            {
                columns.add(quoteSymbol(conn, entry.getKey()));
                values.add(entry.getValue());
            }
            List<String> l_qmarks = new LinkedList<String>();
            for (int i = 0; i < values.size(); i++)
            {
                l_qmarks.add("?");
            }
            String column_string = stringJoin(",", columns);
            String qmark_string = stringJoin(",", l_qmarks);
            String query = String.format("INSERT INTO %s(%s) VALUES (%s)", quoteSchemaTable(conn, schemaName, tableName), column_string, qmark_string);
            stmt = conn.prepareStatement(query);
            int i = 1;
            for (Object item : values)
            {
                stmt.setObject(i++, item);
            }
            stmt.executeUpdate();
            query = "select last_insert_id()";
            stmt = conn.prepareStatement(query);
            ResultSet rs = stmt.executeQuery();
            rs.first();
            return rs.getInt(1);
        }
	
	
	/**
	 * This function is for use with an Oracle connection
	 * @param conn An existing Oracle SQL Connection
	 * @param schema The name of a schema to check in.
	 * @param sequence The name of a sequence to check for.
	 * @return true if the sequence exists in the specified schema.
	 * @throws SQLException.
	 */
	private static boolean sequenceExists(Connection conn, String schema, String sequence)
		throws SQLException
	{
		List<String> sequences = getSequences(conn, schema);
		for (String existingSequence : sequences)
			if (existingSequence.equalsIgnoreCase(sequence))
				return true;
		return false;
	}

	/**
	 * This function is for use with an Oracle connection
	 * @param conn An existing Oracle SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @return A List of sequence names in the given schema
	 * @throws SQLException If the query fails.
	 */
	private static List<String> getSequences(Connection conn, String schemaName) throws SQLException
	{
		List<String> sequences = new Vector<String>();
		ResultSet rs = null;
		try
		{
			DatabaseMetaData md = conn.getMetaData();
			String[] types = new String[]{"SEQUENCE"};
			
			rs = md.getTables(null, schemaName.toUpperCase(), null, types);
			
			// use column index instead of name because sometimes the names are lower case, sometimes upper.
			// column indices: 1=sequence_cat,2=sequence_schem,3=sequence_name,4=sequence_type,5=remarks
			while (rs.next())
				sequences.add(rs.getString(3)); // sequence_name
			
			Collections.sort(sequences, String.CASE_INSENSITIVE_ORDER);
		}
		finally
		{
			// close everything in reverse order
			cleanup(rs);
		}
		//System.out.println(sequences);
		return sequences;
	}
	
	/**
	 * This function checks if a connection is for an Oracle server.
	 * @param conn A SQL Connection.
	 * @return A value of true if the Connection is for an Oracle server.
	 */
	public static boolean isOracleServer(Connection conn)
	{
		try
		{
			if (conn.getMetaData().getDatabaseProductName().equalsIgnoreCase(ORACLE))
				return true;
		}
		catch (SQLException e) // This is expected to be thrown if the connection is invalid.
		{
			e.printStackTrace();
		}
		catch (RuntimeException e) // This is important for catching unexpected errors.
		{
			return false;
		}

		return false;
	}
        /**
	 * @param conn An existing SQL Connection
	 * @param SchemaName A schema name accessible through the given connection
	 * @param tableName The name of an existing table
	 * @param columnNames The names of the columns to use
	 * @throws SQLException If the query fails.
	 */
	public static void createIndex(Connection conn, String schemaName, String tableName, String[] columnNames) throws SQLException
        {
            createIndex(conn, schemaName, tableName, tableName + "_index", columnNames, null);
        }
	/**
	 * @param conn An existing SQL Connection
	 * @param SchemaName A schema name accessible through the given connection
	 * @param tableName The name of an existing table
         * @param indexName The name to use for the new index.
	 * @param columnNames The names of the columns to use
         * @param columnLengths The lengths to use as indices
	 * @throws SQLException If the query fails.
	 */
	public static void createIndex(Connection conn, String schemaName, String tableName, String indexName, String[] columnNames, Integer[] columnLengths) throws SQLException
	{
		String columnNamesStr = "";
		for (int i = 0; i < columnNames.length; i++)
                {
                        if ((columnLengths != null) && columnLengths[i] != 0)
                        {
			    columnNamesStr += (i > 0 ? ", " : "") + String.format("%s(%d)", quoteSymbol(conn, columnNames[i]), columnLengths[i]);
                        }
                        else
                        {
                            columnNamesStr += (i > 0 ? ", " : "") + quoteSymbol(conn, columnNames[i]);
                        }
                }
		String query = String.format(
				"CREATE INDEX %s ON %s (%s)",
				SQLUtils.quoteSymbol(conn, indexName),
				SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
				columnNamesStr
		);
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
		}
		catch (SQLException e)
		{
			//System.out.println(query);
			throw e;
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param SchemaName A schema name accessible through the given connection
	 * @param tableName The name of an existing table
	 * @param columnName The name of the column to create
	 * @param columnType An SQL type to use when creating the column
	 * @throws SQLException If the query fails.
	 */
	public static void addColumn( Connection conn, String schemaName, String tableName, String columnName, String columnType)
		throws SQLException
	{
		String format = "ALTER TABLE %s ADD %s %s"; // Note: PostGreSQL does not accept parentheses around the new column definition.
		String query = String.format(format, quoteSchemaTable(conn, schemaName, tableName), quoteSymbol(conn, columnName), columnType);
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
		}
		catch (SQLException e)
		{
			//System.out.println(query);
			throw e;
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName A table name existing in the given schema
	 * @param columnArg	The name of the column to grab
	 * @return A List of string values from the column
	 * @throws SQLException If the query fails.
	 */
	public static List<String> getColumn(Connection conn, String schemaName, String tableName, String columnArg)
		throws SQLException
	{
		List<String> values = new Vector<String>(); 	//Return value
		Statement stmt = null;
		ResultSet rs = null;

		String query = "";
		try
		{
			query = "SELECT " + quoteSymbol(conn, columnArg) + " FROM " + quoteSchemaTable(conn, schemaName, tableName);
			
			stmt = conn.createStatement();
			rs = stmt.executeQuery(query);
			while (rs.next())
				values.add(rs.getString(1));
		}
		catch (SQLException e)
		{
			System.out.println(query);
			throw e;
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
		}
		return values;
	}
		
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName A table name existing in the given schema
	 * @param columnArg	The name of the integer column to grab
	 * @return A List of integer values from the column
	 * @throws SQLException If the query fails.
	 */
	public static List<Integer> getIntColumn(Connection conn, String schemaName, String tableName, String columnArg)
	throws SQLException
	{
		List<Integer> values = new Vector<Integer>(); 	//Return value
		Statement stmt = null;
		ResultSet rs = null;
		
		String query = "";
		try
		{
			query = "SELECT " + quoteSymbol(conn, columnArg) + " FROM " + quoteSchemaTable(conn, schemaName, tableName);
			
			stmt = conn.createStatement();
			rs = stmt.executeQuery(query);
			while (rs.next())
				values.add(rs.getInt(1));
		}
		catch (SQLException e)
		{
			System.out.println(query);
			throw e;
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
		}
		return values;
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName A table name existing in the given schema
	 * @param newColumnValues The values to be inserted into that table
	 * @throws SQLException If the query fails.
	 */
	public static void insertRow( Connection conn, String schemaName, String tableName, Map<String,Object> newColumnValues)
		throws SQLException
	{
		CallableStatement cstmt = null;
		String query = "";
		int i = 0;
		try
		{
			// build list of quoted column names, question marks, and array of values in correct order
			Set<Entry<String,Object>> entrySet = newColumnValues.entrySet();
			String columnNames = "";
			String questionMarks = "";
			Object[] values = new Object[entrySet.size()];

			for (Entry<String,Object> entry : entrySet)
			{
				if (i > 0)
				{
					columnNames += ",";
					questionMarks += ",";
				}
				columnNames += quoteSymbol(conn, entry.getKey());
				questionMarks += "?";
				values[i] = entry.getValue();
				
				// constrain oracle double values to float range
				if (isOracleServer(conn) && values[i] instanceof Double)
					values[i] = ((Double) values[i]).floatValue();
				
				i++;
			}
			
			query = String.format(
					"INSERT INTO %s (%s) VALUES (%s)",
					quoteSchemaTable(conn, schemaName, tableName),
					columnNames,
					questionMarks
			);
			
			// prepare call and set string parameters
			cstmt = prepareCall(conn, query, values);
			cstmt.executeUpdate();
		}
		catch (SQLException e)
		{
			System.out.println(query);
			System.out.println(newColumnValues);
			throw e;
		}
		finally
		{
			SQLUtils.cleanup(cstmt);
		}
	}

	/**
	 * @param conn An existing SQL Connection
	 * @param schema The name of a schema to check for.
	 * @return true if the schema exists
	 * @throws SQLException If the getSchemas query fails.
	 */
	public static boolean schemaExists(Connection conn, String schema)
		throws SQLException
	{
		List<String> schemas = getSchemas(conn);
		for (String existingSchema : schemas)
			if (existingSchema.equalsIgnoreCase(schema))
				return true;
		return false;
	}
	
	public static void dropTableIfExists(Connection conn, String schema, String table) throws SQLException
	{
		String dbms = conn.getMetaData().getDatabaseProductName();
		String quotedTable = SQLUtils.quoteSchemaTable(conn, schema, table);
		String query = "";
		if (SQLSERVER.equalsIgnoreCase(dbms))
		{
			query = "IF OBJECT_ID('" + quotedTable + "','U') IS NOT NULL DROP TABLE " + quotedTable;
		}
		else if (ORACLE.equalsIgnoreCase(dbms))
		{
			// do nothing if table doesn't exist
			if (!SQLUtils.tableExists(conn, schema, table))
				return;
			query = "DROP TABLE " + quotedTable;
		}
		else
		{
			query = "DROP TABLE IF EXISTS " + quotedTable;
		}
		
		Statement stmt = conn.createStatement();
		stmt.executeUpdate(query);
		stmt.close();
		cleanup(stmt);
	}
		
	/**
	 * This function will delete from a table the rows that have a specified set of column values.
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName A table name existing in the given schema
	 * @param whereParams The set of key-value pairs that will be used in the WHERE clause of the query
	 * @throws SQLException If the query fails.
	 */
	public static void deleteRows(Connection conn, String schemaName, String tableName, Map<String,Object> whereParams) throws SQLException
	{
		CallableStatement cstmt = null;
		String query = "";

		try 
		{
			query = "DELETE FROM " + SQLUtils.quoteSchemaTable(conn, schemaName, tableName);
			
			List<Entry<String,Object>> whereEntries = imposeMapOrdering(whereParams);
			query += buildWhereClause(conn, getEntryKeys(whereEntries));
			
			cstmt = prepareCall(conn, query, getEntryValues(whereEntries));
			cstmt.executeUpdate();
		}
		finally
		{
			SQLUtils.cleanup(cstmt);
		}		
	}

	/**
	 * This will escape special characters in a SQL search string.
	 * @param conn A SQL Connection.
	 * @param searchString A SQL search string containing special characters to be escaped.
	 * @return The searchString with special characters escaped.
	 * @throws SQLException 
	 */
	public static String escapeSearchString(Connection conn, String searchString) throws SQLException
	{
		String escape = conn.getMetaData().getSearchStringEscape();
		StringBuilder sb = new StringBuilder();
		int n = searchString.length();
		for (int i = 0; i < n; i++)
		{
			char c = searchString.charAt(i);
			if (c == '.' || c == '%' || c == '_' || c == '"' || c == '\'' || c == '`')
				sb.append(escape);
			sb.append(c);
		}
		return sb.toString();
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param schema The name of a schema to check in.
	 * @param table The name of a table to check for.
	 * @return true if the table exists in the specified schema.
	 * @throws SQLException If either getSchemas() or getTables() fails.
	 */
	public static boolean tableExists(Connection conn, String schema, String table)
		throws SQLException
	{
		List<String> tables = getTables(conn, schema);
		for (String existingTable : tables)
			if (existingTable.equalsIgnoreCase(table))
				return true;
		return false;
	}
	
	public static void cleanup(ResultSet obj)
	{
		if (obj != null) try { obj.close(); } catch (Exception e) { }
	}
	public static void cleanup(Statement obj)
	{
		if (obj != null) try { obj.close(); } catch (Exception e) { }
	}
	public static void cleanup(CallableStatement obj)
	{
		if (obj != null) try { obj.close(); } catch (Exception e) { }
	}
	public static void cleanup(Connection obj)
	{
		if (obj != null) try { obj.close(); } catch (Exception e) { }
	}

	public static String getVarcharTypeString(Connection conn, int length)
	{
		if (isOracleServer(conn))
			return String.format("VARCHAR2(%s)", length);
		return String.format("VARCHAR(%s)", length);
	}
	public static String getIntTypeString(Connection conn) 
	{
		return "INT";
	}
	public static String getDoubleTypeString(Connection conn)
	{
		String dbms = "";
		try
		{
			dbms = conn.getMetaData().getDatabaseProductName();
		}
		catch (Exception e)
		{
			// this should never happen
			throw new RuntimeException(e);
		}
		
		if (SQLSERVER.equalsIgnoreCase(dbms))
			return "FLOAT"; // this is an 8 floating point type with 53 bits for the mantissa, the same as an 8 byte double.
			                // but SQL Server's DOUBLE PRECISION type isn't standard
		
		return "DOUBLE PRECISION";
	}
	public static String getBigIntTypeString(Connection conn)
	{
		String dbms = "";
		try
		{
			dbms = conn.getMetaData().getDatabaseProductName();
		}
		catch (Exception e)
		{
			// this should never happen
			throw new RuntimeException(e);
		}
		
		if (ORACLE.equalsIgnoreCase(dbms))
			return "NUMBER(19, 0)";
		
		return "BIGINT";
	}
	public static String getDateTimeTypeString(Connection conn)
	{
		if (isOracleServer(conn))
			return "DATE";
		
		return "DATETIME";
	}
	
	public static void copyCsvToDatabase(Connection conn, String formatted_CSV_path, String sqlSchema, String sqlTable) throws SQLException, IOException
	{
		String dbms = conn.getMetaData().getDatabaseProductName();
		Statement stmt = null;
		String quotedTable = quoteSchemaTable(conn, sqlSchema, sqlTable);

		try
		{
			if (dbms.equalsIgnoreCase(SQLUtils.MYSQL))
			{
				stmt = conn.createStatement();
				//ignoring 1st line so that we don't put the column headers as the first row of data
				stmt.executeUpdate(String.format(
						"load data local infile '%s' into table %s fields terminated by ',' enclosed by '\"' lines terminated by '\\n' ignore 1 lines",
						formatted_CSV_path, quotedTable
						));
				stmt.close();
			}
			else if (dbms.equalsIgnoreCase(SQLUtils.ORACLE))
			{
				// Insert each row repeatedly
				boolean prevAutoCommit = conn.getAutoCommit();
				if (prevAutoCommit)
					conn.setAutoCommit(false);
				
				String csvData = org.apache.commons.io.FileUtils.readFileToString(new File(formatted_CSV_path));
				String[][] rows = CSVParser.defaultParser.parseCSV(csvData);
				String query = "", tempQuery = "INSERT INTO %s values (";
				for (int column = 0; column < rows[0].length; column++) // Use header row to determine the number of columns
				{
					if (column == rows[0].length - 1)
						tempQuery = tempQuery + "?)";
					else
						tempQuery = tempQuery + "?,";
				}
				
				query = String.format(tempQuery, quotedTable);
				
				CallableStatement cstmt = null;
				try
				{
					cstmt = conn.prepareCall(query);
					for (int row = 1; row < rows.length; row++) //Skip header line
					{
						setCallableStatementParams(cstmt, rows[row]);
						cstmt.execute();
					}
				}
				catch (SQLException e)
				{
					throw new RemoteException(e.getMessage(), e);
				}
				finally
				{
					SQLUtils.cleanup(cstmt);
				}
			}
			else if (dbms.equalsIgnoreCase(SQLUtils.POSTGRESQL))
			{
				((PGConnection) conn).getCopyAPI().copyIn(
						String.format("COPY %s FROM STDIN WITH CSV HEADER", quotedTable),
						new FileInputStream(formatted_CSV_path));
			}
			else if (dbms.equalsIgnoreCase(SQLUtils.SQLSERVER))
			{
				stmt = conn.createStatement();

				// sql server expects the actual EOL character '\n', and not the textual representation '\\n'
				stmt.executeUpdate(String.format(
						"BULK INSERT %s FROM '%s' WITH ( FIRSTROW = 2, FIELDTERMINATOR = '%s', ROWTERMINATOR = '\n', KEEPNULLS )",
						quotedTable, formatted_CSV_path, SQL_SERVER_DELIMETER
					));
			}
		}
		finally 
		{
			SQLUtils.cleanup(stmt);
		}
	}
	
	public static String getSerialPrimaryKeyTypeString(Connection conn) throws SQLException
	{
		String dbms = conn.getMetaData().getDatabaseProductName();
		if (SQLSERVER.equalsIgnoreCase(dbms))
			return "BIGINT PRIMARY KEY IDENTITY";
		
		if (ORACLE.equalsIgnoreCase(dbms))
			return ORACLE_SERIAL_TYPE;
		
		// for mysql and postgresql, return the following.
		return "SERIAL PRIMARY KEY";
	}

	private static String getCSVNullValue(Connection conn)
	{
		try
		{
			String dbms = conn.getMetaData().getDatabaseProductName();
			
			if (MYSQL.equalsIgnoreCase(dbms))
				return "\\N";
			else if (POSTGRESQL.equalsIgnoreCase(dbms) || SQLSERVER.equalsIgnoreCase(dbms) || ORACLE.equalsIgnoreCase(dbms))
				return ""; // empty string (no quotes)
			else
				throw new InvalidParameterException("Unsupported DBMS type: " + dbms);
		}
		catch (Exception e)
		{
			// this should never happen
			throw new RuntimeException(e);
		}
	}
	
	private static final char SQL_SERVER_DELIMETER = (char)8;
	
	public static String generateCSV(Connection conn, String[][] csvData) throws SQLException
	{
		String outputNullValue = SQLUtils.getCSVNullValue(conn);
		for (int i = 0; i < csvData.length; i++)
		{
			for (int j = 0; j < csvData[i].length; j++)
			{
				if (csvData[i][j] == null)
					csvData[i][j] = outputNullValue;
			}
		}
		
		String dbms = conn.getMetaData().getDatabaseProductName();
		if (SQLSERVER.equalsIgnoreCase(dbms))
		{
			// special case for Microsoft SQL Server because it does not support quotes.
			CSVParser parser = new CSVParser(SQL_SERVER_DELIMETER);
			return parser.createCSV(csvData, false);
		}
		else
		{
			boolean quoteEmptyStrings = outputNullValue.length() > 0;
			return CSVParser.defaultParser.createCSV(csvData, quoteEmptyStrings);
		}
		
		
	}
}

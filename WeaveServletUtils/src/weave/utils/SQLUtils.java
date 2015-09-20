/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.utils;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.rmi.RemoteException;
import java.security.InvalidParameterException;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Arrays;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Vector;

/**
 * SQLUtils
 * 
 * @author Andy Dufilie
 * @author Andrew Wilkinson
 * @author Kyle Monico
 * @author Yen-Fu Luo
 * @author Philip Kovac
 * @author Patrick Stickney
 * @author John Fallon
 */
public class SQLUtils
{
	public static String MYSQL = "MySQL";
	public static String SQLITE = "SQLite";
	public static String POSTGRESQL = "PostgreSQL";
	public static String SQLSERVER = "Microsoft SQL Server";
	public static String ORACLE = "Oracle";
	
	public static String DEFAULT_SQLITE_DATABASE = "sqlite_master";
	
	/**
	 * @param dbms The name of a DBMS (MySQL, PostgreSQL, ...)
	 * @return A driver name that can be used in the getConnection() function.
	 */
	public static String getDriver(String dbms) throws RemoteException
	{
		if (dbms.equalsIgnoreCase(MYSQL))
			return "com.mysql.jdbc.Driver";
		if(dbms.equalsIgnoreCase(SQLITE))
			return "org.sqlite.JDBC";
		if (dbms.equalsIgnoreCase(POSTGRESQL))
			return "org.postgis.DriverWrapper";
		if (dbms.equalsIgnoreCase(SQLSERVER))
			return "net.sourceforge.jtds.jdbc.Driver";
		if (dbms.equalsIgnoreCase(ORACLE))
			return "oracle.jdbc.OracleDriver";
		
		throw new RemoteException("Unknown DBMS");
	}
	
	public static String getDbmsFromConnection(Connection conn)
	{
		try
		{
			String dbms = conn.getMetaData().getDatabaseProductName();
			for (String match : new String[]{ ORACLE, SQLSERVER, MYSQL, SQLITE, POSTGRESQL })
				if (dbms.equalsIgnoreCase(match))
					return match;
			return dbms;
		}
		catch (SQLException e)
		{
			return "";
		}
	}
	
	public static String getDbmsFromConnectString(String connectString) throws RemoteException
	{
		if (connectString.startsWith("jdbc:jtds"))
			return SQLSERVER;
		if (connectString.startsWith("jdbc:oracle"))
			return ORACLE;
		if (connectString.startsWith("jdbc:mysql"))
			return MYSQL;
		if (connectString.startsWith("jdbc:sqlite"))
			return SQLITE;
		if (connectString.startsWith("jdbc:postgresql"))
			return POSTGRESQL;
		
		throw new RemoteException("Unknown DBMS");
	}
	
	/**
	 * @param dbms The name of a DBMS (MySQL, PostgreSQL, Microsoft SQL Server)
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
		else if(SQLITE.equalsIgnoreCase(dbms))
		{
			format = "jdbc:%s:%s";
			// "jdbc:sqlite:C:/path/to/file/DataBase.db"
		}
		else // MySQL or PostGreSQL
		{
			format = "jdbc:%s://%s/%s?user=%s&password=%s";
		}

		// MySQL connect string uses % as an escape character, so we must use URLEncoder.
		// PostgreSQL does not support % as an escape character, and does not work with the & character.
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
		else if( dbms.equalsIgnoreCase(SQLITE))
			result = String.format(format, dbms.toLowerCase(), database);
		else
			result = String.format(format, dbms.toLowerCase(), host, database, user, pass);

		return result;
	}
	
	/**
	 * This maps a driver name to a Driver instance.
	 * The purpose of this map is to avoid instantiating extra Driver objects unnecessarily.
	 */
	private static HashMap<String,Driver> _driverMap = new HashMap<String,Driver>();
	
	/**
	 * Call this when shutting down your application to deregister SQL drivers.
	 */
	public static void staticCleanup()
	{
		for (Connection conn : _staticReadOnlyConnections.values())
			cleanup(conn);
		_staticReadOnlyConnections.clear();
		
		// Now deregister JDBC drivers in this context's ClassLoader:
		// Get the webapp's ClassLoader
		ClassLoader cl = Thread.currentThread().getContextClassLoader();
		// Loop through all drivers
		Enumeration<Driver> drivers = DriverManager.getDrivers();
		while (drivers.hasMoreElements())
		{
			Driver driver = drivers.nextElement();
			if (driver.getClass().getClassLoader() != cl)
			{
				// driver was not registered by the webapp's ClassLoader and may be in use elsewhere
				continue;
			}
			
			// This driver was registered by the webapp's ClassLoader, so deregister it:
			try
			{
				DriverManager.deregisterDriver(driver);
			}
			catch (SQLException e)
			{
				e.printStackTrace();
			}
		}
		
		_driverMap.clear();
	}
	
	/**
	 * This maps a connection string to a Connection object.  Used by getStaticReadOnlyConnection().
	 */
	private static Map<String, Connection> _staticReadOnlyConnections = new HashMap<String, Connection>();
	
	/**
	 * This function will test a connection by running a simple test query.
	 * We cannot rely on Connection.isValid(timeout) because it does not work in some drivers.
	 * Running a test query is a reliable way to find out if the connection is valid.
	 * @param conn A SQL Connection.
	 * @throws SQLException Thrown if the test query fails.
	 */
	public static void testConnection(Connection conn) throws SQLException
	{
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			if (SQLUtils.isOracleServer(conn))
				stmt.execute("SELECT 0 FROM DUAL");
			else
				stmt.execute("SELECT 0");
		}
		catch (RuntimeException e) // This is important for catching unexpected errors.
		{
			/*
				Example unexpected error when the connection is invalid:
				
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
	 * @param connectString The connect string used to create the Connection.
	 * @return A static read-only Connection.
	 */
	public static Connection getStaticReadOnlyConnection(String connectString, String user, String pass) throws RemoteException
	{
		String key = CSVParser.defaultParser.createCSVRow(new String[]{connectString, user != null ? user : "", pass != null ? pass : ""}, false);
		synchronized (_staticReadOnlyConnections)
		{
			Connection conn = null;
			if (_staticReadOnlyConnections.containsKey(key))
			{
				conn = _staticReadOnlyConnections.get(key);
				if (connectionIsValid(conn))
					return conn;
				// if connection is not valid, remove this entry from the Map
				_staticReadOnlyConnections.remove(key);
			}
			
			// get a new connection, throwing an exception if this fails
			conn = getConnection(connectString, user, pass);
			
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
				_staticReadOnlyConnections.put(key, conn);

			return conn;
		}
	}
	
	/**
	 * @param connectString The connect string to use.
	 * @return A new SQL connection using the specified driver & connect string 
	 */
	public static Connection getConnection(String connectString) throws RemoteException
	{
		return getConnection(connectString, null, null);
	}
	
	/**
	 * @param connectString The connect string to use.
	 * @param user The user name
	 * @param pass The password
	 * @return A new SQL connection using the specified driver & connect string 
	 */
	public static Connection getConnection(String connectString, String user, String pass) throws RemoteException
	{
		String dbms = getDbmsFromConnectString(connectString);
		
		String driver = getDriver(dbms);
		
		Connection conn = null;
		try
		{
			// only call newInstance once per driver
			if (!_driverMap.containsKey(driver))
				_driverMap.put(driver, (Driver)Class.forName(driver).newInstance());

			if (user == null && pass == null)
				conn = DriverManager.getConnection(connectString);
			else
				conn = DriverManager.getConnection(connectString, user, pass);
		}
		catch (SQLException ex)
		{
			System.err.println(String.format("driver: %s\nconnectString: %s", driver, connectString));
			throw new RemoteException("Unable to connect to SQL database", ex);
		}
		catch (Exception ex)
		{
			throw new RemoteException("Failed to load driver: \"" + driver + "\"", ex);
		}
		return conn;
	}
	
	/**
	 * @param colName
	 * @return colName with special characters replaced and truncated to 30 characters.
	 */
	public static String fixColumnName(String colName, String suffix)
	{
		colName = colName
			.replace("<=", "LTE")
			.replace(">=", "GTE")
			.replace("<", "LT")
			.replace(">", "GT");
		
		StringBuilder sb = new StringBuilder();
		boolean space = false;
		for (int i = 0; i < colName.length(); i++)
		{
			
			char c = colName.charAt(i);
			if (Character.isJavaIdentifierPart(c))
			{
				if (space)
					sb.append(' ');
				sb.append(c);
				space = false;
			}
			else
			{
				space = true;
			}
		}
		// append suffix before truncating
		sb.append(suffix);
		
		colName = sb.toString();
		
		// if the length of the column name is longer than the 30-character limit in oracle (MySQL limit is 64 characters)
		int max = 30;
		// if name too long, remove spaces
		if (colName.length() > max)
			colName = colName.replace(" ", "");
		// if still too long, truncate
		if (colName.length() > max)
		{
			int halfLeft = max / 2;
			int halfRight = max / 2 - 1 + max % 2; // subtract 1 for the "_" unless max is odd
			colName = colName.substring(0, halfLeft) + "_" + colName.substring(colName.length() - halfRight);
		}
		return colName;
	}

	/**
	 * @param dbms The name of a DBMS (MySQL, PostgreSQL, ...)
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
		else if (dbms.equalsIgnoreCase(POSTGRESQL) || dbms.equalsIgnoreCase(ORACLE) || dbms.equalsIgnoreCase(SQLITE))
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
		String dbms = getDbmsFromConnection(conn);
		return quoteSymbol(dbms, symbol);
	}
	
	/**
	 * @param dbms The name of a DBMS (MySQL, PostgreSQL, ...)
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
		else if (dbms.equalsIgnoreCase(POSTGRESQL) || dbms.equalsIgnoreCase(ORACLE) || dbms.equalsIgnoreCase(SQLITE))
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
	public static String unquoteSymbol(Connection conn, String symbol) throws SQLException, IllegalArgumentException
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
		if (getDbmsFromConnection(conn).equals(MYSQL))
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
	 * If the database is not supported by this function, the queryExpression will not be altered.
	 * @param conn An SQL Connection.
	 * @param queryExpression An expression to be used in a SQL Query.
	 * @return The query expression wrapped in a string cast.
	 */
	public static String stringCast(Connection conn, String queryExpression) throws SQLException
	{
		String dbms = getDbmsFromConnection(conn);
		if (dbms.equals(MYSQL))
			return String.format("cast(%s as char)", queryExpression);
		if (dbms.equals(POSTGRESQL) || dbms.equals(SQLITE))
			return String.format("cast(%s as varchar)", queryExpression);
		
		// dbms type not supported by this function yet
		return queryExpression;
	}
	
	/**
	 * This function returns the name of a binary data type that can be used in SQL queries.
	 * @param dbms The name of a DBMS (MySQL, PostgreSQL, ...)
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
	 * @param dbms The name of a DBMS (MySQL, PostgreSQL, ...)
	 * @param schema The schema the table resides in.
	 * @param table The table.
	 * @return The schema & table name surrounded in quotes, usable in queries for the specified DBMS.
	 */
	public static String quoteSchemaTable(String dbms, String schema, String table)
	{
		if (schema.length() == 0)
			return quoteSymbol(dbms, table);
		
		if (dbms.equalsIgnoreCase(ORACLE))
			schema = schema.toUpperCase();
		
		if(dbms.equalsIgnoreCase(SQLITE))
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
		String dbms = getDbmsFromConnection(conn);
		return quoteSchemaTable(dbms, schema, table);
	}

	public static boolean sqlTypeIsNumeric(int sqlType)
	{
		switch (sqlType)
		{
			case Types.TINYINT:
			case Types.SMALLINT:
			case Types.BIGINT:
			case Types.DECIMAL:
			case Types.INTEGER:
			case Types.FLOAT:
			case Types.DOUBLE:
			case Types.REAL:
			case Types.NUMERIC:
			/* case Types.ROWID: // produces compiler error in some environments */
				return true;
			default:
				return false;
		}
	}
	
	public static boolean sqlTypeIsGeometry(int sqlType)
	{
		// using 1111 as the literal value returned by postgis as a PGGeometry type.
		return sqlType == 1111;
	}
	
	/**
	 * Example usage:
	 * {@code
	 *     getResultFromQuery(conn, "SELECT a, b FROM mytable WHERE c = ? and d = ?", new Object[]&#124; "my-c-value", 0xDDDD &#125;, false)
	 * }
	 * @param connection An SQL Connection
	 * @param query An SQL Query with '?' place holders for parameters
	 * @param params Parameters for the SQL query for all '?' place holders, or null if there are no parameters.
	 * @return A SQLResult object containing the result of the query
	 * @throws SQLException
	 */
	public static <TYPE> SQLResult getResultFromQuery(Connection connection, String query, TYPE[] params, boolean convertToStrings)
		throws SQLException
	{
		Statement stmt = null;
		ResultSet rs = null;
		SQLResult result = null;
		try
		{
			long time1 = System.currentTimeMillis();
			
			if (params == null || params.length == 0)
			{
				stmt = connection.createStatement();
				rs = stmt.executeQuery(query);
			}
			else
			{
				stmt = prepareStatement(connection, query, params);
				rs = ((PreparedStatement)stmt).executeQuery();
			}
			
			long time2 = System.currentTimeMillis();
			
			// make a copy of the query result
			result = new SQLResult(rs, convertToStrings);
			
			long time3 = System.currentTimeMillis();
			
			long queryTime = time2 - time1;
			long readTime = time3 - time2;
			long totalTime = time3 - time1;
			if (totalTime > 1000)
			{
				System.out.println(String.format("[%sms query, %sms read] %s", queryTime, readTime, query));
			}

		}
		catch (SQLException e)
		{
			//e.printStackTrace();
			throw new SQLExceptionWithQuery(query, e);
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
	 * @param rs The ResultSet returned from a SQL query.
	 * @param valueType The Class used for casting values in the ResultSet.
	 * @return A list of field-value pairs containing the record data.
	 * @throws SQLException If the query fails.
	 */
	@SuppressWarnings("unchecked")
	public static <VALUE_TYPE> List<Map<String,VALUE_TYPE>> getRecordsFromResultSet(ResultSet rs, Class<VALUE_TYPE> valueType) throws SQLException
	{
		// list the column names in the result
		String[] columnNames = getColumnNamesFromResultSet(rs);
		// create a Map from each row
		List<Map<String,VALUE_TYPE>> records = new Vector<Map<String,VALUE_TYPE>>();
		rs.setFetchSize(SQLResult.FETCH_SIZE);
		while (rs.next())
		{
			Map<String,VALUE_TYPE> record = new HashMap<String,VALUE_TYPE>(columnNames.length);
			for (int i = 0; i < columnNames.length; i++)
			{
				String columnName = columnNames[i];
				Object columnValue = (valueType == String.class) ? rs.getString(columnName) : rs.getObject(columnName);
				
				record.put(columnName, (VALUE_TYPE)columnValue);
			}
			records.add(record);
		}
		return records;
	}
	public static String[] getColumnNamesFromResultSet(ResultSet rs) throws SQLException
	{
		String[] columnNames = new String[rs.getMetaData().getColumnCount()];
		for (int i = 0; i < columnNames.length; i++)
			columnNames[i] = rs.getMetaData().getColumnName(i + 1);
		return columnNames;
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param selectColumns The list of column names, or null for all columns 
	 * @param fromSchema The schema containing the table to perform the SELECT statement on.
	 * @param fromTable The table to perform the SELECT statement on.
	 * @param where Used to construct the WHERE clause
	 * @param orderBy The field to order by, or null for no specific order.
	 * @param valueType Either String.class or Object.class to denote the VALUE_TYPE class.
	 * @return The resulting rows returned by the query.
	 * @throws SQLException If the query fails.
	 */
	public static <VALUE_TYPE> List<Map<String,VALUE_TYPE>> getRecordsFromQuery(
			Connection conn,
			List<String> selectColumns,
			String fromSchema,
			String fromTable,
			WhereClause<VALUE_TYPE> where,
			String orderBy,
			Class<VALUE_TYPE> valueType
		) throws SQLException
	{
		PreparedStatement pstmt = null;
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
			
			String orderByQuery = "";
			if (orderBy != null)
				orderByQuery = String.format("ORDER BY %s", quoteSymbol(conn, orderBy));
			
			// build complete query
			query = String.format(
					"SELECT %s FROM %s %s %s",
					columnQuery,
					quoteSchemaTable(conn, fromSchema, fromTable),
					where.clause,
					orderByQuery
				);
			
			pstmt = prepareStatement(conn, query, where.params);
			rs = pstmt.executeQuery();
			
			return getRecordsFromResultSet(rs, valueType);
		}
		catch (SQLException e)
		{
			throw new SQLExceptionWithQuery(query, e);
		}
		finally
		{
			// close everything in reverse order
			cleanup(rs);
			cleanup(pstmt);
		}
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param selectColumns The list of columns in the SELECT statement, or null for all columns.
	 * @param fromSchema The schema containing the table to perform the SELECT statement on.
	 * @param fromTable The table to perform the SELECT statement on.
	 * @param whereParams A map of column names to String values used to construct a WHERE clause.
	 * @return The resulting rows returned by the query.
	 * @throws SQLException If the query fails.
	 */
	public static <V> SQLResult getResultFromQuery(
			Connection conn,
			List<String> selectColumns,
			String fromSchema,
			String fromTable,
			Map<String,V> whereParams,
			Set<String> caseSensitiveFields
		) throws SQLException
	{
		PreparedStatement pstmt = null;
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
			WhereClause<V> where = new WhereClauseBuilder<V>(false)
				.addGroupedConditions(whereParams, caseSensitiveFields, null)
				.build(conn);
			
			// build complete query
			query = String.format(
					"SELECT %s FROM %s %s",
					columnQuery,
					quoteSchemaTable(conn, fromSchema, fromTable),
					where.clause
				);
			pstmt = prepareStatement(conn, query, where.params);
			rs = pstmt.executeQuery();
			
			// make a copy of the query result
			result = new SQLResult(rs);
		}
		catch (SQLException e)
		{
			throw new SQLExceptionWithQuery(query, e);
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(pstmt);
		}
		
		// return the copy of the query result
		return result;
	}
	
	public static int executeUpdate(Connection connection, String query)
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
	
	public static int executeUpdate(Connection conn, String query, Object[] params)
		throws SQLException
	{
		PreparedStatement stmt = null;
		int result = 0;
		
		try
		{
			stmt = conn.prepareStatement(query);
			constrainQueryParams(conn, params);
			setPreparedStatementParams(stmt, params);
			result = stmt.executeUpdate();
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

	public static int getSingleIntFromQuery(Connection conn, String query, int defaultValue) throws SQLException
	{
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			return getSingleIntFromQuery(stmt, query, defaultValue);
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}
	
	public static int getSingleIntFromQuery(Statement stmt, String query, int defaultValue) throws SQLException
	{
		ResultSet resultSet = null;
		try
		{
			resultSet = stmt.executeQuery(query);
	        if (resultSet.next())
	        	return resultSet.getInt(1);
	        return defaultValue;
		}
		finally
		{
			SQLUtils.cleanup(resultSet);
		}
	}

	public static int getSingleIntFromQuery(Connection conn, String query, Object[] params, int defaultValue) throws SQLException
	{
		PreparedStatement pstmt = null;
		ResultSet resultSet = null;
		try
		{
			pstmt = conn.prepareStatement(query);
			setPreparedStatementParams(pstmt, params);
			resultSet = pstmt.executeQuery();
			if (resultSet.next())
				return resultSet.getInt(1);
			return defaultValue;
		}
		finally
		{
			SQLUtils.cleanup(resultSet);
			SQLUtils.cleanup(pstmt);
		}
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
			if (md.getDatabaseProductName().equalsIgnoreCase(MYSQL))
			{
				rs = md.getCatalogs();
				// use column index instead of name because sometimes the names are lower case, sometimes upper.
				while (rs.next())
					schemas.add(rs.getString(1)); // table_catalog
			}
			else if( md.getDatabaseProductName().equalsIgnoreCase(SQLITE))
			{
				schemas.add("sqlite_master");
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
		if (schemaName != null)
		{
			if (SQLUtils.isOracleServer(conn))
				schemaName = schemaName.toUpperCase();
			if (schemaName.length() == 0)
				schemaName = null;
		}
		
		List<String> tables = new Vector<String>();
		ResultSet rs = null;
		try
		{
			DatabaseMetaData md = conn.getMetaData();
			String[] types = new String[]{"TABLE", "VIEW"};
			
			// MySQL uses "catalogs" instead of "schemas"
			if (md.getDatabaseProductName().equalsIgnoreCase(MYSQL))
				rs = md.getTables(schemaName, null, null, types);
			else
				rs = md.getTables(null, schemaName, null, types);
			
			//May need a case here for SQLITE using sqlite_master as a catalog name.
			
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
		ResultSet rs = null;
		try
		{
			DatabaseMetaData md = conn.getMetaData();

			tableName = escapeSearchString(conn, tableName);
			
			// MySQL uses "catalogs" instead of "schemas"
			if (md.getDatabaseProductName().equalsIgnoreCase(MYSQL))
				rs = md.getColumns(schemaName, null, tableName, null);
			else if (isOracleServer(conn))
				rs = md.getColumns(null, schemaName.toUpperCase(), tableName, null);
			else
				rs = md.getColumns(null, schemaName, tableName, null);
			
			//May need a case here for SQLITE using sqlite_master as a catalog name.
			
			// use column index instead of name because sometimes the names are lower case, sometimes upper.
			while (rs.next())
				columns.add(rs.getString(4)); // column_name
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(rs);
		}
		return columns;
	}
	
	// not implemented by SQLite JDBC driver
	/* *
	 * Attaches a database to an SQLite instance.
	 * @param conn A SQLite connection.
	 * @param databaseName The name of the database.
	 * @param filePath The path to the file where the database either exists or should be created.
	 * @throws SQLException
	 * /
	public static void createSQLiteDatabase(Connection conn, String databaseName, String filePath) throws SQLException
	{
		if (SQLUtils.schemaExists(conn, databaseName))
			return;
		
		String query = String.format("ATTACH DATABASE ? AS %s", quoteSymbol(conn, databaseName));
		PreparedStatement stmt = null;
		try
		{
			stmt = prepareStatement(conn, query, new String[]{ filePath });
			stmt.executeUpdate(query);
		}
		catch (SQLException e)
		{
			throw new SQLExceptionWithQuery(query, e);
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}*/
	
	/**
	 * Creates a schema in a non-SQLite database.  For SQLite, this does nothing.
	 * @param conn An existing SQL Connection
	 * @param schema The value to be used as the Schema name
	 * @throws SQLException If the query fails.
	 */
	public static void createSchema(Connection conn, String schema)
		throws SQLException
	{
		if (isSQLite(conn))
			return;
		
		if (SQLUtils.schemaExists(conn, schema))
			return;

		String query = String.format("CREATE SCHEMA %s", schema);
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
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
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName The value to be used as the table name
	 * @param columnNames The values to be used as the column names
	 * @param columnTypes The SQL types to use when creating the table
	 * @param primaryKeyColumns The list of columns to be used for primary keys 
	 * @throws SQLException If the query fails.
	 */
	public static void createTable(
			Connection conn,
			String schemaName,
			String tableName,
			List<String> columnNames,
			List<String> columnTypes,
			List<String> primaryKeyColumns
		)
		throws SQLException
	{
		if (columnNames.size() != columnTypes.size())
			throw new IllegalArgumentException(String.format("columnNames length (%s) does not match columnTypes length (%s)", columnNames.size(), columnTypes.size()));
		
		//if table exists return
		if( tableExists(conn, schemaName, tableName) )
			return;
		
		StringBuilder columnClause = new StringBuilder();
		for (int i = 0; i < columnNames.size(); i++)
		{
			if( i > 0 )
				columnClause.append(',');
			String type = columnTypes.get(i);
			columnClause.append(String.format("%s %s", quoteSymbol(conn, columnNames.get(i)), type));
		}
		
		if (primaryKeyColumns != null && primaryKeyColumns.size() > 0)
		{
			String pkName = truncate(String.format("pk_%s", tableName), 30);
			
			String[] quotedKeyColumns = new String[primaryKeyColumns.size()];
			int i = 0;
			for (String keyCol : primaryKeyColumns)
				quotedKeyColumns[i++] = quoteSymbol(conn, keyCol);
			
			// http://www.w3schools.com/sql/sql_primarykey.asp
			columnClause.append(
				String.format(
					", CONSTRAINT %s PRIMARY KEY (%s)",
					quoteSymbol(conn, pkName),
					Strings.join(",", quotedKeyColumns)
				)
			);
		}
		
		String quotedSchemaTable = quoteSchemaTable(conn, schemaName, tableName);
		String query = String.format("CREATE TABLE %s (%s)", quotedSchemaTable, columnClause);
		
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
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
	public static void addForeignKey(
			Connection conn,
			String schemaName,
			String tableName,
			String keyName,
			String targetTable,
			String targetKey
		) throws SQLException
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
			throw new SQLExceptionWithQuery(query, e);
		}
		finally
		{
			SQLUtils.cleanup(stmt);
		}
	}
	public static <TYPE> PreparedStatement prepareStatement(Connection conn, String query, List<TYPE> params) throws SQLException
	{
		PreparedStatement cstmt = conn.prepareStatement(query);
		constrainQueryParams(conn, params);
		setPreparedStatementParams(cstmt, params);
		return cstmt;
	}
	public static <TYPE> PreparedStatement prepareStatement(Connection conn, String query, TYPE[] params) throws SQLException
	{
		PreparedStatement cstmt = conn.prepareStatement(query);
		constrainQueryParams(conn, params);
		setPreparedStatementParams(cstmt, params);
		return cstmt;
	}
	protected static <T> void constrainQueryParams(Connection conn, List<T> params)
	{
		if (isOracleServer(conn))
			for (int i = 0; i < params.size(); i++)
				params.set(i, constrainOracleQueryParam(params.get(i)));
	}
	protected static <T> void constrainQueryParams(Connection conn, T[] params)
	{
		if (isOracleServer(conn))
			for (int i = 0; i < params.length; i++)
				params[i] = constrainOracleQueryParam(params[i]);
	}
	@SuppressWarnings("unchecked")
	protected static <T> T constrainOracleQueryParam(T param)
	{
		// constrain oracle double values to float range
		if (param instanceof Double)
			param = (T)(Float)((Double) param).floatValue();
		return param;
	}
	public static <TYPE> void setPreparedStatementParams(PreparedStatement cstmt, List<TYPE> params) throws SQLException
	{
		int i = 1;
		for (TYPE param : params)
			cstmt.setObject(i++, param);
	}
	public static <TYPE> void setPreparedStatementParams(PreparedStatement cstmt, TYPE[] params) throws SQLException
	{
		int i = 1;
		for (TYPE param : params)
			cstmt.setObject(i++, param);
	}
	
	public static int updateRows(Connection conn, String fromSchema, String fromTable, Map<String,Object> whereParams, Map<String,Object> dataUpdate, Set<String> caseSensitiveFields) throws SQLException
	{
		PreparedStatement stmt = null;
		try
		{
			// build the update block
			String updateBlock;
			List<String> updateBlockList = new LinkedList<String>();
			List<Object> queryParams = new LinkedList<Object>();
			for (Entry<String,Object> data : dataUpdate.entrySet())
			{
		        updateBlockList.add(String.format("%s=?", data.getKey()));
		        queryParams.add(data.getValue());
		    }
			updateBlock = Strings.join(",", updateBlockList);
		    
			// build where clause
		    WhereClause<Object> where = new WhereClauseBuilder<Object>(false)
		    	.addGroupedConditions(whereParams, caseSensitiveFields, null)
		    	.build(conn);
		    queryParams.addAll(where.params);
		    
		    // build and execute query
		    String query = String.format("UPDATE %s SET %s %s", fromTable, updateBlock, where.clause);
		    stmt = prepareStatement(conn, query, queryParams);
		    return stmt.executeUpdate();
		}
		finally
		{
			cleanup(stmt);
		}
	}
	
	/**
	 * Modifies a query so it will only return a single row.
	 * @param dbms The target DBMS.
	 * @param query A SQL Query.
	 * @return The modified query.
	 */
	private static String limitQueryToOneRow(String dbms, String query)
	{
		if (dbms.equals(ORACLE))
			return String.format("SELECT * FROM (%s) WHERE ROWNUM <= 1", query);
		
		if (dbms.equals(MYSQL) || dbms.equals(POSTGRESQL) || dbms.equals(SQLITE))
			return query + " LIMIT 1";
		
		throw new InvalidParameterException("DBMS not supported: " + dbms);
	}
	private static String newIdClause(String dbms, String quotedIdField, String quotedTable)
	{
		if (dbms.equals(SQLITE))
		{
			return String.format(
					"(SELECT CASE WHEN MAX(%s) IS NULL THEN 1 ELSE MAX(%s)+1 END FROM %s LIMIT 1)",
					quotedIdField,
					quotedIdField,
					quotedTable
			);
		}
		
		if (dbms.equals(SQLSERVER))
		{
			return String.format(
					"(SELECT TOP 1 CASE WHEN MAX(%s) IS NULL THEN 1 ELSE MAX(%s)+1 END FROM %s)",
					quotedIdField,
					quotedIdField,
					quotedTable
			);
		}
		
		if (dbms.equals(ORACLE))
		{
			String query = String.format("SELECT MAX(%s)+1 FROM %s", quotedIdField, quotedTable);
			query = limitQueryToOneRow(dbms, query);
			return String.format("GREATEST(1, (%s))", query);
		}
		
		// MySQL/PostgreSQL
		return String.format(
				"GREATEST(1, (SELECT MAX(%s)+1 FROM %s LIMIT 1))",
				quotedIdField,
				quotedTable
			);
	}
	
	/**
	 * Generates a new id manually using MAX(idField)+1.
	 * @param conn
	 * @param schemaName
	 * @param tableName
	 * @param data Unquoted field names mapped to raw values.
	 * @param idField
	 * @return The ID of the new row.
	 * @throws SQLException
	 */
	public static int insertRowReturnID(Connection conn, String schemaName, String tableName, Map<String,Object> data, String idField) throws SQLException
	{
		String dbms = getDbmsFromConnection(conn);
		boolean isOracle = dbms.equals(ORACLE);
		boolean isSQLServer = dbms.equals(SQLSERVER);
		boolean isMySQL = dbms.equals(MYSQL);
		boolean isPostgreSQL = dbms.equals(POSTGRESQL);
		boolean isSQLite = dbms.equals(SQLITE);
		boolean useTwoQueries = isMySQL || isOracle || isSQLite;
		
		String query = null;
		List<String> columns = new LinkedList<String>();
		LinkedList<Object> values = new LinkedList<Object>();
		for (Entry<String,Object> entry : data.entrySet())
		{
			columns.add(quoteSymbol(conn, entry.getKey()));
			values.add(entry.getValue());
		}
		
		String quotedIdField = quoteSymbol(conn, idField);
		String quotedTable = quoteSchemaTable(conn, schemaName, tableName);
		
		String fields_string = quotedIdField + "," + Strings.join(",", columns);
		
		String id_string;
		if (useTwoQueries)
			id_string = "?"; // we get the new id below and then give it as a param
		else
			id_string = newIdClause(dbms, quotedIdField, quotedTable);
		
		String values_string = id_string + "," + Strings.mult(",", "?", values.size());
		
		// build query
		query = String.format("INSERT INTO %s (%s)", quotedTable, fields_string);

		if (isSQLServer)
			query += String.format(" OUTPUT INSERTED.%s", quotedIdField);
		
		query += String.format(" VALUES (%s)", values_string);
		
		if (isPostgreSQL)
			query += String.format(" RETURNING %s", quotedIdField);
		
		try
		{
			int id;
			synchronized (conn)
			{
				if (useTwoQueries)
				{
					String nextQuery = query;
					
					query = String.format(
							"SELECT %s FROM %s",
							newIdClause(dbms, quotedIdField, quotedTable),
							quotedTable
						);
					query = limitQueryToOneRow(dbms, query);
					id = getSingleIntFromQuery(conn, query, 1);
					
					values.addFirst(id);
					
					query = nextQuery;
					executeUpdate(conn, query, values.toArray());
				}
				else
				{
					id = getSingleIntFromQuery(conn, query, values.toArray(), -1);
				}
			}
			return id;
		}
		catch (SQLException e)
		{
			throw new SQLExceptionWithQuery(query, e);
		}
	}
	
	/**
	 * This function checks if a connection is for a PostgreSQL server.
	 * @param conn A SQL Connection.
	 * @return A value of true if the Connection is for a PostgreSQL server.
	 * @throws SQLException 
	 */
	public static boolean isPostgreSQL(Connection conn)
	{
		return getDbmsFromConnection(conn).equals(POSTGRESQL);
	}
	
	/**
	 * This function checks if a connection is for a MySQL server.
	 * @param conn A SQL Connection.
	 * @return A value of true if the Connection is for a MySQL server.
	 * @throws SQLException 
	 */
	public static boolean isMySQL(Connection conn)
	{
		return getDbmsFromConnection(conn).equals(MYSQL);
	}
	
	/**
	 * This function checks if a connection is for an Oracle server.
	 * @param conn A SQL Connection.
	 * @return A value of true if the Connection is for an Oracle server.
	 * @throws SQLException 
	 */
	public static boolean isOracleServer(Connection conn)
	{
		return getDbmsFromConnection(conn).equals(ORACLE);
	}
	
	/**
	 * This function checks if a connection is for a Microsoft SQL Server.
	 * @param conn A SQL Connection.
	 * @return A value of true if the Connection is for a Microsoft SQL Server.
	 */
	public static boolean isSQLServer(Connection conn)
	{
		return getDbmsFromConnection(conn).equals(SQLSERVER);
	}
	
	/**
	 * This function checks if a connection is for a SQLite server.
	 * @param conn A SQL Connection.
	 * @return A value of true if the Connection is for a SQLite Server.
	 */
	public static boolean isSQLite(Connection conn)
	{
		return getDbmsFromConnection(conn).equals(SQLITE);
	}
	
	private static String truncate(String str, int maxLength)
	{
		if (str.length() > maxLength)
			return str.substring(0, maxLength);
		return str;
	}
	
	private static String generateSymbolName(String prefix, Object ...items)
	{
		int hash = Arrays.deepToString(items).hashCode();
		return String.format("%s_%s", prefix, hash);
	}
	
	private static String generateQuotedSymbolName(String prefix, Connection conn, String schema, String table, String ...columns) throws SQLException
	{
		String indexName = generateSymbolName(prefix, schema, table, columns);
		if (isOracleServer(conn))
			return quoteSchemaTable(conn, schema, indexName);
		else
			return quoteSymbol(conn, indexName);
	}
	
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName The name of an existing table
	 * @param columnNames The names of the columns to use
	 * @throws SQLException If the query fails.
	 */
	public static void createIndex(Connection conn, String schemaName, String tableName, String[] columnNames) throws SQLException
    {
        createIndex(conn, schemaName, tableName, columnNames, null);
    }
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName The name of an existing table
	 * @param columnNames The names of the columns to use.
	 * @param columnLengths The lengths to use as indices, may be null.
	 * @throws SQLException If the query fails.
	 */
	public static void createIndex(Connection conn, String schemaName, String tableName, String[] columnNames, Integer[] columnLengths) throws SQLException
	{
		boolean isMySQL = getDbmsFromConnection(conn).equals(MYSQL);
		String fields = "";
		for (int i = 0; i < columnNames.length; i++)
		{
			if (i > 0)
				fields += ", ";
			
			String symbol = quoteSymbol(conn, columnNames[i]);
			if (isMySQL && columnLengths != null && columnLengths[i] > 0)
				fields += String.format("%s(%d)", symbol, columnLengths[i]);
			else
				fields += symbol;
		}
		String query = String.format(
				"CREATE INDEX %s ON %s (%s)",
				generateQuotedSymbolName("index", conn, schemaName, tableName, columnNames),
				SQLUtils.quoteSchemaTable(conn, schemaName, tableName),
				fields
		);
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
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
	
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName The name of an existing table
	 * @param columnName The name of the column to create
	 * @param columnType An SQL type to use when creating the column
	 * @throws SQLException If the query fails.
	 */
	public static void addColumn( Connection conn, String schemaName, String tableName, String columnName, String columnType)
		throws SQLException
	{
		String format = "ALTER TABLE %s ADD %s %s"; // Note: PostgreSQL does not accept parentheses around the new column definition.
		String query = String.format(format, quoteSchemaTable(conn, schemaName, tableName), quoteSymbol(conn, columnName), columnType);
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			stmt.executeUpdate(query);
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
			query = String.format("SELECT %s FROM %s", quoteSymbol(conn, columnArg), quoteSchemaTable(conn, schemaName, tableName));
			
			stmt = conn.createStatement();
			rs = stmt.executeQuery(query);
			rs.setFetchSize(SQLResult.FETCH_SIZE);
			while (rs.next())
				values.add(rs.getString(1));
		}
		catch (SQLException e)
		{
			throw new SQLExceptionWithQuery(query, e);
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
			query = String.format("SELECT %s FROM %s", quoteSymbol(conn, columnArg), quoteSchemaTable(conn, schemaName, tableName));
			
			stmt = conn.createStatement();
			rs = stmt.executeQuery(query);
			rs.setFetchSize(SQLResult.FETCH_SIZE);
			while (rs.next())
				values.add(rs.getInt(1));
		}
		catch (SQLException e)
		{
			throw new SQLExceptionWithQuery(query, e);
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
	 * @param record The record to be inserted into the table
	 * @return The number of rows inserted.
	 * @throws SQLException If the query fails.
	 */
	public static <V> int insertRow( Connection conn, String schemaName, String tableName, Map<String,V> record)
		throws SQLException
	{
		List<Map<String,V>> list = new Vector<Map<String,V>>(1);
		list.add(record);
		return insertRows(conn, schemaName, tableName, list);
	}
	/**
	 * @param conn An existing SQL Connection
	 * @param schemaName A schema name accessible through the given connection
	 * @param tableName A table name existing in the given schema
	 * @param records The records to be inserted into the table
	 * @return The number of rows inserted.
	 * @throws SQLException If the query fails.
	 */
	public static <V> int insertRows( Connection conn, String schemaName, String tableName, List<Map<String,V>> records)
		throws SQLException
	{
		PreparedStatement pstmt = null;
		String query = "insertRows()";
		try
		{
			// get a list of all the field names in all the records
			Set<String> fieldSet = new HashSet<String>();
			for (Map<String,V> record : records)
				fieldSet.addAll(record.keySet());
			List<String> fieldNames = new Vector<String>(fieldSet);
			
			// stop if there aren't any records or field names
			if (records.size() == 0 || fieldNames.size() == 0)
				return 0;
			
			// get full list of ordered query params
			Object[] queryParams = new Object[fieldNames.size() * records.size()];
			int i = 0;
			for (Map<String, V> record : records)
				for (String fieldName : fieldNames)
					queryParams[i++] = record.get(fieldName);

			// quote field names
			for (i = 0; i < fieldNames.size(); i++)
				fieldNames.set(i, quoteSymbol(conn, fieldNames.get(i)));
			
			String quotedSchemaTable = quoteSchemaTable(conn, schemaName, tableName);
			String fieldNamesStr = Strings.join(",", fieldNames);
			
			// construct query
			String recordClause = String.format("(%s)", Strings.mult(",", "?", fieldNames.size()));
			String valuesClause = Strings.mult(",", recordClause, records.size());
			query = String.format(
				"INSERT INTO %s (%s) VALUES %s",
				quotedSchemaTable,
				fieldNamesStr,
				valuesClause
			);
			
			// prepare call and set string parameters
			pstmt = prepareStatement(conn, query.toString(), queryParams);
			int result = pstmt.executeUpdate();
			
			return result;
		}
		catch (SQLException e)
		{
			System.err.println(records);
			throw new SQLExceptionWithQuery(query, e);
		}
		finally
		{
			SQLUtils.cleanup(pstmt);
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
		String dbms = getDbmsFromConnection(conn);
		String quotedTable = SQLUtils.quoteSchemaTable(conn, schema, table);
		String query = "";
		if (dbms.equals(SQLSERVER))
		{
			query = "IF OBJECT_ID('" + quotedTable + "','U') IS NOT NULL DROP TABLE " + quotedTable;
		}
		else if (dbms.equals(ORACLE))
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
	 * @param where The conditions to be used in the WHERE clause of the query
	 * @return The number of rows that were deleted.
	 * @throws SQLException If the query fails.
	 */
	public static <V> int deleteRows(Connection conn, String schemaName, String tableName, WhereClause<V> where) throws SQLException
	{
		// VERY IMPORTANT - do not delete if there are no records specified, because that would delete everything.
		if (Strings.isEmpty(where.clause))
			return 0;
		
		PreparedStatement pstmt = null;
		String query = null;

		try 
		{
			query = String.format("DELETE FROM %s %s", SQLUtils.quoteSchemaTable(conn, schemaName, tableName), where.clause);
			pstmt = prepareStatement(conn, query, where.params);
			return pstmt.executeUpdate();
		}
		catch (SQLException e)
		{
			throw new SQLExceptionWithQuery(query, e);
		}
		finally
		{
			SQLUtils.cleanup(pstmt);
		}		
	}

	/**
	 * This will escape special characters in a SQL search string.
	 * Not reliable on SQLite since there is no escape character.
	 * @param conn A SQL Connection.
	 * @param searchString A SQL search string containing special characters to be escaped.
	 * @return The searchString with special characters escaped.
	 * @throws SQLException 
	 */
	private static String escapeSearchString(Connection conn, String searchString) throws SQLException
	{
		String escape = conn.getMetaData().getSearchStringEscape();
		
		if (escape == null)
		{
			return searchString;
		}
		
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
	public static void cleanup(Connection obj)
	{
		if (obj != null) try { obj.close(); } catch (Exception e) { }
	}

	public static String getVarcharTypeString(Connection conn, int length)
	{
		if (isOracleServer(conn))
			return String.format("VARCHAR2(%s CHAR)", length);
		return String.format("VARCHAR(%s)", length);
	}
	public static String getTinyIntTypeString(Connection conn) throws SQLException
	{
		String dbms = getDbmsFromConnection(conn);
		if (dbms.equals(ORACLE))
			return "NUMBER(1,0)";
		if (dbms.equals(POSTGRESQL))
			return "SMALLINT";
		
		// mysql, sqlserver
		return "TINYINT";
	}
	public static String getIntTypeString(Connection conn)
	{
		if (isOracleServer(conn))
			return "NUMBER(10,0)";
		return "INT";
	}
	public static String getDoubleTypeString(Connection conn)
	{
		if (isSQLServer(conn))
			return "FLOAT"; // this is an 8 floating point type with 53 bits for the mantissa, the same as an 8 byte double.
			                // but SQL Server's DOUBLE PRECISION type isn't standard
		return "DOUBLE PRECISION";
	}
	public static String getBigIntTypeString(Connection conn)
	{
		if (isOracleServer(conn))
			return "NUMBER(20,0)";
		return "BIGINT";
	}
	public static String getDateTimeTypeString(Connection conn)
	{
		if (isOracleServer(conn))
			return "DATE";
		return "DATETIME";
	}
	public static String getLongBlobTypeString(Connection conn)
	{
		if (isOracleServer(conn))
			return "BLOB";
		return "LONGBLOB";
	}
	
	protected static String getCSVNullValue(Connection conn)
	{
		try
		{
			String dbms = getDbmsFromConnection(conn);
			
			if (dbms.equals(MYSQL))
				return "\\N";
			else if (dbms.equals(POSTGRESQL) || dbms.equals(SQLSERVER) || dbms.equals(ORACLE))
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
	
	/**
	 * This function should only be called on a SQL Server connection.
	 * @param conn
	 * @param schema
	 * @param table
	 * @param on
	 * @throws SQLException
	 */
	public static void setSQLServerIdentityInsert(Connection conn, String schema, String table, boolean on) throws SQLException
	{
		if (!isSQLServer(conn))
			return;
		
		String quotedTable = SQLUtils.quoteSchemaTable(conn, schema, table);
		String query = String.format("SET IDENTITY_INSERT %s %s", quotedTable, on ? "ON" : "OFF");
		
		Statement stmt = null;
		try
		{
			stmt = conn.createStatement();
			stmt.execute(query);
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
	
	public static class WhereClause<V>
	{
		public String clause;
		public List<V> params;
		
		/**
		 * An object with three modes: and, or, and cond.
		 * If one property is specified, the others must be null.
		 */
		public static class NestedColumnFilters
		{
			/**
			 * Nested filters to be grouped with AND logic.
			 */
			public NestedColumnFilters[] and;
			/**
			 * Nested filters to be grouped with OR logic.
			 */
			public NestedColumnFilters[] or;
			/**
			 * A condition for a particular field.
			 */
			public ColumnFilter cond;
			
			/**
			 * Makes sure the values in this object are specified correctly.
			 * @throws RemoteException If this object or any of its nested objects are missing required values.
			 */
			public void assertValid() throws RemoteException
			{
				if ((and==null?0:1) + (or==null?0:1) + (cond==null?0:1) != 1)
					error("Exactly one of the properties 'and', 'or', 'cond' must be set");
				
				if (cond != null)
					cond.assertValid();
				if (and != null)
				{
					if (and.length == 0)
						error("'and' must have at least one item");
					for (NestedColumnFilters nested : and)
						if (nested != null)
							nested.assertValid();
						else
							error("'and' must not contain null items");
				}
				if (or != null)
				{
					if (or.length == 0)
						error("'or' must have at least one item");
					for (NestedColumnFilters nested : or)
						if (nested != null)
							nested.assertValid();
						else
							error("'or' must not contain null items");
				}
			}
			private void error(String message) throws RemoteException
			{
				throw new RemoteException("NestedColumnFilters: " + message);
			}
		}

		public WhereClause(String whereClause, List<V> params)
		{
			this.clause = whereClause;
			this.params = params;
		}
		
		/**
		 * A condition for filtering query results.
		 */
		public static class ColumnFilter
		{
			/**
			 * The unquoted field name.
			 */
			public Object f;
			/**
			 * Contains a list of String values ["a", "b", ...]
			 * If <code>v</code> is set, <code>r</code> must be null.
			 */
			public Object[] v;
			/**
			 * Contains a list of numeric ranges [[min,max], [min2,max2], ...]
			 * If <code>r</code> is set, <code>v</code> must be null.
			 */
			public Object[][] r;
			
			/**
			 * Makes sure the values in this object are specified correctly.
			 * @throws RemoteException If this object or any of its nested objects are missing required values.
			 */
			public void assertValid() throws RemoteException
			{
				if (f == null)
					error("'f' cannot be null");
				if ((v == null) == (r == null))
					error("Either 'v' or 'r' must be set, but not both");
			}
			private void error(String message) throws RemoteException
			{
				throw new RemoteException("ColumnFilter: " + message);
			}
		}
		
		/**
		 * Builds a WhereClause from nested filtering logic.
		 * @param conn
		 * @param filters
		 * @return The WhereClause.
		 * @throws SQLException
		 */
		public static WhereClause<Object> fromFilters(Connection conn, NestedColumnFilters filters) throws SQLException
		{
			WhereClause<Object> where = new WhereClause<Object>("", new Vector<Object>());
			StringBuilder sb = new StringBuilder(" WHERE ");
			if (filters != null)
				build(conn, sb, where.params, filters);
			if (!where.params.isEmpty())
				where.clause = sb.toString();
			return where;
		}
		private static void build(Connection conn, StringBuilder clause, List<Object> params, NestedColumnFilters filters) throws SQLException
		{
			clause.append("(");
			if (filters.cond != null)
			{
				String quotedField = quoteSymbol(conn, filters.cond.f.toString());
				String stringCompare = null;
				Object[] values = filters.cond.v != null ? filters.cond.v : filters.cond.r;
				for (int i = 0; i < values.length; i++)
				{
					if (i > 0)
						clause.append(" OR ");
					
					if (values == filters.cond.v) // string value
					{
						if (stringCompare == null)
						{
							stringCompare = String.format("%s = ?", quotedField);
							//stringCompare = caseSensitiveCompare(conn, quotedField, "?");
						}
						clause.append(stringCompare);
						params.add(values[i]);
					}
					else // numeric range
					{
						clause.append(String.format("(? <= %s AND %s <= ?)", quotedField, quotedField));
						Object[] range = (Object[])values[i];
						params.add(range[0]);
						params.add(range[1]);
					}
				}
			}
			else
			{
				NestedColumnFilters[] list = filters.and != null ? filters.and : filters.or;
				int i = 0;
				for (NestedColumnFilters item : list)
				{
					if (i > 0)
						clause.append(list == filters.and ? " AND " : " OR ");
					build(conn, clause, params, item);
					i++;
				}
			}
			clause.append(")");
		}
	}
	
	/**
	 * The escape character (backslash) used by convertWildcards() and getLikeEscapeClause()
	 * @see #convertWildcards(String)
	 * @see #getLikeEscapeClause(Connection)
	 */
	public static final char WILDCARD_ESCAPE = '\\';
	
	/**
	 * Converts a search string which uses basic '?' and '*' wildcards into an equivalent SQL search string.
	 * @param searchString A search string which uses basic '?' and '*' wildcards
	 * @return The equivalent SQL search string using a backslash (\) as an escape character.
	 * @see #getLikeEscapeClause(Connection)
	 */
	public static String convertWildcards(String searchString)
	{
		// escape special characters (including the escape character first)
		for (char chr : new char[]{ WILDCARD_ESCAPE, '%', '_', '[' })
			searchString = searchString.replace("" + chr, "" + WILDCARD_ESCAPE + chr);
		// replace our wildcards with SQL wildcards
		searchString = searchString.replace('?', '_').replace('*', '%');
		return searchString;
	}
	
	/**
	 * Returns an ESCAPE clause for use with a LIKE comparison.
	 * @param conn The SQL Connection where the ESCAPE clause will be used.
	 * @return The ESCAPE clause specifying a backslash (\) as the escape character.
	 * @see #convertWildcards(String)
	 */
	public static String getLikeEscapeClause(Connection conn)
	{
		String dbms = getDbmsFromConnection(conn);
		if (dbms.equals(MYSQL) || dbms.equals(POSTGRESQL))
			return " ESCAPE '\\\\' ";
		return " ESCAPE '\\' ";
	}
	
	/**
	 * Specifies how two SQL terms should be compared
	 */
	public static enum CompareMode
	{
		NORMAL, CASE_SENSITIVE, WILDCARD
	}
	public static class WhereClauseBuilder<V>
	{
		private List<List<Condition>> _nestedConditions = new Vector<List<Condition>>();
		private List<V> _params = new Vector<V>();
		private boolean _conjunctive = false;
		
		/**
		 * @param conjunctive Set to <code>true</code> for Conjunctive Normal Form: (a OR b) AND (x OR y).
		 *                    Set to <code>false</code> for Disjunctive Normal Form: (a AND b) OR (x AND y).
		 */
		public WhereClauseBuilder(boolean conjunctive)
		{
			_conjunctive = conjunctive;
		}
		
		/**
		 * Adds a set of grouped inner conditions.
		 * Conjunctive Normal Form uses outer AND logic and will group these inner conditions with OR logic like (field1 = value1 OR field2 = value2).
		 * Disjunctive Normal Form uses outer OR logic and will group these inner conditions with AND logic like (field1 = value1 AND field2 = value2).
		 * @param fieldsAndValues Unquoted field names mapped to raw values
		 * @param caseSensitiveFields A set of field names which should use case sensitive compare.
		 * @param wildcardFields A set of field names which should use a "LIKE" SQL clause for wildcard search.
		 * @see weave.utils.SQLUtils#convertWildcards(String)
		 */
		public WhereClauseBuilder<V> addGroupedConditions(Map<String,V> fieldsAndValues, Set<String> caseSensitiveFields, Set<String> wildcardFields) throws SQLException
		{
			Map<String, CompareMode> compareModes = new HashMap<String,CompareMode>();
			if (caseSensitiveFields != null)
				for (String field : caseSensitiveFields)
					compareModes.put(field, CompareMode.CASE_SENSITIVE);
			if (wildcardFields != null)
				for (String field : wildcardFields)
					compareModes.put(field, CompareMode.WILDCARD);
			return addGroupedConditions(fieldsAndValues, compareModes);
		}
		
		/**
		 * Adds a set of grouped inner conditions.
		 * Conjunctive Normal Form uses outer AND logic and will group these inner conditions with OR logic like (field1 = value1 OR field2 = value2).
		 * Disjunctive Normal Form uses outer OR logic and will group these inner conditions with AND logic like (field1 = value1 AND field2 = value2).
		 * @param fieldsAndValues Unquoted field names mapped to raw values
		 * @param compareModes Field names mapped to compare modes
		 * @see weave.utils.SQLUtils#convertWildcards(String)
		 */
		public WhereClauseBuilder<V> addGroupedConditions(Map<String,V> fieldsAndValues, Map<String,CompareMode> compareModes) throws SQLException
		{
			if (fieldsAndValues.size() == 0)
				return this;
			List<Condition> conditions = new Vector<Condition>();
			for (Entry<String,V> entry : fieldsAndValues.entrySet())
			{
				Condition cond = new Condition();
				cond.field = entry.getKey();
				cond.valueExpression = "?";
				if (compareModes != null)
					cond.compareMode = compareModes.get(cond.field);
				conditions.add(cond);
				
				_params.add(entry.getValue());
			}
			_nestedConditions.add(conditions);
			return this;
		}
		
		/**
		 * Checks the number of groups which have been added via addGroupedConditions().
		 * @return The number of groups.
		 */
		public int countGroups()
		{
			return _nestedConditions.size();
		}
		
		/**
		 * Builds a WhereClause based on the conditions previously specified with addGroupedConditions().
		 * @param conn A SQL Connection for which the query will be formatted.
		 * @return A WhereClause.
		 * @throws SQLException
		 */
		public WhereClause<V> build(Connection conn) throws SQLException
		{
			String dnf = buildNormalForm(conn);
			String clause = "";
			if (dnf.length() > 0)
				clause = String.format(" WHERE %s ", dnf);
			
			return new WhereClause<V>(clause, _params);
		}
		
		protected String buildNormalForm(Connection conn) throws SQLException
		{
			String outerJunction = _conjunctive ? " AND " : " OR ";
			String innerJunction = _conjunctive ? " OR " : " AND ";
		    List<String> junctions = new LinkedList<String>();
		    for (List<Condition> conditions : _nestedConditions)
		    {
		        List<String> predicates = new LinkedList<String>();
		        for (Condition condition : conditions)
		        	predicates.add(condition.buildPredicate(conn));
		        junctions.add(String.format("(%s)", Strings.join(innerJunction, predicates)));
		    }
	        return Strings.join(outerJunction, junctions);
		}
		
		protected static class Condition
		{
			/**
			 * Unquoted SQL field name
			 */
			public String field;
			
			/**
			 * Fragment of a SQL query for a value (recommended to be "?" unless hard-coded and safe).
			 */
			public String valueExpression;
			
			/**
			 * Specifies how the field and value should be compared
			 */
			public CompareMode compareMode = CompareMode.NORMAL;
			
			public Condition()
			{
			}
			
			/**
			 * @param field Unquoted SQL field name
			 * @param value Fragment of a SQL query for a value (recommended to be "?" unless hard-coded and safe).
			 * @param compareMode Specifies how the field and value should be compared
			 */
			public Condition(String field, String value, CompareMode compareMode)
			{
				this.field = field;
				this.valueExpression = value;
				this.compareMode = compareMode;
			}
			
			public String buildPredicate(Connection conn) throws SQLException
			{
				// prevent null pointer error from switch
				if (compareMode == null)
					compareMode = CompareMode.NORMAL;
				String quotedField = quoteSymbol(conn, field);
				switch (compareMode)
				{
					case CASE_SENSITIVE:
						String compare = caseSensitiveCompare(conn, quotedField, valueExpression);
						return new StringBuilder().append('(').append(compare).append(')').toString();
					case WILDCARD:
						return new StringBuilder().append('(')
							.append(quotedField).append(" LIKE ").append(valueExpression).append(getLikeEscapeClause(conn))
							.append(')').toString();
					default:
						return new StringBuilder().append('(').append(quotedField).append('=').append(valueExpression).append(')').toString();
				}
			}
		}
	}
}

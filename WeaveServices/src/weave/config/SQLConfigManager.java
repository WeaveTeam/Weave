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

import java.io.File;
import java.io.IOException;
import java.rmi.RemoteException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Statement;
import java.util.Date;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;

import weave.config.ISQLConfig.ConnectionInfo;
import weave.utils.FileUtils;
import weave.utils.SQLUtils;
import org.xml.sax.SAXParseException;


/**
 * SQLConfigManager
 * This class contains functions common to any web service that needs to access an SQLConfig file.
 * 
 * @author Andy Dufilie
 * @author Andrew Wilkinson
 */
public final class SQLConfigManager
{
	public synchronized static SQLConfigManager getInstance(ServletContext context) throws ServletException
	{
		if (_instance == null)
			_instance = new SQLConfigManager(WeaveContextParams.getInstance(context));
		return _instance;
	}
	
	
	/**
	 * config
	 * This is the ISQLConfig object this class manages.
	 * This object may be null.
	 */
	private ISQLConfig config = null;
	private String configFileName = null;
	
	private long _lastModifiedTime = -1L;
	
	private WeaveContextParams contextParams = null;
	public WeaveContextParams getContextParams()
	{
		return contextParams;
	}
	
	private static SQLConfigManager _instance = null;
	
	/**
	 * SQLConfigManager
	 * @param configFileName The name of the configuration file to manage.
	 * @throws ServletException 
	 */
	public SQLConfigManager(WeaveContextParams contextParams)
	{
		this.contextParams = contextParams;
		
		SQLConfigXML.copyEmbeddedDTD(contextParams.getConfigPath());
		configFileName = contextParams.getConfigPath() + "/" + SQLConfigXML.XML_FILENAME;

		// if xml file doesn't exist in cfgpath but exists in working path, move file to new location
		try
		{
			File xml = new File(configFileName);
			if(!xml.isFile()) 
			{
				String workingPath = System.getProperty("user.dir").replace('\\', '/');
				File oldXML = new File(workingPath, SQLConfigXML.XML_FILENAME);
				if (oldXML.isFile())
				{
					System.out.println(String.format("Moving \"%s\" to \"%s\".", oldXML.getAbsolutePath(), xml.getAbsolutePath()));
					FileUtils.copy(oldXML, xml);
					oldXML.delete();
					
//					File oldDTD = new File(workingPath, SQLConfigXML.DTD_FILENAME);
//					if (oldDTD.isFile())
//						oldDTD.delete();
				}
			}
		}
		catch (IOException e)
		{
			//e.printStackTrace();
		}
	}
	
	/**
	 * getConfigFileName
	 * @return The name of the active configuration file.
	 */
	synchronized public String getConfigFileName()
	{
		return configFileName;
	}
	
	/**
	 * getConfig
	 * @param configFileName The name of the configuration file to load
	 * @return The ISQLConfig object for the new file
	 * @throws RemoteException
	 */
//	synchronized public ISQLConfig loadConfig(String configFileName) throws RemoteException
//	{
//		config = null;
//		this.configFileName = configFileName;
//		return getConfig();
//	}

	/**
	 * getConfig
	 * If the configuration file has not been loaded yet, it will be loaded.
	 * @return The ISQLConfig object this class manages
	 * @throws RemoteException
	 */
	synchronized public ISQLConfig getConfig() throws RemoteException
	{
		// load config file if not loaded already
		if (config == null)
		{
			if (configFileName == null)
				throw new RemoteException("Server failed to initialize because no configuration file was specified.");
			try
			{
				_lastModifiedTime = 0L; // this forces the config file to be rechecked next time if this function fails
				new File(configFileName).getAbsoluteFile().getParentFile().mkdirs();
				config = new SQLConfigXML(configFileName);
				try
				{
					config = new DatabaseConfig(config);
					System.out.println("Successfully initialized Weave database connection");
				}
				catch (Exception e)
				{
					e.printStackTrace();
					System.out.println("Using configuration stored in "+configFileName);
				}
				_lastModifiedTime = new File(configFileName).lastModified();
			}
			catch (SAXParseException e)
			{
				//e.printStackTrace();
				String msg = String.format(
						"%s parse error: Line %d, column %d: %s",
						new File(configFileName).getName(),
						e.getLineNumber(),
						e.getColumnNumber(),
						e.getMessage()
					);
				throw new RemoteException(msg);
			}
			catch (Exception e)
			{
				e.printStackTrace();
				throw new RemoteException("Server configuration error.", e);
			}
		}
		return config;
	}
	
	/**
	 * detectConfigChanges:
	 * If the configuration file modification time has changed, the new file will be loaded.
	 * If the configuration file has not been loaded yet, it will be loaded.
	 * @throws RemoteException
	 */
	synchronized public void detectConfigChanges() throws RemoteException
	{
		// copy embedded DTD if no DTD exists
		File file = new File(configFileName).getAbsoluteFile();
		 
		if (!new File(file.getParent(), SQLConfigXML.DTD_FILENAME).exists())
			SQLConfigXML.copyEmbeddedDTD(file.getParent());
		
		long lastModified = file.lastModified();
		// if config changed, unload config file
		if (!file.exists() || lastModified != _lastModifiedTime)
		{
			if (lastModified == 0L)
				System.out.println("Config file unloaded.");
			else
				System.out.println("Loading config file with modification time "+ new Date(lastModified));
			// unload old config file
			config = null;
			// load new config file
			getConfig();
		}
	}

	/**
	 * truncate
	 * @param str A string to truncate
	 * @param maxLength the maximum desired length of the result
	 * @return The string, truncated to maxLength characters
	 */
	private String truncate(String str, int maxLength)
	{
		if (str.length() <= maxLength)
			return str;
		return str.substring(0, maxLength);
	}

	/**
	 * writeToAccessLog
	 * This function logs information on a WebMethod call.
	 * @param ip The IP of the current user that made the request
	 * @param duration The length of time it took to process the request
	 * @param method The method that was called
	 * @param args The arguments to the method that was called
	 */
	synchronized public void writeToAccessLog(String ip, long duration, String method, String ... args)
	{
		Connection conn = null;
		Statement stmt = null;
		CallableStatement cstmt = null;
		try
		{
			ISQLConfig config = getConfig();
			String connectionName = config.getAccessLogConnectionName();
			ConnectionInfo connInfo = config.getConnectionInfo(connectionName);
			if (connInfo == null)
				return;

			// get connection
			conn = connInfo.getStaticReadOnlyConnection();
			// stop if can't connect
			if (conn == null)
				return;
			stmt = conn.createStatement();
			
			String schema = config.getAccessLogSchema();
			String table = config.getAccessLogTable();
			String quotedSchemaTable = SQLUtils.quoteSchemaTable(conn, schema, table);
			String query;

			// create schema if it doesn't exist
			if (!SQLUtils.schemaExists(conn, schema))
			{
				query = "CREATE SCHEMA " + schema;
				stmt.executeUpdate(query);
			}

			// create table if it doesn't exist
			if (!SQLUtils.tableExists(conn, schema, table))
			{
				query = "CREATE TABLE "+quotedSchemaTable+" ("
					+ " time TIMESTAMP, ip CHAR(39), runningTime INT, method CHAR(64),"
					+ " arg1 CHAR(64), arg2 CHAR(64), arg3 CHAR(64), arg4 CHAR(64), arg5 CHAR(64),"
					+ " arg6 CHAR(64), arg7 CHAR(64), arg8 CHAR(64), arg9 CHAR(64), arg10 CHAR(64)"
					+ ")";
				stmt.executeUpdate(query);
			}

			// insert row in log table
			cstmt = conn.prepareCall("insert into "+quotedSchemaTable+" values (now(),?,?,?, ?,?,?,?,?, ?,?,?,?,?)");
			int index = 1;
			cstmt.setString(index++, truncate(ip, 39));
			cstmt.setLong(index++, duration);
			cstmt.setString(index++, truncate(method, 64));
			for (int i = 0; i < 10; i++)
			{
				if (i < args.length)
					cstmt.setString(index++, truncate(args[i], 64));
				else
					cstmt.setString(index++, "");
			}
			cstmt.executeUpdate();
		}
		catch (Exception e)
		{
			//e.printStackTrace();
		}
		finally
		{
			SQLUtils.cleanup(stmt);
			SQLUtils.cleanup(cstmt);
//			SQLUtils.cleanup(conn);
		}
	}
}

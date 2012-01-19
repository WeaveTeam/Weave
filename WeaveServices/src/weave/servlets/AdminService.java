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

package weave.servlets;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.UUID;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.AdminServiceResponse;
import weave.beans.UploadFileFilter;
import weave.beans.UploadedFile;
import weave.config.DatabaseConfig;
import weave.config.DublinCoreUtils;
import weave.config.ISQLConfig;
import weave.config.ISQLConfig.AttributeColumnInfo;
import weave.config.ISQLConfig.AttributeColumnInfo.DataType;
import weave.config.ISQLConfig.AttributeColumnInfo.Metadata;
import weave.config.ISQLConfig.ConnectionInfo;
import weave.config.ISQLConfig.DatabaseConfigInfo;
import weave.config.ISQLConfig.GeometryCollectionInfo;
import weave.config.SQLConfigManager;
import weave.config.SQLConfigUtils;
import weave.config.SQLConfigXML;
import weave.geometrystream.GeometryStreamConverter;
import weave.geometrystream.SHPGeometryStreamUtils;
import weave.geometrystream.SQLGeometryStreamDestination;
import weave.utils.CSVParser;
import weave.utils.DBFUtils;
import weave.utils.FileUtils;
import weave.utils.ListUtils;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.XMLUtils;

public class AdminService extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	
	public AdminService()
	{
	}
	
	/**
	 * This constructor is for testing only.
	 * @param configManager
	 */
	public AdminService(SQLConfigManager configManager)
	{
		this.configManager = configManager;
	}
	
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		configManager = SQLConfigManager.getInstance(config.getServletContext());
		
		tempPath = configManager.getContextParams().getTempPath();
		uploadPath = configManager.getContextParams().getUploadPath();
		docrootPath = configManager.getContextParams().getDocrootPath();
	}
	
//	/**
//	 * ONLY FOR TESTING.
//	 * @throws ServletException
//	 */
//	public void init2() throws ServletException
//	{
//		tempPath = configManager.getContextParams().getTempPath();
//		uploadPath = configManager.getContextParams().getUploadPath();
//		docrootPath = configManager.getContextParams().getDocrootPath();
//	}
	private String tempPath;
	private String uploadPath;
	private String docrootPath;
	
	private static int StringType = 0;
	private static int IntType = 1;
	private static int DoubleType = 2;
	private SQLConfigManager configManager;

	synchronized public AdminServiceResponse checkSQLConfigExists()
	{
		try
		{
			if (databaseConfigExists())
				return new AdminServiceResponse(true, "Configuration file exists.");
		}
		catch (RemoteException se)
		{
			se.printStackTrace();
			
			File configFile = new File(configManager.getConfigFileName());
			if (configFile.exists())
				return new AdminServiceResponse(false, String.format("%s is invalid. Please edit the file and fix the problem"
						+ " or delete it and create a new one through the admin console.\n\n%s", configFile.getName(), se.getMessage()));
		}
		return new AdminServiceResponse(false, "The configuration storage location must be specified.");
	}

	synchronized private boolean databaseConfigExists() throws RemoteException
	{
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		return config.isConnectedToDatabase();
	}

	synchronized public boolean authenticate(String connectionName, String password) throws RemoteException
	{
		
		boolean result = checkPasswordAndGetConfig(connectionName, password) != null;
		
		if (!result)
			System.out.println(String.format("authenticate(\"%s\",\"%s\") == %s", connectionName, password, result));
		
		return result;
	}

	synchronized private ISQLConfig checkPasswordAndGetConfig(String connectionName, String password) throws RemoteException
	{
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		
		ConnectionInfo info = config.getConnectionInfo(connectionName);
		if (info == null || !password.equals(info.pass))
			throw new RemoteException("Incorrect username or password.");

		return config;
	}

	synchronized private void backupAndSaveConfig(ISQLConfig config) throws RemoteException
	{
		try
		{
			String fileName = configManager.getConfigFileName();
			File configFile = new File(fileName);
			File backupFile = new File(tempPath, "sqlconfig_backup.txt");
			// make a backup
			FileUtils.copy(configFile, backupFile);
			// save the new config to the file
			XMLUtils.getStringFromXML(config.getDocument(), SQLConfigXML.DTD_FILENAME, fileName);
		}
		catch (Exception e)
		{
			throw new RemoteException("Backup failed", e);
		}
	}

	/**
	 * This creates a backup of a single config entry.
	 * 
	 * @throws Exception
	 */
	synchronized private void createConfigEntryBackup(ISQLConfig config, String entryType, String entryName) throws RemoteException
	{
		// copy the config entry to a temp SQLConfigXML
		String entryXMLString = null;
		// create a block of code so tempConfig won't stay in memory
		try
		{
			SQLConfigXML tempConfig = new SQLConfigXML();
			SQLConfigUtils.migrateSQLConfigEntry(config, tempConfig, entryType, entryName);
			entryXMLString = tempConfig.getConfigEntryXML(entryType, entryName);
			
			// stop if xml entry is blank
			if (entryXMLString == null || !entryXMLString.contains("/"))
				return;
	
			// write the config entry to a temp file
			File newFile = new File(tempPath, "backup_" + entryType + "_" + entryName.replaceAll("[^a-zA-Z0-9]", "") + "_"
					+ UUID.randomUUID() + ".txt");
			BufferedWriter out = new BufferedWriter(new FileWriter(newFile));
			out.write(entryXMLString);
			out.flush();
			out.close();
		}
		catch (Exception e)
		{
			throw new RemoteException("Backup failed", e);
		}
	}

	// /////////////////////////////////////////////////
	// functions for managing Weave client XML files
	// /////////////////////////////////////////////////

	/**
	 * Return a list of Client Config files from docroot
	 * 
	 * @return A list of (xml) client config files existing in the docroot
	 *         folder.
	 */
	synchronized public String[] getWeaveFileNames(String configConnectionName, String password, Boolean showAllFiles) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(configConnectionName, password);
		ConnectionInfo info = config.getConnectionInfo(configConnectionName);
		File[] files = null;
		List<String> listOfFiles = new ArrayList<String>();
		FilenameFilter xmlFilter = new FilenameFilter()
		{
			public boolean accept(File dir, String fileName)
			{
				return (fileName.endsWith(".xml"));
			}
		};
		
		if(showAllFiles == true)
		{
			try
			{
				String root = docrootPath;			
				File rootFolder = new File(root);	
				files = rootFolder.listFiles();

				for (File f : files) 
				{
					if(!f.isDirectory())
						continue;
					File[] configs = f.listFiles(xmlFilter);
					for (File configfile : configs) 
					{
						listOfFiles.add(f.getName() + "/" + configfile.getName());
					}
				}
			} catch (SecurityException e) 
			{
				throw new RemoteException("Permission error reading directory.",e);
			}
		}
		
		String path = docrootPath;
		if(!showAllFiles && info.folderName.length() > 0)
			path = path + info.folderName + "/";
		
		File docrootFolder = new File(path);
		
		try
		{
			docrootFolder.mkdirs();
			files = docrootFolder.listFiles(xmlFilter);
			for (File file : files)
			{
				if (file.isFile())
				{
					// System.out.println(file.getName());
					listOfFiles.add(((!showAllFiles && info.folderName.length() > 0) ? info.folderName + "/" : "") + file.getName().toString());
				}
			}
		}
		catch (SecurityException e)
		{
			throw new RemoteException("Permission error reading directory.",e);
		}

		return ListUtils.toStringArray(listOfFiles);
	}

	synchronized public String saveWeaveFile(String connectionName, String password, String fileContents, String xmlFile, boolean overwriteFile) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		ConnectionInfo info = config.getConnectionInfo(connectionName);
		
		// 5.2 client web page configuration file ***.xml
		String output = "";
		try
		{
			// remove special characters
			xmlFile = xmlFile.replace("\\", "").replace("/", "");
			if (!xmlFile.toLowerCase().endsWith(".xml"))
				xmlFile += ".xml";
			
			String path = docrootPath;
			if(info.folderName.length() > 0)
				path = path + info.folderName + "/";
			
			File file = new File(path + xmlFile);
			
			if (file.exists())
			{
				if (!overwriteFile)
					return String.format("File already exists and was not changed: \"%s\"", xmlFile);
				if (!info.is_superuser && info.folderName.length() == 0)
					return String.format("User \"%s\" does not have permission to overwrite configuration files.  Please save under a new filename.", connectionName);
			}
			
			BufferedWriter out = new BufferedWriter(new FileWriter(file));

			output = fileContents;

			out.write(output);
			out.close();
		}
		catch (IOException e)
		{
			throw new RemoteException("Error occurred while saving file", e);
		}

		return "Successfully generated " + xmlFile + ".";
	}

	/**
	 * Delete a Client Config file from docroot
	 * 
	 * @return A String message indicating if file was deleted.
	 * 
	 */
	synchronized public String removeWeaveFile(String configConnectionName, String password, String fileName) throws RemoteException, IllegalArgumentException
	{
		ISQLConfig config = checkPasswordAndGetConfig(configConnectionName, password);
		ConnectionInfo info = config.getConnectionInfo(configConnectionName);
		
		if (!config.getConnectionInfo(configConnectionName).is_superuser && info.folderName.length() == 0)
			return String.format("User \"%s\" does not have permission to remove configuration files.", configConnectionName);

		String path = docrootPath;
		if(info.folderName.length() > 0)
			path = path + info.folderName + "/";
		
		File f = new File(path + fileName);
		try
		{
			// Make sure the file or directory exists and isn't write protected
			if (!f.exists())
				throw new IllegalArgumentException("Delete: no such file or directory: " + fileName);

			if (!f.canWrite())
				throw new IllegalArgumentException("File cannot be deleted Delete: write protected: " + fileName);

			// If it is a directory, make sure it is empty
			if (f.isDirectory())
				throw new IllegalArgumentException("Cannot Delete a directory");

			// Attempt to delete it
			boolean success = f.delete();

			if (!success)
				throw new IllegalArgumentException("Delete: deletion failed");

			return "Successfully deleted file " + fileName;
		}
		catch (SecurityException e)
		{
			throw new RemoteException("File could not be deleted", e);
		}
	}

	// /////////////////////////////////////////////////
	// functions for managing SQL connection entries
	// /////////////////////////////////////////////////
	
	synchronized public String[] getConnectionNames(String connectionName, String password) throws RemoteException
	{
		try
		{
			// only check password and superuser privileges if dbInfo is valid
			if (databaseConfigExists())
			{
				ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
				// non-superusers can't get connection info for other users
				if (!config.getConnectionInfo(connectionName).is_superuser)
					return new String[]{connectionName};
			}
			// otherwise, return all connection names
			List<String> connectionNames = configManager.getConfig().getConnectionNames();
			return ListUtils.toStringArray(getSortedUniqueValues(connectionNames, false));
		}
		catch (RemoteException se)
		{
			return new String[]{};
		}
	}
	
	synchronized public ConnectionInfo getConnectionInfo(String loginConnectionName, String loginPassword, String connectionNameToGet) throws RemoteException
	{
		ISQLConfig config;
		if (databaseConfigExists())
		{
			config = checkPasswordAndGetConfig(loginConnectionName, loginPassword);
			// non-superusers can't get connection info
			if (!config.getConnectionInfo(loginConnectionName).is_superuser)
				return null;
		}
		else
		{
			config = configManager.getConfig();
		}
		ConnectionInfo info = config.getConnectionInfo(connectionNameToGet);
		info.pass = ""; // don't send password
		return info;
	}

	synchronized public String saveConnectionInfo(String currentConnectionName, String currentPassword, String newConnectionName, String dbms, String ip, String port, String database, String sqlUser, String password, String folderName, boolean grantSuperuser, boolean configOverwrite) throws RemoteException
	{
		if (newConnectionName.equals(""))
			throw new RemoteException("Connection name cannot be empty.");
		
		ConnectionInfo newConnectionInfo = new ConnectionInfo();
		newConnectionInfo.name = newConnectionName;
		newConnectionInfo.dbms = dbms;
		newConnectionInfo.ip = ip;
		newConnectionInfo.port = port;
		newConnectionInfo.database = database;
		newConnectionInfo.user = sqlUser;
		newConnectionInfo.pass = password;
		newConnectionInfo.folderName = folderName;
		newConnectionInfo.is_superuser = true;
		
		// if the config file doesn't exist, create it
		String fileName = configManager.getConfigFileName();
		if (!new File(fileName).exists())
		{
			try
			{
				XMLUtils.getStringFromXML(new SQLConfigXML().getDocument(), SQLConfigXML.DTD_FILENAME, fileName);
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
		}

		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		// if there are existing connections and DatabaseConfigInfo exists, check the password. otherwise, allow anything.
		if (config.getConnectionNames().size() > 0 && config.getDatabaseConfigInfo() != null)
		{
			config = checkPasswordAndGetConfig(currentConnectionName, currentPassword);
			
			// non-superusers can't save connection info
			if (!config.getConnectionInfo(currentConnectionName).is_superuser)
				throw new RemoteException(String.format("User \"%s\" does not have permission to modify connections.", currentConnectionName));
			// is_superuser for the new connection will only be false if there is an existing superuser connection and grantSuperuser is false.
			newConnectionInfo.is_superuser = grantSuperuser;
		}
		
		// test connection only - to validate parameters
		Connection conn = null;
		try
		{
			conn = newConnectionInfo.getConnection();
			SQLUtils.testConnection(conn);
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("The connection named \"%s\" was not created because the server could not"
					+ " connect to the specified database with the given parameters.", newConnectionInfo.name), e);
		}
		finally
		{
			// close the connection, as we will not use it later
			SQLUtils.cleanup(conn);
		}

		// if the connection already exists AND overwrite == false throw error
		if (!configOverwrite && ListUtils.findString(newConnectionInfo.name, config.getConnectionNames()) >= 0)
		{
			throw new RemoteException(String.format("The connection named \"%s\" already exists.  Action cancelled.", newConnectionInfo.name));
		}

		// generate config connection entry
		try
		{
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_CONNECTION, newConnectionInfo.name);

			// do not delete if this is the last user (which must be a superuser)
			List<String> connectionNames = config.getConnectionNames();
			
			// check for number of superusers
			int numSuperUsers = 0;
			for (String name : connectionNames)
			{
				if (config.getConnectionInfo(name).is_superuser)
					++numSuperUsers;
				if (numSuperUsers >= 2)
					break;
			}
			// sanity check
			if (currentConnectionName == newConnectionName && numSuperUsers == 1 && !newConnectionInfo.is_superuser)
				throw new RemoteException("Cannot remove superuser privileges from last remaining superuser.");
			
			config.removeConnection(newConnectionInfo.name);
			config.addConnection(newConnectionInfo);

			backupAndSaveConfig(config);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(
					String.format("Unable to create connection entry named \"%s\": %s", newConnectionInfo.name, e.getMessage()),e
				);
		}

		return String.format("The connection named \"%s\" was created successfully.", newConnectionName);
	}

	synchronized public String removeConnectionInfo(String loginConnectionName, String loginPassword, String connectionNameToRemove) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(loginConnectionName, loginPassword);
		
		// allow only a superuser to remove a connection
		ConnectionInfo loginConnectionInfo = config.getConnectionInfo(loginConnectionName);
		if (!loginConnectionInfo.is_superuser)
			throw new RemoteException("Only superusers can remove connections.");
		
		try
		{
			if (ListUtils.findString(connectionNameToRemove, config.getConnectionNames()) < 0)
				throw new RemoteException("Connection \"" + connectionNameToRemove + "\" does not exist.");
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_CONNECTION, connectionNameToRemove);
			
			// check for number of superusers
			List<String> connectionNames = config.getConnectionNames();
			int numSuperUsers = 0;
			for (String name : connectionNames)
				if (config.getConnectionInfo(name).is_superuser)
					++numSuperUsers;
			// do not allow removal of last superuser
			if (numSuperUsers == 1 && loginConnectionName.equals(connectionNameToRemove))
				throw new RemoteException("Cannot remove the only superuser.");
			
			config.removeConnection(connectionNameToRemove);
			backupAndSaveConfig(config);
			return "Connection \"" + connectionNameToRemove + "\" was deleted.";
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
	}

	synchronized public DatabaseConfigInfo getDatabaseConfigInfo(String connectionName, String password) throws RemoteException
	{
		try
		{
			if (databaseConfigExists())
				return checkPasswordAndGetConfig(connectionName, password).getDatabaseConfigInfo();
		}
		catch (RemoteException e)
		{
			if (e.detail instanceof FileNotFoundException)
				return null;
			throw e;
		}
		return null;
	}

	synchronized public String migrateConfigToDatabase(String connectionName, String password, String schema, String geometryConfigTable, String dataConfigTable) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password); 

		if (!config.getConnectionInfo(connectionName).is_superuser)
			throw new RemoteException("Unable to migrate config to database without superuser privileges.");
		
		String configFileName = configManager.getConfigFileName();
		int count = 0;
		try
		{
			// load xmlConfig in memory
			SQLConfigXML xmlConfig = new SQLConfigXML(configFileName);
			DatabaseConfigInfo info = new DatabaseConfigInfo();
			info.schema = schema;
			info.connection = connectionName;
			info.dataConfigTable = dataConfigTable;
			info.geometryConfigTable = geometryConfigTable;
			// save db config info to in-memory xmlConfig
			xmlConfig.setDatabaseConfigInfo(info);
			// migrate from in-memory xmlConfig to the db
			count = SQLConfigUtils.migrateSQLConfig(xmlConfig, new DatabaseConfig(xmlConfig));
			// save in-memory xmlConfig to disk
			backupAndSaveConfig(xmlConfig);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			if (count > 0)
				throw new RemoteException("Migrated " + count + " items then failed", e);
			throw new RemoteException("Migration failed", e);
		}

		String result = String.format("The admin console will now use the \"%s\" connection to store configuration information.", connectionName);
		if (count > 0)
			result = String.format("%s items were copied from %s into the database.  %s", count, new File(configFileName).getName(), result);
		return result;
	}

	// /////////////////////////////////////////////////
	// functions for managing DataTable entries
	// /////////////////////////////////////////////////

	synchronized public String[] getDataTableNames(String connectionName, String password) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		ConnectionInfo cInfo = config.getConnectionInfo(connectionName);
		String dataConnection;
		if (cInfo.is_superuser)
			dataConnection = null; // let it get all of the data tables
		else
			dataConnection = connectionName; // get only the ones on this connection
		return ListUtils.toStringArray(config.getDataTableNames(dataConnection));		
	}

	/**
	 * Returns metadata about columns of the given data table.
	 */
	synchronized public AttributeColumnInfo[] getDataTableInfo(String connectionName, String password, String dataTableName) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		List<AttributeColumnInfo> info = config.getAttributeColumnInfo(dataTableName);

		return info.toArray(new AttributeColumnInfo[info.size()]);
	}
	
	/**
	 * Returns the results of testing attribute column sql queries.
	 */
	synchronized public AttributeColumnInfo[] testAllQueries(String connectionName, String password, String dataTableName) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		HashMap<String, String> params = new HashMap<String, String>();
		params.put(Metadata.DATATABLE.toString(), dataTableName);
		List<AttributeColumnInfo> infolist = config.getAttributeColumnInfo(params);
		for (int i = 0; i < infolist.size(); i ++)
		{
			AttributeColumnInfo attributeColumnInfo = infolist.get(i);
			try
			{
				String query = attributeColumnInfo.sqlQuery;
				System.out.println(query);
				SQLResult result = SQLConfigUtils.getRowSetFromQuery(config, attributeColumnInfo.connection, query);
				attributeColumnInfo.metadata.put(AttributeColumnInfo.SQLRESULT, String.format("Returned %s rows", result.rows.length));
			}
			catch (Exception e)
			{
				e.printStackTrace();
				attributeColumnInfo.metadata.put(AttributeColumnInfo.SQLRESULT, e.getMessage());
			}
		}
		
		return infolist.toArray(new AttributeColumnInfo[0]);
	}

	@SuppressWarnings("unchecked")
	synchronized public String saveDataTableInfo(String connectionName, String password, Object[] columnMetadata) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		
		// first validate the information
		String dataTableName = null;
		for (Object object : columnMetadata)
		{
			Map<String, Object> metadata = (Map<String, Object>) object;
			String _dataTableName = (String) metadata.get(Metadata.DATATABLE.toString());
			if (dataTableName == null)
				dataTableName = _dataTableName;
			else if (dataTableName != _dataTableName)
				throw new RemoteException("overwriteDataTableEntry(): dataTable property not consistent among column entries.");
			
//			String _dataTableConnection = (String) metadata.get(Metadata.CONNECTION.toString());
//			if (dataTableConnection == null)
//				dataTableConnection = _dataTableConnection;
//			else if (dataTableConnection != _dataTableConnection)
//				throw new RemoteException("overwriteDataTableEntry(): " + Metadata.CONNECTION.toString() + " property not consistent among column entries.");
		}
		if (!SQLConfigUtils.userCanModifyDataTable(config, connectionName, dataTableName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to modify DataTable \"%s\".", connectionName, dataTableName));
		
		try
		{
			// start a block of code so tempConfig will not stay in memory
			{
				// make a new SQLConfig object and add the entry
				SQLConfigXML tempConfig = new SQLConfigXML();
				// add all the columns to the new blank config
				for (int i = 0; i < columnMetadata.length; i++)
				{
					// create metadata map that AttributeColumnInfo wants
					Map<String, String> metadata = new HashMap<String, String>();
					for (Entry<String, Object> entry : ((Map<String, Object>) columnMetadata[i]).entrySet())
					{
						//System.out.println(entry.getKey() + ':' + (String) entry.getValue());
						metadata.put(entry.getKey(), (String) entry.getValue());
					}
					// Exclude connection & sqlQuery properties from metadata
					// object
					// because they are separate parameters to the constructor.
					AttributeColumnInfo columnInfo = new AttributeColumnInfo(metadata.remove(AttributeColumnInfo.CONNECTION),
							metadata.remove(AttributeColumnInfo.SQLQUERY), metadata);
					// add the column info to the temp blank config
					tempConfig.addAttributeColumn(columnInfo);
				}
				// backup any existing dataTable entry, then copy over the new
				// entry
				createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_DATATABLE, dataTableName);
				SQLConfigUtils.migrateSQLConfigEntry(tempConfig, config, ISQLConfig.ENTRYTYPE_DATATABLE, dataTableName);
			}
			backupAndSaveConfig(config);

			return String.format("The dataTable entry \"%s\" was saved.", dataTableName);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
	}

	synchronized public void removeAttributeColumnInfo(String connectionName, String password, Object[] columnMetadata) throws RemoteException
	{
		
	}

	synchronized public String removeDataTableInfo(String connectionName, String password, String dataTableName) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		if (!SQLConfigUtils.userCanModifyDataTable(config, connectionName, dataTableName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to remove DataTable \"%s\".", connectionName, dataTableName));
		try
		{
			if (ListUtils.findString(dataTableName, config.getDataTableNames(null)) < 0)
				throw new RemoteException("DataTable \"" + dataTableName + "\" does not exist.");
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_DATATABLE, dataTableName);
			config.removeDataTable(dataTableName);
			backupAndSaveConfig(config);
			return "DataTable \"" + dataTableName + "\" was deleted.";
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
	}

	// /////////////////////////////////////////////////////
	// functions for managing GeometryCollection entries
	// /////////////////////////////////////////////////////

	synchronized public String[] getGeometryCollectionNames(String connectionName, String password) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		ConnectionInfo cInfo = config.getConnectionInfo(connectionName);
		String geometryConnection;
		if (cInfo.is_superuser)
			geometryConnection = null; // let it get all of the geometries
		else
			geometryConnection = connectionName; // get only the ones on this connection
		return ListUtils.toStringArray(config.getGeometryCollectionNames(geometryConnection));
	}

	/**
	 * Returns metadata about the given geometry collection.
	 */
	synchronized public GeometryCollectionInfo getGeometryCollectionInfo(String connectionName, String password, String geometryCollectionName) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		return config.getGeometryCollectionInfo(geometryCollectionName);
	}

	synchronized public String saveGeometryCollectionInfo(String connectionName, String password, String geomName, String geomConnection, String geomSchema, String geomTablePrefix, String geomKeyType, String geomImportNotes, String geomProjection) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		if (!SQLConfigUtils.userCanModifyGeometryCollection(config, connectionName, geomName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to modify GeometryCollection \"%s\".", connectionName, geomName));
		
		// if this user isn't a superuser, don't allow an overwrite of an existing geometrycollection
		ConnectionInfo currentConnectionInfo = config.getConnectionInfo(connectionName);
		if (!currentConnectionInfo.is_superuser)
		{
			GeometryCollectionInfo oldGeometry = config.getGeometryCollectionInfo(geomName);
			
			if (oldGeometry != null && !oldGeometry.connection.equals(connectionName))
				throw new RemoteException("An existing geometry collection with the same name exists on another connection. Unable to overwrite without superuser privileges.");
		}

		try
		{
			// start a block of code so tempConfig will not stay in memory
			{
				// make a new SQLConfig object and add the entry
				SQLConfigXML tempConfig = new SQLConfigXML();
				// add all the columns to the new blank config
				GeometryCollectionInfo info = new GeometryCollectionInfo();
				info.name = geomName;
				info.connection = geomConnection;
				info.schema = geomSchema;
				info.tablePrefix = geomTablePrefix;
				info.keyType = geomKeyType;
				info.importNotes = geomImportNotes;
				info.projection = geomProjection;
				// add the info to the temp blank config
				tempConfig.addGeometryCollection(info);
				// backup any existing dataTable entry, then copy over the new
				// entry
				createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_GEOMETRYCOLLECTION, geomName);
				SQLConfigUtils.migrateSQLConfigEntry(tempConfig, config, ISQLConfig.ENTRYTYPE_GEOMETRYCOLLECTION, geomName);
			}
			backupAndSaveConfig(config);

			return String.format("The geometryCollection entry \"%s\" was saved.", geomName);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
	}

	synchronized public String removeGeometryCollectionInfo(String connectionName, String password, String geometryCollectionName) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		if (!SQLConfigUtils.userCanModifyGeometryCollection(config, connectionName, geometryCollectionName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to remove GeometryCollection \"%s\".", connectionName, geometryCollectionName));
		try
		{
			if (ListUtils.findString(geometryCollectionName, config.getGeometryCollectionNames(null)) < 0)
				throw new RemoteException("Geometry Collection \"" + geometryCollectionName + "\" does not exist.");
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_GEOMETRYCOLLECTION, geometryCollectionName);
			config.removeGeometryCollection(geometryCollectionName);
			backupAndSaveConfig(config);
			return "Geometry Collection \"" + geometryCollectionName + "\" was deleted.";
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
	}

	// ///////////////////////////////////////////
	// functions for getting SQL info
	// ///////////////////////////////////////////

	/**
	 * The following functions get information about the database associated
	 * with a given connection name.
	 */
	synchronized public String[] getSchemas(String configConnectionName, String password) throws RemoteException
	{
		checkPasswordAndGetConfig(configConnectionName, password);
		List<String> schemasList = getSchemasList(configConnectionName);
		return ListUtils.toStringArray(getSortedUniqueValues(schemasList, false));
	}

	synchronized public String[] getTables(String configConnectionName, String password, String schemaName) throws RemoteException
	{
		checkPasswordAndGetConfig(configConnectionName, password);
		List<String> tablesList = getTablesList(configConnectionName, schemaName);
		
		return ListUtils.toStringArray(getSortedUniqueValues(tablesList, false));
	}

	synchronized public String[] getColumns(String configConnectionName, String password, String schemaName, String tableName) throws RemoteException
	{
		checkPasswordAndGetConfig(configConnectionName, password);
		return ListUtils.toStringArray(getColumnsList(configConnectionName, schemaName, tableName));
	}

	synchronized private List<String> getSchemasList(String connectionName) throws RemoteException
	{
		ISQLConfig config = configManager.getConfig();
		List<String> schemas;
		try
		{
			Connection conn = SQLConfigUtils.getStaticReadOnlyConnection(config, connectionName);
			schemas = SQLUtils.getSchemas(conn);
		}
		catch (SQLException e)
		{
			// e.printStackTrace();
			throw new RemoteException("Unable to get schema list from database.", e);
		}
		finally
		{
			// SQLUtils.cleanup(conn);
		}
		// don't want to list information_schema.
		ListUtils.removeIgnoreCase("information_schema", schemas);
		return schemas;
	}

	synchronized private List<String> getTablesList(String connectionName, String schemaName) throws RemoteException
	{
		ISQLConfig config = configManager.getConfig();
		List<String> tables;
		try
		{
			Connection conn = SQLConfigUtils.getStaticReadOnlyConnection(config, connectionName);
			tables = SQLUtils.getTables(conn, schemaName);
		}
		catch (SQLException e)
		{
			// e.printStackTrace();
			throw new RemoteException("Unable to get schema list from database.", e);
		}
		finally
		{
			// SQLUtils.cleanup(conn);
		}
		return tables;
	}

	synchronized private List<String> getColumnsList(String connectionName, String schemaName, String tableName) throws RemoteException
	{
		ISQLConfig config = configManager.getConfig();
		List<String> columns;
		try
		{
			Connection conn = SQLConfigUtils.getStaticReadOnlyConnection(config, connectionName);
			columns = SQLUtils.getColumns(conn, schemaName, tableName);
		}
		catch (SQLException e)
		{
			// e.printStackTrace();
			throw new RemoteException("Unable to get column list from database.", e);
		}
		finally
		{
			// SQLUtils.cleanup(conn);
		}
		return columns;
	}

	// ///////////////////////////////////////////
	// functions for getting miscellaneous info
	// ///////////////////////////////////////////

	synchronized public String[] getKeyTypes(String connectionName, String password) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		return ListUtils.toStringArray(getSortedUniqueValues(config.getKeyTypes(), true));
	}

	synchronized public UploadedFile[] getUploadedCSVFiles() throws RemoteException
	{
		File directory = new File(uploadPath);
		List<UploadedFile> list = new ArrayList<UploadedFile>();
		File[] listOfFiles = null;
		
		try {
			if( directory.isDirectory() ) {
				listOfFiles = directory.listFiles(new UploadFileFilter("csv"));
				for( File file : listOfFiles ) {
					if( file.isFile() ) {
						UploadedFile uploadedFile = 
							new UploadedFile(
								file.getName(),
								file.length(),
								file.lastModified()
							);
						list.add(uploadedFile);
					}
				}
			}
		} catch(Exception e) {
			throw new RemoteException(e.getMessage());
		}
		
		int n = list.size();
		return list.toArray(new UploadedFile[n]);
	}
	
	synchronized public UploadedFile[] getUploadedShapeFiles() throws RemoteException
	{
		File directory = new File(uploadPath);
		List<UploadedFile> list = new ArrayList<UploadedFile>();
		File[] listOfFiles = null;
		
		try {
			if( directory.isDirectory() ) {
				listOfFiles = directory.listFiles(new UploadFileFilter("shp"));
				for( File file : listOfFiles ) {
					if( file.isFile() ) {
						UploadedFile uploadedFile = 
							new UploadedFile(
								file.getName(),
								file.length(),
								file.lastModified()
							);
						list.add(uploadedFile);
					}
				}
			}
		} catch(Exception e) {
			throw new RemoteException(e.getMessage());
		}
		
		int n = list.size();
		return list.toArray(new UploadedFile[n]);
	}
	/**
	 * Read a list of csv files and return common header columns.
	 * 
	 * @param A
	 *            list of csv file names.
	 * @return A list of common header files or null if none exist encoded using
	 * 
	 */
	synchronized public String[] getCSVColumnNames(String csvFile) throws RemoteException
	{
		String[] headerLine = null;

		try
		{
			String csvData = org.apache.commons.io.FileUtils.readFileToString(new File(uploadPath, csvFile));
			// Read first line only (header line).
			int index = csvData.indexOf("\r");
			int index2 = csvData.indexOf("\n");
			if (index2 < index && index2 >= 0)
				index = index2;
			String header = index < 0 ? csvData : csvData.substring(0, index);
			csvData = null; // don't need this in memory anymore
			String[][] rows = CSVParser.defaultParser.parseCSV(header);
			headerLine = rows[0];
		}
		catch (FileNotFoundException e)
		{
			throw new RemoteException(e.getMessage());
		}
		catch (Exception e)
		{
			throw new RemoteException(e.getMessage());
		}

		return headerLine;
	}

	synchronized public String[] listDBFFileColumns(String dbfFileName) throws RemoteException
	{
		try
		{
			List<String> names = DBFUtils.getAttributeNames(new File(uploadPath, correctFileNameCase(dbfFileName)));
			return ListUtils.toStringArray(names);
		}
		catch (IOException e)
		{
			throw new RemoteException("IOException", e);
		}
	}

	synchronized private String correctFileNameCase(String fileName) {
		
		try 
		{
			File directory = new File(uploadPath);

			if( directory.isDirectory() )
			{
				for( String file : directory.list() )
				{
					if( file.equalsIgnoreCase(fileName) )
						return file;
				}
			}
		} catch( Exception e ) {}
		return fileName;
	}

	/**
	 * getSortedUniqueValues
	 * 
	 * @param values
	 *            A list of string values which may contain duplicates.
	 * @param moveEmptyStringToEnd
	 *            If set to true and "" is at the front of the list, "" is moved
	 *            to the end.
	 * @return A sorted list of unique values found in the given list.
	 */
	private List<String> getSortedUniqueValues(List<String> values, boolean moveEmptyStringToEnd)
	{
		Set<String> uniqueValues = new HashSet<String>();
		uniqueValues.addAll(values);
		Vector<String> result = new Vector<String>(uniqueValues);
		Collections.sort(result, String.CASE_INSENSITIVE_ORDER);
		// if empty string is at beginning of sorted list, move it to the end of
		// the list
		if (moveEmptyStringToEnd && result.size() > 0 && result.get(0).equals(""))
			result.add(result.remove(0));
		return result;
	}

	// ///////////////////////////////////////////
	// functions for importing data
	// ///////////////////////////////////////////
	
	/**
	 * This function accepts an uploaded file.
	 * @param fileName The name of the file.
	 * @param content The file content.
	 */
	public void uploadFile(String fileName, InputStream content) throws RemoteException
	{
		// make sure the upload folder exists
		(new File(uploadPath)).mkdirs();

		String filePath = uploadPath + fileName;
		try
		{
			FileUtils.copy(content, new FileOutputStream(filePath));
		}
		catch (Exception e)
		{
			throw new RemoteException("File upload failed.", e);
		}
	}

	/**
	 * Return a list of files existing in the csv upload folder on the server.
	 * 
	 * @return A list of files existing in the csv upload folder.
	 */
	synchronized public List<String> getUploadedFileNames() throws RemoteException
	{
		File uploadFolder = new File(uploadPath);
		File[] files = null;
		List<String> listOfFiles = new ArrayList<String>();

		try
		{
			files = uploadFolder.listFiles();
			for (File file : files)
			{
				if (file.isFile())
				{
					// System.out.println(file.getName());
					listOfFiles.add(file.getName().toString());
				}
			}
		}
		catch (SecurityException e)
		{
			throw new RemoteException("Permission error reading directory.");
		}

		return listOfFiles;
	}

	private boolean valueIsInt(String value)
	{
		boolean retVal = true;
		try {
			Integer.parseInt(value);
		}
		catch (Exception e) {
			retVal = false;
		}
		return retVal;
	}
	private boolean valueIsDouble(String value)
	{
		boolean retVal = true;
		try {
			Double.parseDouble(value);
		}
		catch (Exception e) {
			retVal = false;
		}
		return retVal;
	}	
	private boolean valueHasLeadingZero(String value)
	{
		boolean temp = valueIsInt(value);
		if (!temp)
			return false;
			
		if (value.length() < 2)
			return false;
		
		if (value.charAt(0) == '0' && value.charAt(1) != '.')
			return true;
		
		return false;
	}
	
	synchronized public String importCSV(String connectionName, String password, String csvFile, String csvKeyColumn, String csvSecondaryKeyColumn, String sqlSchema, String sqlTable, boolean sqlOverwrite, String configDataTableName, boolean configOverwrite, String configGeometryCollectionName, String configKeyType, String[] nullValues, String[] filterColumnNames) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		ConnectionInfo connInfo = config.getConnectionInfo(connectionName);
		if (sqlOverwrite && !connInfo.is_superuser)
			throw new RemoteException(String.format("User \"%s\" does not have permission to overwrite SQL tables.", connectionName));
		if (!SQLConfigUtils.userCanModifyDataTable(config, connectionName, configDataTableName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to overwrite DataTable \"%s\".", connectionName, configDataTableName));

		Connection conn = null;
		Statement stmt = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, connectionName);

			sqlTable = sqlTable.toLowerCase(); // fix for MySQL running under Linux
	
			String[] columnNames = null;
			String[] originalColumnNames = null;
			int fieldLengths[] = null;
			
			// Load the CSV file and reformat it
			String formatted_CSV_path = tempPath + "temp.csv";
			int[] types = null;
			int i = 0;
			int j = 0;
			int num = 1;
			String outputNullValue = SQLUtils.getCSVNullValue(conn);
			boolean ignoreKeyColumnQueries = false;
			
			String csvData = org.apache.commons.io.FileUtils.readFileToString(new File(uploadPath, csvFile));
			String[][] rows = CSVParser.defaultParser.parseCSV(csvData);

			if (rows.length == 0)
				throw new RemoteException("CSV file is empty: " + csvFile);

			// if there is no key column, we need to append a unique Row ID column
			if ("".equals(csvKeyColumn))
			{
				ignoreKeyColumnQueries = true;	
				// get the maximum number of rows in a column
				int maxNumRows = 0;
				for (i = 0; i < rows.length; ++i) 
				{
					String[] column = rows[i];
					int numRows = column.length; // this includes the column name in row 0
					if (numRows > maxNumRows)
						maxNumRows = numRows;
				}

				
				csvKeyColumn = "row_id";
				for (i = 0; i < rows.length; ++i)
				{
					String[] row = rows[i];
					String[] newRow = new String[row.length + 1];
					
					System.arraycopy(row, 0, newRow, 0, row.length);
					if (i == 0)
						newRow[newRow.length - 1] = csvKeyColumn;
					else
						newRow[newRow.length - 1] = "row" + i;
					rows[i] = newRow;
				}
			}
			
			// Read the column names
			
			columnNames = rows[0];
			originalColumnNames = new String[columnNames.length];
			fieldLengths = new int[columnNames.length];
			// converge the column name to meet the requirement of mySQL.
			for (i = 0; i < columnNames.length; i++)
			{
				String colName = columnNames[i];
				if (colName.length() == 0)
					colName = "Column " + (i+1);
				// save original column name
				originalColumnNames[i] = colName;
				// if the column name has "/", "\", ".", "<", ">".
				colName = colName.replace("/", "");
				colName = colName.replace("\\", "");
				colName = colName.replace(".", "");
				colName = colName.replace("<", "less than");
				colName = colName.replace(">", "more than");
				// if the length of the column name is longer than the 64-character limit
				int maxColNameLength = 64;
				int halfMaxColNameLength = 30;
				boolean isKeyCol = csvKeyColumn.equalsIgnoreCase(colName);
				if (colName.length() >= maxColNameLength)
				{
					colName = colName.replace(" ", "");
					if (colName.length() >= maxColNameLength)
					{
						colName = colName.substring(0, halfMaxColNameLength) + "_" + colName.substring(colName.length() - halfMaxColNameLength);
					}
				}
				// copy new name if key column changed
				if (isKeyCol)
					csvKeyColumn = colName;
				// if find the column names are repetitive
				for (j = 0; j < i; j++)
				{
					if (colName.equalsIgnoreCase(columnNames[j]))
					{
						colName += "_" + num;
						num++;
					}
				}
				// save the new name
				columnNames[i] = colName;
			}

			// Initialize the types of columns as int (will be changed inside loop if necessary)
			types = new int[columnNames.length];
			for (i = 0; i < columnNames.length; i++)
			{
				fieldLengths[i] = 0;
				types[i] = IntType;
			}

			// Read the data and get the column type
			for (int iRow = 1; iRow < rows.length; iRow++)
			{
				String[] nextLine = rows[iRow];
				// Format each line
				for (i = 0; i < columnNames.length && i < nextLine.length; i++)
				{
					// keep track of the longest String value found in this column
					fieldLengths[i] = Math.max(fieldLengths[i], nextLine[i].length());
					
					// Change missing data into NULL, later add more cases to deal with missing data.
					String[] nullValuesStandard = new String[]{"", ".", "..", " ", "-", "\"NULL\"", "NULL", "NaN"};
					for(String[] values : new String[][] {nullValuesStandard, nullValues })
					{			
						for (String nullValue : values)
						{
							if (nextLine[i].equalsIgnoreCase(nullValue))
							{
								nextLine[i] = outputNullValue;
								break;
							}
						}
					}
					if (nextLine[i].equals(outputNullValue))
						continue;

					// 3.3.2 is a string, update the type.
					// 04 is a string (but Integer.parseInt would not throw an exception)
					try
					{
						String value = nextLine[i];
						while (value.indexOf(',') > 0)
							value = value.replace(",", ""); // valid input format
						
						// if the value is an int or double with an extraneous leading zero, it's defined to be a string
						if (valueHasLeadingZero(value))
							types[i] = StringType;
						
						// if the type was determined to be a string before (or just above), continue
						if (types[i] == StringType)
							continue;
						
						// if the type is an int
						if (types[i] == IntType)
						{
							// check that it's still an int
							if (valueIsInt(value))
								continue;
						}
						
						// it either wasn't an int or is no longer an int, check for a double
						if (valueIsDouble(value))
						{
							types[i] = DoubleType;
							continue;
						}
						
						// if we're down here, it must be a string
						types[i] = StringType;
					}
					catch (Exception e)
					{
						// this shouldn't happen, but it's just to be safe
						types[i] = StringType;
					}
				}
			}
			
			// now we need to remove commas from any numeric values because the SQL drivers don't like it
			for (int iRow = 1; iRow < rows.length; iRow++)
			{
				String[] nextLine = rows[iRow];
				// Format each line
				for (i = 0; i < columnNames.length && i < nextLine.length; i++)
				{
					String value = nextLine[i];
					if (types[i] == IntType || types[i] == DoubleType)
					{
						while (value.indexOf(",") >= 0)
							value = value.replace(",", "");
						nextLine[i] = value;
					}
				}
			}
			// save modified CSV
			BufferedWriter out = new BufferedWriter(new FileWriter(formatted_CSV_path));
			boolean quoteEmptyStrings = outputNullValue.length() > 0;
			String temp = CSVParser.defaultParser.createCSVFromArrays(rows, quoteEmptyStrings);
			out.write(temp);
			out.close();

			// Import the CSV file into SQL.
			// Drop the table if it exists.
			if (sqlOverwrite)
			{
				SQLUtils.dropTableIfExists(conn, sqlSchema, sqlTable);
			}
			else
			{
				if (ListUtils.findIgnoreCase(sqlTable, getTablesList(connectionName, sqlSchema)) >= 0)
					throw new RemoteException("CSV not imported.\nSQL table already exists.");
			}

			if (!configOverwrite)
			{
				if (ListUtils.findIgnoreCase(configDataTableName, config.getDataTableNames(null)) >= 0)
					throw new RemoteException(String.format(
							"CSV not imported.\nDataTable \"%s\" already exists in the configuration.",
							configDataTableName));
			}

			// create a list of the column types
			List<String> columnTypesList = new Vector<String>();
			for (i = 0; i < columnNames.length; i++)
			{
				if (types[i] == StringType || csvKeyColumn.equalsIgnoreCase(columnNames[i]))
					columnTypesList.add(SQLUtils.getVarcharTypeString(conn, fieldLengths[i]));
				else if (types[i] == IntType)
					columnTypesList.add(SQLUtils.getIntTypeString(conn));
				else if (types[i] == DoubleType)
					columnTypesList.add(SQLUtils.getDoubleTypeString(conn));
			}
			// create the table
			SQLUtils.createTable(conn, sqlSchema, sqlTable, Arrays.asList(columnNames), columnTypesList);

			// import the data
			SQLUtils.copyCsvToDatabase(conn, formatted_CSV_path, sqlSchema, sqlTable);
			
			return addConfigDataTable(config, configOverwrite, configDataTableName, connectionName,
					configGeometryCollectionName, configKeyType, csvKeyColumn, csvSecondaryKeyColumn, originalColumnNames,
					columnNames, sqlSchema, sqlTable, ignoreKeyColumnQueries, filterColumnNames);
		}
		catch (RemoteException e) // required since RemoteException extends IOException
		{
			throw e;
		}
		catch (SQLException e)
		{
			throw new RemoteException("Import failed.", e);
		}
		catch (FileNotFoundException e)
		{
			e.printStackTrace();
			throw new RemoteException("File not found: " + csvFile);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			throw new RemoteException("Cannot read file: " + csvFile);
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(stmt);
			SQLUtils.cleanup(conn);
		}
	}

	synchronized public String addConfigDataTableFromDatabase(String connectionName, String password, String schemaName, String tableName, String keyColumnName, String secondaryKeyColumnName, String configDataTableName, boolean configOverwrite, String geometryCollectionName, String keyType, String[] filterColumnNames) throws RemoteException
	{
		// use lower case sql table names (fix for mysql linux problems)
		//tableName = tableName.toLowerCase();

		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		String[] columnNames = getColumnsList(connectionName, schemaName, tableName).toArray(new String[0]);
		return addConfigDataTable(config, configOverwrite, configDataTableName, connectionName, geometryCollectionName,
				keyType, keyColumnName, secondaryKeyColumnName, columnNames, columnNames, schemaName, tableName, false, filterColumnNames);
	}

	synchronized private String addConfigDataTable(ISQLConfig config, boolean configOverwrite, String configDataTableName, String connectionName, String geometryCollectionName, String keyType, String keyColumnName, String secondarySqlKeyColumn, String[] configColumnNames, String[] sqlColumnNames, String sqlSchema, String sqlTable, boolean ignoreKeyColumnQueries, String[] filterColumnNames) throws RemoteException
	{
		ConnectionInfo info = config.getConnectionInfo(connectionName);
		if (info == null)
			throw new RemoteException(String.format("Connection named \"%s\" does not exist.", connectionName));
		String dbms = info.dbms;
		if (sqlColumnNames == null)
			sqlColumnNames = new String[0];

		// if key column is actually the name of a column, put quotes around it.
		// otherwise, don't.
		int iKey = ListUtils.findIgnoreCase(keyColumnName, sqlColumnNames); 
		int iSecondaryKey = ListUtils.findIgnoreCase(secondarySqlKeyColumn, sqlColumnNames);

		String sqlKeyColumn; // save the original column name
		if (iKey >= 0)
		{
			sqlKeyColumn = keyColumnName; // before quoting, save the column name
			keyColumnName = SQLUtils.quoteSymbol(dbms, sqlColumnNames[iKey]);
		}
		else
		{
			sqlKeyColumn = SQLUtils.unquoteSymbol(dbms, keyColumnName); // get the original columnname 
		}
		
		if (iSecondaryKey >= 0)
			secondarySqlKeyColumn = SQLUtils.quoteSymbol(dbms, sqlColumnNames[iSecondaryKey]);
		// Write SQL statements into sqlconfig.

		if (!configOverwrite)
		{
			if (ListUtils.findIgnoreCase(configDataTableName, config.getDataTableNames(null)) >= 0)
				throw new RemoteException(String.format("DataTable \"%s\" already exists in the configuration.", configDataTableName));
		}
		else
		{
			if (!SQLConfigUtils.userCanModifyDataTable(config, connectionName, configDataTableName))
				throw new RemoteException(String.format("User \"%s\" does not have permission to overwrite DataTable \"%s\".", connectionName, configDataTableName));
		}

		// connect to database, generate and test each query before modifying config file
		List<String> titles = new LinkedList<String>();
		List<String> queries = new Vector<String>();
		List<String> dataTypes = new Vector<String>();
		String query = null;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, connectionName);
			SQLResult filteredValues = null;
			if (filterColumnNames != null && filterColumnNames.length > 0)
			{
				// get a list of unique combinations of filter values
				String columnList = "";
				for (int i = 0; i < filterColumnNames.length; i++)
				{
					if (i > 0)
						columnList += ",";
					columnList += SQLUtils.quoteSymbol(conn, filterColumnNames[i]);
				}
				query = String.format(
					"select distinct %s from %s order by %s",
					columnList,
					SQLUtils.quoteSchemaTable(conn, sqlSchema, sqlTable),
					columnList
				);
				filteredValues = SQLUtils.getRowSetFromQuery(conn, query);
//				System.out.println(query);
//				System.out.println(filteredValues);
			}
			for (int iCol = 0; iCol < sqlColumnNames.length; iCol++)
			{
				String sqlColumn = sqlColumnNames[iCol];
//				System.out.println("columnName: " + columnName + "\tkeyColumnName: " + keyColumnName + "\toriginalKeyCol: " + originalKeyColumName);
				if (ignoreKeyColumnQueries && sqlKeyColumn.equals(sqlColumn))
					continue;
				sqlColumn = SQLUtils.quoteSymbol(dbms, sqlColumn);
				
				// hack
				if (secondarySqlKeyColumn != null && secondarySqlKeyColumn.length() > 0)
					sqlColumn += "," + secondarySqlKeyColumn;
				
				// generate column query
				query = String.format("SELECT %s,%s FROM %s", keyColumnName, sqlColumn, SQLUtils.quoteSchemaTable(dbms, sqlSchema, sqlTable));

				if (filteredValues != null)
				{
					// generate one query per unique filter value combination
					for (int iRow = 0 ; iRow < filteredValues.rows.length ; iRow++ )
					{
						String filteredQuery = buildFilteredQuery(conn, query, filteredValues, iRow);
						titles.add(buildFilteredColumnTitle(configColumnNames[iCol], filteredValues, iRow));
						queries.add(filteredQuery);
						dataTypes.add(testQueryAndGetDataType(conn, filteredQuery));
					}
				}
				else
				{
					titles.add(configColumnNames[iCol]);
					queries.add(query);
					dataTypes.add(testQueryAndGetDataType(conn, query));
				}
			}
			// done generating queries

			// generate config DataTable entry
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_DATATABLE, configDataTableName);

			config.removeDataTable(configDataTableName);

			Map<String, String> metadata = new HashMap<String, String>();
			metadata.put(Metadata.DATATABLE.toString(), configDataTableName);
			metadata.put(Metadata.KEYTYPE.toString(), keyType);
			metadata.put(Metadata.GEOMETRYCOLLECTION.toString(), geometryCollectionName);
			
			int numberSqlColumns = titles.size();
			for (int i = 0; i < numberSqlColumns; i++)
			{
				metadata.put(Metadata.NAME.toString(), titles.get(i));
				metadata.put(Metadata.DATATYPE.toString(), dataTypes.get(i));
				AttributeColumnInfo attrInfo = new AttributeColumnInfo(connectionName, queries.get(i), metadata);
				config.addAttributeColumn(attrInfo);
			}

			backupAndSaveConfig(config);
		}
		catch (SQLException e)
		{
			throw new RemoteException(String.format("Failed to add DataTable \"%s\" to the configuration.\n", configDataTableName), e);
		}
		catch (RemoteException e)
		{
			throw new RemoteException(String.format("Failed to add DataTable \"%s\" to the configuration.\n", configDataTableName), e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
		
		if (sqlColumnNames.length == 0)
			throw new RemoteException("No columns were found.");
		
		return String.format("DataTable \"%s\" was added to the configuration with %s generated attribute column queries.\n", configDataTableName, titles.size());
	}
	
	private String testQueryAndGetDataType(Connection conn, String query) throws RemoteException
	{
		Statement stmt = null;
		ResultSet rs = null;
		DataType dataType = null;
		try
		{
			String dbms = conn.getMetaData().getDatabaseProductName();
			if (!dbms.equalsIgnoreCase(SQLUtils.SQLSERVER) && !dbms.equalsIgnoreCase(SQLUtils.ORACLE))
				query += " LIMIT 1";
	
			stmt = conn.createStatement();
			rs = stmt.executeQuery(query);
	
			dataType = DataType.fromSQLType(rs.getMetaData().getColumnType(2));
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to execute generated query:\n" + query, e);
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
		}
		
		return dataType.toString();
	}
	
	private String buildFilteredColumnTitle(String columnName, SQLResult filteredValues, int filteredValueRow)
	{
		String columnTitle = columnName + " (";
		for (int j = 0 ; j < filteredValues.rows[filteredValueRow].length ; j++ )
		{
			if (j > 0)
				columnTitle += " ";
			boolean isNull = filteredValues.rows[filteredValueRow][j] == null;
			String value;
			if (isNull)
				value = "NULL";
			else
				value = filteredValues.rows[filteredValueRow][j].toString();
			columnTitle += isNull ? "NULL" : value;
		}
		columnTitle += ")";
		return columnTitle;
	}
	
	private String buildFilteredQuery(Connection conn, String unfilteredQuery, SQLResult filteredValues, int filteredValueRow) throws IllegalArgumentException, SQLException
	{
		String query = unfilteredQuery + " where ";
		for (int j = 0 ; j < filteredValues.rows[filteredValueRow].length ; j++ )
		{
			if (j > 0)
				query += " and ";
			boolean isNull = filteredValues.rows[filteredValueRow][j] == null;
			String value;
			if (isNull)
				value = "NULL";
			else
				value = filteredValues.rows[filteredValueRow][j].toString();
			query += String.format(
				"%s=%s",
				SQLUtils.quoteSymbol(conn, filteredValues.columnNames[j]),
				isNull ? "NULL" : SQLUtils.quoteString(conn, value)
			);
		}
		return query;
	}

	/**
	 * The following functions involve getting shapes into the database and into
	 * the config file.
	 */

	synchronized public String convertShapefileToSQLStream(String configConnectionName, String password, String[] fileNameWithoutExtension, String[] keyColumns, String sqlSchema, String sqlTablePrefix, boolean sqlOverwrite, String configGeometryCollectionName, boolean configOverwrite, String configKeyType, String projectionSRS, String[] nullValues) throws RemoteException
	{
		// use lower case sql table names (fix for mysql linux problems)
		sqlTablePrefix = sqlTablePrefix.toLowerCase();

		ISQLConfig config = checkPasswordAndGetConfig(configConnectionName, password);
		ConnectionInfo connInfo = config.getConnectionInfo(configConnectionName);
		if (sqlOverwrite && !connInfo.is_superuser)
			throw new RemoteException(String.format("User \"%s\" does not have permission to overwrite SQL tables.", configConnectionName));
		if (!SQLConfigUtils.userCanModifyGeometryCollection(config, configConnectionName, configGeometryCollectionName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to overwrite GeometryCollection \"%s\".", configConnectionName, configGeometryCollectionName));

		if (!configOverwrite)
		{
			if (ListUtils.findIgnoreCase(configGeometryCollectionName, config.getGeometryCollectionNames(null)) >= 0)
				throw new RemoteException(String.format(
						"Shapes not imported. SQLConfig geometryCollection \"%s\" already exists.",
						configGeometryCollectionName));
		}

		String dbfTableName = sqlTablePrefix + "_dbfdata";
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
			// store dbf data to database
			storeDBFDataToDatabase(configConnectionName, password, fileNameWithoutExtension, sqlSchema, dbfTableName, sqlOverwrite, nullValues);
			GeometryStreamConverter converter = new GeometryStreamConverter(
					new SQLGeometryStreamDestination(conn, sqlSchema, sqlTablePrefix, sqlOverwrite)
			);
			for (String file : fileNameWithoutExtension)
			{
				// convert shape data to streaming sql format
				String shpfile = uploadPath + file + ".shp";
				SHPGeometryStreamUtils.convertShapefile(converter, shpfile, Arrays.asList(keyColumns));
			}
			converter.flushAndCommitAll();
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException("Shapefile import failed", e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
		String fileList = Arrays.asList(fileNameWithoutExtension).toString();
		if (fileList.length() > 103)
			fileList = fileList.substring(0, 50) + "..." + fileList.substring(fileList.length() - 50);
		String importNotes = String.format("file: %s, keyColumns: %s", fileList, Arrays.asList(keyColumns));

		// get key column SQL code
		String keyColumnsString;
		if (keyColumns.length == 1)
		{
			keyColumnsString = keyColumns[0];
		}
		else
		{
			keyColumnsString = "CONCAT(";
			for (int i = 0; i < keyColumns.length; i++)
			{
				if (i > 0)
					keyColumnsString += ",";
				keyColumnsString += "CAST(" + keyColumns[i] + " AS CHAR)";
			}
			keyColumnsString += ")";
		}

		// add SQL statements to sqlconfig
		String[] columnNames = getColumnsList(configConnectionName, sqlSchema, dbfTableName).toArray(new String[0]);
		String resultAddSQL = addConfigDataTable(config, configOverwrite, configGeometryCollectionName, configConnectionName,
				configGeometryCollectionName, configKeyType, keyColumnsString, null, columnNames, columnNames, sqlSchema,
				dbfTableName, false, null);

		return resultAddSQL
				+ "\n\n"
				+ addConfigGeometryCollection(configOverwrite, configConnectionName, password, configGeometryCollectionName,
						configKeyType, sqlSchema, sqlTablePrefix, projectionSRS, importNotes);
	}

	synchronized public String storeDBFDataToDatabase(String configConnectionName, String password, String[] fileNameWithoutExtension, String sqlSchema, String sqlTableName, boolean sqlOverwrite, String[] nullValues) throws RemoteException
	{
		// use lower case sql table names (fix for mysql linux problems)
		sqlTableName = sqlTableName.toLowerCase();

		ISQLConfig config = checkPasswordAndGetConfig(configConnectionName, password);
		ConnectionInfo connInfo = config.getConnectionInfo(configConnectionName);
		if (sqlOverwrite && !connInfo.is_superuser)
			throw new RemoteException(String.format("User \"%s\" does not have permission to overwrite SQL tables.", configConnectionName));

		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
			File[] files = new File[fileNameWithoutExtension.length];
			for (int i = 0; i < files.length; i++)
				files[i] = new File(uploadPath + fileNameWithoutExtension[i] + ".dbf");

			DBFUtils.storeAttributes(files, conn, sqlSchema, sqlTableName, sqlOverwrite, nullValues);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException("DBF import failed", e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
		// String importNotes = String.format("file: %s, keyColumns: %s",
		// fileNameWithoutExtension, keyColumns);

		return "DBF Data stored successfully";
	}

	synchronized public String addConfigGeometryCollection(boolean configOverwrite, String configConnectionName, String password, String configGeometryCollectionName, String configKeyType, String sqlSchema, String sqlTablePrefix, String projectionSRS, String importNotes) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(configConnectionName, password);

		if (!configOverwrite)
		{
			if (ListUtils.findIgnoreCase(configGeometryCollectionName, config.getGeometryCollectionNames(null)) >= 0)
				throw new RemoteException(String.format("GeometryCollection \"%s\" already exists in the configuration.",
						configGeometryCollectionName));
		}
		else
		{
			if (!SQLConfigUtils.userCanModifyGeometryCollection(config, configConnectionName, configGeometryCollectionName))
				throw new RemoteException(String.format("User \"%s\" does not have permission to overwrite GeometryCollection \"%s\".", configConnectionName, configGeometryCollectionName));
		}

		// add geometry collection
		GeometryCollectionInfo info = new GeometryCollectionInfo();
		info.name = configGeometryCollectionName;
		info.connection = configConnectionName;
		info.schema = sqlSchema;
		info.tablePrefix = sqlTablePrefix;
		info.keyType = configKeyType;
		info.importNotes = importNotes;
		info.projection = projectionSRS;

		createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_GEOMETRYCOLLECTION, info.name);
		config.removeGeometryCollection(info.name);
		config.addGeometryCollection(info);
		backupAndSaveConfig(config);

		return String.format("GeometryCollection \"%s\" was added to the configuration", configGeometryCollectionName);
	}

	// //////////////////////////////////////////////
	// functions for managing dublin core metadata
	// //////////////////////////////////////////////

	/**
	 * Adds Dublin Core Elements to the metadata store in association with the
	 * given dataset..
	 * 
	 * @param connectionName
	 *            the name of the connection to use
	 * @param password
	 *            the password for the given connection
	 * @param dataTableName
	 *            the name of the dataset to associate the given elements with
	 * @param elements
	 *            the key-value pairs defining the new Dublin Core elements to
	 *            add. Keys are expected to be like "dc:title" and
	 *            "dc:description", values are expected to be Strings.
	 * @throws RemoteException
	 */
	synchronized public void addDCElements(String connectionName, String password, String dataTableName, Map<String, Object> elements) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);

		if (!SQLConfigUtils.userCanModifyDataTable(config, connectionName, dataTableName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to modify DataTable \"%s\".", connectionName, dataTableName));

		DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
		String configConnectionName = configInfo.connection;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
			String schema = configInfo.schema;
			DublinCoreUtils.addDCElements(conn, schema, dataTableName, elements);
		}
		catch (SQLException e)
		{
			throw new RemoteException("addDCElements failed", e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
	}

	/**
	 * Queries the database for the Dublin Core metadata elements associated
	 * with the data set with the given name and returns the result. The result
	 * is returned as a Map whose keys are Dublin Core property names and whose
	 * values are the values for those properties (for the given data set)
	 * stored in the metadata store.
	 * 
	 * If an error occurs, a map is returned with a single key-value pair whose
	 * key is "error".
	 */
	synchronized public Map<String,String> listDCElements(String connectionName, String password, String dataTableName) throws RemoteException
	{
		Connection conn = null;
		try
		{
			ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
			
			DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
			String configConnectionName = configInfo.connection;
			String schema = configInfo.schema;
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
			return DublinCoreUtils.listDCElements(conn, schema, dataTableName);
		}
		catch (SQLException e)
		{
			throw new RemoteException("listDCElements failed", e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
	}

	/**
	 * Deletes the specified metadata entries.
	 */
	synchronized public void deleteDCElements(String connectionName, String password, String dataTableName, List<Map<String, String>> elements) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		if (!SQLConfigUtils.userCanModifyDataTable(config, connectionName, dataTableName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to modify DataTable \"%s\".", connectionName, dataTableName));

		DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
		String configConnectionName = configInfo.connection;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
			String schema = configInfo.schema;
			DublinCoreUtils.deleteDCElements(conn, schema, dataTableName, elements);
		}
		catch (SQLException e)
		{
			throw new RemoteException("deleteDCElements failed", e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
	}

	/**
	 * Saves an edited metadata row to the server.
	 */
	synchronized public void updateEditedDCElement(String connectionName, String password, String dataTableName, Map<String, String> object) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		if (!SQLConfigUtils.userCanModifyDataTable(config, connectionName, dataTableName))
			throw new RemoteException(String.format("User \"%s\" does not have permission to modify DataTable \"%s\".", connectionName, dataTableName));

		DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
		String configConnectionName = configInfo.connection;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
			String schema = configInfo.schema;
			DublinCoreUtils.updateEditedDCElement(conn, schema, dataTableName, object);
		}
		catch (SQLException e)
		{
			throw new RemoteException("updateEditedDCElement failed", e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
	}

	synchronized public String saveReportDefinitionFile(String fileName, String fileContents) throws RemoteException
	{
		File reportDefFile;
		try
		{
			File docrootDir = new File(docrootPath);
			if (!docrootDir.exists())
				throw new RemoteException("Unable to find docroot directory");
			File reportsDir = new File(docrootDir, "\\WeaveReports");
			if (!reportsDir.exists())
				reportsDir.mkdir();
			if (!reportsDir.exists())
				throw new RemoteException("Unable to access reports directory");
			reportDefFile = new File(reportsDir, fileName);
			BufferedWriter writer = new BufferedWriter(new FileWriter(reportDefFile));
			writer.write(fileContents);
			writer.close();
		}
		catch (Exception e)
		{
			throw new RemoteException("Error writing report definition file: " + fileName, e);
		}
		return "Successfully wrote the report definition file: " + reportDefFile.getAbsolutePath();
	}
}

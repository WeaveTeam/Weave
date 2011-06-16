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
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.FilenameFilter;
import java.io.IOException;
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
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.UUID;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.config.DatabaseConfig;
import weave.config.DublinCoreElement;
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
import weave.servlets.GenericServlet;
import weave.utils.CSVParser;
import weave.utils.DBFUtils;
import weave.utils.FileUtils;
import weave.utils.ListUtils;
import weave.utils.SQLUtils;
import weave.utils.XMLUtils;
import weave.beans.AdminServiceResponse;
import weave.beans.UploadFileFilter;
import weave.beans.UploadedFile;
import org.postgresql.PGConnection;

public class AdminService extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	
	public AdminService()
	{
	}
	
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		configManager = SQLConfigManager.getInstance(config.getServletContext());
		
		tempPath = configManager.getContextParams().getTempPath();
		uploadPath = configManager.getContextParams().getUploadPath();
		docrootPath = configManager.getContextParams().getDocrootPath();
	}
	private String tempPath;
	private String uploadPath;
	private String docrootPath;
	
	private static int StringType = 0;
	private static int IntType = 1;
	private static int DoubleType = 2;
	private static String CSV_NULL_VALUE = "\\N";

	private SQLConfigManager configManager;

	synchronized public AdminServiceResponse checkSQLConfigExists()
	{
		String welcomeMessage = "Welcome to the Weave Admin Console!\nPlease add a database connection first."; 

		File configFile = new File(configManager.getConfigFileName());
		try
		{
			configManager.detectConfigChanges();
			if (configManager.getConfig().getConnectionNames().size() == 0)
				return new AdminServiceResponse(false, welcomeMessage); 
				
			return new AdminServiceResponse(true, configFile.getName() + " exists.");
		}
		catch (RemoteException se)
		{
			se.printStackTrace();
			try
			{
				if (configFile.exists())
					return new AdminServiceResponse(false, configFile.getName() + " is invalid. Please edit the file and fix the problem"
							+ " or delete it and create a new one through the admin console.\n" + "\n" + se.getMessage());
			}
			catch (Exception e)
			{
			}
			return new AdminServiceResponse(false, welcomeMessage);
		}
	}

	synchronized public AdminServiceResponse checkSQLConfigMigrated() throws RemoteException
	{
		try
		{
			if(configManager.checkSQLConfigMigrated())
				return new AdminServiceResponse(true,"SQLConfig.xml file is migrated");
			else
				return new AdminServiceResponse(false,"SQLConfig.xml is not migrated");
		}catch(RemoteException e)
		{
			e.printStackTrace();
			return new AdminServiceResponse(false,"Could not check if sqlconfig.xml is migrated");
		}
	}
	
	synchronized public Boolean authenticate(String connectionName, String password) throws RemoteException
	{
		ISQLConfig config = null;
		try
		{
			configManager.detectConfigChanges();
			config = configManager.getConfig();
		}
		catch (RemoteException e)
		{
			return true; // accept anything if config file fails
		}

		ConnectionInfo info = config.getConnectionInfo(connectionName);
		boolean result = password.equals(info.pass);
		if (!result)
			System.out.println(String.format("authenticate(\"%s\",\"%s\") == %s", connectionName, password, result));
		return result;
	}

	synchronized private ISQLConfig checkPasswordAndGetConfig(String connectionName, String password) throws RemoteException
	{
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();

		ConnectionInfo info = config.getConnectionInfo(connectionName);
		if (!password.equals(info.pass))
			throw new RemoteException("Incorrect password.");

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
	synchronized public String[] getWeaveFileNames(String configConnectionName, String password) throws RemoteException
	{
		checkPasswordAndGetConfig(configConnectionName, password);

		File docrootFolder = new File(docrootPath);
		FilenameFilter xmlFilter = new FilenameFilter()
		{
			public boolean accept(File dir, String fileName)
			{
				return (fileName.endsWith(".xml"));
			}
		};
		File[] files = null;
		List<String> listOfFiles = new ArrayList<String>();

		try
		{
			files = docrootFolder.listFiles(xmlFilter);
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
			throw new RemoteException("Permission error reading directory.",e);
		}

		return ListUtils.toStringArray(listOfFiles);
	}

	synchronized public String saveWeaveFile(String connectionName, String password, String fileContents, String xmlFile, boolean overwriteFile) throws RemoteException
	{
		checkPasswordAndGetConfig(connectionName, password);

		// 5.2 client web page configuration file ***.xml
		String output = "";
		try
		{
			// remove special characters
			xmlFile = xmlFile.replace("\\", "").replace("/", "");
			if (!xmlFile.toLowerCase().endsWith(".xml"))
				xmlFile += ".xml";
			
			File file = new File(docrootPath + xmlFile);
			
			if (!overwriteFile)
			{
				if (file.exists())
					return String.format("File already exists: %s", xmlFile);
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
		checkPasswordAndGetConfig(configConnectionName, password);

		File f = new File(docrootPath + fileName);
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

	synchronized public String[] getConnectionNames() throws RemoteException
	{
		configManager.detectConfigChanges();
		return ListUtils.toStringArray(getSortedUniqueValues(configManager.getConfig().getConnectionNames(), false));
	}

	synchronized public ConnectionInfo getConnectionInfo(String loginConnectionName, String loginPassword, String connectionNameToGet) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(loginConnectionName, loginPassword);
		return config.getConnectionInfo(connectionNameToGet);
	}

	synchronized public String saveConnectionInfo(String connectionName, String dbms, String ip, String port, String database, String user, String password, boolean configOverwrite) throws RemoteException
	{
		// test the connection before we create the config file
		if (connectionName == "")
			throw new RemoteException("Connection name cannot be empty.");

		ConnectionInfo info = new ConnectionInfo();
		info.name = connectionName;
		info.dbms = dbms;
		info.ip = ip;
		info.port = port;
		info.database = database;
		info.user = user;
		info.pass = password;
		// test connection only - to validate parameters
		Connection conn = null;
		try
		{
			conn = info.getConnection();
		}
		catch (Exception e)
		{
			throw new RemoteException(String.format("The connection named \"%s\" was not created because the server could not"
					+ " connect to the specified database with the given parameters.", info.name), e);
		}
		finally
		{
			// close the connection, as we will not use it later
			SQLUtils.cleanup(conn);
		}

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

		if (ListUtils.findString(info.name, config.getConnectionNames()) >= 0 && configOverwrite == false)
		{
			throw new RemoteException(String
					.format("The connection named \"%s\" already exists.  Action cancelled.", info.name));
		}

		// generate config connection entry
		try
		{
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_CONNECTION, info.name);

			config.removeConnection(info.name);
			config.addConnection(info);

			backupAndSaveConfig(config);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(String.format("Unable to create connection entry named \"%s\": %s", info.name, e
					.getMessage()));
		}

		return String.format("The connection named \"%s\" was created successfully.", connectionName);
	}

	synchronized public String removeConnectionInfo(String loginConnectionName, String loginPassword, String connectionNameToRemove) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(loginConnectionName, loginPassword);
		try
		{
			if (ListUtils.findString(connectionNameToRemove, config.getConnectionNames()) < 0)
				throw new RemoteException("Connection \"" + connectionNameToRemove + "\" does not exist.");
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_CONNECTION, connectionNameToRemove);
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
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		return config.getDatabaseConfigInfo();
	}

	synchronized public AdminServiceResponse migrateConfigToDatabase(String connectionName, String password, String schema, String geometryConfigTable, String dataConfigTable) throws RemoteException
	{
		checkPasswordAndGetConfig(connectionName, password);

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
				return new AdminServiceResponse(false,"Migrated " + count + " items then failed"+ e.getMessage());
			return new AdminServiceResponse(false,"Migration failed +" + e.getMessage());
		}

		return new AdminServiceResponse(true,count
				+ " items were copied from " + new File(configFileName).getName()
				+ " into the database.  The admin console will now use the specified database connection to store further configuration entries.");
	}

	// /////////////////////////////////////////////////
	// functions for managing DataTable entries
	// /////////////////////////////////////////////////

	synchronized public String[] getDataTableNames() throws RemoteException
	{
		configManager.detectConfigChanges();
		return ListUtils.toStringArray(getSortedUniqueValues(configManager.getConfig().getDataTableNames(), true));
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

	@SuppressWarnings("unchecked")
	synchronized public String saveDataTableInfo(String connectionName, String password, Object[] columnMetadata) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);

		String dataTableName = null;
		for (Object object : columnMetadata)
		{
			Map<String, Object> metadata = (Map<String, Object>) object;
			String _dataTableName = (String) metadata.get("dataTable");
			if (dataTableName == null)
				dataTableName = _dataTableName;
			else if (dataTableName != _dataTableName)
				throw new RemoteException("overwriteDataTableEntry(): dataTable property not consistent among column entries.");
		}

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

	synchronized public String removeDataTableInfo(String connectionName, String password, String entryName) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		try
		{
			if (ListUtils.findString(entryName, config.getDataTableNames()) < 0)
				throw new RemoteException("DataTable \"" + entryName + "\" does not exist.");
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_DATATABLE, entryName);
			config.removeDataTable(entryName);
			backupAndSaveConfig(config);
			return "DataTable \"" + entryName + "\" was deleted.";
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

	synchronized public String[] getGeometryCollectionNames() throws RemoteException
	{
		configManager.detectConfigChanges();
		return ListUtils.toStringArray(getSortedUniqueValues(configManager.getConfig().getGeometryCollectionNames(), true));
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

	synchronized public String removeGeometryCollectionInfo(String connectionName, String password, String entryName) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		try
		{
			if (ListUtils.findString(entryName, config.getGeometryCollectionNames()) < 0)
				throw new RemoteException("Geometry Collection \"" + entryName + "\" does not exist.");
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_GEOMETRYCOLLECTION, entryName);
			config.removeGeometryCollection(entryName);
			backupAndSaveConfig(config);
			return "Geometry Collection \"" + entryName + "\" was deleted.";
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
		;
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

	synchronized public String[] getKeyTypes() throws RemoteException
	{
		configManager.detectConfigChanges();
		return ListUtils.toStringArray(getSortedUniqueValues(configManager.getConfig().getKeyTypes(), true));
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
			String[][] rows = CSVParser.defaultParser.parseCSV(csvData);

			// Read first line only (header line).
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
	// /**
	// * temporary solution -- An interface for modifying the XML configuration.
	// * These functions depend on the SQLConfig implementation rather than the
	// * interface. These functions should be replaced with some other interface
	// * when an implementation of ISQLConfig is developed that uses a database.
	// *
	// * @throws RemoteException
	// */
	// synchronized public String getConfigEntryXML(String connectionName,
	// String password, String entryType, String entryName) throws
	// RemoteException
	// {
	// ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
	//
	// SQLConfigXML tempConfig;
	// try
	// {
	// tempConfig = new SQLConfigXML();
	// SQLConfigUtils.migrateSQLConfigEntry(config, tempConfig, entryType,
	// entryName);
	// return tempConfig.getConfigEntryXML(entryType, entryName);
	// }
	// catch (Exception e)
	// {
	// e.printStackTrace();
	// throw new RemoteException("getConfigEntryXML() threw " +
	// e.getClass().getName(), e);
	// }
	// }
	//
	// /**
	// * temporary solution -- An interface for modifying the XML configuration.
	// * These functions depend on the SQLConfig implementation rather than the
	// * interface. These functions should be replaced with some other interface
	// * when an implementation of ISQLConfig is developed that uses a database.
	// *
	// * @throws RemoteException
	// */
	// synchronized public String overwriteConfigEntryXML(String connectionName,
	// String password, String entryXML) throws RemoteException
	// {
	// ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
	//
	// try
	// {
	// // start a block of code so tempConfig will not stay in memory
	// EntryInfo info = null;
	// {
	// // make a new SQLConfig object and add the entry
	// SQLConfigXML tempConfig = new SQLConfigXML();
	// info = tempConfig.overwriteConfigEntryXML(entryXML);
	// if (info.name == "")
	// throw new RemoteException(info.type + " name cannot be empty.");
	//
	// createConfigEntryBackup(config, info.type, info.name);
	//
	// SQLConfigUtils.migrateSQLConfigEntry(tempConfig, config, info.type,
	// info.name);
	// }
	// backupAndSaveConfig(config);
	//
	// return String.format("The %s entry \"%s\" was saved.", info.type,
	// info.name);
	// }
	// catch (Exception e)
	// {
	// e.printStackTrace();
	// throw new RemoteException(e.getMessage());
	// }
	// }

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
	public void uploadFile(String fileName, byte[] content) throws RemoteException
	{
		// make sure the upload folder exists
		(new File(uploadPath)).mkdirs();

		String filePath = uploadPath + fileName;
		try
		{
			FileUtils.copy(new ByteArrayInputStream(content), new FileOutputStream(filePath));
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

	synchronized public String importCSV(String connectionName, String password, String csvFile, String csvKeyColumn, String csvSecondaryKeyColumn, String sqlSchema, String sqlTable, boolean sqlOverwrite, String configDataTableName, boolean configOverwrite, String configGeometryCollectionName, String configKeyType, String[] nullValues) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);

		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, connectionName);
		}
		catch (SQLException e)
		{
			throw new RemoteException(e.getMessage(), e);
		}
		String dbms = config.getConnectionInfo(connectionName).dbms;

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

		try
		{
			String csvData = org.apache.commons.io.FileUtils.readFileToString(new File(uploadPath, csvFile));
			String[][] rows = CSVParser.defaultParser.parseCSV(csvData);

			if (rows.length == 0)
				throw new RemoteException("CSV file is empty: " + csvFile);

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
								nextLine[i] = CSV_NULL_VALUE;
								break;
							}
						}
					}
					if (nextLine[i].equals(CSV_NULL_VALUE))
						continue;
					
					// 3.3.2 is a string, update the type.
					try
					{
						// if this fails, it will throw an exception
						String value = nextLine[i];
						while (value.indexOf(',') > 0)
							value = value.replace(",", "");
						Integer.parseInt(value);
						nextLine[i] = value;
					}
					catch (Exception e)
					{
						try
						{
							// if this fails, it will throw an exception
							Double.parseDouble(nextLine[i]);

							types[i] = DoubleType;
						}
						catch (Exception e2)
						{
							types[i] = StringType;
						}
					}
				}
			}
			
			// save modified CSV
			BufferedWriter out = new BufferedWriter(new FileWriter(formatted_CSV_path));
			out.write(CSVParser.defaultParser.createCSVFromArrays(rows));
			out.close();
		}
		catch (RemoteException e)
		{
			e.printStackTrace();
			throw e;
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage(), e);
		}

		// Import the CSV file into SQL.
		Statement stmt = null;
		String returnMsg = "";
		try
		{
			String quotedTable = SQLUtils.quoteSchemaTable(dbms, sqlSchema, sqlTable);

			// Drop the table if it exists.
			if (sqlOverwrite)
			{
				stmt = conn.createStatement();
				stmt.executeUpdate("DROP TABLE IF EXISTS " + quotedTable);
				stmt.close();
			}
			else
			{
				if (ListUtils.findIgnoreCase(sqlTable, getTablesList(connectionName, sqlSchema)) >= 0)
					throw new RemoteException("CSV not imported. SQL table already exists.");
			}

			if (!configOverwrite)
			{
				if (ListUtils.findIgnoreCase(configDataTableName, config.getDataTableNames()) >= 0)
					throw new RemoteException(String.format("CSV not imported. DataTable \"%s\" already exists in the configuration.",
							configDataTableName));
			}

			// create a table
			String query = "CREATE TABLE " + quotedTable + " (";
			for (i = 0; i < columnNames.length; i++)
			{
				String quotedColumnName = SQLUtils.quoteSymbol(dbms, columnNames[i]);
				if (i > 0)
					query += ",";
				if (types[i] == StringType || csvKeyColumn.equalsIgnoreCase(columnNames[i]))
					query += String.format("%s VARCHAR(%s)", quotedColumnName, fieldLengths[i]);
				else if (types[i] == IntType)
					query += quotedColumnName + " INT";
				else if (types[i] == DoubleType)
					query += quotedColumnName + " DOUBLE PRECISION";
			}
			query += ");";
			stmt = conn.createStatement();
			System.out.println(query);
			stmt.executeUpdate(query);
			stmt.close();

			// import the data
			System.out.println(conn.getMetaData().getDatabaseProductName());
			if (dbms.equalsIgnoreCase(SQLUtils.MYSQL))
			{
				stmt = conn.createStatement();
				//ignoring 1st line so that we don't put the column headers as the first row of data
				stmt.executeUpdate(String.format(
						"load data local infile '%s' into table %s fields terminated by ',' enclosed by '\"' lines terminated by '\\n' ignore 1 lines",
						formatted_CSV_path, quotedTable));
				stmt.close();
			}
			else if (dbms.equalsIgnoreCase(SQLUtils.POSTGRESQL))
			{
				// using modified driver from
				// http://kato.iki.fi/sw/db/postgresql/jdbc/copy/
				((PGConnection) conn).getCopyAPI().copyIntoDB(
						String.format("COPY %s FROM STDIN WITH CSV HEADER", quotedTable),
						new FileInputStream(formatted_CSV_path));
			}

			returnMsg += addConfigDataTable(config, configOverwrite, configDataTableName, connectionName,
					configGeometryCollectionName, configKeyType, csvKeyColumn, csvSecondaryKeyColumn, Arrays.asList(originalColumnNames), Arrays
							.asList(columnNames), sqlSchema, sqlTable);
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			returnMsg += "Unable to import CSV.\n";
			String errorMsg = e.getMessage();
			if (errorMsg.length() > 512)
				errorMsg = errorMsg.substring(0, 512);
			returnMsg += errorMsg;
		}
		catch (FileNotFoundException e)
		{
			e.printStackTrace();
			returnMsg += "Unable to import CSV.\nFile not found: ";
			String errorMsg = e.getMessage();
			if (errorMsg.length() > 512)
				errorMsg = errorMsg.substring(0, 512);
			returnMsg += errorMsg;
		}
		finally
		{
			// close everything in reverse order
			SQLUtils.cleanup(stmt);
			SQLUtils.cleanup(conn);
		}

		return returnMsg;
	}

	synchronized public String addConfigDataTableFromDatabase(String connectionName, String password, String schemaName, String tableName, String keyColumnName, String secondaryKeyColumnName, String configDataTableName, boolean configOverwrite, String geometryCollectionName, String keyType) throws RemoteException
	{
		// use lower case sql table names (fix for mysql linux problems)
		tableName = tableName.toLowerCase();

		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);
		List<String> columnNames = getColumnsList(connectionName, schemaName, tableName);
		return addConfigDataTable(config, configOverwrite, configDataTableName, connectionName, geometryCollectionName,
				keyType, keyColumnName, secondaryKeyColumnName, columnNames, columnNames, schemaName, tableName);
	}

	synchronized private String addConfigDataTable(ISQLConfig config, boolean configOverwrite, String configDataTableName, String connectionName, String geometryCollectionName, String keyType, String keyColumnName, String secondaryKeyColumnName, List<String> configColumnNames, List<String> sqlColumnNames, String sqlSchema, String sqlTable) throws RemoteException
	{
		// use lower case sql table names (fix for mysql linux problems)
		sqlTable = sqlTable.toLowerCase();

		ConnectionInfo info = config.getConnectionInfo(connectionName);
		String dbms = info.dbms;
		if (sqlColumnNames == null)
			sqlColumnNames = new Vector<String>();
		// if key column is actually the name of a column, put quotes around it.
		// otherwise, don't.
		int i = ListUtils.findIgnoreCase(keyColumnName, sqlColumnNames);
		
		int j = ListUtils.findIgnoreCase(secondaryKeyColumnName, sqlColumnNames);
		if (i >= 0)
			keyColumnName = SQLUtils.quoteSymbol(dbms, sqlColumnNames.get(i));
		if (j >= 0)
			secondaryKeyColumnName = SQLUtils.quoteSymbol(dbms, sqlColumnNames.get(j));
		// Write SQL statements into sqlconfig.

		if (!configOverwrite)
		{
			if (ListUtils.findIgnoreCase(configDataTableName, config.getDataTableNames()) >= 0)
				throw new RemoteException(String.format("DataTable \"%s\" already exists in the configuration.", configDataTableName));
		}

		boolean dataTableCreated = false;

		// connect to database, generate and test each query before modifying
		// config file
		List<String> queries = new Vector<String>();
		List<String> dataTypes = new Vector<String>();
		Statement stmt = null;
		ResultSet rs = null;
		String query = null;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, connectionName);
			stmt = conn.createStatement();
			for (i = 0; i < sqlColumnNames.size(); i++)
			{
				// test each query
				query = generateColumnQuery(dbms, keyColumnName, secondaryKeyColumnName, sqlColumnNames.get(i), sqlSchema, sqlTable);
				rs = stmt.executeQuery(query + " LIMIT 1");
				DataType dataType = DataType.fromSQLType(rs.getMetaData().getColumnType(2));
				SQLUtils.cleanup(rs);
				queries.add(query);
				dataTypes.add(dataType.toString());
			}
		}
		catch (SQLException e)
		{
			throw new RemoteException("DataTable was not added to the configuration. Unable to execute generated query:\n\n" + query, e);
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(stmt);
			SQLUtils.cleanup(conn);
		}
		// done generating queries

		// generate config DataTable entry
		try
		{
			createConfigEntryBackup(config, ISQLConfig.ENTRYTYPE_DATATABLE, configDataTableName);

			config.removeDataTable(configDataTableName);

			Map<String, String> metadata = new HashMap<String, String>();
			metadata.put(Metadata.DATATABLE.toString(), configDataTableName);
			metadata.put(Metadata.KEYTYPE.toString(), keyType);
			metadata.put(Metadata.GEOMETRYCOLLECTION.toString(), geometryCollectionName);
			for (i = 0; i < sqlColumnNames.size(); i++)
			{
				metadata.put(Metadata.NAME.toString(), configColumnNames.get(i));
				metadata.put(Metadata.DATATYPE.toString(), dataTypes.get(i));
				AttributeColumnInfo attrInfo = new AttributeColumnInfo(connectionName, queries.get(i), metadata);
				config.addAttributeColumn(attrInfo);
			}

			backupAndSaveConfig(config);

			dataTableCreated = true;
		}
		catch (Exception e)
		{
			e.printStackTrace();
			dataTableCreated = false;
		}

		if (dataTableCreated)
		{
			if (sqlColumnNames.size() == 0)
				throw new RemoteException("DataTable was not added because no columns were found.");
			return String.format("DataTable \"%s\" was added to the configuration with %s columns.\n", configDataTableName,
					sqlColumnNames.size());
		}
		throw new RemoteException(String.format("Failed to add DataTable \"%s\" to the configuration.\n", configDataTableName));
	}

	private String generateColumnQuery(String dbms, String keyColumn, String secondaryKeyColumn, String dataColumn, String schema, String table)
	{
		// return String.format(
		// "SELECT DISTINCT w.`ISO ALPHA-3 code`, u.`%s` " +
		// "FROM world.`world_name_table` as w, %s as u WHERE u.%s=w.`Country or area name` OR u.%s=w.`Country name`",
		// dataColumn,
		// SQLUtils.quoteSchemaTable(dbms, schema, table),
		// keyColumn, keyColumn);
		if(secondaryKeyColumn == null)
			secondaryKeyColumn = "";
		if(secondaryKeyColumn != "")
			secondaryKeyColumn = "," + secondaryKeyColumn;

		return String.format("SELECT %s,%s%s FROM %s", keyColumn, SQLUtils.quoteSymbol(dbms, dataColumn), secondaryKeyColumn, SQLUtils
				.quoteSchemaTable(dbms, schema, table));
	}

	/**
	 * The following functions involve getting shapes into the database and into
	 * the config file.
	 */

	synchronized public String convertShapefileToSQLStream(String configConnectionName, String password, String[] fileNameWithoutExtension, List<String> keyColumns, String sqlSchema, String sqlTablePrefix, boolean sqlOverwrite, String configGeometryCollectionName, boolean configOverwrite, String configKeyType, String projectionSRS, String[] nullValues) throws RemoteException
	{
		// use lower case sql table names (fix for mysql linux problems)
		sqlTablePrefix = sqlTablePrefix.toLowerCase();

		ISQLConfig config = checkPasswordAndGetConfig(configConnectionName, password);


		if (!configOverwrite)
		{
			if (ListUtils.findIgnoreCase(configGeometryCollectionName, config.getGeometryCollectionNames()) >= 0)
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
				SHPGeometryStreamUtils.convertShapefile(converter, shpfile, keyColumns);
			}
			converter.flushAndCommitAll();
		}
		catch (FileNotFoundException e)
		{
			e.printStackTrace();
			throw new RemoteException("FileNotFoundException", e);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			throw new RemoteException("IOException", e);
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			throw new RemoteException("SQLException", e);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException("Exception", e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}
		String fileList = Arrays.asList(fileNameWithoutExtension).toString();
		if (fileList.length() > 103)
			fileList = fileList.substring(0, 50) + "..." + fileList.substring(fileList.length() - 50);
		String importNotes = String.format("file: %s, keyColumns: %s", fileList, keyColumns);

		// get key column SQL code
		String keyColumnsString;
		if (keyColumns.size() == 1)
		{
			keyColumnsString = keyColumns.get(0);
		}
		else
		{
			keyColumnsString = "CONCAT(";
			for (int i = 0; i < keyColumns.size(); i++)
			{
				if (i > 0)
					keyColumnsString += ",";
				keyColumnsString += "CAST(" + keyColumns.get(i) + " AS CHAR)";
			}
			keyColumnsString += ")";
		}

		// add SQL statements to sqlconfig
		List<String> columnNames = getColumnsList(configConnectionName, sqlSchema, dbfTableName);
		String resultAddSQL = addConfigDataTable(config, configOverwrite, configGeometryCollectionName, configConnectionName,
				configGeometryCollectionName, configKeyType, keyColumnsString, "",columnNames, columnNames, sqlSchema,
				dbfTableName);

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
			if (ListUtils.findIgnoreCase(configGeometryCollectionName, config.getGeometryCollectionNames()) >= 0)
				throw new RemoteException(String.format("GeometryCollection \"%s\" already exists in the configuration.",
						configGeometryCollectionName));
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

		DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
		if (configInfo == null)
			throw new RemoteException(
					"No configuration database found. This is necessary to store the Dublin Core properties. Please migrate your configuration into a database (see the Database connections tab).");

		String configConnectionName = configInfo.connection;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
		}
		catch (SQLException e)
		{
			throw new RemoteException("addDCElements failed", e);
		}

		String schema = configInfo.schema;
		DublinCoreUtils.addDCElements(conn, schema, dataTableName, elements);

		// System.out.println("in addDCElements");
		// int i = 0;
		// for (Map.Entry<String, Object> e : elements.entrySet())
		// System.out.println("  elements[" + (i++) + "] = {" + e.getKey()
		// + " = " + e.getValue());
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
	synchronized public DublinCoreElement[] listDCElements(String connectionName, String password, String dataTableName) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);

		DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
		if (configInfo == null)
			throw new RemoteException(
					"No configuration database found. This is necessary to store the Dublin Core properties. Please migrate your configuration into a database (see the Database connections tab).");

		String configConnectionName = configInfo.connection;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
		}
		catch (SQLException e)
		{
			throw new RemoteException("listDCElements failed", e);
		}

		String schema = configInfo.schema;
		List<DublinCoreElement> list = DublinCoreUtils.listDCElements(conn, schema, dataTableName);

		int n = list.size();
		return list.toArray(new DublinCoreElement[n]);

		// DublinCoreElement[] result = new DublinCoreElement[n];
		// for (int i = 0; i < n; i++)
		// {
		// result[i] = list.get(i);
		// System.out.println("list.get(i).element = " + list.get(i).element +
		// " list.get(i).value = " + list.get(i).value);
		// }
		// return result;
	}

	/**
	 * Deletes the specified metadata entries.
	 */
	synchronized public void deleteDCElements(String connectionName, String password, String dataTableName, List<Map<String, String>> elements) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);

		DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
		if (configInfo == null)
			throw new RemoteException(
					"No configuration database found. This is necessary to store the Dublin Core properties. Please migrate your configuration into a database (see the Database connections tab).");

		String configConnectionName = configInfo.connection;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
		}
		catch (SQLException e)
		{
			throw new RemoteException("deleteDCElements failed", e);
		}

		String schema = configInfo.schema;
		DublinCoreUtils.deleteDCElements(conn, schema, dataTableName, elements);
	}

	/**
	 * Saves an edited metadata row to the server.
	 */
	synchronized public void updateEditedDCElement(String connectionName, String password, String dataTableName, Map<String, String> object) throws RemoteException
	{
		ISQLConfig config = checkPasswordAndGetConfig(connectionName, password);

		DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
		if (configInfo == null)
			throw new RemoteException(
					"No configuration database found. This is necessary to store the Dublin Core properties. Please migrate your configuration into a database (see the Database connections tab).");

		String configConnectionName = configInfo.connection;
		Connection conn = null;
		try
		{
			conn = SQLConfigUtils.getConnection(config, configConnectionName);
		}
		catch (SQLException e)
		{
			throw new RemoteException("updateEditedDCElement failed", e);
		}

		String schema = configInfo.schema;
		DublinCoreUtils.updateEditedDCElement(conn, schema, dataTableName, object);
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

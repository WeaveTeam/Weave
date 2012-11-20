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

import static weave.config.WeaveConfig.getConnectionConfig;
import static weave.config.WeaveConfig.getDataConfig;
import static weave.config.WeaveConfig.getDocrootPath;
import static weave.config.WeaveConfig.getUploadPath;
import static weave.config.WeaveConfig.initWeaveConfig;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.rmi.RemoteException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.UploadFileFilter;
import weave.beans.UploadedFile;
import weave.beans.WeaveFileInfo;
import weave.config.ConnectionConfig;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.config.ConnectionConfig.DatabaseConfigInfo;
import weave.config.DataConfig;
import weave.config.DataConfig.DataEntity;
import weave.config.DataConfig.DataEntityMetadata;
import weave.config.DataConfig.DataEntityTableInfo;
import weave.config.DataConfig.DataEntityWithChildren;
import weave.config.DataConfig.DataType;
import weave.config.DataConfig.PrivateMetadata;
import weave.config.DataConfig.PublicMetadata;
import weave.config.WeaveConfig;
import weave.config.WeaveContextParams;
import weave.geometrystream.GeometryStreamConverter;
import weave.geometrystream.SHPGeometryStreamUtils;
import weave.geometrystream.SQLGeometryStreamDestination;
import weave.utils.BulkSQLLoader;
import weave.utils.CSVParser;
import weave.utils.DBFUtils;
import weave.utils.FileUtils;
import weave.utils.ListUtils;
import weave.utils.ProgressManager.ProgressPrinter;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import flex.messaging.io.amf.ASObject;

public class AdminService
		extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	
	public AdminService()
	{
	}

	public void init(ServletConfig config)
		throws ServletException
	{
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config.getServletContext()));
	}
	
	@Override
	protected Object cast(Object value, Class<?> type)
	{
		if (type == DataEntityMetadata.class && value != null && value instanceof ASObject)
		{
			ASObject aso = (ASObject) value;
			DataEntityMetadata dem = new DataEntityMetadata();
			ASObject privateMetadata = (ASObject)aso.get("privateMetadata");
			ASObject publicMetadata = (ASObject)aso.get("publicMetadata");
			for (Object key : privateMetadata.keySet())
				dem.privateMetadata.put((String)key, (String)privateMetadata.get(key));
			for (Object key : publicMetadata.keySet())
				dem.publicMetadata.put((String)key, (String)publicMetadata.get(key));
			return dem;
		}
		return super.cast(value, type);
	}
	
	/**
	 * This function should be the first thing called by the Admin Console to initialize the servlet.
	 * If SQL config data migration is required, it will be done and periodic status updates will be written to the servlet output stream.
	 * @throws RemoteException Thrown when the DataConfig could not be initialized.
	 */
	public void initializeAdminService() throws RemoteException
	{
		try
		{
			PrintStream ps = new PrintStream(getServletRequestInfo().response.getOutputStream());
			ProgressPrinter pp = new ProgressPrinter(ps);
			WeaveConfig.initializeAdminService(pp.getProgressManager());
		}
		catch (IOException e)
		{
			throw new RemoteException("Unable to initialize admin service", e);
		}
	}
	
	public boolean checkDatabaseConfigExists() throws RemoteException
	{
		return getConnectionConfig().getDatabaseConfigInfo() != null;
	}

	
	/**
	 * @param user
	 * @param password
	 * @return true if the user has superuser privileges.
	 * @throws RemoteException If authentication fails.
	 */
	public boolean authenticate(String user, String password) throws RemoteException
	{
		return getConnectionInfo(user, password).is_superuser;
	}
	
	private ConnectionInfo getConnectionInfo(String user, String password) throws RemoteException
	{
		ConnectionConfig connConfig = getConnectionConfig();
		ConnectionInfo info = connConfig.getConnectionInfo(user);
		if (info == null || !password.equals(info.pass))
		{
			System.out.println(String.format("authenticate failed, name=\"%s\" pass=\"%s\"", user, password));
			throw new RemoteException("Incorrect username or password.");
		}
		return info;
	}
	
    private void tryModify(String user, String pass, int entityId) throws RemoteException
    {
        // superuser can modify anything
        if (!getConnectionInfo(user, pass).is_superuser)
        {
        	DataEntity entity = getDataConfig().getEntity(entityId);
	        String owner = entity.privateMetadata.get(PrivateMetadata.CONNECTION);
	        if (!user.equals(owner))
	        	throw new RemoteException(String.format("User \"%s\" cannot modify entity %s.", user, entityId));
        }
    }
	
	//////////////////////////////
	// Weave client config files

	/**
	 * Return a list of Client Config files from docroot
	 * 
	 * @return A list of (xml) client config files existing in the docroot folder.
	 */
	public String[] getWeaveFileNames(String user, String password, Boolean showAllFiles)
		throws RemoteException
	{
		ConnectionInfo info = getConnectionInfo(user, password);
		File[] files = null;
		List<String> listOfFiles = new ArrayList<String>();
		FilenameFilter fileFilter = new FilenameFilter()
		{
			public boolean accept(File dir, String fileName)
			{
				return fileName.endsWith(".weave") || fileName.endsWith(".xml");
			}
		};

		if (showAllFiles == true)
		{
			try
			{
				String root = getDocrootPath();
				File rootFolder = new File(root);
				files = rootFolder.listFiles();

				for (File f : files)
				{
					if (!f.isDirectory())
						continue;
					File[] configs = f.listFiles(fileFilter);
					for (File configfile : configs)
					{
						listOfFiles.add(f.getName() + "/" + configfile.getName());
					}
				}
			}
			catch (SecurityException e)
			{
				throw new RemoteException("Permission error reading directory.", e);
			}
		}

		String path = getDocrootPath();
		if (!showAllFiles && info.folderName.length() > 0)
			path = path + info.folderName + "/";

		File docrootFolder = new File(path);

		try
		{
			docrootFolder.mkdirs();
			files = docrootFolder.listFiles(fileFilter);
			for (File file : files)
			{
				if (file.isFile())
				{
					listOfFiles.add(((!showAllFiles && info.folderName.length() > 0)
							? info.folderName + "/" : "") + file.getName().toString());
				}
			}
		}
		catch (SecurityException e)
		{
			throw new RemoteException("Permission error reading directory.", e);
		}

		Collections.sort(listOfFiles, String.CASE_INSENSITIVE_ORDER);
		return ListUtils.toStringArray(listOfFiles);
	}

	/**
	 * @param user
	 * @param password
	 * @param fileContent
	 * @param fileName
	 * @param overwriteFile
	 * @return
	 * @throws RemoteException
	 */
	public String saveWeaveFile(
			String user, String password, InputStream fileContent, String fileName, boolean overwriteFile)
		throws RemoteException
	{
		ConnectionInfo info = getConnectionInfo(user, password);

		try
		{
			// remove special characters
			fileName = fileName.replace("\\", "").replace("/", "");

			if (!fileName.toLowerCase().endsWith(".weave") && !fileName.toLowerCase().endsWith(".xml"))
				fileName += ".weave";

			String path = getDocrootPath();
			if (info.folderName.length() > 0)
				path = path + info.folderName + "/";

			File file = new File(path + fileName);

			if (file.exists())
			{
				if (!overwriteFile)
					return String.format("File already exists and was not changed: \"%s\"", fileName);
				if (!info.is_superuser && info.folderName.length() == 0)
					return String.format(
							"User \"%s\" does not have permission to overwrite configuration files.  Please save under a new filename.",
							user);
			}

			FileUtils.copy(fileContent, new FileOutputStream(file));
		}
		catch (IOException e)
		{
			throw new RemoteException("Error occurred while saving file", e);
		}

		return "Successfully generated " + fileName + ".";
	}

	/**
	 * Delete a Client Config file from docroot
	 * 
	 * @return A String message indicating if file was deleted.
	 * 
	 */
	public String removeWeaveFile(String user, String password, String fileName)
		throws RemoteException, IllegalArgumentException
	{
		ConnectionInfo info = getConnectionInfo(user, password);

		if (!info.is_superuser && info.folderName.length() == 0)
			return String.format(
					"User \"%s\" does not have permission to remove configuration files.", user);

		String path = getDocrootPath();
		if (info.folderName.length() > 0)
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

	public WeaveFileInfo getWeaveFileInfo(String user, String password, String fileName)
		throws RemoteException
	{
		authenticate(user, password);
		return new WeaveFileInfo(getDocrootPath() + fileName);
	}

	//////////////////////////////
	// ConnectionInfo management

	public String generateConnectString(String dbms, String ip, String port, String database, String user, String pass)
		throws RemoteException
	{
		return SQLUtils.getConnectString(dbms, ip, port, database, user, pass);
	}
	
	public String[] getConnectionNames(String user, String password)
		throws RemoteException
	{
		try
		{
			ConnectionConfig config = getConnectionConfig();
			// only check password and superuser privileges if dbInfo is valid
			if (config.getDatabaseConfigInfo() != null)
			{
				// non-superusers can't get connection info for other users
				if (!getConnectionInfo(user, password).is_superuser)
					return new String[] { user };
			}
			// otherwise, return all connection names
			String[] connectionNames = config.getConnectionInfoNames().toArray(new String[0]);
			Arrays.sort(connectionNames, String.CASE_INSENSITIVE_ORDER);
			return connectionNames;
		}
		catch (RemoteException se)
		{
			return new String[] {};
		}
	}

	public ConnectionInfo getConnectionInfo(String loginUser, String loginPass, String userToGet)
		throws RemoteException
	{
		// non-superusers can't get connection info
		if (getConnectionInfo(loginUser, loginPass).is_superuser)
			return getConnectionConfig().getConnectionInfo(userToGet);
		return null;
	}

	public String saveConnectionInfo(
			String currentUser, String currentPass,
			String newUser, String dbms, String newPass,
			String folderName, boolean grantSuperuser, String connectString,
			boolean configOverwrite)
		throws RemoteException
	{
		if (newUser.equals(""))
			throw new RemoteException("Connection name cannot be empty.");

		ConnectionInfo newConnectionInfo = new ConnectionInfo();
		newConnectionInfo.name = newUser;
		newConnectionInfo.dbms = dbms;
		newConnectionInfo.pass = newPass;
		newConnectionInfo.folderName = folderName;
		newConnectionInfo.is_superuser = true;
		newConnectionInfo.connectString = connectString;

		// if there are existing connections and DatabaseConfigInfo exists,
		// check the password. otherwise, allow anything.
		ConnectionConfig config = getConnectionConfig();
		
		if (config.getConnectionInfoNames().size() > 0 && config.getDatabaseConfigInfo() != null)
		{
			authenticate(currentUser, currentPass);

			// non-superusers can't save connection info
			if (!config.getConnectionInfo(currentUser).is_superuser)
				throw new RemoteException(String.format(
						"User \"%s\" does not have permission to modify connections.", currentUser));
			// is_superuser for the new connection will only be false if there
			// is an existing superuser connection and grantSuperuser is false.
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
			throw new RemoteException(
					String.format("The connection named \"%s\" was not created because the server could not"
							+ " connect to the specified database with the given parameters.", newConnectionInfo.name),
					e);
		}
		finally
		{
			// close the connection, as we will not use it later
			SQLUtils.cleanup(conn);
		}

		// if the connection already exists AND overwrite == false throw error
		if (!configOverwrite && config.getConnectionInfoNames().contains(newConnectionInfo.name))
		{
			throw new RemoteException(String.format(
					"The connection named \"%s\" already exists.  Action cancelled.", newConnectionInfo.name));
		}

		// generate config connection entry
		try
		{
			// do not delete if this is the last user (which must be a
			// superuser)
			Collection<String> connectionNames = config.getConnectionInfoNames();

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
			if (currentUser == newUser && numSuperUsers == 1 && !newConnectionInfo.is_superuser)
				throw new RemoteException("Cannot remove superuser privileges from last remaining superuser.");

			config.removeConnectionInfo(newConnectionInfo.name);
			config.saveConnectionInfo(newConnectionInfo);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(String.format(
					"Unable to create connection entry named \"%s\": %s", newConnectionInfo.name, e.getMessage()), e);
		}

		return String.format("The connection named \"%s\" was created successfully.", newUser);
	}

	public String removeConnectionInfo(
			String loginUser, String loginPassword, String userToRemove)
		throws RemoteException
	{
		// allow only a superuser to remove a connection
		if (!getConnectionInfo(loginUser, loginPassword).is_superuser)
			throw new RemoteException("Only superusers can remove connections.");

		try
		{
			ConnectionConfig config = getConnectionConfig();
			
			if (config.getConnectionInfoNames().contains(userToRemove))
				throw new RemoteException("Connection \"" + userToRemove + "\" does not exist.");

			// check for number of superusers
			Collection<String> connectionNames = config.getConnectionInfoNames();
			int numSuperUsers = 0;
			for (String name : connectionNames)
				if (config.getConnectionInfo(name).is_superuser)
					++numSuperUsers;
			// do not allow removal of last superuser
			if (numSuperUsers == 1 && loginUser.equals(userToRemove))
				throw new RemoteException("Cannot remove the only superuser.");

			config.removeConnectionInfo(userToRemove);
			return "Connection \"" + userToRemove + "\" was deleted.";
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
	}

	//////////////////////////////////
	// DatabaseConfigInfo management
	
	public DatabaseConfigInfo getDatabaseConfigInfo(String user, String password)
		throws RemoteException
	{
		authenticate(user, password);
		return getConnectionConfig().getDatabaseConfigInfo();
	}

	public String setDatabaseConfigInfo(String user, String password, String schema)
		throws RemoteException
	{
		if (!getConnectionInfo(user, password).is_superuser)
			throw new RemoteException("Unable to store configuration information without superuser privileges.");
		
		// create info object
		DatabaseConfigInfo info = new DatabaseConfigInfo();
		info.schema = schema;
		info.connection = user;
		getConnectionConfig().setDatabaseConfigInfo(info);

		return String.format(
				"The admin console will now use the \"%s\" connection to store configuration information.",
				user);
	}

	//////////////////////////
	// DataEntity management
	
	public void addParentChildRelationship(String user, String password, int parentId, int childId, int insertAtIndex) throws RemoteException
	{
		tryModify(user, password, parentId);
		getDataConfig().buildHierarchy(parentId, childId, insertAtIndex);
	}

	public void removeParentChildRelationship(String user, String password, int parentId, int childId) throws RemoteException
	{
		tryModify(user, password, parentId);
		getDataConfig().removeChild(parentId, childId);
	}

	public int newEntity(String user, String password, int entityType, DataEntityMetadata meta, int parentId) throws RemoteException
	{
		tryModify(user, password, parentId);
		int new_id = getDataConfig().newEntity(entityType, meta);
        getDataConfig().addChild(parentId, new_id, DataConfig.NULL);
        return new_id;
        
	}

	public void removeEntity(String user, String password, int entityId) throws RemoteException
	{
		tryModify(user, password, entityId);
		getDataConfig().removeEntity(entityId);
	}

	public void updateEntity(String user, String password, int entityId, DataEntityMetadata diff) throws RemoteException
	{
		tryModify(user, password, entityId);
		getDataConfig().updateEntity(entityId, diff);
	}
	
	public DataEntityTableInfo[] getDataTableList(String user, String password) throws RemoteException
	{
		authenticate(user, password);
		return getDataConfig().getDataTableList();
	}

	public int[] getEntityChildIds(String user, String password, int parentId) throws RemoteException
	{
		authenticate(user, password);
		return ListUtils.toIntArray( getDataConfig().getChildIds(parentId) );
	}

	public int[] getEntityIdsByMetadata(String user, String password, DataEntityMetadata meta, int entityType) throws RemoteException
	{
		authenticate(user, password);
		return ListUtils.toIntArray( getDataConfig().getEntityIdsByMetadata(meta, entityType) );
	}

	public DataEntity[] getEntitiesById(String user, String password, int[] ids) throws RemoteException
	{
		authenticate(user, password);
		DataConfig config = getDataConfig();
		Set<Integer> idSet = new HashSet<Integer>();
		for (int id : ids)
			idSet.add(id);
		DataEntity[] result = config.getEntitiesById(idSet).toArray(new DataEntity[0]);
		for (int i = 0; i < result.length; i++)
		{
			int[] childIds = ListUtils.toIntArray( config.getChildIds(result[i].id) );
			result[i] = new DataEntityWithChildren(result[i], childIds);
		}
		return result;
	}

	///////////////////////
	// SQL info retrieval
	
	/**
	 * The following functions get information about the database associated with a given connection name.
	 */
	public String[] getSQLSchemaNames(String user, String password)
		throws RemoteException
	{
		try
		{
			Connection conn = getConnectionInfo(user, password).getStaticReadOnlyConnection();
			List<String> schemas = SQLUtils.getSchemas(conn);
			// don't want to list information_schema.
			ListUtils.removeIgnoreCase("information_schema", schemas);
			return ListUtils.toStringArray(getSortedUniqueValues(schemas, false));
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get schema list from database.", e);
		}
	}

	public String[] getSQLTableNames(String configConnectionName, String password, String schemaName)
		throws RemoteException
	{
		try
		{
			Connection conn = getConnectionInfo(configConnectionName, password).getStaticReadOnlyConnection();
			List<String> tables = SQLUtils.getTables(conn, schemaName);
			return ListUtils.toStringArray(getSortedUniqueValues(tables, false));
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get schema list from database.", e);
		}
	}

	public String[] getSQLColumnNames(String configConnectionName, String password, String schemaName, String tableName)
		throws RemoteException
	{
		try
		{
			Connection conn = getConnectionInfo(configConnectionName, password).getStaticReadOnlyConnection();
			List<String> columns = SQLUtils.getColumns(conn, schemaName, tableName);
			return ListUtils.toStringArray(columns);
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to get column list from database.", e);
		}
	}

	/////////////////
	// File uploads

	/**
	 * This function accepts an uploaded file.
	 * 
	 * @param fileName The name of the file.
	 * @param content The file content.
	 * @param append Set to true to append to an existing file.
	 */
	public void uploadFile(String fileName, InputStream content, boolean append)
		throws RemoteException
	{
		// make sure the upload folder exists
		(new File(getUploadPath())).mkdirs();

		String filePath = getUploadPath() + fileName;
		try
		{
			FileUtils.copy(content, new FileOutputStream(filePath, append));
		}
		catch (Exception e)
		{
			throw new RemoteException("File upload failed.", e);
		}
	}

	public UploadedFile[] getUploadedCSVFiles()
		throws RemoteException
	{
		File directory = new File(getUploadPath());
		List<UploadedFile> list = new ArrayList<UploadedFile>();
		File[] listOfFiles = null;

		try
		{
			if (directory.isDirectory())
			{
				listOfFiles = directory.listFiles(new UploadFileFilter("csv"));
				for (File file : listOfFiles)
				{
					if (file.isFile())
					{
						UploadedFile uploadedFile = new UploadedFile(file.getName(), file.length(), file.lastModified());
						list.add(uploadedFile);
					}
				}
			}
		}
		catch (Exception e)
		{
			throw new RemoteException(e.getMessage());
		}

		int n = list.size();
		return list.toArray(new UploadedFile[n]);
	}

	public UploadedFile[] getUploadedSHPFiles()
		throws RemoteException
	{
		File directory = new File(getUploadPath());
		List<UploadedFile> list = new ArrayList<UploadedFile>();
		File[] listOfFiles = null;

		try
		{
			if (directory.isDirectory())
			{
				listOfFiles = directory.listFiles(new UploadFileFilter("shp"));
				for (File file : listOfFiles)
				{
					if (file.isFile())
					{
						UploadedFile uploadedFile = new UploadedFile(file.getName(), file.length(), file.lastModified());
						list.add(uploadedFile);
					}
				}
			}
		}
		catch (Exception e)
		{
			throw new RemoteException(e.getMessage());
		}

		int n = list.size();
		return list.toArray(new UploadedFile[n]);
	}

	/**
	 * Read a list of csv files and return common header columns.
	 * 
	 * @param A list of csv file names.
	 * @return A list of common header files or null if none exist encoded using
	 * 
	 */
	public String[] getCSVColumnNames(String csvFile)
		throws RemoteException
	{
		String[] headerLine = null;

		try
		{
			BufferedReader in = new BufferedReader(new FileReader(new File(getUploadPath(), csvFile)));
			String header = in.readLine();
			String[][] rows = CSVParser.defaultParser.parseCSV(header, true);
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

	public String[] getDBFColumnNames(String dbfFileName)
		throws RemoteException
	{
		try
		{
			List<String> names = DBFUtils.getAttributeNames(new File(getUploadPath(), correctFileNameCase(dbfFileName)));
			return ListUtils.toStringArray(names);
		}
		catch (IOException e)
		{
			throw new RemoteException("IOException", e);
		}
	}

	public Object[][] getDBFData(String dbfFileName)
		throws RemoteException
	{
		try
		{
			Object[][] dataArray = DBFUtils.getDBFData(new File(getUploadPath(), correctFileNameCase(dbfFileName)));
			return dataArray;
		}
		catch (IOException e)
		{
			throw new RemoteException("IOException", e);
		}
	}

	private String correctFileNameCase(String fileName)
	{
		try
		{
			File directory = new File(getUploadPath());

			if (directory.isDirectory())
			{
				for (String file : directory.list())
				{
					if (file.equalsIgnoreCase(fileName))
						return file;
				}
			}
		}
		catch (Exception e)
		{
		}
		return fileName;
	}

	/////////////////////////////////
	// Key column uniqueness checks

	/**
	 * getSortedUniqueValues
	 * 
	 * @param values A list of string values which may contain duplicates.
	 * @param moveEmptyStringToEnd If set to true and "" is at the front of the list, "" is moved to the end.
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
	
	public boolean checkKeyColumnForSQLImport(
			String connectionName, String password, String schemaName, String tableName, String keyColumnName,
			String secondaryKeyColumnName)
		throws RemoteException
	{
		ConnectionInfo info = getConnectionInfo(connectionName, password);
		
		if (info == null)
			throw new RemoteException(String.format("Connection named \"%s\" does not exist.", connectionName));

		Boolean isUnique = true;
		Connection conn = null;
		try
		{
			conn = info.getConnection();
			
			List<String> columnNames = SQLUtils.getColumns(conn, schemaName, tableName);
	
			// if key column is actually the name of a column, put quotes around it.
			// otherwise, don't.
			int iKey = ListUtils.findIgnoreCase(keyColumnName, columnNames);
			int iSecondaryKey = ListUtils.findIgnoreCase(secondaryKeyColumnName, columnNames);
	
			if (iKey >= 0)
			{
				keyColumnName = SQLUtils.quoteSymbol(conn, columnNames.get(iKey));
			}
			else
			{
				// get the original column name
				keyColumnName = SQLUtils.unquoteSymbol(conn, keyColumnName);
			}
	
			if (iSecondaryKey >= 0)
				secondaryKeyColumnName = SQLUtils.quoteSymbol(conn, columnNames.get(iSecondaryKey));

			if (secondaryKeyColumnName == null || secondaryKeyColumnName.isEmpty())
			{
				String totalRowsQuery = String.format(
						"select count(%s) from %s", keyColumnName, SQLUtils.quoteSchemaTable(
								conn, schemaName, tableName));
				SQLResult totalRowsResult = SQLUtils.getResultFromQuery(conn, totalRowsQuery, null, false);

				String distinctRowsQuery = String.format(
						"select count(distinct %s) from %s", keyColumnName, SQLUtils.quoteSchemaTable(
								conn, schemaName, tableName));
				SQLResult distinctRowsResult = SQLUtils.getResultFromQuery(conn, distinctRowsQuery, null, false);
				isUnique = distinctRowsResult.rows[0][0].equals(totalRowsResult.rows[0][0]);
			}
			else
			{
				String query = String.format(
						"select %s,%s from %s", keyColumnName, secondaryKeyColumnName, SQLUtils.quoteSchemaTable(
								conn, schemaName, tableName));

				SQLResult result = SQLUtils.getResultFromQuery(conn, query, null, false);
				Set<String> keySet = new HashSet<String>();
				for (int i = 0; i < result.rows.length; i++)
				{
					String key = result.rows[i][0].toString() + ',' + result.rows[i][1].toString();
					if (keySet.contains(key))
					{
						isUnique = false;
						break;
					}
					keySet.add(key);
				}
			}

		}
		catch (Exception e)
		{
			throw new RemoteException("Error querying key columns", e);
		}
		finally
		{
			SQLUtils.cleanup(conn);
		}

		return isUnique;
	}
	
	/**
	 * Check if selected key column from CSV data has unique values
	 * 
	 * @param csvFile The CSV file to check
	 * 
	 * @param keyColumn The column name to check for unique values
	 * 
	 * @return A list of common header files or null if none exist encoded using
	 * 
	 */
	public Boolean checkKeyColumnForCSVImport(String csvFile, String keyColumn, String secondaryKeyColumn)
		throws RemoteException
	{

		Boolean isUnique = true;
		try
		{
			String[] headers = getCSVColumnNames(csvFile);

			int keyColIndex = 0;
			int secKeyColIndex = 0;

			for (int i = 0; i < headers.length; i++)
			{
				if (headers[i].equals(keyColumn))
				{
					keyColIndex = i;
					break;
				}
			}

			String[][] rows = CSVParser.defaultParser.parseCSV(new File(getUploadPath(), csvFile), true);

			HashMap<String, Boolean> map = new HashMap<String, Boolean>();
			
			if (secondaryKeyColumn == null)
			{
				
				for (int i = 1; i < rows.length; i++)
				{
					String key = rows[i][keyColIndex].toString();
					if (map.get(key) == null)
					{
						map.put(key, true);
					}
					else
					{
						System.out.println(String.format("Duplicate key: \"%s\" in column %s/%s, row %s of %s", key, csvFile, keyColumn, i, rows.length));
						System.out.println(Arrays.asList(rows[i]));
						isUnique = false;
						break;
					}

				}
			}
			else
			{
				for (int i = 0; i < headers.length; i++)
				{
					if (headers[i].equals(secondaryKeyColumn))
					{
						secKeyColIndex = i;
						break;
					}
				}
				
				
				for(int i = 0; i < rows.length; i++)
				{
					String key = rows[i][keyColIndex].toString() + ',' + rows[i][secKeyColIndex].toString();
					if (map.get(key) == null)
					{
						map.put(key, true);
					}
					else
					{
						System.out.println(String.format("Duplicate key: \"%s\" in column %s/%s/%s, row %s of %s", key, csvFile, keyColumn, secondaryKeyColumn, i, rows.length));
						System.out.println(Arrays.asList(rows[i]));
						isUnique = false;
						break;
					}

				}
			}
		}
		catch (FileNotFoundException e)
		{
			throw new RemoteException(e.getMessage());
		}
		catch (Exception e)
		{
			throw new RemoteException(e.getMessage());
		}

		return isUnique;
	}
	
	////////////////
	// Data import

	private boolean valueIsInt(String value)
	{
		boolean retVal = true;
		try
		{
			Integer.parseInt(value);
		}
		catch (Exception e)
		{
			retVal = false;
		}
		return retVal;
	}

	private boolean valueIsDouble(String value)
	{
		boolean retVal = true;
		try
		{
			Double.parseDouble(value);
		}
		catch (Exception e)
		{
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

	public String importCSV(
			String connectionName, String password, String csvFile, String csvKeyColumn, String csvSecondaryKeyColumn,
			String sqlSchema, String sqlTable, boolean sqlOverwrite, String configDataTableName,
			boolean configOverwrite, String configKeyType, String[] nullValues,
			String[] filterColumnNames)
		throws RemoteException
	{
		ConnectionInfo connInfo = getConnectionInfo(connectionName, password);
		DataConfig dataConfig = getDataConfig();
		
		final int StringType = 0;
		final int IntType = 1;
		final int DoubleType = 2;
		
		if (sqlOverwrite && !connInfo.is_superuser)
			throw new RemoteException(String.format(
					"User \"%s\" does not have permission to overwrite SQL tables.", connectionName));

		Connection conn = null;
		Statement stmt = null;
		try
		{
			conn = connInfo.getConnection();

			sqlTable = sqlTable.toLowerCase(); // bug fix for MySQL running under Linux

			String[] columnNames = null;
			String[] originalColumnNames = null;
			int fieldLengths[] = null;

			// Load the CSV file and reformat it
			int[] types = null;
			int i = 0;
			int j = 0;
			int num = 1;

			boolean ignoreKeyColumnQueries = false;

			String[][] rows = CSVParser.defaultParser.parseCSV(new File(getUploadPath(), csvFile), true);

			if (rows.length == 0)
				throw new RemoteException("CSV file is empty: " + csvFile);

			// if there is no key column, we need to append a unique Row ID
			// column
			if ("".equals(csvKeyColumn))
			{
				ignoreKeyColumnQueries = true;
				// get the maximum number of rows in a column
				int maxNumRows = 0;
				for (i = 0; i < rows.length; ++i)
				{
					String[] column = rows[i];
					int numRows = column.length; // this includes the column
													// name in row 0
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
					colName = "Column " + (i + 1);
				// save original column name
				originalColumnNames[i] = colName;
				// if the column name has "/", "\", ".", "<", ">".
				colName = colName.replace("/", "");
				colName = colName.replace("\\", "");
				colName = colName.replace(".", "");
				colName = colName.replace("<", "less than");
				colName = colName.replace(">", "more than");
				// if the length of the column name is longer than the
				// 64-character limit
				int maxColNameLength = 64 - 4; // leave space for "_123" if
												// there end up being duplicate
												// column names
				boolean isKeyCol = csvKeyColumn.equalsIgnoreCase(colName);
				// if name too long, remove spaces
				if (colName.length() > maxColNameLength)
					colName = colName.replace(" ", "");
				// if still too long, truncate
				if (colName.length() > maxColNameLength)
				{
					int half = maxColNameLength / 2 - 1;
					colName = colName.substring(0, half) + "_" + colName.substring(colName.length() - half);
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

			// Initialize the types of columns as int (will be changed inside
			// loop if necessary)
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
					// keep track of the longest String value found in this
					// column
					fieldLengths[i] = Math.max(fieldLengths[i], nextLine[i].length());

					// Change missing data into NULL, later add more cases to
					// deal with missing data.
					String[] nullValuesStandard = new String[] {
							"", ".", "..", " ", "-", "\"NULL\"", "NULL", "NaN" };
					ALL_NULL_VALUES: for (String[] values : new String[][] {
							nullValuesStandard, nullValues })
					{
						for (String nullValue : values)
						{
							if (nextLine[i] != null && nextLine[i].equalsIgnoreCase(nullValue))
							{
								nextLine[i] = null;

								break ALL_NULL_VALUES;
							}
						}
					}
					if (nextLine[i] == null)
						continue;

					// 04 is a string (but Integer.parseInt would not throw an exception)
					try
					{
						String value = nextLine[i];
						while (value.indexOf(',') > 0)
							value = value.replace(",", ""); // valid input
															// format

						// if the value is an int or double with an extraneous
						// leading zero, it's defined to be a string
						if (valueHasLeadingZero(value))
							types[i] = StringType;

						// if the type was determined to be a string before (or
						// just above), continue
						if (types[i] == StringType)
							continue;

						// if the type is an int
						if (types[i] == IntType)
						{
							// check that it's still an int
							if (valueIsInt(value))
								continue;
						}

						// it either wasn't an int or is no longer an int, check
						// for a double
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

			// now we need to remove commas from any numeric values because the
			// SQL drivers don't like it
			for (int iRow = 1; iRow < rows.length; iRow++)
			{
				String[] nextLine = rows[iRow];
				// Format each line
				for (i = 0; i < columnNames.length && i < nextLine.length; i++)
				{
					if (nextLine[i] == null)
						continue;
					String value = nextLine[i];
					if (types[i] == IntType || types[i] == DoubleType)
					{
						while (value.indexOf(",") >= 0)
							value = value.replace(",", "");
						nextLine[i] = value;
					}
				}
			}
			// Import the CSV file into SQL.
			// Drop the table if it exists.
			if (sqlOverwrite)
			{
				SQLUtils.dropTableIfExists(conn, sqlSchema, sqlTable);
			}
			else
			{
				if (ListUtils.findIgnoreCase(sqlTable, getSQLTableNames(connectionName, password, sqlSchema)) >= 0)
					throw new RemoteException("CSV not imported.\nSQL table already exists.");
			}

			if (!configOverwrite)
			{
				/* Get list of unique values common among datatables only. */
				List<String> uniqueNames = new LinkedList<String>();
				for (DataEntity de : dataConfig.getEntitiesById(dataConfig.getEntityIdsByMetadata(null, DataEntity.TYPE_DATATABLE)))
					uniqueNames.add(de.publicMetadata.get(PublicMetadata.TITLE));

				if (ListUtils.findIgnoreCase(configDataTableName, uniqueNames) >= 0)
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
			SQLUtils.createTable(conn, sqlSchema, sqlTable, Arrays.asList(columnNames), columnTypesList, null);

			
			// import the data
			BulkSQLLoader loader = BulkSQLLoader.newInstance(conn, sqlSchema, sqlTable, columnNames);
			for (Object[] row : rows)
				loader.addRow(row);
			loader.flush();

			return addConfigDataTable(
					configDataTableName, connectionName,
					configKeyType, csvKeyColumn, csvSecondaryKeyColumn, originalColumnNames, columnNames, sqlSchema,
					sqlTable, ignoreKeyColumnQueries, filterColumnNames);
		}
		catch (RemoteException e) // required since RemoteException extends
									// IOException
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

	public String importSQL(
			String connectionName, String password, String schemaName, String tableName, String keyColumnName,
			String secondaryKeyColumnName, String configDataTableName,
			String keyType, String[] filterColumnNames)
		throws RemoteException
	{
		authenticate(connectionName, password);
		String[] columnNames = getSQLColumnNames(connectionName, password, schemaName, tableName);
		return addConfigDataTable(
				configDataTableName, connectionName, keyType,
				keyColumnName, secondaryKeyColumnName, columnNames, columnNames, schemaName, tableName, false,
				filterColumnNames);
	}

	private String addConfigDataTable(
			String configDataTableName, String connectionName,
			String keyType, String keyColumnName, String secondarySqlKeyColumn,
			String[] configColumnNames, String[] sqlColumnNames, String sqlSchema, String sqlTable,
			boolean ignoreKeyColumnQueries, String[] filterColumnNames)
		throws RemoteException
	{
		//TODO: return table ID
		
		DataConfig dataConfig = getDataConfig();
		ConnectionConfig connConfig = getConnectionConfig();
		
		String failMessage = String.format(
				"Failed to add DataTable \"%s\" to the configuration.\n", configDataTableName);
		if (sqlColumnNames == null || sqlColumnNames.length == 0)
			throw new RemoteException("No columns were found.");
		ConnectionInfo connInfo = getConnectionConfig().getConnectionInfo(connectionName);
		if (connInfo == null)
			throw new RemoteException(String.format("Connection named \"%s\" does not exist.", connectionName));
		String dbms = connInfo.dbms;

		// if key column is actually the name of a column, put quotes around it.
		// otherwise, don't.
		int iKey = ListUtils.findIgnoreCase(keyColumnName, sqlColumnNames);
		int iSecondaryKey = ListUtils.findIgnoreCase(secondarySqlKeyColumn, sqlColumnNames);

		String sqlKeyColumn; // save the original column name
		if (iKey >= 0)
		{
			sqlKeyColumn = keyColumnName; // before quoting, save the column
											// name
			keyColumnName = SQLUtils.quoteSymbol(dbms, sqlColumnNames[iKey]);
		}
		else
		{
			sqlKeyColumn = SQLUtils.unquoteSymbol(dbms, keyColumnName); // get
																		// the
																		// original
																		// columnname
		}

		if (iSecondaryKey >= 0)
			secondarySqlKeyColumn = SQLUtils.quoteSymbol(dbms, sqlColumnNames[iSecondaryKey]);
		// Write SQL statements into sqlconfig.

		List<String> uniqueNames = new LinkedList<String>();
		for (DataEntity de : dataConfig.getEntitiesById(dataConfig.getEntityIdsByMetadata(null, DataEntity.TYPE_DATATABLE)))
			uniqueNames.add(de.publicMetadata.get(PublicMetadata.TITLE));
		if (ListUtils.findIgnoreCase(configDataTableName, uniqueNames) >= 0)
			throw new RemoteException(String.format(
					"DataTable \"%s\" already exists in the configuration.", configDataTableName));

		// connect to database, generate and test each query before modifying
		// config file
		List<String> titles = new LinkedList<String>();
		List<String> queries = new Vector<String>();
		List<Object[]> queryParamsList = new Vector<Object[]>();
		List<String> dataTypes = new Vector<String>();
		String query = null;
		Connection conn = connConfig.getConnectionInfo(connectionName).getStaticReadOnlyConnection();
		try
		{
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
				query = String.format("select distinct %s from %s order by %s", columnList, SQLUtils.quoteSchemaTable(
						conn, sqlSchema, sqlTable), columnList);
				filteredValues = SQLUtils.getResultFromQuery(conn, query, null, true);
				// System.out.println(query);
				// System.out.println(filteredValues);
			}
			for (int iCol = 0; iCol < sqlColumnNames.length; iCol++)
			{
				String sqlColumn = sqlColumnNames[iCol];
				// System.out.println("columnName: " + columnName +
				// "\tkeyColumnName: " + keyColumnName + "\toriginalKeyCol: " +
				// originalKeyColumName);
				if (ignoreKeyColumnQueries && sqlKeyColumn.equals(sqlColumn))
					continue;
				sqlColumn = SQLUtils.quoteSymbol(dbms, sqlColumn);

				// hack
				if (secondarySqlKeyColumn != null && secondarySqlKeyColumn.length() > 0)
					sqlColumn += "," + secondarySqlKeyColumn;

				// generate column query
				query = String.format("SELECT %s,%s FROM %s", keyColumnName, sqlColumn, SQLUtils.quoteSchemaTable(
						dbms, sqlSchema, sqlTable));

				if (filteredValues != null)
				{
					// generate one query per unique filter value combination
					for (int iRow = 0; iRow < filteredValues.rows.length; iRow++)
					{
						String filteredQuery = buildFilteredQuery(conn, query, filteredValues.columnNames);
						titles.add(buildFilteredColumnTitle(configColumnNames[iCol], filteredValues.rows[iRow]));
						queries.add(filteredQuery);
						queryParamsList.add(filteredValues.rows[iRow]);
						dataTypes.add(testQueryAndGetDataType(conn, filteredQuery, filteredValues.rows[iRow]));
					}
				}
				else
				{
					titles.add(configColumnNames[iCol]);
					queries.add(query);
					dataTypes.add(testQueryAndGetDataType(conn, query, null));
				}
			}
			// done generating queries

			DataEntityMetadata tableProperties = new DataEntityMetadata();
			tableProperties.publicMetadata.put(PublicMetadata.TITLE, configDataTableName);
			int table_id = dataConfig.newEntity(DataEntity.TYPE_DATATABLE, tableProperties);

			for (int i = 0; i < titles.size(); i++)
			{
				DataEntityMetadata newMeta = new DataEntityMetadata();
				newMeta.privateMetadata.put(PrivateMetadata.CONNECTION, connectionName);
				newMeta.privateMetadata.put(PrivateMetadata.SQLQUERY, queries.get(i));
				if (filteredValues != null)
				{
					String paramsStr = CSVParser.defaultParser.createCSVRow(queryParamsList.get(i), true);
					newMeta.privateMetadata.put(PrivateMetadata.SQLPARAMS, paramsStr);
				}
				newMeta.publicMetadata.put(PublicMetadata.KEYTYPE, keyType);
				newMeta.publicMetadata.put(PublicMetadata.TITLE, titles.get(i));
				newMeta.publicMetadata.put(PublicMetadata.DATATYPE, dataTypes.get(i));

				int col_id = dataConfig.newEntity(DataEntity.TYPE_COLUMN, newMeta);
                dataConfig.addChild(table_id, col_id, 0);
			}
		}
		catch (SQLException e)
		{
			throw new RemoteException(failMessage, e);
		}
		catch (RemoteException e)
		{
			throw new RemoteException(failMessage, e);
		}
		catch (IOException e)
		{
			throw new RemoteException(failMessage, e);
		}

		return String.format(
				"DataTable \"%s\" was added to the configuration with %s generated attribute column queries.\n",
				configDataTableName, titles.size());
	}

	/**
	 * @param conn An active SQL connection used to test the query.
	 * @param query SQL query which may contain '?' marks for parameters.
	 * @param params Optional list of parameters to pass to the SQL query. May be null.
	 * @return The Weave dataType metadata value to use, based on the result of the SQL query.
	 */
	private String testQueryAndGetDataType(Connection conn, String query, Object[] params)
		throws RemoteException
	{
		CallableStatement cstmt = null;
		Statement stmt = null;
		ResultSet rs = null;
		String dataType = null;
		try
		{
			String dbms = conn.getMetaData().getDatabaseProductName();
			if (!dbms.equalsIgnoreCase(SQLUtils.SQLSERVER) && !dbms.equalsIgnoreCase(SQLUtils.ORACLE))
				query += " LIMIT 1";

			if (params == null || params.length == 0)
			{
				// We have to use Statement when there are no parameters,
				// because CallableStatement
				// will fail in Microsoft SQL Server with
				// "Incorrect syntax near the keyword 'SELECT'".
				stmt = conn.createStatement();
				rs = stmt.executeQuery(query);
			}
			else
			{
				cstmt = conn.prepareCall(query);
				for (int i = 0; i < params.length; i++)
					cstmt.setObject(i + 1, params[i]);
				rs = cstmt.executeQuery();
			}

			dataType = DataType.fromSQLType(rs.getMetaData().getColumnType(2));
		}
		catch (SQLException e)
		{
			throw new RemoteException("Unable to execute generated query:\n" + query, e);
		}
		finally
		{
			SQLUtils.cleanup(rs);
			SQLUtils.cleanup(cstmt);
			SQLUtils.cleanup(stmt);
		}

		return dataType;
	}

	private String buildFilteredColumnTitle(String columnName, Object[] filterValues)
	{
		String columnTitle = columnName + " (";
		for (int j = 0; j < filterValues.length; j++)
		{
			if (j > 0)
				columnTitle += " ";
			columnTitle += filterValues[j] == null
					? "NULL" : filterValues[j].toString();
		}
		columnTitle += ")";
		return columnTitle;
	}

	private String buildFilteredQuery(Connection conn, String unfilteredQuery, String[] columnNames)
		throws IllegalArgumentException, SQLException
	{
		String query = unfilteredQuery + " where ";
		for (int j = 0; j < columnNames.length; j++)
		{
			if (j > 0)
				query += " and ";
			query += SQLUtils.caseSensitiveCompare(conn, SQLUtils.quoteSymbol(conn, columnNames[j]), "?");
		}
		return query;
	}

	/**
	 * The following functions involve getting shapes into the database and into the config file.
	 */

	public String importSHP(
			String configConnectionName, String password, String[] fileNameWithoutExtension, String[] keyColumns,
			String sqlSchema, String sqlTablePrefix, boolean sqlOverwrite, String configTitle,
			String configKeyType, String projectionSRS, String[] nullValues, boolean importDBFData)
		throws RemoteException
	{
		ConnectionInfo connInfo = getConnectionInfo(configConnectionName, password);
		
		// use lower case sql table names (fix for mysql linux problems)
		sqlTablePrefix = sqlTablePrefix.toLowerCase();


		if (sqlOverwrite && !connInfo.is_superuser)
			throw new RemoteException(String.format(
					"User \"%s\" does not have permission to overwrite SQL tables.", configConnectionName));

		String dbfTableName = sqlTablePrefix + "_dbfdata";
		Connection conn = null;
		try
		{
			conn = connInfo.getConnection();
			// store dbf data to database
			if (importDBFData)
			{
				importDBF(
						configConnectionName, password, fileNameWithoutExtension, sqlSchema, dbfTableName,
						sqlOverwrite, nullValues);
			}

			GeometryStreamConverter converter = new GeometryStreamConverter(new SQLGeometryStreamDestination(
					conn, sqlSchema, sqlTablePrefix, sqlOverwrite));
			for (String file : fileNameWithoutExtension)
			{
				// convert shape data to streaming sql format
				String shpfile = getUploadPath() + file + ".shp";
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

		String resultAddSQL = "";
		if (importDBFData)
		{

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
			String[] columnNames = getSQLColumnNames(configConnectionName, password, sqlSchema, dbfTableName);
			resultAddSQL = addConfigDataTable(
					configTitle, configConnectionName,
					configKeyType, keyColumnsString, null, columnNames, columnNames,
					sqlSchema, dbfTableName, false, null);
		}
		else
		{
			resultAddSQL = "DBF Import disabled.";
		}

		try
		{
			// add geometry column
			DataEntityMetadata geomInfo = new DataEntityMetadata();
	
			geomInfo.privateMetadata.put(PrivateMetadata.CONNECTION, configConnectionName);
			geomInfo.privateMetadata.put(PrivateMetadata.SQLSCHEMA, sqlSchema);
			geomInfo.privateMetadata.put(PrivateMetadata.SQLTABLEPREFIX, sqlTablePrefix);
			geomInfo.privateMetadata.put(PrivateMetadata.FILENAME, CSVParser.defaultParser.createCSVRow(fileNameWithoutExtension, true));
			geomInfo.privateMetadata.put(PrivateMetadata.KEYCOLUMN, CSVParser.defaultParser.createCSVRow(keyColumns, true));
	
			geomInfo.publicMetadata.put(PublicMetadata.TITLE, configTitle);
			geomInfo.publicMetadata.put(PublicMetadata.KEYTYPE, configKeyType);
			geomInfo.publicMetadata.put(PublicMetadata.PROJECTION, projectionSRS);
	
			// TODO: use table ID from addConfigDataTable()
			getDataConfig().newEntity(DataEntity.TYPE_COLUMN, geomInfo);
		}
		catch (IOException e)
		{
			throw new RemoteException("Unexpected error",e);
		}

		return resultAddSQL;
	}

	public String importDBF(
			String configConnectionName, String password, String[] fileNameWithoutExtension, String sqlSchema,
			String sqlTableName, boolean sqlOverwrite, String[] nullValues)
		throws RemoteException
	{
		ConnectionInfo info = getConnectionInfo(configConnectionName, password);
		
		// use lower case sql table names (fix for mysql linux problems)
		sqlTableName = sqlTableName.toLowerCase();

		if (sqlOverwrite && !info.is_superuser)
			throw new RemoteException(String.format(
					"User \"%s\" does not have permission to overwrite SQL tables.", configConnectionName));

		Connection conn = null;
		try
		{
			conn = info.getConnection();
			File[] files = new File[fileNameWithoutExtension.length];
			for (int i = 0; i < files.length; i++)
				files[i] = new File(getUploadPath() + fileNameWithoutExtension[i] + ".dbf");

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
	
	//////////////////////
	// SQL query testing

	/**
	 * Returns the results of testing attribute column sql queries.
	 */
	public DataEntity[] testAllQueries(String user, String password, int table_id)
		throws RemoteException
	{
		authenticate(user, password);
		DataConfig config = getDataConfig();
		Collection<Integer> ids = config.getChildIds(table_id);
		DataEntity[] columns = config.getEntitiesById(ids).toArray(new DataEntity[0]);
		for (DataEntity entity : columns)
		{
			try
			{
				String connName = entity.privateMetadata.get(PrivateMetadata.CONNECTION);
				String query = entity.privateMetadata.get(PrivateMetadata.SQLQUERY);
				String sqlParams = entity.privateMetadata.get(PrivateMetadata.SQLPARAMS);
				System.out.println(query);
				SQLResult result;
				Connection conn = getConnectionConfig().getConnectionInfo(connName).getStaticReadOnlyConnection();

				String[] sqlParamsArray = null;
				if (sqlParams != null && sqlParams.length() > 0)
					sqlParamsArray = CSVParser.defaultParser.parseCSV(sqlParams, true)[0];
				
				result = SQLUtils.getResultFromQuery(conn, query, sqlParamsArray, false);

				entity.privateMetadata.put(PrivateMetadata.SQLRESULT, String.format(
						"Returned %s rows", result.rows.length));
			}
			catch (Exception e)
			{
				e.printStackTrace();
				entity.privateMetadata.put(PrivateMetadata.SQLRESULT, e.getMessage());
			}
		}
		return columns;
	}

	//////////////////
	// Miscellaneous

	public String[] getKeyTypes()
		throws RemoteException
	{
		return getDataConfig().getUniquePublicValues(PublicMetadata.KEYTYPE).toArray(new String[0]);
	}
}

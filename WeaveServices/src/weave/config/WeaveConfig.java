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

package weave.config;

import java.io.File;
import java.rmi.RemoteException;

import weave.utils.BulkSQLLoader;
import weave.utils.MapUtils;
import weave.utils.ProgressManager;

/**
 * @author adufilie
 */
public class WeaveConfig
{
	private static WeaveContextParams weaveContextParams = null;
	private static ConnectionConfig _connConfig;
	private static DataConfig _dataConfig;
	
	public static void initWeaveConfig(WeaveContextParams wcp)
	{
		if (weaveContextParams == null)
		{
			weaveContextParams = wcp;
			BulkSQLLoader.temporaryFilesDirectory = new File(getUploadPath());
		}
	}
	
	public static WeaveContextParams getWeaveContextParams()
	{
		return weaveContextParams;
	}
	
	public static final String ALLOW_R_SCRIPT_ACCESS = "allow-r-script-access";
	public static final String ALLOW_RSERVE_ROOT_ACCESS = "allow-rserve-root-access";
	private static LiveProperties properties;
	public static String getProperty(String key)
	{
		if (properties == null)
		{
			if (weaveContextParams == null)
				return null;
			properties = new LiveProperties(
				new File(weaveContextParams.getConfigPath(), "config.properties"),
				MapUtils.<String,String>fromPairs(
					ALLOW_R_SCRIPT_ACCESS, "false"
				)
			);
		}
		return properties.getProperty(key);
	}
	public static boolean getPropertyBoolean(String key)
	{
		String value = getProperty(key);
		return value != null && value.equalsIgnoreCase("true");
	}
	
	public static String getConnectionConfigFilePath()
	{
		if (weaveContextParams == null)
			return null;
		return weaveContextParams.getConfigPath() + "/" + ConnectionConfig.XML_FILENAME;
	}
	
	synchronized public static ConnectionConfig getConnectionConfig() throws RemoteException
	{
		if (_connConfig == null)
			_connConfig = new ConnectionConfig(new File(getConnectionConfigFilePath()));
		return _connConfig;
	}
	
	synchronized public static DataConfig getDataConfig() throws RemoteException
	{
		ConnectionConfig cc = getConnectionConfig();
		if (_dataConfig == null)
			_dataConfig = new DataConfig(cc);
		return _dataConfig;
	}

	/**
	 * This function should be the first thing called by the Admin Console to initialize the servlet.
	 * If SQL config data migration is required, it will be done and periodic status updates will be written to the output stream.
	 * @param progress Used to output SQL config data migration status updates.
	 * @throws RemoteException Thrown when the DataConfig could not be initialized.
	 */
	synchronized public static void initializeAdminService(ProgressManager progress) throws RemoteException
	{
		ConnectionConfig cc = getConnectionConfig();
		if (cc.migrationPending())
		{
			_dataConfig = null; // set to null first in case next line fails
			_dataConfig = cc.initializeNewDataConfig(progress);
		}
	}
	
	public static String getDocrootPath()
	{
		if (weaveContextParams == null)
			return null;
		return weaveContextParams.getDocrootPath();
	}
	
	public static String getUploadPath()
	{
		if (weaveContextParams == null)
			return null;
		return weaveContextParams.getUploadPath();
	}
}

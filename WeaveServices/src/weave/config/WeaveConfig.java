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
import java.io.OutputStream;
import java.io.PrintStream;
import java.rmi.RemoteException;

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
			weaveContextParams = wcp;
	}
	
	public static WeaveContextParams getWeaveContextParams()
	{
		return weaveContextParams;
	}
	
	public static ConnectionConfig getConnectionConfig() throws RemoteException
	{
		synchronized(_connConfig)
		{
			if (_connConfig == null)
				_connConfig = new ConnectionConfig(new File(weaveContextParams.getConfigPath() + "/" + ConnectionConfig.XML_FILENAME));
		}
		return _connConfig;
	}
	
	public static DataConfig getDataConfig() throws RemoteException
	{
		ConnectionConfig cc = getConnectionConfig();
		synchronized(_dataConfig)
		{
			if (_dataConfig == null)
				_dataConfig = new DataConfig(cc);
		}
		return _dataConfig;
	}

	/**
	 * This function should be the first thing called by the Admin Console to initialize the servlet.
	 * If SQL config data migration is required, it will be done and periodic status updates will be written to the output stream.
	 * @param out A stream used to output SQL config data migration status updates.
	 * @throws RemoteException Thrown when the DataConfig could not be initialized.
	 */
	public static void initializeAdminService(OutputStream out) throws RemoteException
	{
		ConnectionConfig cc = getConnectionConfig();
		synchronized(_dataConfig)
		{
			if (_dataConfig == null)
				_dataConfig = cc.initializeNewDataConfig(new PrintStream(out));
		}
	}
	
	public static String getDocrootPath()
	{
		return weaveContextParams.getDocrootPath();
	}
	
	public static String getUploadPath()
	{
		return weaveContextParams.getUploadPath();
	}
	
	public static String getTempPath()
	{
		return weaveContextParams.getTempPath();
	}
}

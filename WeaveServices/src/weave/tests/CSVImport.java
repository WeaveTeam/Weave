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
package weave.tests;

import java.io.File;
import java.rmi.RemoteException;

import weave.config.ISQLConfig;
import weave.config.SQLConfigManager;
import weave.config.WeaveContextParams;
import weave.servlets.AdminService;

public class CSVImport
{
	/**
	 * @param args
	 * @throws Exception
	 */
	public static void main(String[] args) throws Exception
	{
		File file = new File("FULLPATHTOFILE");
		System.out.println(file.getAbsolutePath());
		
		String _configPath = "\\tomcat\\webapps\\weave-config";
		String _docrootPath = "\\tomcat\\webapps\\ROOT";
		SQLConfigManager configManager = new SQLConfigManager(new WeaveContextParams(_configPath,_docrootPath));
		ISQLConfig config = configManager.getConfig();

		if (config == null)
			throw new RemoteException("config is null");

		AdminService as = new AdminService(configManager);
		//as.init2(); // un-comment this to run the test
		as.importCSV("<USER>", "<PASSWORD>", file.getPath(), "KEY", "", "weave", "tablename", true, "dataTable", true, "", "", (new String[] {""}), null, (new String[] {""}));
	}
}

package weave.servlets;

import static weave.config.WeaveConfig.initWeaveConfig;

import java.rmi.RemoteException;
import java.sql.SQLException;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.servlets.WeaveServlet;

import weave.config.WeaveContextParams;
import weave.interfaces.IScriptEngine;
import weave.models.AwsProjectService;


public class DataManagementServlet extends WeaveServlet implements IScriptEngine
{	
	private static final long serialVersionUID = 1L;
	
}

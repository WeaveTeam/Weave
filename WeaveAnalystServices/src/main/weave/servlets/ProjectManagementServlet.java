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

public class ProjectManagementServlet extends WeaveServlet implements
		IScriptEngine {
	private static final long serialVersionUID = 1L;

	public ProjectManagementServlet() {

	}

	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config
				.getServletContext()));
	}

	public Object delegateToMethods(String action, Map<String, Object> params) {
		Object returnStatus = null;

		if (action.matches("REPORT_PROJECTS")) {
			try {
				returnStatus = AwsProjectService.getProjectListFromDatabase();
			} catch (RemoteException e) {
				e.printStackTrace();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		} else if (action.matches("REPORT_QUERY_OBJECTS")) {
			try {
				returnStatus = AwsProjectService
						.getQueryObjectsFromDatabase(params);
			} catch (RemoteException e) {
				e.printStackTrace();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}

		else if (action.matches("DELETE_PROJECT")) {
			try {
				returnStatus = AwsProjectService
						.deleteProjectFromDatabase(params);
			} catch (RemoteException e) {
				e.printStackTrace();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		} else if (action.matches("DELETE_QUERY_OBJECT")) {
			try {
				returnStatus = AwsProjectService
						.deleteQueryObjectFromProjectFromDatabase(params);
			} catch (RemoteException e) {
				e.printStackTrace();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		} else if (action.matches("INSERT_QUERY_OBJECTS")) {
			try {
				returnStatus = AwsProjectService
						.insertMultipleQueryObjectInProjectFromDatabase(params);
			} catch (RemoteException e) {
				e.printStackTrace();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}

		return returnStatus;

	}
}

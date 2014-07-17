package weave.servlets;

import static weave.config.WeaveConfig.initWeaveConfig;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.config.WeaveContextParams;
import weave.interfaces.IScriptEngine;
import weave.models.AwsProjectService;

public class ProjectManagementServlet extends WeaveServlet implements
		IScriptEngine {
	private static final long serialVersionUID = 1L;

	public ProjectManagementServlet() {
		super(new AwsProjectService());//grouping servlets just add the servlet here
	}

	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config
				.getServletContext()));
	}

}

package weave.servlets;

import static weave.config.WeaveConfig.initWeaveConfig;

import java.io.File;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.config.WeaveContextParams;
import weave.servlets.WeaveServlet;
import weave.utils.SQLUtils.WhereClause.NestedColumnFilters;

import weave.config.AwsContextParams;
import weave.models.computations.ComputationEngineBroker;
import weave.models.computations.ScriptResult;

public class ComputationalServlet extends WeaveServlet
{	
	public ComputationalServlet()
	{
	}
	
	private static String awsConfigPath = "";
	private String programPath = "";
	private String tempDirPath = "";
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config.getServletContext()));
		programPath = WeaveContextParams.getInstance(config.getServletContext()).getRServePath();
		tempDirPath = AwsContextParams.getInstance(config.getServletContext()).getAwsConfigPath() + "temp";
		awsConfigPath = AwsContextParams.getInstance(config.getServletContext()).getAwsConfigPath();
	}

	private static final long serialVersionUID = 1L;

	
	public ScriptResult runScript(String scriptName, int[] ids, NestedColumnFilters filters) throws Exception
	{
		
		ScriptResult result = new ScriptResult();
		//String scriptPath = awsConfigPath + "RScripts/" + scriptName;
		String scriptPath = "";//"C:\\Tomcat\\webapps\\aws-config\\RScripts\\AWS_ParallelVersion2.R";
		File n = new File(awsConfigPath);
		String d = n.getParent();
		scriptPath = d + File.separator + "RScripts" + File.separator + scriptName;
		ComputationEngineBroker broker = new ComputationEngineBroker();
		result = broker.decideComputationEngine(scriptPath, ids, filters, programPath, tempDirPath);

		return result;
	}
}
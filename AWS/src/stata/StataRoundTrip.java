package stata;

import stata.CommandUtils;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebInitParam;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class StataRoundTrip
 */
@WebServlet(urlPatterns = { "/StataRoundTrip" }, initParams = {
		@WebInitParam(name = "request", value = ""),
		@WebInitParam(name = "response", value = "") })
public class StataRoundTrip extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private String statpath = "C:/Program Files (x86)/Stata12/Stata-64.exe";

	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public StataRoundTrip() {
		super();
		// TODO Auto-generated constructor stub
	}

	/**
	 * @see Servlet#getServletInfo()
	 */
	public String getServletInfo() {
		// TODO Auto-generated method stub
		return null;
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doGet(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {

	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse
	 *      response)
	 */
	protected void doPost(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		response.setContentType("text/xml");
		// response.getWriter().println("<responseFromServer>response from server"+request.getPathInfo()+"</responseFromServer>");

		ArrayList<String> command = new ArrayList<String>();

		command.add(statpath);
		command.add("-e");
		command.add("do");
		command.add("C:/Stata/s02_stata test ageadj_2013-0529send.do");
		// command.add("C:/Users/remote/Desktop/Stata/brfs_uml1.do");
		System.out.println(command);
		// runCommand(command);

		// go get csv, store in response,
		response = collectResults(response);
		if (response.isCommitted()) {
			System.out.println("response is Committed");
		}
		response.flushBuffer();
		System.out.println(response.toString());

	}

	private void runCommand(ArrayList<String> command) {
		String[] temp = new String[command.size()];

		String[] args = (String[]) command.toArray(temp);

		// System.out.println("***commands is**"+ Arrays.toString(args));

		try {
			int result = CommandUtils.runCommand(args);
			System.out.println("Program terminated with status " + result);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private HttpServletResponse collectResults(HttpServletResponse response) {
		CSVParser parser = new CSVParser();
		try {
			String[][] csv = parser.parseCSV(new File(
					"C:/Stata/stata_result.csv"), true);

			PrintWriter pr = response.getWriter();
			String csvs = parser.createCSV(csv, true, true);
			pr.println(csvs);
			// int size = csv.length;
			// for (int i = 0; i < size; i ++)
			// {
			// pr.println(csv[i]);
			// }
			pr.flush();
			pr.close();

		} catch (Exception e) {
		}
		return response;

	}

}

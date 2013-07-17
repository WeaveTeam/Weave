package weave.servlets;

import weave.utils.CSVParser;
import weave.utils.CommandUtils;
import weave.servlets.GenericServlet;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Path;
import java.util.ArrayList;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

public class StataServlet extends GenericServlet {
	private static final long serialVersionUID = 1L;
	private String statpath = "C:/Program Files (x86)/Stata12/Stata-64.exe";

	public StataServlet() {
		// Constructor
	}

	// Public functions
	public String SendScriptToStata(String scriptName, String[] options) throws IOException {
		String path = "C:/stataScripts/";
		String fileName = path + scriptName + "-setup.do";
		FileOutputStream fop = null;
		try {
			File setupFile = new File(fileName);

			if (setupFile.createNewFile()) {
				System.out.println("File is created");
			} else {
				System.out.println("file already exists");
			}

			fop = new FileOutputStream(setupFile);

			byte[] contentInBytes = options[0].getBytes();

			fop.write(contentInBytes);
			fop.flush();
			fop.close();

			System.out.println("Done");

		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				if (fop != null) {
					fop.close();
				}
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return "gobbldygook";
	}

	/**
	 * 
	 */
	protected void BuildDo(String scriptFilePath) throws IOException {
		// TODO Auto-generated method stub
		
		ArrayList<String> command = new ArrayList<String>();

		command.add(statpath);
		command.add("-e");
		command.add("do");
		command.add(scriptFilePath);
		// command.add("C:/Users/remote/Desktop/Stata/brfs_uml1.do");
		System.out.println(command);
		runCommand(command);
	}
	
	/**
	 * Private Run Command function to access the commandline.
	 * 
	 * @param command
	 */
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

}

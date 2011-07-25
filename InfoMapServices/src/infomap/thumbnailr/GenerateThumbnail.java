package infomap.thumbnailr;

import infomap.utils.CommandUtils;

import java.io.*;
import java.util.*;

import javax.servlet.*;
import javax.servlet.http.*;

public class GenerateThumbnail extends HttpServlet {

	private static final long serialVersionUID = 1L;
	
	private String wkPath = "C:\\Program Files\\wkhtmltopdf\\wkhtmltoimage.exe";
	private String imgPath = "C:\\temp\\";
	
	
	public void doGet(HttpServletRequest request,
                    HttpServletResponse response)
      throws ServletException, IOException {
		PrintWriter out = response.getWriter();
	
		String url = request.getParameter("url");
		String imgName = request.getParameter("imgName");
		
		out.println(url);
		ArrayList<String> command = new ArrayList<String>();
		command.add(wkPath);
		command.add("--quality");
		command.add("70");
		command.add("--height");
		command.add("800");
		command.add("--crop-w");
		command.add("800");	
		command.add(url);
		command.add(imgPath + imgName + ".jpg");
		
		
		String[] temp = new String[command.size()];
		
		String[] args = (String[])command.toArray(temp);
		
		int result = CommandUtils.runCommand(args);
		
		System.out.println("Program terminated with status " + result);
		
		out.close();
  }
	
	
}
package infomap.thumbnailr;



import java.io.*;
import java.net.URL;
import javax.servlet.*;
import javax.servlet.http.*;




public class SaveThumbnailFromURL  extends HttpServlet {

	private static final long serialVersionUID = 2L;
	
//	private String thumbnailPath = "C:\\temp\\";
	private String thumbnailPath = "/var/lib/tomcat6/webapps/ROOT/infomap/thumbnails/";
	
	
	
	public void doGet(HttpServletRequest request,
                    HttpServletResponse response)
      throws ServletException, IOException {
		PrintWriter out = response.getWriter();
	
		String url = request.getParameter("url");
		//get the last occurrence of '.' to get the extension of the image
		int lastIndex = url.lastIndexOf('.');
		String imgExtension = url.substring(lastIndex, url.length());
		String imgName = request.getParameter("imgName") + imgExtension;
		
		 System.out.println("IN SAVE THUMBNAIL SERVLET");
		
		out.print(imgName);
		 BufferedInputStream in = null;
	     FileOutputStream fout = null;
	        try
	        {
	                in = new BufferedInputStream(new URL(url).openStream());
	                fout = new FileOutputStream(thumbnailPath + imgName);

	                byte data[] = new byte[1024];
	                int count;
	                while ((count = in.read(data, 0, 1024)) != -1)
	                {
	                        fout.write(data, 0, count);
	                }
	                
	                System.out.println("Imaged Saved as " + thumbnailPath + imgName);
	        }
	        finally
	        {
	                if (in != null)
	                        in.close();
	                if (fout != null)
	                        fout.close();
	                System.out.println("IN SAVE THUMBNAIL SERVLET FINALLY");
	        		
	        }
	        System.out.println("CLOSING SAVE THUMBNAIL SERVLET");
			
	    out.close();
	}
}
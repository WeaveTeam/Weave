package infomap.admin;

import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.solr.client.solrj.SolrServer;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.response.UpdateResponse;
import org.apache.solr.common.SolrException;
import org.apache.solr.common.SolrInputDocument;


public class FileUploader extends HttpServlet{
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	public static SolrServer solrInstance = null;
    public String solrServerUrl = "http://129.63.8.219:8080/solr/";
	
    public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException, SolrException
	{
		System.out.println("uploading files");
		
		String link = request.getParameter("link");
		
		String title = request.getParameter("title");
		
		String description = request.getParameter("descr");
		
		DateFormat dateFormat = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss");
		//get current date time with Date()
		Date date = new Date();
		
		String date_added = dateFormat.format(date);
		
		if(solrInstance != null)
			solrInstance = new HttpSolrServer(solrServerUrl);
		
		SolrInputDocument doc = new SolrInputDocument();
		
		doc.addField("link", link);
		doc.addField("title", title);
		doc.addField("description", description);
		doc.addField("date_added", date_added);
		
		try{
			
			UpdateResponse result = solrInstance.add(doc);
			System.out.println("Uploading document status " + result.getStatus());
		}catch (Exception e)
		{
			e.printStackTrace();
		}
		
		
	}
}
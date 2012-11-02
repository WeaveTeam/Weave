package infomap.admin;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import org.xml.sax.ContentHandler;

import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathFactory;

import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrServer;
import org.apache.solr.client.solrj.impl.ConcurrentUpdateSolrServer;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.request.UpdateRequest;
import org.apache.solr.client.solrj.response.FacetField;
import org.apache.solr.client.solrj.response.FacetField.Count;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.client.solrj.response.UpdateResponse;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrInputDocument;
import org.apache.tika.metadata.Metadata;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.sax.BodyContentHandler;
import org.slf4j.spi.LocationAwareLogger;
import org.w3c.dom.Document;

import com.dropbox.client2.DropboxAPI;
import com.dropbox.client2.DropboxAPI.Entry;
import com.dropbox.client2.session.AccessTokenPair;
import com.dropbox.client2.session.AppKeyPair;
import com.dropbox.client2.session.RequestTokenPair;
import com.dropbox.client2.session.Session.AccessType;
import com.dropbox.client2.session.WebAuthSession;
import com.dropbox.client2.session.WebAuthSession.WebAuthInfo;
import com.google.gson.Gson;


import infomap.beans.QueryResultWithWordCount;
import infomap.servlets.GenericServlet;
import infomap.utils.DebugTimer;
import infomap.utils.SQLResult;
import infomap.utils.SQLUtils;
import infomap.utils.XMLUtils;

import java.util.Iterator;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


/**
 *class SolrDataServices
 */
public class AdminService extends GenericServlet{
	private static final long serialVersionUID = 1L;
       
    private static String username = "root";
    private static String password = "oic3Ind2";
    private static String host = "129.63.8.219";
    private static String port = "3306";
    private static String database = "solr_sources";
    private Connection conn = null;
	
    public static HttpSolrServer solrInstance = null;
    private static int bufferSize = 20;
	private static int backgroundThreads = 4;
	
	
    public static String solrServerUrl = "http://129.63.8.219:8080/solr/research_core/";

    public static ConcurrentUpdateSolrServer streamingSolrserver = null;
	
    public AdminService() {
        
//        getConnection();
//		try{
//			
//			solrInstance = new CommonsHttpSolrServer(solrServerUrl);
//		}catch(Exception e){
//			e.printStackTrace();
//		}
    }
    
    
    public static void main(String[] args) {
		
//    	deleteAllDocuments();
	}
    
    private static void deleteAllDocuments()
    {
    	try{
    		setSolrServer("http://129.63.8.219:8080/solr/research_core/");
    		
    		//query = query + "&wt=json";
       	 QueryResponse response = null;
       	try{
   			
       		SolrInputDocument d = new SolrInputDocument();
       		Map<String, String> mp = new HashMap<String, String>();
       		mp.put("set", "BIG TITLE SABMAN. 8");
       		d.addField("link", "http://cardinalscholar.bsu.edu/handle/123456789/194764");
//       		d.addField("imgName", mp);
//       		d.addField("description","This is a description");
//       		d.addField("attr_text_summary","This is a summary.");
       		d.addField("title",mp);
//       		UpdateResponse resp = solrInstance.add(d);
       		
       		SolrInputDocument d2 = new SolrInputDocument();
       		Map<String, String> mp2 = new HashMap<String, String>();
       		mp2.put("set", "BIG TITLE SABMAN 9");
       		d2.addField("link", "http://cardinalscholar.bsu.edu/handle/123456789/1947640000");
//       		d2.addField("imgName", mp2);
//       		d2.addField("description","This is a description");
//       		d2.addField("attr_text_summary","This is a summary.");
       		d2.addField("title",mp2);
//       		UpdateResponse resp2 = solrInstance.add(d2);
       		
       		SolrInputDocument[] twoDocsArray = new SolrInputDocument[2];
       		
       		twoDocsArray[0] = d;
       		twoDocsArray[1] = d2;
       		
       		List<SolrInputDocument> twoDocs = Arrays.asList(twoDocsArray);
        	
       		setStreamingSolrServer("http://129.63.8.219:8080/solr/research_core/");
       		
       		streamingSolrserver.add(twoDocs,1000);

       		System.out.println("Updated with ");
       		
       	}catch(Exception e)
       	{
       		e.printStackTrace();
       	}
    		
    	}catch(Exception e)
    	{
    		e.printStackTrace();
    	}
		
    }
    
	private static void setSolrServer(String solrURL)
	{
		try{
			
			if(solrInstance != null)
			{
				if(solrInstance.getBaseURL().equals(solrURL))
					return;
			}
			solrServerUrl = solrURL;
			solrInstance = new HttpSolrServer(solrServerUrl);
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	
	private static void setStreamingSolrServer(String solrURL)
	{
		try {
			if(streamingSolrserver!=null)
			{
				//if updating the same solr server no need to create another instance
				if(solrServerUrl.equals(solrURL))
						return;
			}
			
			solrServerUrl = solrURL;
			streamingSolrserver = new ConcurrentUpdateSolrServer(solrServerUrl, bufferSize, backgroundThreads);
			
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
    private void getConnection()
    {
    	try{
    		Class.forName("com.mysql.jdbc.Driver").newInstance();
    		
    		String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
    		
    		
    		
    	}catch (Exception e)
    	{
    		e.printStackTrace();
    	}
    	
    }
	
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
    	super.doGet(request, response);
    	PrintWriter out = response.getWriter();
    	
		out.println("Deployed!");
	}
    
    
    @Override
    public void destroy() {
    	// TODO Auto-generated method stub
    	System.out.println("Shutting down data sources Executor");
    	executor.shutdown();
    	super.destroy();
    }
    synchronized public Object[][] getRssFeeds()
    {
    	String query = "SELECT title,url FROM rss_feeds";
    	SQLResult result = null;
    	Connection connection = null;
		try
		{
			String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
			connection = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
			result = SQLUtils.getRowSetFromQuery(connection, query);
			
		}
		catch (Exception e)
		{
			System.out.println(query);
			e.printStackTrace();
		}finally{
			SQLUtils.cleanup(connection);
		}
		return  result.rows;	
    }
    
    public String addRssFeed(String title,String url) throws RemoteException
	{
		try{
			
			
			String connURL = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
			

			String query = "SELECT * FROM rss_feeds WHERE url = '"+ url + "'";
			
			SQLResult checkResult = SQLUtils.getRowSetFromQuery(conn, query);
			
			if (checkResult.rows.length != 0)
			{
				return "RSS Feed already exists";
			}
			
			String titleQuery = "SELECT * FROM rss_feeds WHERE title = '"+ title + "'";
			
			SQLResult checkTitleQueryResult = SQLUtils.getRowSetFromQuery(conn, titleQuery);
			
			if (checkTitleQueryResult.rows.length != 0)
			{
				return "There is already a feed with the same title. Please give a different title.";
			}
			
			Map<String, Object> valueMap = new HashMap<String, Object>();
			
			valueMap.put("title", title);
			valueMap.put("url", url);
			
			SQLUtils.insertRow(conn, database, "rss_feeds", valueMap);
			
			return "RSS Feed added successfully";
		}catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		
		
	}
    
    
    public String deleteRssFeed(String url) throws RemoteException
	{
    	try{
			
    		String connURL = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
			
			
			
			String query = "DELETE FROM rss_feeds WHERE url = '"+ url + "'";
			
			int result = SQLUtils.getRowCountFromUpdateQuery(conn, query);
			
			return "RSS Feed was deleted";
		}catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		
	}

    public String addAtomFeed(String url, String title) throws RemoteException
	{
		try{
			
			
			String connURL = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
			
			Statement stat = conn.createStatement();
			
			String query = "SELECT * FROM atom_feeds WHERE url = '"+ url + "'";
			
			ResultSet checkIfExists = stat.executeQuery(query);
			
			//if url already exists then return
			if(!checkIfExists.next())
				return "Atom Feed alreadt exists";

			
			String titleQuery = "SELECT * FROM atom_feeds WHERE title = '"+ title + "'";
			
			SQLResult checkTitleQueryResult = SQLUtils.getRowSetFromQuery(conn, titleQuery);
			
			if (checkTitleQueryResult.rows.length != 0)
				return "There is already a feed with the same title. Please give a different title.";
			
			
			Map<String, Object> valueMap = new HashMap<String, Object>();
			
			valueMap.put("title", title);
			valueMap.put("url", url);
			
			SQLUtils.insertRow(conn, database, "atom_feeds", valueMap);
			
			return "Atom Feed added successfully";
			
		}catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		
		
	}
    public void deleteAtomFeed(String title)
	{
		try{
			
			String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
			
			
			String deleteFileSource = "DELETE FROM atom_feeds WHERE titile ='"+title+"')";
			
			Statement stat = conn.createStatement();
			int result = stat.executeUpdate(deleteFileSource);
			
			System.out.println("deleting atom feed: " + result);
			
			stat.close();
			conn.close();
			
		}catch (Exception e)
		{
			e.printStackTrace();
		}
		
	}
    
    public void addFilePath(String url, String title)
	{
    	try{
			
    		String connURL = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
			
		
		String insertFileSource = "INSERT INTO file_sources (url,title) VALUE ('"+ url+"','"+title+"')";
		
		Statement stat = conn.createStatement();
		int result = stat.executeUpdate(insertFileSource);
		
		System.out.println("adding file path : " + result);
			
		recursivelyAddFiles(url);
		
    	}catch(Exception e)
    	{
    		e.printStackTrace();
    	}
			
		
	}
    
    
    public void recursivelyAddFiles(String path)
    {
    	
    	File file = new File(path);
		
		if(file.isFile())
		{
	    	try{
				
	    		String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
	    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
				
			
			String insertFileSource = "INSERT INTO file_paths (url,title) VALUE ('"+ path+"')";
			
			Statement stat = conn.createStatement();
			int result = stat.executeUpdate(insertFileSource);
			
			System.out.println("adding file path : " + result);
			
			stat.close();
			conn.close();
		
			}catch (Exception e)
			{
				e.printStackTrace();
			}
		}else if(file.isDirectory())
		{
			String[] fileList = file.list();
			
			for(int i=0; i<fileList.length; i++)
			{
				recursivelyAddFiles(path+"/"+fileList[i]);
			}
			
		}
	
    

	}
    
    public void deleteFilePath(String title)
	{
		try{
			
			String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
			
			String deleteFileSource = "DELETE FROM file_sources WHERE titile ='"+title+"')";
			
			Statement stat = conn.createStatement();
			int result = stat.executeUpdate(deleteFileSource);
			
			System.out.println("deleting file path : " + result);
			
			stat.close();
			conn.close();
			
		}catch (Exception e)
		{
			e.printStackTrace();
		}
		
	}
    
    public String renameFile(String filePath, String newName, Boolean overwrite)
    {
    	File file = new File(filePath);
    	 if(file.isFile())
    	 {
    		 File newFile = new File(file.getAbsolutePath()+newName);
    		 if(newFile.isFile())
    			 if(!overwrite)
    				 return "file name already exists. Give a new file name or allow overwrite.";
    			 else{
    				 newFile.delete();
    			 }
    		
    		 Boolean result = file.renameTo(newFile);
    		 if(result)
    			 return "file sucessfully renamed";
    		 else
    			 return "file rename not successful";
    	 }else{
    		 return "Given file path is not a file";
    	 }
    }
    
    /**
     * This function takes an array of entities and an array of documents. This checks for which entities
     * are present in the documents and returns that set of entities
     * 
     * @param entities
     * @param docs
     * @return
     */
    public String[] searchInDocuments(String[] entities, String[] docs,String solrURL)
    {
    	 setSolrServer(solrURL);
    	HashMap<String, Boolean> matchedEntitiesMap = new HashMap<String, Boolean>();
		
    	for (int i = 0; i < docs.length; i++)
    	{
    		//$match = array('\\', '+', '-', '&', '|', '!', '(', ')', '{', '}', '[', ']', '^', '~', '*', '?', ':', '"', ';', ' ');
            //$replace = array('\\\\', '\\+', '\\-', '\\&', '\\|', '\\!', '\\(', '\\)', '\\{', '\\}', '\\[', '\\]', '\\^', '\\~', '\\*', '\\?', '\\:', '\\"', '\\;', '\\ ');
            
    		String docURL = docs[i].replaceAll("\\:", "\\\\:");
    		docURL = docURL.replaceAll("&amp;", "%26");
    		System.out.println("QUERYING FOR " + docURL);
    		String queryURL = "http://129.63.8.219:8080/solr/select/?version=2.2&start=0&rows=1&indent=on&fl=description&q=link:" + docURL;
    		try{
    			
    			URL url = new URL(queryURL);
    			URLConnection solrConn = url.openConnection();
    			solrConn.setDoOutput(true);
    			
    			//read the response
    			BufferedReader rd = new BufferedReader(new InputStreamReader(solrConn.getInputStream()));
 
    			String line;
    			String content = "";
    			while ((line = rd.readLine()) != null) {
    				
    				content += line;
    			}
    			
    			content = content.replaceAll("[^ -~]", " ");
    			
    			Document doc = XMLUtils.getXMLFromString(content);

    			XPathFactory factory = XPathFactory.newInstance();
    			XPath xpath = factory.newXPath();
    			
    			String descr = XMLUtils.getStringFromXPath(doc, xpath, "/response/result/doc/str/text()");
    			
    			for (int j=0; j < entities.length; j++)
    			{
    				if(descr.toLowerCase().indexOf(entities[j].toLowerCase()) != -1)
    				{
    					matchedEntitiesMap.put(entities[j], true);
    				}
    			}
    			
    			
    			
    		}catch (Exception e)
    		{
    			e.printStackTrace();
    		}
    		
    	}
    	
    	
    	return matchedEntitiesMap.keySet().toArray(new String[0]);
    
    	
    	
    }
    
    public long getNumberOfMatchedDocuments(String query,String fq,String solrURL)
    {
        	 setSolrServer(solrURL);
        	//query = query + "&wt=json";
        	 QueryResponse response = null;
        	try{
    			
        		SolrQuery q = new SolrQuery().setQuery(query);
        		if(!fq.isEmpty())
        			q.setFilterQueries(fq);
        		q.setRows(1);
        		 response = solrInstance.query(q);
        		
        		System.out.println("QUERY IS " + q.toString());
        		
        	}catch(Exception e)
        	{
        		e.printStackTrace();
        	}
        	return response.getResults().getNumFound();
    }
    
    private int highlightSnippetsCount =10; 
    private int highlightFragmentSize = 150;
    private ExecutorService executor = Executors.newFixedThreadPool(3);
    private DebugTimer timer = new DebugTimer();
    public QueryResultWithWordCount getQueryResults(String[] queryTerms,String fq,String sortField,int rows, String solrURL) throws NullPointerException
    {
    	 setSolrServer(solrURL);
    	//query = query + "&wt=json";
    	 timer.start();
    	System.out.println("CALLING GET QUERY");

    	MendeleyDataSource mds = new MendeleyDataSource();
    	 mds.query = queryTerms.clone();
    	 mds.solrServerURL = solrURL;
    	 
    	 ArxivDataSource ads = new ArxivDataSource();
    	 ads.query = queryTerms.clone();
    	 ads.solrServerURL = solrURL;
    	 
    	 BaseDataSource bds = new BaseDataSource();
    	 bds.query = queryTerms.clone();
    	 bds.solrServerURL = solrURL;
    	 
    	 executor.execute(ads);
    	 executor.execute(mds);
    	 executor.execute(bds);
    	
    	String query = parseBasicQuery(queryTerms, "AND");
    	long totalNumberOfDocuments = getNumberOfMatchedDocuments(query, fq, solrURL);

    	ArrayList<String[]> r = new ArrayList<String[]>();
    	QueryResultWithWordCount result = new QueryResultWithWordCount();
    	
    	try{
			
    		SolrQuery q = new SolrQuery().setQuery(query).setSortField(sortField, SolrQuery.ORDER.asc);
    		if(!fq.isEmpty())
    			q.setFilterQueries(fq);
    		
    		
    		
    		//set number of rows
    		q.setRows(rows);
    		
    		//set highlighting
    		q.setHighlight(true).setHighlightSnippets(highlightSnippetsCount).setHighlightFragsize(highlightFragmentSize);
    		
    		q.setParam("hl.fl", "description");
    		
    		q.setParam("hl.simple.pre","<b>");
    		q.setParam("hl.simple.post","</b>");
    		
    		q.addFacetField("description");
    		q.setFacet(true);
    		q.setFacetLimit(100);
    		
    		//set fields to title,date and summary only
    		q.setFields("link,title,attr_text_summary,date_added,date_published,imgName");
    		
//    		.setFilterQueries(fq).setSortField(sortField, SolrQuery.ORDER.desc);
    		
    		
    		QueryResponse response = solrInstance.query(q);
    		
    		Iterator<SolrDocument> iter = response.getResults().iterator();
    		
    		System.out.println("QUERY IS " + q.toString());
    		
//    		System.out.println("NUM OF DOCUMENTS IS " + response.getResults().getNumFound());
    		    		
    		while (iter.hasNext()){
    			SolrDocument doc = iter.next();
    			String[] docArray =new String[5];
    			
    			docArray[0] = (String)doc.getFieldValue("link");
    			docArray[1] = (String)doc.getFieldValue("title");
    			
    			
    			//Show text summary if exists
    			docArray[2] = "";
    			String docSummary = (String)doc.getFieldValue("attr_text_summary"); 
    			if( docSummary !=null)
    			{
    				docArray[2] += "<b>Summary: </b>" + docSummary;
    			}
    			//Show sentences with containing query words
    			if(response.getHighlighting().get(docArray[0]).get("description") !=null )
    			{
    				List<String> highlightsList = response.getHighlighting().get(docArray[0]).get("description");
    				
    				Iterator<String> highlightsIter = highlightsList.iterator();
    				
    				docArray[2] += "<br/><br/><b>Matches: </b>";
    				
    				while(highlightsIter.hasNext())
    				{
    					docArray[2] += " '" + highlightsIter.next() + "'...";
    				}
    				
    			}
//    			else //else show first 200 characters of description
//    			{
//    				String descr = (String)doc.getFieldValue("description");
//    				docArray[2] = "<b>Description: </b>";
//    				if(descr == null)
//    					descr = "No description available";
//    				
//        			if(descr.length()>200)
//        				docArray[2] = descr.substring(0, 200);
//        			else
//        				docArray[2] = descr;
//    			}
    			
    			
//    			int linkLen = docArray[0].length();
//    			String linkExtension = docArray[0].substring(linkLen-3,linkLen);
//    			String imgExtension = ".jpg";
//				
//				if(linkExtension.equalsIgnoreCase("pdf") || linkExtension.equalsIgnoreCase("doc")){
//					imgExtension = ".png";
//				}
    			if(doc.getFieldValue("imgName") !=null)
    				docArray[3] = "http://129.63.8.219:8080/thumbnails/"+  (String)doc.getFieldValue("imgName");
    			
    			if(doc.containsKey("date_published"))
    				docArray[4] = doc.getFieldValue("date_published").toString();
    			else if(doc.containsKey("date_added"))
    				docArray[4] = doc.getFieldValue("date_added").toString();
    			else
    				docArray[4] = "";
//    			System.out.println("Content IS " + docArray[0] + docArray[1] + docArray[2] + docArray[3] + docArray[4]); 
    			
    			r.add(docArray);
    		}
    		
    		
    		//creating an array of facet words and its word count
    		try{
    			
    			FacetField ff = response.getFacetField("description");
    			Iterator<Count> iter2= ff.getValues().iterator();
    			
    			String[][] wordCount = new String[ff.getValueCount()][2];
    			
    			int countIndex = 0;
    			
    			while(iter2.hasNext())
    			{
    				Count currentCount = iter2.next();
    				
    				String[] temp = new String[2];
    				
    				temp[0] = currentCount.getName();
    				temp[1] = String.valueOf(currentCount.getCount());
    				
    				wordCount[countIndex] = temp;
    				countIndex ++;
    			}
    			
    			result.wordCount = wordCount.clone();
    		}catch(Exception e)
    		{
    			System.out.println("Error getting Facet Count ");
    			e.printStackTrace();
    		}
    		
    	}catch (Exception e)
		{
			e.printStackTrace();
		}
    	
    	
    	
    	result.queryResult = r.toArray();
    	result.totalNumberOfDocuments = (int)totalNumberOfDocuments;
    	System.out.println("ENDING GET QUERY" + timer.get());
    	return result;
    }
    
    /**
     * Add documents from Array to Solr Server
     * @param an array of SolrInputDocument 
     */
    public static void addDocuments(SolrInputDocument[] docs,String solrURL)
    {
    	if(docs==null || docs.length == 0){
    		
    		System.out.println("addDocuments was called but no Documents added");
    		return;
    	}
    	
    	List<SolrInputDocument> d = Arrays.asList(docs);
    	
    	setStreamingSolrServer(solrURL);
    	try{
    	streamingSolrserver.add(d);
    	}catch(Exception e)
    	{
    		System.out.println("Error when adding "+docs.length+"documents");
    		e.printStackTrace();
    	}
    }
    
    public static void addTextDocument(String username, String fileName, InputStream content, String solrURL) throws RemoteException, MalformedURLException, ParseException
    {
    	String link = username + ":" + fileName;
    	
		AutoDetectParser parser = new AutoDetectParser();
		
		
		ContentHandler textHandler = new BodyContentHandler();
		Metadata metadata = new Metadata();
		
		try{
			parser.parse(content, textHandler, metadata);
		}catch(Exception e){
			e.printStackTrace();
		}
		
		SolrInputDocument doc = new SolrInputDocument();
		
		doc.addField("link", link);
		
		String title = metadata.get("title");
		if(title == null)
			title = fileName;
		
		Date currentDate = new Date();
		doc.addField("title", title);
		doc.addField("description", textHandler.toString());
		doc.addField("username", username);
		doc.addField("date_added", currentDate);
		
		if(metadata.get("Creation-Date") != null)
		{
			DateFormat formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
			Date date_published = new Date();
			date_published = formatter.parse(metadata.get("Creation-Date"));
			doc.addField("date_published", date_published);			
		}
		
//		System.out.println("Dumping metadata for file: " + fileName);
//	    for (String name : metadata.names()) {
//	    	System.out.println(name + ":" + metadata.get(name));
//	    }
		
		addDoc(doc,solrURL, true);
    }
    
    private static void addDoc(SolrInputDocument d,String solrURL,Boolean commit)
    {
    	try{
			setStreamingSolrServer(solrURL);
			SolrQuery q = new SolrQuery().setQuery("link:"+"\""+d.getFieldValue("link").toString()+"\"");
			QueryResponse r = streamingSolrserver.query(q);
			
			if(r.getResults().getNumFound()>0)
			{
				System.out.println("Document already exists " + d.getFieldValue("link").toString());
			}else{
				
				streamingSolrserver.add(d);
			}
			
//			if(commit)
//				streamingSolrserver.commit(); 
		}catch (Exception e)
		{
			e.printStackTrace();
		}
    }
    
    private static String parseBasicQuery(String[] query, String operator)
	{
		
    	String queryString = "";
    	
    	//if it is not a single word we add the operator between each keyword
		//splitting the keywords at the spaces. 
		if(query.length > 1)
		{
			for(int i = 0; i < query.length; i++)
			{
				queryString += query[i];
				//add operator for all terms except for last
				if(i != query.length-1)
					queryString += " "+operator+" ";
			}
			
		}
		else
		{
			queryString = query[0];
		}
		
		//we need to search in both the title and the description fields.
		//the solr syntax for searching multiple words in a single field is "field_name:(query words)"
		queryString = "title:(" + queryString + ") OR description:(" + queryString + ")";
		
		return queryString;
	}
    
    
    private static final String APP_KEY = "j8ffufccso68w4y";
    private static final String APP_SECRET = "ww7tgcyeqr3ksmf";
    private static final AccessType ACCESS_TYPE = AccessType.DROPBOX;
    private static DropboxAPI<WebAuthSession> mDBApi;
 
    public String testDropbox() throws Exception 
    {
        AppKeyPair appKeys = new AppKeyPair(APP_KEY, APP_SECRET);
        WebAuthSession session = new WebAuthSession(appKeys, ACCESS_TYPE);
        WebAuthInfo authInfo = session.getAuthInfo();
 
        RequestTokenPair pair = authInfo.requestTokenPair;
        String url = authInfo.url;
        
//        Desktop.getDesktop().browse(new URL(url).toURI());
//        JOptionPane.showMessageDialog(null, "Press ok to continue once you have authenticated.");
        session.retrieveWebAccessToken(pair);
 
        AccessTokenPair tokens = session.getAccessTokenPair();
        System.out.println("Use this token pair in future so you don't have to re-authenticate each time:");
        System.out.println("Key token: " + tokens.key);
        System.out.println("Secret token: " + tokens.secret);
 
        mDBApi = new DropboxAPI<WebAuthSession>(session);
        
        return url;
    }
    
    public void testAddFileToDropBox() throws Exception
    {
    	 System.out.println();
         System.out.print("Uploading file...");
         String fileContents = "Hello World!";
         ByteArrayInputStream inputStream = new ByteArrayInputStream(fileContents.getBytes());
         Entry newEntry = mDBApi.putFile("/testing.txt", inputStream, fileContents.length(), null, null);
         System.out.println("Done. \nRevision of file: " + newEntry.rev);
    }
    
}
package infomap.admin;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.Reader;

import org.xml.sax.ContentHandler;

import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLDecoder;
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
import java.util.Properties;

import javax.security.auth.callback.LanguageCallback;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathFactory;

import org.apache.commons.io.IOUtils;
import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrResponse;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.SolrQuery.ORDER;
import org.apache.solr.client.solrj.impl.ConcurrentUpdateSolrServer;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.response.FacetField;
import org.apache.solr.client.solrj.response.FacetField.Count;
import org.apache.solr.client.solrj.response.Group;
import org.apache.solr.client.solrj.response.GroupCommand;
import org.apache.solr.client.solrj.response.GroupResponse;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrDocumentList;
import org.apache.solr.common.SolrInputDocument;
import org.apache.solr.common.params.GroupParams;
import org.apache.solr.common.params.ModifiableSolrParams;
import org.apache.tika.metadata.Metadata;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.sax.BodyContentHandler;
import org.w3c.dom.Document;

import cc.mallet.types.*;
import cc.mallet.pipe.*;
import cc.mallet.pipe.iterator.*;
import cc.mallet.topics.*;

import java.util.*;
import java.io.*;

import com.dropbox.client2.DropboxAPI;
import com.dropbox.client2.DropboxAPI.Entry;
import com.dropbox.client2.session.AccessTokenPair;
import com.dropbox.client2.session.AppKeyPair;
import com.dropbox.client2.session.RequestTokenPair;
import com.dropbox.client2.session.Session.AccessType;
import com.dropbox.client2.session.WebAuthSession;
import com.dropbox.client2.session.WebAuthSession.WebAuthInfo;
import com.google.gson.Gson;

import edu.mit.jwi.Dictionary;
import edu.mit.jwi.IDictionary;
import edu.mit.jwi.item.IIndexWord;
import edu.mit.jwi.item.ISynset;
import edu.mit.jwi.item.IWord;
import edu.mit.jwi.item.IWordID;
import edu.mit.jwi.item.POS;
import edu.mit.jwi.morph.WordnetStemmer;
import edu.stanford.nlp.ling.CoreLabel;
import edu.stanford.nlp.process.CoreLabelTokenFactory;
import edu.stanford.nlp.process.PTBTokenizer;

import infomap.beans.EntityDistributionObject;
import infomap.beans.QueryResultWithWordCount;
import infomap.beans.SolrClusterObject;
import infomap.beans.SolrClusterResponseModel;
import infomap.beans.TopicClassificationResults;
import weave.servlets.GenericServlet;
import weave.utils.CSVParser;
import weave.utils.DebugTimer;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.XMLUtils;

import opennlp.tools.sentdetect.SentenceDetectorME;
import opennlp.tools.sentdetect.SentenceModel;

import java.util.Iterator;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Pattern;

/**
 * class SolrDataServices
 */
public class AdminService extends GenericServlet {
	private static final long serialVersionUID = 1L;

	private static String username = null;
	private static String password = null;
	private static String host = "localhost";
	private static String port = "3306";
	private static String database = "solr_sources";
	private Connection conn = null;

	public static HttpSolrServer solrInstance = null;
	private static int bufferSize = 20;
	private static int backgroundThreads = 4;

	public static String solrServerUrl = null;
	
	public static String serverURL = null;

	public static ConcurrentUpdateSolrServer streamingSolrserver = null;
	
	private static Boolean _testMode = false;

	public AdminService() {
		Properties prop = new Properties();
		try{
			InputStream config = getClass().getClassLoader().getResourceAsStream("infomap/resources/config.properties");
			prop.load(config);
			
			solrServerUrl = prop.getProperty("solrServerURL");
			serverURL = prop.getProperty("serverURL");
			username = prop.getProperty("dbUsername");
			password = prop.getProperty("dbPassword");
			host = prop.getProperty("feedSourcesDBServerURL");
			_testMode = prop.getProperty("testMode").equals("true");
		}catch (Exception e)
		{
			System.out.println("Error reading configuration file");
		}
	}

//	public static void main(String[] args) {
//		//testing
//		AdminService inst = new AdminService();
//	
//		 String [] requiredKeywords = new String[1];
//		 String [] relatedKeywords = new String[1];
//
//		 requiredKeywords[0] = "Montana";
//		 relatedKeywords[0] = " obesity";
//		 try{
//			 
//			 inst.getClustersForQueryWithRelatedKeywords(requiredKeywords, relatedKeywords,null,5000,"AND");
//		 }catch (Exception e) {
//			// TODO: handle exception
//			 e.printStackTrace();
//		}
//	}

	private static void deleteAllDocuments() {
		try {
			String queryString = "title:((california OR washington) AND (obesity OR BMI OR overweight)) OR description:((california OR washington) AND (obesity OR BMI OR overweight))";

			SolrQuery query = new SolrQuery();

			// query = query + "&wt=json";
			QueryResponse response = null;
			Object[][] result = new Object[5][];
			try {

				query.setQuery(queryString);

				query.setFields("link");

				query.set(GroupParams.GROUP_LIMIT, 5000);

				query.set(GroupParams.GROUP, true);

				query.set(GroupParams.GROUP_QUERY,
						"title:(\"new jersey\") OR description:(\"new jersey\")");

				query.add(GroupParams.GROUP_QUERY,
						"title:(\"massachusetts\") OR description:(\"massachusetts\")");

				response = solrInstance.query(query);
				GroupResponse gr = response.getGroupResponse();

				List<GroupCommand> gc = gr.getValues();

				Iterator<GroupCommand> gcIter = gc.iterator();

				int count = 0;
				while (gcIter.hasNext()) {
					GroupCommand g = gcIter.next();

					List<Group> groups = g.getValues();

					Iterator<Group> groupsIter = groups.iterator();
					while (groupsIter.hasNext()) {
						Group group = groupsIter.next();

						SolrDocumentList docList = group.getResult();

						Iterator<SolrDocument> docIter = docList.iterator();
						ArrayList<String> docs = new ArrayList<String>();
						while (docIter.hasNext()) {
							SolrDocument doc = docIter.next();

							docs.add((String) doc.getFieldValue("link"));
						}
//						System.out.println("DOCS ARE + " + docs.toString());
						result[count] = docs.toArray();
					}
					count++;
				}
//				System.out.println("Updated with ");

			} catch (Exception e) {
				e.printStackTrace();
			}

		} catch (Exception e) {
			e.printStackTrace();
		}

	}

	private static void setSolrServer(String solrURL) {
		try {

			if (solrInstance != null) {
				if (solrInstance.getBaseURL().equals(solrURL))
					return;
			}
			solrServerUrl = solrURL;
			solrInstance = new HttpSolrServer(solrServerUrl);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private static void setStreamingSolrServer(String solrURL) {
		try {
			if (streamingSolrserver != null) {
				// if updating the same solr server no need to create another
				// instance
				if (solrServerUrl.equals(solrURL))
					return;
			}

			solrServerUrl = solrURL;
			streamingSolrserver = new ConcurrentUpdateSolrServer(solrServerUrl,
					bufferSize, backgroundThreads);

		} catch (Exception e) {
			e.printStackTrace();
		}
	}

//	private void getConnection() {
//		try {
//			Class.forName("com.mysql.jdbc.Driver").newInstance();
//
//			String url = SQLUtils.getConnectString("MySQL", host, port,
//					database, username, password);
//			conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
//
//		} catch (Exception e) {
//			e.printStackTrace();
//		}
//
//	}

	@Override
	protected void doGet(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {
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

	synchronized public Object[][] getRssFeeds() {
		String query = "SELECT title, url FROM %s";
		SQLResult result = null;
		Connection connection = null;
		try {
			String url = SQLUtils.getConnectString(SQLUtils.MYSQL, host, port,
					database, username, password);
			connection = SQLUtils.getConnection(url);
			result = SQLUtils.getResultFromQuery(connection, query, null, true);

		} catch (Exception e) {
			System.out.println(query);
			e.printStackTrace();
		} finally {
			SQLUtils.cleanup(connection);
		}
		return result.rows;
	}

	public String addRssFeed(String title, String url) throws RemoteException {
		try {

			String connURL = SQLUtils.getConnectString(SQLUtils.MYSQL, host, port,
					database, username, password);
			conn = SQLUtils.getConnection(connURL);

			String query = "SELECT * FROM rss_feeds WHERE url = ?";
			
			String[] params = new String[1];
			params[0]= url;
			SQLResult checkResult = SQLUtils.getResultFromQuery(conn,query, params, true);

			if (checkResult.rows.length != 0) {
				return "RSS Feed already exists";
			}

//			String titleQuery = "SELECT * FROM rss_feeds WHERE title = '"
//					+ title + "'";
//			String[] titleQueryParams = new String[1];
//			titleQueryParams[0] = title;
//			SQLResult checkTitleQueryResult = SQLUtils.getRowSetFromQuery(conn,titleQuery);
//
//			if (checkTitleQueryResult.rows.length != 0) {
//				return "There is already a feed with the same title. Please give a different title.";
//			}

			Map<String, Object> valueMap = new HashMap<String, Object>();

			valueMap.put("title", title);
			valueMap.put("url", url);

			SQLUtils.insertRow(conn, database, "rss_feeds", valueMap);

			return "RSS Feed added successfully";
		} catch (Exception e) {
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}

	}

	public String deleteRssFeed(String url) throws RemoteException {
		try {

			String connURL = SQLUtils.getConnectString(SQLUtils.MYSQL, host, port,
					database, username, password);
			conn = SQLUtils.getConnection(connURL);
			
			String query = "DELETE FROM rss_feeds WHERE url = '" + url + "'";

			int result = SQLUtils.getRowCountFromUpdateQuery(conn, query);

			return "RSS Feed was deleted";
		} catch (Exception e) {
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}

	}

//	public String addAtomFeed(String url, String title) throws RemoteException {
//		try {
//
//			String connURL = SQLUtils.getConnectString(SQLUtils.MYSQL, host, port,
//					database, username, password);
//			conn = SQLUtils.getConnection(connURL);
//
//			Statement stat = conn.createStatement();
//
//			String query = "SELECT * FROM atom_feeds WHERE url = '" + url + "'";
//
//			ResultSet checkIfExists = stat.executeQuery(query);
//
//			// if url already exists then return
//			if (!checkIfExists.next())
//				return "Atom Feed alreadt exists";
//
////			String titleQuery = "SELECT * FROM atom_feeds WHERE title = '"
////					+ title + "'";
////
////			SQLResult checkTitleQueryResult = SQLUtils.getRowSetFromQuery(conn,titleQuery);
////
////			if (checkTitleQueryResult.rows.length != 0)
////				return "There is already a feed with the same title. Please give a different title.";
//
//			Map<String, Object> valueMap = new HashMap<String, Object>();
//
//			valueMap.put("title", title);
//			valueMap.put("url", url);
//
//			SQLUtils.insertRow(conn, database, "atom_feeds", valueMap);
//
//			return "Atom Feed added successfully";
//
//		} catch (Exception e) {
//			e.printStackTrace();
//			throw new RemoteException(e.getMessage());
//		}
//
//	}
//
//	public void deleteAtomFeed(String title) {
//		try {
//
//			String url = SQLUtils.getConnectString(SQLUtils.MYSQL, host, port,
//					database, username, password);
//			conn = SQLUtils.getConnection(url);
//
//			String deleteFileSource = "DELETE FROM atom_feeds WHERE titile ='"
//					+ title + "')";
//
//			Statement stat = conn.createStatement();
//			int result = stat.executeUpdate(deleteFileSource);
//
//			System.out.println("deleting atom feed: " + result);
//
//			stat.close();
//			conn.close();
//
//		} catch (Exception e) {
//			e.printStackTrace();
//		}
//
//	}

//	public void addFilePath(String url, String title) {
//		try {
//
//			String connURL = SQLUtils.getConnectString("MySQL", host, port,
//					database, username, password);
//			conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
//
//			String insertFileSource = "INSERT INTO file_sources (url,title) VALUE ('"
//					+ url + "','" + title + "')";
//
//			Statement stat = conn.createStatement();
//			int result = stat.executeUpdate(insertFileSource);
//
//			System.out.println("adding file path : " + result);
//
//			recursivelyAddFiles(url);
//
//		} catch (Exception e) {
//			e.printStackTrace();
//		}
//
//	}

//	public void recursivelyAddFiles(String path) {
//
//		File file = new File(path);
//
//		if (file.isFile()) {
//			try {
//
//				String url = SQLUtils.getConnectString("MySQL", host, port,
//						database, username, password);
//				conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
//
//				String insertFileSource = "INSERT INTO file_paths (url,title) VALUE ('"
//						+ path + "')";
//
//				Statement stat = conn.createStatement();
//				int result = stat.executeUpdate(insertFileSource);
//
//				System.out.println("adding file path : " + result);
//
//				stat.close();
//				conn.close();
//
//			} catch (Exception e) {
//				e.printStackTrace();
//			}
//		} else if (file.isDirectory()) {
//			String[] fileList = file.list();
//
//			for (int i = 0; i < fileList.length; i++) {
//				recursivelyAddFiles(path + "/" + fileList[i]);
//			}
//
//		}
//
//	}
//
//	public void deleteFilePath(String title) {
//		try {
//
//			String url = SQLUtils.getConnectString("MySQL", host, port,
//					database, username, password);
//			conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
//
//			String deleteFileSource = "DELETE FROM file_sources WHERE titile ='"
//					+ title + "')";
//
//			Statement stat = conn.createStatement();
//			int result = stat.executeUpdate(deleteFileSource);
//
//			System.out.println("deleting file path : " + result);
//
//			stat.close();
//			conn.close();
//
//		} catch (Exception e) {
//			e.printStackTrace();
//		}
//
//	}

	public String renameFile(String filePath, String newName, Boolean overwrite) {
		File file = new File(filePath);
		if (file.isFile()) {
			File newFile = new File(file.getAbsolutePath() + newName);
			if (newFile.isFile())
				if (!overwrite)
					return "file name already exists. Give a new file name or allow overwrite.";
				else {
					newFile.delete();
				}

			Boolean result = file.renameTo(newFile);
			if (result)
				return "file sucessfully renamed";
			else
				return "file rename not successful";
		} else {
			return "Given file path is not a file";
		}
	}

	/**
	 * This function takes an array of entities and an array of documents. This
	 * checks for which entities are present in the documents and returns that
	 * set of entities
	 * 
	 * @param entities
	 * @param docs
	 * @return
	 */
	public String[] searchInDocuments(String[] entities, String[] docs,
			String solrURL) {
		setSolrServer(solrURL);
		HashMap<String, Boolean> matchedEntitiesMap = new HashMap<String, Boolean>();

		for (int i = 0; i < docs.length; i++) {
			// $match = array('\\', '+', '-', '&', '|', '!', '(', ')', '{', '}',
			// '[', ']', '^', '~', '*', '?', ':', '"', ';', ' ');
			// $replace = array('\\\\', '\\+', '\\-', '\\&', '\\|', '\\!',
			// '\\(', '\\)', '\\{', '\\}', '\\[', '\\]', '\\^', '\\~', '\\*',
			// '\\?', '\\:', '\\"', '\\;', '\\ ');

			String docURL = docs[i].replaceAll("\\:", "\\\\:");
			docURL = docURL.replaceAll("&amp;", "%26");
			System.out.println("QUERYING FOR " + docURL);
			String queryURL = solrServerUrl + "/select/?version=2.2&start=0&rows=1&indent=on&fl=description&q=link:"
					+ docURL;
			try {

				URL url = new URL(queryURL);
				URLConnection solrConn = url.openConnection();
				solrConn.setDoOutput(true);

				// read the response
				BufferedReader rd = new BufferedReader(new InputStreamReader(
						solrConn.getInputStream()));

				String line;
				String content = "";
				while ((line = rd.readLine()) != null) {

					content += line;
				}

				content = content.replaceAll("[^ -~]", " ");

				Document doc = XMLUtils.getXMLFromString(content);

				XPathFactory factory = XPathFactory.newInstance();
				XPath xpath = factory.newXPath();

				String descr = XMLUtils.getStringFromXPath(doc, xpath,
						"/response/result/doc/str/text()");

				for (int j = 0; j < entities.length; j++) {
					if (descr.toLowerCase().indexOf(entities[j].toLowerCase()) != -1) {
						matchedEntitiesMap.put(entities[j], true);
					}
				}

			} catch (Exception e) {
				e.printStackTrace();
			}

		}

		return matchedEntitiesMap.keySet().toArray(new String[0]);

	}

	public long getNumberOfMatchedDocuments(String query, String fq,
			String solrURL) {
		setSolrServer(solrURL);
		// query = query + "&wt=json";
		QueryResponse response = null;
		try {

			SolrQuery q = new SolrQuery().setQuery(query);
			if (!fq.isEmpty())
				q.setFilterQueries(fq);
			q.setRows(1);
			response = solrInstance.query(q);

			//System.out.println("QUERY IS " + q.toString());

		} catch (Exception e) {
			e.printStackTrace();
		}
		return response.getResults().getNumFound();
	}

	private int highlightSnippetsCount = 10;
	private int highlightFragmentSize = 150;
	private ExecutorService executor = Executors.newFixedThreadPool(10);
	private DebugTimer timer = new DebugTimer();

	private static String formulateQuery(String[] requiredKeywords,
			String[] relatedKeywords, String operator) {
		String result = null;

		// We OR the required keywords and OR the related keywords. Then we AND
		// between the two.
		// So this way, we have at least one of the required keywords and one of
		// the related keywords

		if (requiredKeywords == null || requiredKeywords.length == 0) {
			return result;
		}
		
		String queryString = "";
		if(relatedKeywords == null || relatedKeywords.length ==0)
		{
			queryString = mergeKeywords(requiredKeywords, operator);
		}
		else
		{
			
			String requiredQueryString = mergeKeywords(requiredKeywords, operator);
			queryString = "(" + requiredQueryString + ")";
			
			if (relatedKeywords != null && relatedKeywords.length > 0) {
				String relatedQueryString = mergeKeywords(relatedKeywords, "OR");
				queryString = queryString + " AND " + "(" + relatedQueryString
				+ ")";
			}
		}
		

		result = "title:(" + queryString + ") OR description:(" + queryString
				+ ") OR attr_text_keywords:(" + queryString + ")";

		return result;
	}
	
	public String[][] getWordCount(String[] requiredKeywords,
			String[] relatedKeywords, String dateFilter, String operator,String sources,String sortBy) {
		setSolrServer(solrServerUrl);

		String[][] result = null;

		String queryString = formulateQuery(requiredKeywords, relatedKeywords,operator);

		if (queryString == null)
			return null;

		try {


			SolrQuery q = new SolrQuery().setQuery(queryString);
			
			setSortField(q,sortBy);
			
			if (dateFilter != null)
				if (!dateFilter.isEmpty())
					q.setFilterQueries(dateFilter);
			
			if(sources!=null && sources.length()>0)
			{
				q.setFilterQueries("source:"+sources);
			}
			
			
			// set number of rows
			q.setRows(1);

			q.addFacetField("description");
			q.setFacet(true);
			q.setFacetLimit(100);
			q.set("facet.method", "enum"); 
			// set fields to title,date and summary only
			q.setFields("link");

			QueryResponse response = solrInstance.query(q);

			FacetField ff = response.getFacetField("description");
			Iterator<Count> iter2 = ff.getValues().iterator();

			String[][] wordCount = new String[ff.getValueCount()][2];
			result = new String[ff.getValueCount()][2];
			int countIndex = 0;

			while (iter2.hasNext()) {
				Count currentCount = iter2.next();

				String[] temp = new String[2];

				temp[0] = currentCount.getName();
				temp[1] = String.valueOf(currentCount.getCount());

				wordCount[countIndex] = temp;
				countIndex++;
			}

			result = wordCount.clone();
		} catch (Exception e) {
			System.out.println("Error getting Facet Count ");
			e.printStackTrace();
		}

		return result;
	}
	
	//return all the sentences that contains at least one required keyword and one related keywords
	public String[] entitySentences(String[] requiredKeywords, String[] relatedKeywords, String dateFilter,
			 int rows,String operator) throws NullPointerException{
		
		setSolrServer(solrServerUrl);
		String queryString = formulateQuery(requiredKeywords, relatedKeywords,operator);  
        Set<String> tempresult = new HashSet<String>();
		if (queryString == null)
			return null;
		try {

			// Query Results are always sorted by descending order of relevance
			SolrQuery q = new SolrQuery().setQuery(queryString).setSortField(
					"score", SolrQuery.ORDER.desc);
			if (dateFilter != null)
				if (!dateFilter.isEmpty())
					q.setFilterQueries(dateFilter);
			q.setRows(rows);
			q.setFields("link,description");
			QueryResponse response = solrInstance.query(q);
			SolrDocumentList documents = response.getResults();
			int documentSize = documents.size();
			SolrDocument doc = null;
			String originalTexts = "";
			URL sentenceModelPath = getClass().getClassLoader().getResource("infomap/resources/en-sent.bin");
	        String sentenceModelFilePath = URLDecoder.decode(sentenceModelPath.getFile(),"UTF-8");
	        SentenceModel senModel = new SentenceModel(new FileInputStream(sentenceModelFilePath));
	        SentenceDetectorME sentenceDetector = new SentenceDetectorME(senModel);
	        String sentences[] = null;
			Iterator<SolrDocument> itr1 = documents.iterator();
			if (documentSize > 0) {
				while(itr1.hasNext()){
					doc = itr1.next();
					if (doc.getFieldValue("description") != null) {
					originalTexts = doc.getFieldValue("description").toString();
					sentences = sentenceDetector.sentDetect(doc.getFieldValue("description").toString());
					for(int j=0; j<sentences.length; j++){
                        //use required keyword and related keyword
						for(int k=0; k<requiredKeywords.length; k++){
							for(int l=0; l<relatedKeywords.length; l++){
								if(sentences[j].contains(requiredKeywords[k]) && sentences[j].contains(relatedKeywords[l]) && !tempresult.add(sentences[j]) ){ 
									tempresult.add(sentences[j]); 
									}
							}
						}
					}
				}
				}				
				
			} else {
				System.out.println("NO Documents returned...");
			}

		} catch (Exception e) {
			e.printStackTrace();
		}
		String [] result = new String[tempresult.size()];
		Iterator<String> iter = tempresult.iterator();
		int tempcounter = 0;
		String tempString = "";
		while(iter.hasNext()){
			tempString = iter.next();
			result[tempcounter] = tempString;
            tempcounter++;
		}
		
		//tracing
/*		for(int i=0; i<result.length; i++){
			System.out.println("******" + result[i]);
		}*/
		
		return result;
	}

	//use topic modeling to divide all the documents returned for a query into several groups
	public TopicClassificationResults classifyDocumentsForQuery(
			String[] requiredKeywords, String[] relatedKeywords,
			String dateFilter, int rows, int numOfTopics,
			int numOfKeywordsInEachTopic,String operator,String sources,String sortBy) throws NullPointerException {
		setSolrServer(solrServerUrl);

		ArrayList<String[]> r = new ArrayList<String[]>();
		
		String[] uncategoried = null;
        Set<String> tempuncategoried = new HashSet<String>();

		String queryString = formulateQuery(requiredKeywords, relatedKeywords,operator);

		if (queryString == null)
			return null;

		TopicClassificationResults topicModelingResutls = new TopicClassificationResults();
		try {

			// Query Results are always sorted by descending order of relevance
			SolrQuery q = new SolrQuery().setQuery(queryString);
			setSortField(q, sortBy);
			
			if (dateFilter != null)
				if (!dateFilter.isEmpty())
					q.setFilterQueries(dateFilter);
			
			if(sources!=null && sources.length()>0)
			{
				q.setFilterQueries("source:"+sources);
			}
			
			// set number of rows
			q.setRows(rows);

			q.setFields("link,description");

			QueryResponse response = solrInstance.query(q);
			SolrDocumentList documents = response.getResults();
			int documentSize = documents.size();
			SolrDocument doc = null;
			Iterator<SolrDocument> itr = documents.iterator();
			String originalTexts = "";
			String singleInstance = "";
			if (documentSize > 0) {
				while (itr.hasNext()) {
					doc = itr.next();
					if (doc.getFieldValue("description") != null) {
						singleInstance = doc.getFieldValue("link").toString()
								+ "\t"
								+ "X"
								+ "\t"
								+ doc.getFieldValue("description").toString()
										.replace('\n', ' ').replace('\r', ' ')
								+ "\r\n";
						originalTexts += singleInstance;
					}else{
						tempuncategoried.add(doc.getFieldValue("link").toString());
					}
				}
			} else {
				System.out.println("NO Documents returned...");
			}

			// Begin by importing documents from text to feature sequences
			ArrayList<Pipe> pipeList = new ArrayList<Pipe>();

			// Pipes: lowercase, tokenize, remove stopwords, map to features
			pipeList.add(new CharSequenceLowercase());
			pipeList.add(new CharSequence2TokenSequence(Pattern
					.compile("\\p{L}[\\p{L}\\p{P}]+\\p{L}")));
		
			URL stoplistPath = getClass().getClassLoader().getResource(
					"infomap/resources/stopwords.txt");
//			System.out.println(stoplistPath.getFile());
			String stopListFilePath = URLDecoder.decode(stoplistPath.getFile(),
					"UTF-8");
			pipeList.add(new TokenSequenceRemoveStopwords(new File(
					stopListFilePath), "UTF-8", false, false, false));
			pipeList.add(new TokenSequence2FeatureSequence());
			InstanceList instances = new InstanceList(new SerialPipes(pipeList));
			Reader fileReader = new InputStreamReader(
					IOUtils.toInputStream(originalTexts));
			instances
					.addThruPipe(new CsvIterator(
							fileReader,
							Pattern.compile("^(\\S*)[\\s]*(\\S*)[\\s]*([\\w\\W\\s\\S\\d\\D]*)$"),
							3, 2, 1)); 	// data, label, name, fields

			// Create a model with numOfTopics topics, alpha_t = 0.01, beta_w = 0.01
			// Note that the first parameter is passed as the sum over topics,
			// while the second is the parameter for a single dimension of the
			// Dirichlet prior.
			ParallelTopicModel model = new ParallelTopicModel(numOfTopics, 1.0,
					0.01);
			model.logger.setLevel(java.util.logging.Level.OFF);
			model.addInstances(instances);

			//two parallel samplers
			model.setNumThreads(2);

			//for better result, change 100 to some larger number such as 1000 or 2000
			model.setNumIterations(100);
			model.estimate();

			Alphabet dataAlphabet = instances.getDataAlphabet();
			int dataSize = instances.size();
			int[] groupInfo = new int[dataSize];
			for (int i = 0; i < dataSize; i++) {
				groupInfo[i] = 0;
			}

			double[] distributions;
			double temp;
			for (int i = 0; i < dataSize; i++) {
				distributions = model.getTopicProbabilities(i);
				temp = 0.0;
				for (int j = 0; j < distributions.length; j++) {
					if (temp < distributions[j]) {
						groupInfo[i] = j;
						temp = distributions[j];
					}
				}
			}
			int[] groupSize = new int[numOfTopics];
			for (int i = 0; i < numOfTopics; i++) {
				groupSize[i] = 0;
			}

			for (int i = 0; i < dataSize; i++) {
				groupSize[groupInfo[i]]++;
			}

			// document Group infomation
			String documentGroupInfo[][] = new String[dataSize][2];
			for (int i = 0; i < dataSize; i++) {
				for (int j = 0; j < 2; j++) {
					documentGroupInfo[i][j] = "";
				}
			}

			for (int i = 0; i < dataSize; i++) {
				documentGroupInfo[i][0] = documents.get(i)
						.getFieldValue("link").toString();
				documentGroupInfo[i][1] = Integer.toString(groupInfo[i]);
			}

			// Get an array of sorted sets of word ID/count pairs
			ArrayList<TreeSet<IDSorter>> topicSortedWords = model
					.getSortedWords();

			String topicKeywords[][] = new String[numOfTopics][numOfKeywordsInEachTopic];
			for (int i = 0; i < numOfTopics; i++) {
				for (int j = 0; j < numOfKeywordsInEachTopic; j++) {
					topicKeywords[i][j] = "";
				}
			}

			HashMap<Object, Integer> uniquewordChecker = new HashMap<Object, Integer>();

			for (int topic = 0; topic < numOfTopics; topic++) {
				Iterator<IDSorter> iterator = topicSortedWords.get(topic)
						.iterator();
				while (iterator.hasNext()) {
					IDSorter idCountPair = iterator.next();
					if (uniquewordChecker.containsKey(dataAlphabet
							.lookupObject(idCountPair.getID()))) {
						uniquewordChecker
								.put(dataAlphabet.lookupObject(idCountPair
										.getID()), uniquewordChecker
										.get(dataAlphabet
												.lookupObject(idCountPair
														.getID())) + 1);
					} else {
						uniquewordChecker.put(
								dataAlphabet.lookupObject(idCountPair.getID()),
								1);
					}
				}
			}

			for (int topic = 0; topic < numOfTopics; topic++) {
				Iterator<IDSorter> iterator = topicSortedWords.get(topic)
						.iterator();
				int rank = 0;
				while (iterator.hasNext() && rank < numOfKeywordsInEachTopic) {
					IDSorter idCountPair = iterator.next();
					if (uniquewordChecker.get(dataAlphabet
							.lookupObject(idCountPair.getID())) == 1) {
						topicKeywords[topic][rank] = dataAlphabet
								.lookupObject(idCountPair.getID()) + " ";
						rank++;
					}
				}
				// System.out.println(out);
			}
			String[][] resultUrls = new String[numOfTopics][];

			for (int i = 0; i < numOfTopics; i++) {
				resultUrls[i] = new String[groupSize[i]];
				int tempCounter = 0;
				// for(int j = 0; j < groupSize[i]; j++){

				for (int k = 0; k < dataSize; k++) {
					if (groupInfo[k] == i) {
						resultUrls[i][tempCounter] = documents.get(k)
								.getFieldValue("link").toString();
						tempCounter++;
					}
				}
			}
			 //tracing
/*			 for(int i = 0; i < numOfTopics; i++)
			 {
			 for(int j = 0; j < numOfKeywordsInEachTopic; j++)
			 {
			 System.out.print(topicKeywords[i][j]);
			 }
			 System.out.println();
			 }*/

			if(tempuncategoried.size()>0){
				uncategoried = new String[tempuncategoried.size()];
				Iterator<String> iter = tempuncategoried.iterator();
				int tempcounter = 0;
				String tempString = "";
				while(iter.hasNext()){
					tempString = iter.next();
					uncategoried[tempcounter] = tempString;
		            tempcounter++;
				}
			}
			
			topicModelingResutls.keywords = topicKeywords;

			topicModelingResutls.urls = resultUrls;
			
			topicModelingResutls.uncategoried = uncategoried;
			

		} catch (Exception e) {
			e.printStackTrace();
		}

		return topicModelingResutls;
	}
	
	public String[][] getClustersForQueryWithRelatedKeywords(
			String[] requiredKeywords, String[] relatedKeywords,
			String dateFilter, int rows,String operator,String sources,String sortBy) throws IOException, SolrServerException
	{
		String[][] result = null;
		
		setSolrServer(solrServerUrl);
		
		String queryString = formulateQuery(requiredKeywords, relatedKeywords,operator);
		if (queryString == null)
			return null;
		try{
			// Query Results are always sorted by descending order of relevance
			SolrQuery q = new SolrQuery().setQuery(queryString);
			
			setSortField(q, sortBy);
			
			if (dateFilter != null)
				if (!dateFilter.isEmpty())
					q.setFilterQueries(dateFilter);

			if(sources!=null && sources.length()>0)
			{
				q.setFilterQueries("source:"+sources);
			}
			
			// set number of rows
			q.setRows(rows);

			// set field to hasSummary. Just a field with low content. Since we are only interested in the clusters
			q.setFields("link");
			
			URL url = new URL(solrInstance.getBaseURL()+ "/" + "clustering?" + q.toString()+"&wt=json");
			
			StringWriter writer = new StringWriter();
			IOUtils.copy(url.openStream(),writer,"UTF-8");
			Gson gson = new Gson();
			SolrClusterResponseModel clusterResponse = gson.fromJson(writer.toString(), SolrClusterResponseModel.class);
			
			int numOfDocs = clusterResponse.response.docs.length;
			int numOfLabels = clusterResponse.clusters.length;
			
			Map<String,Object> docsToLabel = new HashMap<String, Object>();
			
			for (int i=0; i < numOfDocs; i++)
			{
				String link = (String)clusterResponse.response.docs[i].link;
				Map<String, String> lScore = new HashMap<String, String>(numOfLabels);
				for (int j=0; j < numOfLabels; j++)
				{
					String label = clusterResponse.clusters[j].labels[0];
					
					if(clusterResponse.clusters[j].docs.contains(link))
					{
						lScore.put(label, String.valueOf(clusterResponse.clusters[j].score));
					}
					else
					{
						lScore.put(label, "0.0");
					}
				}
				docsToLabel.put(link, lScore);
			}
			Set<String> docs = docsToLabel.keySet();
			
			Iterator<String> docIterator = docs.iterator();
			List<Map<String, String>> records = new ArrayList<Map<String,String>>();
			
			while(docIterator.hasNext())
			{
				String doc = docIterator.next();
				Map<String, String> recordObject = new HashMap<String, String>();
				recordObject.put("document", doc);
				recordObject.putAll((Map<String, String>)docsToLabel.get(doc));
				records.add(recordObject);
			}
			
			Map<String, String>[] rs = records.toArray(new HashMap[records.size()]);
			
			result = new CSVParser().convertRecordsToRows(rs);
			
		}catch (Exception e) {
			// TODO: handle exception
			e.printStackTrace();
		}
		
		return result;
	}
	
	public Object[] getResultsForQueryWithRelatedKeywords(
			String[] requiredKeywords, String[] relatedKeywords,
			String dateFilter, int rows,String operator,String sources,String sortBy) throws NullPointerException {
		setSolrServer(solrServerUrl);

		ArrayList<String[]> r = new ArrayList<String[]>();

		String queryString = formulateQuery(requiredKeywords, relatedKeywords,operator);
		if (queryString == null)
			return null;

		try {

			SolrQuery q = new SolrQuery().setQuery(queryString);
			
			setSortField(q,sortBy);
			
			if (dateFilter != null)
				if (!dateFilter.isEmpty())
					q.setFilterQueries(dateFilter);
			
			if(sources!=null && sources.length()>0)
			{
				q.setFilterQueries("source:"+sources);
			}
			
			// set number of rows
			q.setRows(rows);

			// set fields to title,date and summary only
			q.setFields("link,title,date_added,date_published,imgName");

			QueryResponse response = solrInstance.query(q);
			Iterator<SolrDocument> iter = response.getResults().iterator();

			//System.out.println("QUERY IS " + q.toString());

			while (iter.hasNext()) {
				SolrDocument doc = iter.next();
				String[] docArray = new String[5];

				docArray[0] = (String) doc.getFieldValue("link");
				docArray[1] = (String) doc.getFieldValue("title");

				if (doc.getFieldValue("imgName") != null)
				{
					String imageURL = (String)doc.getFieldValue("imgName");
					if (imageURL.contains("http"))
					{
						docArray[2] = imageURL;
					}else
					{
						docArray[2] = serverURL + "thumbnails/"
						+ (String) doc.getFieldValue("imgName");
					}
				}
					
				if (doc.containsKey("date_published"))
					docArray[3] = doc.getFieldValue("date_published")
							.toString();
				else
					docArray[3]= "";
				
				if (doc.containsKey("date_added"))
					docArray[4] = doc.getFieldValue("date_added").toString();
				else
					docArray[4] = "";

				r.add(docArray);
			}

		} catch (Exception e) {
			e.printStackTrace();
		}

		Object[] queryResult = r.toArray();
		return queryResult;

	}
	
	private void setSortField(SolrQuery q, String sortBy)
	{
		// Query Results are always sorted by descending order of relevance
		String sortField = "";
		if(sortBy.equals("Relevance"))
			sortField = "score";
		else if (sortBy.equals("Date Published"))
			sortField = "date_published";
		else if (sortBy.equals("Date Added"))
			sortField = "date_added";
		
		q.addSortField(sortField, ORDER.desc);
		
		/* add a secondary sort field*/
		if(!sortField.equals("date_added"))
			q.addSortField("date_added", ORDER.desc);
	}
	
	public String getDescriptionForURL(String url, String[] keywords)
	{
		setSolrServer(solrServerUrl);
		
		if (url == null)
			return null;
		String result ="";
		try {
			
			//OR all keywords so that they are highlighted
			String queryString = "";
			
			for (int i=0; i<keywords.length; i++)
			{
				if(i+1 == keywords.length)
				{
					queryString += keywords[i];
					break;
				}
				queryString += keywords[i] + " OR ";
			}
			
			// Query Results are always sorted by descending order of relevance
			SolrQuery q = new SolrQuery().setQuery(queryString);

			// set fields to title,date and summary only
			q.setFields("link,attr_text_summary");
			q.setRows(1);//redundant but still
			String filteredQuery ="link:\""+url+"\""; 
			q.setFilterQueries(filteredQuery);
			
			// set highlighting
			q.setHighlight(true).setHighlightSnippets(highlightSnippetsCount)
					.setHighlightFragsize(highlightFragmentSize);

			q.setParam("hl.fl", "description");

			q.setParam("hl.simple.pre", "<b>");
			q.setParam("hl.simple.post", "</b>");
			
			QueryResponse response = solrInstance.query(q);
			Iterator<SolrDocument> iter = response.getResults().iterator();

			while (iter.hasNext()) {
				SolrDocument doc = iter.next();
				String docSummary = (String) doc.getFieldValue("attr_text_summary");
				if (docSummary != null) {
					result += "<b>Summary: </b>" + docSummary;
				}
			}
			//Show sentences with containing query words
			if (response.getHighlighting().get(url)
					.get("description") != null) {
				List<String> highlightsList = response.getHighlighting()
						.get(url).get("description");

				Iterator<String> highlightsIter = highlightsList.iterator();

				result += "<br/><br/><b>Matches: </b>";

				while (highlightsIter.hasNext()) {
					result += " '" + highlightsIter.next()
							+ "'...<br/><br/>";
				}

			}
		}catch(Exception e)
		{
			e.printStackTrace();
		}
		
		return result;
		
	}

	public Object[] getLinksForFilteredQuery(String[] requiredKeywords,
			String[] relatedKeywords, String dateFilter, String[] filterby,
			int rows,String operator,String sources,String sortBy) throws NullPointerException {
		setSolrServer(solrServerUrl);

		ArrayList<String> r = new ArrayList<String>();

		String queryString = formulateQuery(requiredKeywords, relatedKeywords, operator);

		if (queryString == null)
			return null;

		try {

			// Query Results are always sorted by descending order of relevance
			SolrQuery q = new SolrQuery().setQuery(queryString);
			
			setSortField(q, sortBy);

			String filterString = "";

			for (int i = 0; i < filterby.length; i++) {
				filterString += "(title:" + filterby[i] + " OR description:"
						+ filterby[i] + " OR attr_text_keywords:" + filterby[i]
						+ ")";

				if (i != filterby.length - 1) {
					filterString += " AND ";
				}
			}

			if (dateFilter != null)
				if (!dateFilter.isEmpty())
					filterString += filterString + " AND " + dateFilter;

			if (!filterString.isEmpty())
				q.addFilterQuery(filterString);
			
			if(sources!=null && sources.length()>0)
			{
				q.addFilterQuery("source:"+sources);
			}

			// set number of rows
			q.setRows(rows);

			// set fields to title,date and summary only
			q.setFields("link");

			QueryResponse response = solrInstance.query(q);
			Iterator<SolrDocument> iter = response.getResults().iterator();

			//System.out.println("QUERY IS " + q.toString());

			while (iter.hasNext()) {
				SolrDocument doc = iter.next();

				r.add((String) doc.getFieldValue("link"));
			}

		} catch (Exception e) {
			e.printStackTrace();
		}

		Object[] queryResult = r.toArray();
		return queryResult;

	}

	public long getNumOfDocumentsForQuery(String[] requiredKeywords,
			String[] relatedKeywords, String dateFilter, String operator,String sources) {
		setSolrServer(solrServerUrl);

		String queryString = formulateQuery(requiredKeywords, relatedKeywords, operator);

		if (queryString == null)
			return 0;

		QueryResponse response = null;
		try {

			SolrQuery q = new SolrQuery().setQuery(queryString);

			if (dateFilter != null)
				if (!dateFilter.isEmpty())
					q.setFilterQueries(dateFilter);
			
			if(sources!=null && sources.length()>0)
			{
				q.setFilterQueries("source:"+sources);
			}
			
			q.setRows(1);
			q.setFields("link");

			response = solrInstance.query(q);

		} catch (Exception e) {
			e.printStackTrace();
		}
		return response.getResults().getNumFound();
	}

	public EntityDistributionObject getEntityDistributionForQuery(
			String[] requiredKeywords, String[] relatedKeywords,
			String dateFilter, String[] entities, int rows, String operator,String sources,String sortBy) {

		Object[][] urls = new Object[entities.length][];

		setSolrServer(solrServerUrl);

		// Setting up the query
		String queryString = formulateQuery(requiredKeywords, relatedKeywords, operator);

		if (queryString == null) {
			return null;
		}

		QueryResponse response = null;
		try {

			SolrQuery q = new SolrQuery().setQuery(queryString);

			setSortField(q, sortBy);
			
			if (dateFilter != null)
				if (!dateFilter.isEmpty())
					q.setFilterQueries(dateFilter);

			if(sources!=null && sources.length()>0)
			{
				q.setFilterQueries("source:"+sources);
			}
			
			q.setFields("link");

			// Setting up the Group Parameters
			// For each value in the entities array, we set up a group by query
			// and search for the entity value in the title or description.
			q.set(GroupParams.GROUP, true);

			q.set(GroupParams.GROUP_LIMIT, rows);

			int count = 0;
			for (int i = 0; i < entities.length; i++) 
			{
//				System.out.println("RUNNING QUERY FOR ENTITY" + entities[i]);
				String groupQuery = "title:(\"" + entities[i]
						+ "\") OR description:(\"" + entities[i] + "\")";
				q.set(GroupParams.GROUP_QUERY, groupQuery);
				// groupQuery= "title:(\"" + entities[i] +
				// "\") OR description:(\"" + entities[i] + "\")";
				// q.add(GroupParams.GROUP_QUERY, groupQuery);

				// System.out.println("ENTITY QUERY" + q.toString());

				response = solrInstance.query(q);

				GroupResponse gr = response.getGroupResponse();

				List<GroupCommand> gc = gr.getValues();

				Iterator<GroupCommand> gcIter = gc.iterator();

				while (gcIter.hasNext()) {
					GroupCommand g = gcIter.next();

					List<Group> groups = g.getValues();

					Iterator<Group> groupsIter = groups.iterator();
					while (groupsIter.hasNext()) {
						Group group = groupsIter.next();

						SolrDocumentList docList = group.getResult();

						Iterator<SolrDocument> docIter = docList.iterator();
						ArrayList<String> docs = new ArrayList<String>();
						while (docIter.hasNext()) {
							SolrDocument doc = docIter.next();

							docs.add((String) doc.getFieldValue("link"));
						}
						urls[count] = docs.toArray();
					}
				}
				count++;
			}

		} catch (Exception e) {
			e.printStackTrace();
		}

		EntityDistributionObject result = new EntityDistributionObject();

		result.entities = entities;
		result.urls = urls;
		return result;
	}

	private static String mergeKeywords(String[] keywords, String operator) {
		String result = "";

		if (keywords == null || keywords.length == 0)
			return result;
		String tempStr = "";
		for (int i = 0; i < keywords.length; i++) 
		{
			
			tempStr = keywords[i].trim();
			
			result += tempStr;			
			if (i != keywords.length - 1)
			{
				result += " " + operator + " ";
			}
		}
		return result;
	}
	
	public long getTotalNumberOfQueryResults(String[] requiredQueryTerms, String[] relatedQueryTerms)
	{
		long result=0;

		if(requiredQueryTerms == null)
			return 0;
		
		MendeleyDataSource mds = new MendeleyDataSource();
		mds.requiredQueryTerms= requiredQueryTerms.clone();
		if(relatedQueryTerms != null)
			mds.relatedQueryTerms = relatedQueryTerms.clone();
		result = result + mds.getTotalNumberOfQueryResults();
		
		ArxivDataSource ads = new ArxivDataSource();
		ads.requiredQueryTerms = requiredQueryTerms.clone();
		if(relatedQueryTerms != null)
			ads.relatedQueryTerms = relatedQueryTerms.clone();
		result = result + ads.getTotalNumberOfQueryResults();
		
		BaseDataSource bds = new BaseDataSource();
		bds.requiredQueryTerms = requiredQueryTerms.clone();
		if(relatedQueryTerms != null)
			bds.relatedQueryTerms = relatedQueryTerms.clone();
		result = result + bds.getTotalNumberOfQueryResults();
		
		OpenLibraryDataSource olds = new OpenLibraryDataSource();
		olds.requiredQueryTerms = requiredQueryTerms.clone();
		olds.solrServerURL = solrServerUrl;
		result = result + olds.getTotalNumberOfQueryResults();
		
		GoogleBooksDataSource gbds = new GoogleBooksDataSource();
		gbds.requiredQueryTerms = requiredQueryTerms.clone();
		gbds.solrServerURL = solrServerUrl;
		result = result + gbds.getTotalNumberOfQueryResults();
		return result;
	}
	
	public void queryDataSources(String[] requiredQueryTerms, String[] relatedQueryTerms) 
	{
		if(requiredQueryTerms == null)
			return;
		
		MendeleyDataSource mds = new MendeleyDataSource();
		mds.requiredQueryTerms= requiredQueryTerms.clone();
		if(relatedQueryTerms != null)
			mds.relatedQueryTerms = relatedQueryTerms.clone();
		mds.solrServerURL = solrServerUrl;

		ArxivDataSource ads = new ArxivDataSource();
		ads.requiredQueryTerms = requiredQueryTerms.clone();
		if(relatedQueryTerms != null)
			ads.relatedQueryTerms = relatedQueryTerms.clone();
		ads.solrServerURL = solrServerUrl;

		BaseDataSource bds = new BaseDataSource();
		bds.requiredQueryTerms = requiredQueryTerms.clone();
		if(relatedQueryTerms != null)
			bds.relatedQueryTerms = relatedQueryTerms.clone();
		bds.solrServerURL = solrServerUrl;
		
		OpenLibraryDataSource olds = new OpenLibraryDataSource();
		olds.requiredQueryTerms = requiredQueryTerms.clone();
		olds.solrServerURL = solrServerUrl;
		
		GoogleBooksDataSource gbds = new GoogleBooksDataSource();
		gbds.requiredQueryTerms = requiredQueryTerms.clone();
		if(relatedQueryTerms != null)
			gbds.relatedQueryTerms = relatedQueryTerms.clone();
		gbds.solrServerURL = solrServerUrl;
		
		
		executor.execute(ads);
		executor.execute(mds);
		executor.execute(bds);
		if(!_testMode)
		{
			executor.execute(olds);
			executor.execute(gbds);
		}
		System.out.println("Finished Calling Sources " + timer.get());
	}

	public QueryResultWithWordCount getQueryResults(String[] queryTerms,
			String fq, String sortField, int rows, String solrURL)
			throws NullPointerException {
		setSolrServer(solrURL);
		// query = query + "&wt=json";
		timer.start();
//		System.out.println("CALLING GET QUERY");

		String query = parseBasicQuery(queryTerms, "AND");
		long totalNumberOfDocuments = getNumberOfMatchedDocuments(query, fq,
				solrURL);

		ArrayList<String[]> r = new ArrayList<String[]>();
		QueryResultWithWordCount result = new QueryResultWithWordCount();

		try {

			SolrQuery q = new SolrQuery().setQuery(query).setSortField(
					sortField, SolrQuery.ORDER.asc);
			if (!fq.isEmpty())
				q.setFilterQueries(fq);

			// set number of rows
			q.setRows(rows);

			// set highlighting
			q.setHighlight(true).setHighlightSnippets(highlightSnippetsCount)
					.setHighlightFragsize(highlightFragmentSize);

			q.setParam("hl.fl", "description");

			q.setParam("hl.simple.pre", "<b>");
			q.setParam("hl.simple.post", "</b>");

			q.addFacetField("description");
			q.setFacet(true);
			q.setFacetLimit(100);

			// set fields to title,date and summary only
			q.setFields("link,title,attr_text_summary,date_added,date_published,imgName");

			// .setFilterQueries(fq).setSortField(sortField,
			// SolrQuery.ORDER.desc);

//			System.out.println("Making Response " + timer.get());
			QueryResponse response = solrInstance.query(q);
//			System.out.println("Got Response " + timer.get()+ response.getElapsedTime() + response.getQTime());
			Iterator<SolrDocument> iter = response.getResults().iterator();

			//System.out.println("QUERY IS " + q.toString());

			// System.out.println("NUM OF DOCUMENTS IS " +
			// response.getResults().getNumFound());
			System.out.println("iterating throught documents " + timer.get());
			while (iter.hasNext()) {
				SolrDocument doc = iter.next();
				String[] docArray = new String[5];

				docArray[0] = (String) doc.getFieldValue("link");
				docArray[1] = (String) doc.getFieldValue("title");

				// Show text summary if exists
				docArray[2] = "";
				String docSummary = (String) doc
						.getFieldValue("attr_text_summary");
				if (docSummary != null) {
					docArray[2] += "<b>Summary: </b>" + docSummary;
				}
				// Show sentences with containing query words
				if (response.getHighlighting().get(docArray[0])
						.get("description") != null) {
					List<String> highlightsList = response.getHighlighting()
							.get(docArray[0]).get("description");

					Iterator<String> highlightsIter = highlightsList.iterator();

					docArray[2] += "<br/><br/><b>Matches: </b>";

					while (highlightsIter.hasNext()) {
						docArray[2] += " '" + highlightsIter.next() + "'...";
					}

				}
				// else //else show first 200 characters of description
				// {
				// String descr = (String)doc.getFieldValue("description");
				// docArray[2] = "<b>Description: </b>";
				// if(descr == null)
				// descr = "No description available";
				//
				// if(descr.length()>200)
				// docArray[2] = descr.substring(0, 200);
				// else
				// docArray[2] = descr;
				// }

				// int linkLen = docArray[0].length();
				// String linkExtension =
				// docArray[0].substring(linkLen-3,linkLen);
				// String imgExtension = ".jpg";
				//
				// if(linkExtension.equalsIgnoreCase("pdf") ||
				// linkExtension.equalsIgnoreCase("doc")){
				// imgExtension = ".png";
				// }
				if (doc.getFieldValue("imgName") != null)
					docArray[3] = serverURL + "thumbnails/"
							+ (String) doc.getFieldValue("imgName");

				if (doc.containsKey("date_published"))
					docArray[4] = doc.getFieldValue("date_published")
							.toString();
				else if (doc.containsKey("date_added"))
					docArray[4] = doc.getFieldValue("date_added").toString();
				else
					docArray[4] = "";
				// System.out.println("Content IS " + docArray[0] + docArray[1]
				// + docArray[2] + docArray[3] + docArray[4]);

				r.add(docArray);
			}

			// creating an array of facet words and its word count
			try {

				FacetField ff = response.getFacetField("description");
				Iterator<Count> iter2 = ff.getValues().iterator();

				String[][] wordCount = new String[ff.getValueCount()][2];

				int countIndex = 0;

				while (iter2.hasNext()) {
					Count currentCount = iter2.next();

					String[] temp = new String[2];

					temp[0] = currentCount.getName();
					temp[1] = String.valueOf(currentCount.getCount());

					wordCount[countIndex] = temp;
					countIndex++;
				}

				result.wordCount = wordCount.clone();
			} catch (Exception e) {
				System.out.println("Error getting Facet Count ");
				e.printStackTrace();
			}

		} catch (Exception e) {
			e.printStackTrace();
		}

		result.queryResult = r.toArray();
		result.totalNumberOfDocuments = (int) totalNumberOfDocuments;
		System.out.println("ENDING GET QUERY" + timer.get());
		return result;
	}

	/**
	 * Add documents from Array to Solr Server
	 * 
	 * @param an
	 *            array of SolrInputDocument
	 */
	public static void addDocuments(SolrInputDocument[] docs, String solrURL) {
		if (docs == null || docs.length == 0) {

			return;
		}

		List<SolrInputDocument> d = Arrays.asList(docs);

		setStreamingSolrServer(solrURL);
		try {
			streamingSolrserver.add(d);
			System.out.println("ADDING DOCUMENTS WITH Num Of DOcs: " + docs.length);
		} catch (Exception e) {
			System.out
					.println("Error when adding " + docs.length + "documents");
			e.printStackTrace();
		}
	}

	public static void addTextDocument(String username, String fileName,
			InputStream content, String solrURL) throws RemoteException,
			MalformedURLException, ParseException {
		String link = username + ":" + fileName;

		AutoDetectParser parser = new AutoDetectParser();

		ContentHandler textHandler = new BodyContentHandler();
		Metadata metadata = new Metadata();

		try {
			parser.parse(content, textHandler, metadata);
		} catch (Exception e) {
			e.printStackTrace();
		}

		SolrInputDocument doc = new SolrInputDocument();

		doc.addField("link", link);

		String title = metadata.get("title");
		if (title == null)
			title = fileName;

		Date currentDate = new Date();
		doc.addField("title", title);
		doc.addField("description", textHandler.toString());
		doc.addField("username", username);
		doc.addField("date_added", currentDate);

		if (metadata.get("Creation-Date") != null) {
			DateFormat formatter = new SimpleDateFormat(
					"yyyy-MM-dd'T'HH:mm:ss'Z'");
			Date date_published = new Date();
			date_published = formatter.parse(metadata.get("Creation-Date"));
			doc.addField("date_published", date_published);
		}

		// System.out.println("Dumping metadata for file: " + fileName);
		// for (String name : metadata.names()) {
		// System.out.println(name + ":" + metadata.get(name));
		// }

		addDoc(doc, solrURL, true);
	}

	private static void addDoc(SolrInputDocument d, String solrURL,
			Boolean commit) {
		try {
			setStreamingSolrServer(solrURL);
			SolrQuery q = new SolrQuery().setQuery("link:" + "\""
					+ d.getFieldValue("link").toString() + "\"");
			QueryResponse r = streamingSolrserver.query(q);

			if (r.getResults().getNumFound() > 0) {
				System.out.println("Document already exists "+ d.getFieldValue("link").toString());
			} else {

				streamingSolrserver.add(d);
			}

			// if(commit)
			// streamingSolrserver.commit();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * 
	 * @param query
	 * @param operator
	 * @return
	 */
	private static String parseBasicQuery(String[] query, String operator) {

		String queryString = "";

		// if it is not a single word we add the operator between each keyword
		// splitting the keywords at the spaces.
		if (query.length > 1) {
			for (int i = 0; i < query.length; i++) {
				queryString += query[i];
				// add operator for all terms except for last
				if (i != query.length - 1)
					queryString += " " + operator + " ";
			}

		} else {
			queryString = query[0];
		}

		// we need to search in both the title and the description fields.
		// the solr syntax for searching multiple words in a single field is
		// "field_name:(query words)"
		queryString = "title:(" + queryString + ") OR description:("
				+ queryString + ")";

		return queryString;
	}

	public String[] extractKeywords(String text) throws IOException
	{ 
		List<String> result = new ArrayList<String>();
		
		Reader r = new StringReader(text);
		
		PTBTokenizer ptbt = new PTBTokenizer(r, new CoreLabelTokenFactory(), "ptb3Escaping=false");
		
		List<Token> relatedWords = new ArrayList<Token>();
		 for (CoreLabel label; ptbt.hasNext(); ) {
		        label = (CoreLabel)ptbt.next();
//		        System.out.println(label.word());
		        relatedWords.add(new Token(label.word()));
		      }
		
		/*Create mallet type Tokens for processing*/
		TokenSequence tokens = new TokenSequence(relatedWords);
		Instance instance = new Instance(tokens, null, null, null);
		
		/*Remove non-alpha words*/
		TokenSequenceRemoveNonAlpha nonAlphaRemover = new TokenSequenceRemoveNonAlpha();
		nonAlphaRemover.pipe(instance);
		
		URL stoplistPath = getClass().getClassLoader().getResource("infomap/resources/stopwords.txt");
		String stopListFilePath = URLDecoder.decode(stoplistPath.getFile(),	"UTF-8");
		TokenSequenceRemoveStopwords stopWordsRemover = new TokenSequenceRemoveStopwords(new File(stopListFilePath), 
												"UTF-8", false, false, false);
		stopWordsRemover.pipe(instance);
		
		/*Get Lemma for each word from WordNet*/
		URL wordNetDirectory = getClass().getClassLoader().getResource("infomap/resources/wordnet-dict");
		IDictionary dict = new Dictionary(wordNetDirectory);
		IIndexWord idxWord;
		IWordID wordID;
		IWord word;
		dict.open();
		
		tokens = (TokenSequence)instance.getData();
		Iterator<Token> iter = tokens.iterator();
		while(iter.hasNext())
		{
			String currWord = iter.next().getText();
			WordnetStemmer stemmer = new WordnetStemmer(dict);
			List<String> stems = stemmer.findStems(currWord, POS.NOUN);
			if(stems.size() >0)
			{
				result.addAll(stems);
				for(String stem:stems)
				{
					try
					{
						idxWord = dict.getIndexWord(stem,POS.NOUN);
						wordID = idxWord.getWordIDs().get(0);
						word = dict.getWord(wordID);
						ISynset synset = word.getSynset();
						List<IWord> synsetWords = synset.getWords();
						for(IWord relatedWord:synsetWords)
						{
							result.add(dict.getWord(relatedWord.getID()).getLemma());
						}
					}catch (NullPointerException e) {
						continue;
					}
				}
			}
			else
			{
				result.add(currWord);
			}
			
		}
		dict.close();
		
		return getUniqueKeywords(result.toArray(new String[result.size()])); 
	}
	
	private String[] getUniqueKeywords(String[] words)
	{
		HashMap<String, Boolean> uniqueWordChecker = new HashMap<String, Boolean>();
		List<String> result = new ArrayList<String>();
		for (int i = 0; i < words.length; i++) 
		{
			if(words[i] == null)
				continue;
			if(!uniqueWordChecker.containsKey(words[i].toLowerCase()))
			{
				String currWord = words[i].toLowerCase();
				uniqueWordChecker.put(currWord, true);
				result.add(words[i]);
			}
		}
		
		return (String[])result.toArray(new String[result.size()]);
	}
		
	private static final String APP_KEY = "j8ffufccso68w4y";
	private static final String APP_SECRET = "ww7tgcyeqr3ksmf";
	private static final AccessType ACCESS_TYPE = AccessType.DROPBOX;
	private static DropboxAPI<WebAuthSession> mDBApi;

	public String testDropbox() throws Exception {
		AppKeyPair appKeys = new AppKeyPair(APP_KEY, APP_SECRET);
		WebAuthSession session = new WebAuthSession(appKeys, ACCESS_TYPE);
		WebAuthInfo authInfo = session.getAuthInfo();

		RequestTokenPair pair = authInfo.requestTokenPair;
		String url = authInfo.url;

		// Desktop.getDesktop().browse(new URL(url).toURI());
		// JOptionPane.showMessageDialog(null,
		// "Press ok to continue once you have authenticated.");
		session.retrieveWebAccessToken(pair);

		AccessTokenPair tokens = session.getAccessTokenPair();
		System.out
				.println("Use this token pair in future so you don't have to re-authenticate each time:");
		System.out.println("Key token: " + tokens.key);
		System.out.println("Secret token: " + tokens.secret);

		mDBApi = new DropboxAPI<WebAuthSession>(session);

		return url;
	}

	public void testAddFileToDropBox() throws Exception {
		System.out.println();
		System.out.print("Uploading file...");
		String fileContents = "Hello World!";
		ByteArrayInputStream inputStream = new ByteArrayInputStream(
				fileContents.getBytes());
		Entry newEntry = mDBApi.putFile("/testing.txt", inputStream,
				fileContents.length(), null, null);
		System.out.println("Done. \nRevision of file: " + newEntry.rev);
	}

}
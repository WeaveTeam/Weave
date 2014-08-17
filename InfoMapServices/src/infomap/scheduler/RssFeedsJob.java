package infomap.scheduler;

import infomap.admin.AdminService;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.sql.Connection;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;
import java.util.ArrayList;

import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrInputDocument;
import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;

import weave.utils.SQLResult;
import weave.utils.SQLUtils;

import com.sun.syndication.feed.synd.SyndContent;
import com.sun.syndication.feed.synd.SyndEntryImpl;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.feed.synd.SyndPerson;
import com.sun.syndication.io.FeedException;
import com.sun.syndication.io.SyndFeedInput;
import com.sun.syndication.io.XmlReader;


public class RssFeedsJob implements Job {

	private static String solrServerURL = null;
	private static String username = null;
	private static String password = null;
	private static String host = "localhost";
	private static String port = "3306";
	private static String database = "solr_sources";
	private static String table = "rss_feeds";
	private static String SOURCE_TYPE = "RssFeeds";
	
	public RssFeedsJob() {

		Properties prop = new Properties();
		try {
			InputStream config = getClass().getClassLoader().getResourceAsStream("infomap/resources/config.properties");
			prop.load(config);

			solrServerURL = prop.getProperty("solrServerURL");
			database = prop.getProperty("feedSourcesDB");
			table = prop.getProperty("feedSourcesTable");
			username = prop.getProperty("dbUsername");
			password = prop.getProperty("dbPassword");
			host = prop.getProperty("feedSourcesDBServerURL");
		} catch (Exception e) {
			System.out.println("Error reading configuration file");
			return;
		}

	}
	
	@Override
	public void execute(JobExecutionContext arg0) throws JobExecutionException {
		triggerRssFeedsIndexing();
	}
	
	public static void triggerRssFeedsIndexing()
	{
		String query = String.format("SELECT title, url FROM %s", table);
		SQLResult rssFeeds = null;
		Connection connection = null;
		try {
			String url = SQLUtils.getConnectString(SQLUtils.MYSQL, host, port,
					database, username, password);
			connection = SQLUtils.getConnection(url);
			rssFeeds = SQLUtils.getResultFromQuery(connection, query, null, true);

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			SQLUtils.cleanup(connection);
		}

		// ToDo If there is no rss feeds in the table, then return.
		if (rssFeeds.rows.length == 0) return;
		
		// SyndFeed
		String feedName = null;
		URL feedUrl = null;
		SyndFeedInput input = null;
		SyndFeed feed = null;
		List<SolrInputDocument> docs = new ArrayList<SolrInputDocument>();
		
		for (int i = 0; i < rssFeeds.rows.length; i++)
		{
			try {
				feedName = rssFeeds.rows[i][0].toString();
				feedUrl = new URL(rssFeeds.rows[i][1].toString());
			} catch (MalformedURLException e) {
				e.printStackTrace();
			}
			
			input = new SyndFeedInput();
			try {
				feed = input.build(new XmlReader(feedUrl));
			} catch (IllegalArgumentException e) {
				e.printStackTrace();
			} catch (FeedException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}
			
			List<SyndEntryImpl> documents = null;
			// ToDo feed might be null ==> feed.getEntries() ==> throw NullPointerException
			try {				
				documents = feed.getEntries();
			} catch (Exception ex) {
				ex.printStackTrace();
			}
			
			SyndEntryImpl entry = null;
			SyndContent descr = null;
			List<SyndPerson> authorsList = null;
			Iterator<SyndPerson> authorIterator = null;
			String authors = "";
			String title = "";
			
			for (int j = 0; j < documents.size(); j++)
			{
				SolrInputDocument doc = new SolrInputDocument();
				
				entry = documents.get(j);

				// Add Link
				doc.addField("link", entry.getLink());
				
				// Add title
				authorsList = entry.getAuthors();
				authorIterator = authorsList.iterator();				
				while(authorIterator.hasNext())
				{
					authors += authorIterator.next().getName();
					
					authors += ", "; 
				}
				
				title = entry.getTitle();
				
				if(!authors.equals(""))
				{
					authors.substring(0, authors.length()-2); // Remove last ", "
					title += " by " + authors;
				}
				
				doc.addField("title", title);
				
				// Add Description
				descr = entry.getDescription();
				doc.addField("description", descr.getValue());
				
				// Set date_added to current date
				Date date_added = new Date();
				doc.addField("date_added", date_added);
				
				// Set updatedDate to published date
				Date pubDate = entry.getPublishedDate();
				doc.addField("date_published", pubDate);
				
				// Add SOURCE_TYPE
				doc.addField("source", SOURCE_TYPE);
				
				// Add RSS feed name
				doc.addField("attr_text_rss_name", feedName);
				
				docs.add(doc);
			}
			// This only shows how many docs are retrieved from rss feed. (documents might contain both old and new docs)
//			System.out.println((new Date()).toString() + " : " + feedName + " : " + documents.size()); 
		}
		SolrInputDocument[] solrDocs = docs.toArray(new SolrInputDocument[docs.size()]);

		// Index document in solr
		// Following code refers to method updateSolrServer in AbstractDataSource.java
		if(solrDocs == null)
			return;
		
		HttpSolrServer solrServer = new HttpSolrServer(solrServerURL);
		ArrayList<SolrInputDocument> updatedResults = new ArrayList<SolrInputDocument>();
		for(int i = 0; i < solrDocs.length; i++) {
			try {
				SolrQuery q = new SolrQuery().setQuery("link:"+"\""+(String) solrDocs[i].getFieldValue("link")+"\"");
				QueryResponse resp = solrServer.query(q);
				// Check whether document already existing in solr
				if(resp.getResults().getNumFound() > 0) continue;
				else updatedResults.add(solrDocs[i]);
			}catch (Exception ex) {
				System.out.println("Error Removing Old Docs in Data source RSS feeds");
				continue; // ToDo why skip?
			}			
		}
		
		SolrInputDocument[] updatedResultsArray = new SolrInputDocument[updatedResults.size()];
		AdminService.addDocuments(updatedResults.toArray(updatedResultsArray), solrServerURL);
	}
}

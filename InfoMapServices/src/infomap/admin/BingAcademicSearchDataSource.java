package infomap.admin;

import infomap.admin.BingAcademicSearchDataModel.Result;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLEncoder;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.solr.common.SolrInputDocument;

import com.google.gson.Gson;
import com.sun.syndication.feed.atom.Entry;
import com.sun.syndication.feed.synd.SyndEntryImpl;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.io.SyndFeedInput;
import com.sun.syndication.io.XmlReader;

import flex.messaging.io.ArrayList;

public class BingAcademicSearchDataSource  extends AbstractDataSource{
	
	public static void main(String[] args) {
		BingAcademicSearchDataSource inst  = new BingAcademicSearchDataSource();
		
		inst.requiredQueryTerms = new String[1];
		inst.relatedQueryTerms = new String[1];
		
		inst.requiredQueryTerms[0] = "Atlanta";
		
		inst.relatedQueryTerms[0] = "unemployment";
		
		inst.getTotalNumberOfQueryResults();
		SolrInputDocument[] test = inst.searchForQuery();
		System.out.println(test);
	}
	public BingAcademicSearchDataSource() {
		Properties prop = new Properties();
		try{
			InputStream config = getClass().getClassLoader().getResourceAsStream("infomap/resources/config.properties");
			prop.load(config);
			
			APP_ID= prop.getProperty("microsoftAcademicSearchId");
		}catch (Exception e)
		{
			System.out.println("Error reading configuration file");
		}
	}
	
	private String APP_ID = "";
	@Override
	String getSourceName() {
		return "Bing Academic Search";
	}

	private int max_results_per_query = 100;
	@Override
	SolrInputDocument[] searchForQuery() {
		
		if(APP_ID.equals(""))
		{
			return null;
		}
		
		System.out.println("Calling service on " + getSourceName());
		List<SolrInputDocument> results = new ArrayList();
		
		String[] requiredTerms = getRequiredQueryTerms();
		String queryTerms = "";
		for(int i =0; i < requiredTerms.length; i++)
		{
			try
			{
				
				if(relatedQueryTerms != null || relatedQueryTerms.length>0)
				{
					for (int j = 0; j <relatedQueryTerms.length; j++)
					{
						queryTerms = URLEncoder.encode(requiredTerms[i]+" " +relatedQueryTerms[j] , "UTF-8");
						getDocumentsForResults(queryTerms,results);
					}
				}
				else
				{
					queryTerms = URLEncoder.encode(requiredTerms[i], "UTF-8");
					getDocumentsForResults(queryTerms,results);
				}
			}
			catch (NullPointerException nullE) {
				/*if relatedTerms is empty*/
				try
				{
					queryTerms = URLEncoder.encode(requiredTerms[i], "UTF-8");
					getDocumentsForResults(queryTerms,results);
				}
				catch (Exception ioError) {
					ioError.printStackTrace();
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
			
		}
		
		return results.toArray(new SolrInputDocument[results.size()]);
	}
	
	private void getDocumentsForResults(String queryTerms,List<SolrInputDocument> results)
	{
		String reqURI ="";
		int numOfDocs = getNumOfDocumentsForQuery(queryTerms);
		for (int j =0; j<numOfDocs; j=j+max_results_per_query)
		{
			reqURI = BASE_REQUEST_URL+"&AppId="+APP_ID+"&StartIdx="+(1+j)+""+"&EndIdx="+(100+j)+"&FullTextQuery="+queryTerms;
			//System.out.println("BASE QUERY IS " + reqURI);
			DefaultHttpClient httpclient = new DefaultHttpClient();
			
			try 
			{
				/* Read and Parse JSON result */
				HttpGet httpget = new HttpGet(reqURI);
				httpget.setHeader("Content-Type", "text/plain; charset=UTF-8");//this is required for special characters.
				HttpResponse response = httpclient.execute(httpget);
				HttpEntity entity = response.getEntity();
				
				BufferedReader in = new BufferedReader(new InputStreamReader(entity.getContent(),"UTF-8"));
				String line = null;
				String jsonString = "";
				while((line = in.readLine()) != null) 
				{
					jsonString += line;
				}
				
				Gson gson = new Gson();
				
				BingAcademicSearchDataModel t = gson.fromJson(jsonString, BingAcademicSearchDataModel.class);
				Result[] documents = t.getDocuments();
				SolrInputDocument d = null;
				String tempURL = "";
				String tempString = "";
				String tempAuthors = "";
				for (int k =0; k<documents.length; k++)
				{
					d = new SolrInputDocument();
					
					/*Adding Title*/
					tempString = documents[k].Title;
					if(tempString != null)
					{
						tempAuthors = documents[k].getAuthors();
						if(tempAuthors != null)
						{
							tempString += " by " + tempAuthors;
						}
					}
					d.addField("title", tempString);
					
					/* Adding link */ 
					tempURL = documents[k].getURL();
					if(tempURL == null)
					{
						continue; //if no URL then don't index/add
					}
					d.addField("link", tempURL);
					
					/* Adding Description */
					
					/* The abstract is incomplete from the API but you can get more from the RSS feeds*/
					if(documents[k].ID !=null)
					{
						try{
							tempURL = "http://academic.research.microsoft.com/Rss?cata=9&id="+documents[k].ID;
							SyndFeedInput input = new SyndFeedInput();
							URL feedURL = new URL(tempURL);
							SyndFeed feed = input.build(new XmlReader(feedURL));
							List<SyndEntryImpl> entries = feed.getEntries();
							
							Iterator<SyndEntryImpl> itr = entries.iterator();
							SyndEntryImpl item = itr.next();
							tempString = item.getDescription().getValue();
							d.addField("description", tempString);
						}catch(Exception e)
						{
							tempString = documents[k].Abstract;
							if(tempString !=null)
							{
								d.addField("description", tempString);
							}
						}
					}
					else
					{
						tempString = documents[k].Abstract;
						if(tempString !=null)
						{
							d.addField("description", tempString);
						}
					}
				
					
					/* Adding subject areas as keywords */
					tempString = documents[k].getKeywords();
					if(tempString !=null)
					{
						d.addField("attr_text_keywords",tempString);
					}
					
					
					/* Setting date_added to current date */
					Date date_added = new Date();
					d.addField("date_added", date_added);	
					
					/* Setting published date */
					String pubDateString = documents[k].Year;
					Date pubDate = null;
					DateFormat format = null;
					
					if(pubDateString !=null)
					{
						format = new SimpleDateFormat("yyyy");
						pubDate = format.parse(pubDateString);
						d.addField("date_published", pubDate);
						
					}
					
					d.addField("source", getSourceType());
					
					results.add(d);
				}
		
			}
			catch(Exception e)
			{
				System.out.println("Error getting documents from Bing Service");
//				e.printStackTrace();
			}
	
		}
	}
	
	private String BASE_REQUEST_URL = "http://academic.research.microsoft.com/json.svc/search?ResultObjects=publication&PublicationContent=AllInfo&FullTextQuery=";;
	@Override
	long getTotalNumberOfQueryResults() {
		
		if(APP_ID.equals(""))
		{
			return 0;
		}
		long result = 0;
		String query = "";
		String[] requiredTerms = getRequiredQueryTerms();
		for (int i = 0; i <requiredTerms.length; i++)
		{
			try{
				
				try{
					
					if(relatedQueryTerms.length>0)
					{
						for (int j = 0; j <relatedQueryTerms.length; j++)
						{
							query = URLEncoder.encode(requiredTerms[i]+" " +relatedQueryTerms[j] , "UTF-8");
							result += getNumOfDocumentsForQuery(query);
						}
					}
					else
					{
						query = URLEncoder.encode(requiredTerms[i], "UTF-8");
						result += getNumOfDocumentsForQuery(requiredTerms[i]);
					}
				}catch (NullPointerException nullE)
				{
					query = URLEncoder.encode(requiredTerms[i], "UTF-8");
					result += getNumOfDocumentsForQuery(requiredTerms[i]);
				}
			}catch(Exception e)
			{
				e.printStackTrace();
			}
			
		}
		return result;
	}
	
	private int getNumOfDocumentsForQuery(String queryTerms)
	{
		String reqURI = BASE_REQUEST_URL+"&AppId="+APP_ID+"&StartIdx=1&EndIdx=1&FullTextQuery="+queryTerms;
		DefaultHttpClient httpclient = new DefaultHttpClient();
		int result= 0;
		try {
			HttpGet httpget = new HttpGet(reqURI);
			
			HttpResponse response = httpclient.execute(httpget);
			HttpEntity entity = response.getEntity();
			
			BufferedReader in = new BufferedReader(new InputStreamReader(entity.getContent()));
			String line = null;
			String jsonString = "";
			while((line = in.readLine()) != null) {
				jsonString += line;
			}
			
			Gson gson = new Gson();
			
			BingAcademicSearchDataModel b = gson.fromJson(jsonString, BingAcademicSearchDataModel.class);
			
			result = b.getTotalItems();

		}catch(Exception e){
			e.printStackTrace();
		}
		return result;
	}
	
	@Override
	String getSourceType() {
		return "Papers";
	}

}

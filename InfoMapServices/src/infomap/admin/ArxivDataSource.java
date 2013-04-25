package infomap.admin;

import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.solr.common.SolrInputDocument;

import com.sun.org.apache.xerces.internal.impl.xpath.regex.ParseException;
import com.sun.syndication.feed.synd.SyndContent;
import com.sun.syndication.feed.synd.SyndEntryImpl;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.feed.synd.SyndPerson;
import com.sun.syndication.io.FeedException;
import com.sun.syndication.io.SyndFeedInput;
import com.sun.syndication.io.XmlReader;

import flex.messaging.io.ArrayList;

/*
 * Class for Querying ARXIV: http://arxiv.org/help/api/user-manual
 * 
 */
public class ArxivDataSource extends AbstractDataSource
{

	
	public static String SOURCE_NAME = "ARXIV";
	@Override
	String getSourceName() {
		return SOURCE_NAME;
	}
	
	@Override
	String getSourceType() {
		return "Papers";
	}
	
	private static String BASE_URL = "http://export.arxiv.org/api/query?&sortBy=lastUpdatedDate&sortOrder=descending";
	
	private static int numberOfDocumentsPerRequest = 2000;
	
	/* sample query : http://export.arxiv.org/api/query?search_query=all:obesity AND (all:norepinephrine OR all:metaheuristic) /% */
	private String generateQuery(String requiredTerm)
	{
		String result = "all:" + requiredTerm;
		
		/* If no related terms return only required term*/
		if(relatedQueryTerms == null || relatedQueryTerms.length == 0)
		{
			try
			{
				result = URLEncoder.encode(result, "UTF-8");
				return result;
			}catch (Exception e) {
				System.out.println("Error encoding");
				return "";
			}
		}
		
		result +=  " AND (";
		
		for (int i = 0; i <relatedQueryTerms.length; i++)
		{
			result = result + "all:\""+relatedQueryTerms[i]+"\"";
			
			if(i != relatedQueryTerms.length-1)
			{
				result = result + " OR ";
			}
		}
		
		result = result + ")";
		try
		{
			result = URLEncoder.encode(result, "UTF-8");
		}catch (Exception e) {
			System.out.println("Error encoding URL");
		}
		return result;
	}
	
	@Override
	long getTotalNumberOfQueryResults() {
		// TODO Auto-generated method stub
		long result = 0;
		String[] requiredTerms = getRequiredQueryTerms();
		for (int i = 0; i <requiredTerms.length; i++)
		{	
			try{
				result += getNumberOfDocumentsForQuery(requiredTerms[i]);
			}
			catch (Exception e) {
				System.out.println("Error getting number of documents for " + getSourceName());
				return 0;
			} 
		}
		return result;
	}
	
	private int getNumberOfDocumentsForQuery(String requiredQueryTerm) throws MalformedURLException
	{
		Integer result = null;
		String queryString = generateQuery(requiredQueryTerm);
		try
		{
			URL feedUrl = new URL(BASE_URL + "&search_query=" + queryString + "&start=0&max_results=0");
			InputStream in  =  feedUrl.openStream();
			BufferedReader reader = new BufferedReader(new InputStreamReader(in));
			String line = reader.readLine();
			String content = line;
			Pattern pat = Pattern.compile("(.*>)([0-9]+)(</opensearch:totalResults>)");
			Boolean b = false;
			while((line = reader.readLine())!=null)
			{
			    content += line;
			    b = pat.matches("(.*>)([0-9]+)(</opensearch:totalResults>)", line);
			    if(b)
		    	{
			    	Matcher m = pat.matcher(line);
			    	if(m.find())
			    	{
			    		result = Integer.parseInt(m.group(2));
			    		break;
			    	}
		    	}
			}
		}catch (Exception e) {
			System.out.println("Error making query");
		}
		return result;
	}
	
	@Override
	SolrInputDocument[] searchForQuery() throws ParseException
	{
		System.out.println("Calling service on " + getSourceName());
		
		String queryString = "";
		List<SolrInputDocument> results = new ArrayList();
		try{
			String[] requiredTerms = getRequiredQueryTerms();
		for (int i = 0; i <requiredTerms.length; i++)
		{
			queryString = generateQuery(requiredTerms[i]);
			int numOfDocs = getNumberOfDocumentsForQuery(requiredTerms[i]);
			
			/*Break the request into slices of 2000 docs at a time*/
			for(int j = 0; j<numOfDocs; j=j+numberOfDocumentsPerRequest)
			{
				try{
					/* Putting a 3 second delay between queries as requested by ARXIV*/
					Thread.sleep(1000 * 3);
				}catch (Exception e) {
					System.out.println("Error when trying to put ARXIV data source to sleep.");
				}
				
				URL feedUrl = new URL(BASE_URL + "&search_query=" + queryString + "&start="+ j
						+"&max_results=" + Integer.toString(numberOfDocumentsPerRequest));
				
				SyndFeedInput input = new SyndFeedInput();
				SyndFeed feed = input.build(new XmlReader(feedUrl));
				
				List<SyndEntryImpl> documents = feed.getEntries();
				
				
				for (int k = 0; k<documents.size(); k++)
				{
					SyndEntryImpl entry = documents.get(k);
					
					SolrInputDocument d = new SolrInputDocument();
					
					
					//Adding title with author names
					
					String authors = "";
					
					List<SyndPerson> authorsList = entry.getAuthors();
					
					Iterator<SyndPerson> authorIterator = authorsList.iterator();
					
					while(authorIterator.hasNext())
					{
						authors += authorIterator.next().getName();
						
						authors += ", "; 
					}
					
					authors.substring(0, authors.length()-2);
					
					String title = entry.getTitle();
					
					if(!authors.equals(""))
						title += " by " + authors;
					
					
					d.addField("title", title);
					
					//Adding link 
					d.addField("link", entry.getLink());
					
					//Adding Description
					
					SyndContent descr = entry.getDescription();
					
					d.addField("description", descr.getValue());
					
					//setting date_added to current date
					Date date_added = new Date();
					d.addField("date_added", date_added);	
					
					//setting updatedDate to published date
					Date pubDate = entry.getPublishedDate();
					d.addField("date_published", pubDate);
					
					d.addField("source", getSourceType());
					results.add(d);
				}
			}
		}
		
		} catch (MalformedURLException e) {
			System.out.println("Error in ARXIV Request with  URL");
		}
		catch (IOException e) {
			System.out.println("Error in ARIV Request with SyndFeedInput");
			e.printStackTrace();
		}
		catch (FeedException e) {
			System.out.println("Error in ARIV Request with SyndFeed");
		}
		
		 
		return results.toArray(new SolrInputDocument[results.size()]);
	}

	
}
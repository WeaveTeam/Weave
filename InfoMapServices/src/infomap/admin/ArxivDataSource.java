package infomap.admin;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.io.IOException;

import org.apache.solr.common.SolrInputDocument;

import com.sun.org.apache.xerces.internal.impl.xpath.regex.ParseException;
import com.sun.syndication.feed.synd.SyndContent;
import com.sun.syndication.feed.synd.SyndEntryImpl;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.feed.synd.SyndPerson;
import com.sun.syndication.io.FeedException;
import com.sun.syndication.io.SyndFeedInput;
import com.sun.syndication.io.XmlReader;


public class ArxivDataSource extends AbstractDataSource{

	
	public static String SOURCE_NAME = "ARXIV";
	@Override
	String getSourceName() {
		return SOURCE_NAME;
	}
	
	private static String BASE_URL = "http://export.arxiv.org/api/query?&sortBy=lastUpdatedDate&sortOrder=descending";
	
	private static int numberOfRequestedDocuments = 2000;
	
	@Override
	SolrInputDocument[] searchForQuery(String operator) throws ParseException{
		
		String queryString = "";
		
		operator = "AND";//defaulting to AND for now
		
		for (int i =0; i <query.length; i++)
		{
			queryString += query[i];
			
			//Don't add operator for last query term
			if(i!=query.length -1)
			{
				queryString += "+"+ operator +"+";
			}
		}
		SolrInputDocument[] results = null;
		try{
			
		URL feedUrl = new URL(BASE_URL + "&search_query=all:" + queryString + "&start=0&max_results=" + Integer.toString(numberOfRequestedDocuments));

        SyndFeedInput input = new SyndFeedInput();
        SyndFeed feed = input.build(new XmlReader(feedUrl));

        List<SyndEntryImpl> documents = feed.getEntries();
		
		results = new SolrInputDocument[documents.size()];
		
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
			
			results[k]= d;
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
//		System.out.println("STORING ARXIV RESULTS");
		return results;
	}
	
//    public static void main(String[] args) {
//        boolean ok = false;
//        if (true) {
//            try {
//                URL feedUrl = new URL("http://export.arxiv.org/api/query?search_query=all:greening&start=0&max_results=10");
//
//                SyndFeedInput input = new SyndFeedInput();
//                SyndFeed feed = input.build(new XmlReader(feedUrl));
//                List<SyndEntryImpl> documents = feed.getEntries();
//                
//                SyndEntryImpl s = documents.get(0);
//                System.out.println(s.getPublishedDate());
//                System.out.println(s.getUpdatedDate());
//                ok = true;
//            }
//            catch (Exception ex) {
//                ex.printStackTrace();
//                System.out.println("ERROR: "+ex.getMessage());
//            }
//        }
//
//        if (!ok) {
//            System.out.println();
//            System.out.println("FeedReader reads and prints any RSS/Atom feed type.");
//            System.out.println("The first parameter must be the URL of the feed to read.");
//            System.out.println();
//        }
//    }

}
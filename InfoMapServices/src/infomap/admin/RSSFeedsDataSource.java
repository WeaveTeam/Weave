package infomap.admin;

import java.net.URL;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.solr.common.SolrInputDocument;

import com.sun.syndication.feed.atom.Entry;
import com.sun.syndication.feed.synd.SyndFeed;
import com.sun.syndication.io.SyndFeedInput;
import com.sun.syndication.io.XmlReader;

public class RSSFeedsDataSource extends AbstractDataSource
{
	public String[] links;
	
//	public void addDocumentsToSolr()
//	{
//		if(links.length == 0)
//			return;
//		
//		List<SolrInputDocument> results = new ArrayList<SolrInputDocument>();
//		
//		for (int i = 0; i < links.length; i++)
//		{
//			SyndFeedInput input = new SyndFeedInput();
//			try
//			{
//				URL feedURL = new URL(links[i]);
//				SyndFeed feed = input.build(new XmlReader(feedURL));
//				List<Entry> entries = feed.getEntries();
//				
//				Iterator<Entry> itr = entries.iterator();
//				SolrInputDocument d;
//				while (itr.hasNext())
//				{
//					Entry item = itr.next();
//					d = new SolrInputDocument();
//					
//					/* Adding link */
//					d.addField("title", item.getTitle());
//					
//					/* Adding link */ 
//					d.addField("link", item.getId());
//					
//					/* Adding Description */
//					d.addField("description", item.getSummary());
//									
//					results.add(d);
//				}
//				
//				
//			}catch (Exception e) {
//				e.printStackTrace();
//			}
//		}
//	}

	@Override
	String getSourceName() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	SolrInputDocument[] searchForQuery() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	long getTotalNumberOfQueryResults() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	String getSourceType() {
		// TODO Auto-generated method stub
		return null;
	}
	
}

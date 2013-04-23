package infomap.admin;

import infomap.utils.ArrayUtils;

import java.math.BigInteger;
import java.net.URLEncoder;
import java.security.MessageDigest;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Properties;

import org.apache.commons.io.IOUtils;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrInputDocument;

import weave.utils.FileUtils;

import com.google.gson.Gson;

public class OpenLibraryDataSource extends AbstractDataSource 
{
//	public static void main(String[] args) {
//		OpenLibraryDataSource inst = new OpenLibraryDataSource();
//		
//		FileUtils.copyFileFromURL("http://covers.openlibrary.org/b/olid/OL7440033M-S.jpg?default=false", "C:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\webapps\\ROOT\\saby.jpg");
//	}
	
	private static String requestURL = "http://openlibrary.org/search.json?";
	
	@Override
	String getSourceName() {
		return "Open Library";
	}
	
	@Override
	String getSourceType() {
		return "Books";
	}
	
	@Override
	SolrInputDocument[] searchForQuery() 
	{
		List<SolrInputDocument> result = new ArrayList<SolrInputDocument>();
		long numOfDocs = 0;
		
		numOfDocs = getTotalNumberOfQueryResults();
		
		if(numOfDocs == 0)
			return null;
		
		double numOfPages = Math.ceil(numOfDocs / 100.0);
		HttpSolrServer solrServer = new HttpSolrServer(solrServerURL);
		OpenLibraryDataModel queryResults = null;
		/* OpenLibrary returns results of 100 per page */
		for (int i = 1; i<=numOfPages; i++)
		{
			queryResults = parseJSONResult(i);
			
			OpenLibraryDoc[] docs = queryResults.docs;
			
			SolrInputDocument d = null;
			for(int j = 0; j < docs.length; j++)
			{
				String key ="";
				if(docs[j].key != null)
				{
					key = docs[j].key;
				}else if(docs[j].cover_edition_key !=null)
				{
					key = docs[j].cover_edition_key;
				}
				else
				{
					continue;
				}
				
				
				try
				{
					/*If already added we ignore. We do this to avoid querying the source for cover images*/
					SolrQuery q = new SolrQuery().setQuery("link:"+"\"http://openlibrary.org/works/"+key+"\"");
					QueryResponse resp = solrServer.query(q);
					if(resp.getResults().getNumFound()>0)
					{
						continue;
					}
				}catch (SolrServerException e) {
					continue;
				}
				
				d = new SolrInputDocument();
				
				if(docs[j].title == null)
					continue;
				
				String title = docs[j].title;
				
				if(docs[j].author_name != null)
					title += " by " + ArrayUtils.joinArrayElements(docs[j].author_name, " ");
				
				d.addField("title", title);
				
				if(docs[j].text != null)
					d.addField("description", ArrayUtils.joinArrayElements(docs[j].text, " "));
				
				if(docs[j].subject != null)
					d.addField("attr_text_keywords", ArrayUtils.joinArrayElements(docs[j].subject, ","));
				
				/* Setting date_added to current date */
				Date date_added = new Date();
				d.addField("date_added", date_added);	
				
				/* Setting published date */
				if(docs[j].publish_date !=null)
				{
					String pubDateString = docs[j].publish_date[0];
					Date pubDate = null;
					DateFormat format = null;
					
					if(pubDateString !=null)
					{
						try
						{
							if(pubDateString.matches("[a-zA-Z]{3,9} [0-9]{1,2}, [0-9]{4}"))//June 30,2003
							{
								format = new SimpleDateFormat("MMM d, yyyy");
								pubDate = format.parse(pubDateString);
							}
							else if(pubDateString.matches("[a-zA-Z]{3,9} [0-9]{4}")) //June 2003
							{
								format = new SimpleDateFormat("MMM yyy");
								pubDate = format.parse(pubDateString);
							}
							else if(pubDateString.matches("[0-9]{4}"))//2003
							{
								format = new SimpleDateFormat("yyyy");
								pubDate = format.parse(pubDateString);
							}
							if(pubDate !=null)
								d.addField("date_published", pubDate);
						}catch (ParseException e) {
							System.out.println("Error getting published date");
						}	
					}
				}
				
				d.addField("source", "Books");
				d.addField("link", "http://openlibrary.org/works/"+key);
				
				String imgName = FileUtils.generateUniqueNameFromURL("http://openlibrary.org/works/"+key) + ".jpg";
				if(copyImageFromURL("http://covers.openlibrary.org/b/olid/"+key+"-S.jpg?default=false", imgName));
					d.addField("imgName", imgName);
				
				result.add(d);
			}
		}
		
		return result.toArray(new SolrInputDocument[result.size()]);
	}
	
	@Override
	long getTotalNumberOfQueryResults() 
	{
		long numberOfDocs = 0;
		
		if(requiredQueryTerms.length == 0)
			return numberOfDocs;
			
		OpenLibraryDataModel result = parseJSONResult(1);
		
		if(result != null)
			numberOfDocs = result.numFound;
			
		return numberOfDocs;
	}
	
	private OpenLibraryDataModel parseJSONResult(int page)
	{
		OpenLibraryDataModel result = null;
		String query = ArrayUtils.joinArrayElements(requiredQueryTerms, "%20");
		
		try{
			/* Read and Parse JSON result */
			query = URLEncoder.encode(query, "UTF-8");
			String reqURI = requestURL+"&q="+query+"&page="+page;
			HttpGet httpget = new HttpGet(reqURI);
			httpget.setHeader("Content-Type", "text/plain; charset=UTF-8");//this is required for special characters.
			DefaultHttpClient httpclient = new DefaultHttpClient();
			HttpResponse response = httpclient.execute(httpget);
			HttpEntity entity = response.getEntity();
			
			String streamString = IOUtils.toString(entity.getContent(), "UTF-8");
			
			Gson gson = new Gson();
			
			result = gson.fromJson(streamString, OpenLibraryDataModel.class);
		}catch (Exception e) {
			e.printStackTrace();
			return result;
		}
		return result;
	}
}

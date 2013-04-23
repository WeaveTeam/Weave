package infomap.admin;

import flex.messaging.io.ArrayList;
import infomap.utils.ArrayUtils;

import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Properties;

import org.apache.commons.io.IOUtils;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.solr.common.SolrInputDocument;

import weave.utils.FileUtils;

import com.google.gson.Gson;

public class GoogleBooksDataSource extends AbstractDataSource 
{
	public static void main(String[] args) {
		GoogleBooksDataSource t = new GoogleBooksDataSource();
		
		t.requiredQueryTerms = new String[2];
		t.requiredQueryTerms[0] = "data";
		t.requiredQueryTerms[1] = "visualization";
		
		System.out.println(t.searchForQuery());
	}

	@Override
	String getSourceName() 
	{
		return "Google Books";
	}
	
	@Override
	String getSourceType() {
		return "Books";
	}
	
	private String requestURL = "https://www.googleapis.com/books/v1/volumes?&orderBy=newest&fields=totalItems,items(volumeInfo(title,subtitle,authors,publishedDate,description,categories,imageLinks,canonicalVolumeLink))";
	
	private int max_per_page_request =40;
	@Override
	SolrInputDocument[] searchForQuery() 
	{
		List<SolrInputDocument> result = new ArrayList();	
		
		int totalNumOfDocs = (int)getTotalNumberOfQueryResults();
		
		if (totalNumOfDocs == 0)
			return new SolrInputDocument[0];
		
		for(int i=0;i<totalNumOfDocs;i=i+max_per_page_request)
		{
			GoogleBooksDataModel queryResult = getResultsForRequest(max_per_page_request, i);
			
			SolrInputDocument d = null;
			
			if(queryResult.items == null)
				break;
			
			for (int j = 0;j<queryResult.items.length; j++)
			{
				d = new SolrInputDocument();
				String link = queryResult.items[j].getURL();
				d.addField("title", queryResult.items[j].getTitle());
				d.addField("description", queryResult.items[j].getTitle());
				d.addField("link", link);
				if(queryResult.items[j].getDate().length()>0)
				{
					String pubDateString = queryResult.items[j].getDate();
					Date pubDate = null;
					DateFormat format = null;
					
					if(pubDateString !=null)
					{
						try
						{
							if(pubDateString.matches("[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}"))//if dcdate is of form yyyy-mm-dd
							{
								format = new SimpleDateFormat("yyyy-MM-dd");
								pubDate = format.parse(pubDateString);
							}
							else if(pubDateString.matches("[0-9]{4}-[0-9]{1,2}")) // if dcdate is of form yyyy-mm
							{
								format = new SimpleDateFormat("yyyy-MM");
								pubDate = format.parse(pubDateString);
							}
							else if(pubDateString.matches("[0-9]{4}"))//if dcdate is of form yyyy
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
				
				/* Setting date_added to current date */
				Date date_added = new Date();
				d.addField("date_added", date_added);	
				
				if(queryResult.items[j].getKeywords().length()>0)
					d.addField("attr_text_keywords", queryResult.items[j].getKeywords());
				
				d.addField("source", getSourceType());
				
				if(queryResult.items[j].getImageURL().length()>0)
				{
					String imgName = FileUtils.generateUniqueNameFromURL(link) + ".jpg";
					if(copyImage(queryResult.items[j].getImageURL(), imgName));
						d.addField("imgName", imgName);
				}
				
				result.add(d);
			}
			
		}
		
		return result.toArray(new SolrInputDocument[result.size()]);
	}
	
	@Override
	long getTotalNumberOfQueryResults() 
	{
		GoogleBooksDataModel result = null;
		try{
			result = getResultsForRequest(1, 0);			
			return result.totalItems;
		}
		catch(Exception e)
		{
			System.out.println("Error getting number of documents from Google Books");
		}
		return 0;
	}
	
	private Boolean copyImage(String sourceURL,String imageName)
	{
		int index = sourceURL.lastIndexOf('.');
		
		String imgExtension = sourceURL.substring(index, sourceURL.length());
		
		Properties prop = new Properties();
		
		try
		{
			prop.load(getClass().getClassLoader().getResourceAsStream("infomap/resources/config.properties"));
			String tomcatPath = prop.getProperty("tomcatPath");
			
			String thumbnailPath = prop.getProperty("thumbnailPath");
			String destinationPath = tomcatPath + thumbnailPath + imageName; 
			
			URL l = new URL(sourceURL);
			URLConnection c = l.openConnection();
			c.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:19.0) Gecko/20100101 Firefox/19.0" );
			c.connect();
			
			/*Get Image Extension from Header
			String imageExtension = c.getHeaderField("Content-type");
			String[] temp = imageExtension.split("/");
			imageExtension = temp[temp.length-1];
			destinationPath +=imageExtension;*/
			
			InputStream in = c.getInputStream();

			FileOutputStream out =new FileOutputStream(destinationPath);

			FileUtils.copy(in, out);
			
			return true;
		
		}catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}
	
	private GoogleBooksDataModel getResultsForRequest(int maxResults,int startIndex)
	{
		try
		{
			String query = ArrayUtils.joinArrayElements(requiredQueryTerms, " ");
			query = URLEncoder.encode(query, "UTF-8");
			String reqURI = requestURL+"&q="+query+"&maxResults="+maxResults+"&startIndex="+startIndex;
			HttpGet httpget = new HttpGet(reqURI);
			httpget.setHeader("Content-Type", "text/plain; charset=UTF-8");//this is required for special characters.
			DefaultHttpClient httpclient = new DefaultHttpClient();
			HttpResponse response = httpclient.execute(httpget);
			HttpEntity entity = response.getEntity();
			
			String streamString = IOUtils.toString(entity.getContent(), "UTF-8");
			Gson gson = new Gson();
			
			return gson.fromJson(streamString, GoogleBooksDataModel.class);
		}catch (Exception e) {
			return null;
		}
	}

}

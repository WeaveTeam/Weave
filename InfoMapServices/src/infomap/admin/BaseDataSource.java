package infomap.admin;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.HttpParams;
import org.apache.solr.common.SolrInputDocument;
import org.apache.solr.common.util.DateUtil;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.sun.syndication.feed.synd.SyndContent;

public class BaseDataSource extends AbstractDataSource{
	
	@Override
	String getSourceName() {
		// TODO Auto-generated method stub
		return "BASE";
	}
	
	private static String REQUEST_URL = "http://baseapi.ub.uni-bielefeld.de/cgi-bin/BaseHttpSearchInterface.fcgi?func=PerformSearch&sortby=dcdate&format=json";
	
	/** The Constant UTF_8_CHAR_SET. */
	protected static final Charset UTF_8_CHAR_SET = Charset.forName("UTF-8");
	
	/*
	 * BASE API returns incomplete results in JSON format when requesting more than 400-500 documents.
	 * So we restrict to 100 and make multiple requests.
	 */
	private static int numberOfDocuments = 100;
	
	/*
	 * The offset value is the value of the starting index of the result set.
	 * This helps to break a single request into multiple requests. 
	 */
	private static int offset = 0;
	
	@Override
	SolrInputDocument[] searchForQuery(String operator) {
		// TODO Auto-generated method stub
		System.out.println("IN BASE-SEARCHFORQUERY");
    	
		
		SolrInputDocument[] results = null;
		
		String reqURI = REQUEST_URL+"&query="+getQueryString() + "&hits=" + numberOfDocuments + "&offset=" + offset;
		System.out.println("BASE QUERY IS " + reqURI);
		DefaultHttpClient httpclient = new DefaultHttpClient();
		
		try {
			HttpGet httpget = new HttpGet(reqURI);
			httpget.setHeader("Content-Type", "text/plain; charset=UTF-8");//this is required for special characters.
			HttpResponse response = httpclient.execute(httpget);
			HttpEntity entity = response.getEntity();
			
			BufferedReader in = new BufferedReader(new InputStreamReader(entity.getContent(),"UTF-8"));
			String line = null;
			String jsonString = "";
			while((line = in.readLine()) != null) {
				jsonString += line;
//				if(jsonString.contains("French dressing"))
//					System.out.println("FOUND WORDS " + jsonString);
			}
			
			Gson gson = new Gson();
			
			BaseDataModel t = gson.fromJson(jsonString, BaseDataModel.class);
			SolrInputDocument d = null;
			results = new SolrInputDocument[t.response.docs.length];
			for (int i =0; i<t.response.docs.length; i++)
			{
				d = new SolrInputDocument();
				
				d.addField("title", t.response.docs[i].dctitle);
				
				//Adding link 
				d.addField("link", t.response.docs[i].dclink);
				
				//Adding Description
				d.addField("description", t.response.docs[i].dcdescription);
				
				//Adding subject areas as keywords
				if(t.response.docs[i].dcsubject !=null)
				{
					String[] keywordsArray = t.response.docs[i].dcsubject;
					String keywords="";
					if(keywordsArray.length > 0)
					{
						for (int k=0; k<keywordsArray.length; k++)
						{
							keywords += keywordsArray[k] + ",";
						}
						
						d.addField("attr_text_keywords",keywords);
					}
				}

				
				//setting date_added to current date
				Date date_added = new Date();
				d.addField("date_added", date_added);	
				
				//setting published date
				String pubDateString = t.response.docs[i].dcdate;
				Date pubDate = null;
				DateFormat format = null;
				
				if(pubDateString !=null)
				{
					
					//if dcdate is of form yyyy-mm-dd
					if(pubDateString.matches("/[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$/"))
					{
						format = new SimpleDateFormat("yyyy-MM-dd");
						pubDate = format.parse(pubDateString);
					}else if(pubDateString.matches("/[0-9]{4}-[0-9]{1,2}$/")) // if dcdate is of form yyyy-mm
					{
						format = new SimpleDateFormat("yyyy-MM");
						pubDate = format.parse(pubDateString);
					}else if(pubDateString.matches("/[0-9]{4}$/"))//if dcdate is of form yyyy
					{
						format = new SimpleDateFormat("yyyy");
						pubDate = format.parse(pubDateString);
					}
					
					d.addField("date_published", pubDate);
					
				}else{
//					System.out.println("DATE IS NULL for " + t.response.docs[i].dclink + "with " + t.response.docs[i].dcdate);
				}
				results[i] = d;
			}
			

		}catch(Exception e){
			e.printStackTrace();
		}
		
		System.out.println("BASE FOUND DOCUMENTS  " + results.length);
		return results;
	}
	
	private String getQueryString()
	{
		String queryString = "";
		
		for (int i =0; i <query.length; i++)
		{
			queryString += query[i];
			
			//Don't add operator for last query term
			if(i!=query.length -1)
			{
				queryString += "+";
			}
		}
		
		return queryString;
	}
	
	private int getNumOfDocuments()
	{
		String reqURI = REQUEST_URL+"&query="+getQueryString();
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
			
			BaseDataModel b = gson.fromJson(jsonString, BaseDataModel.class);
			
			result = Integer.parseInt(b.response.numFound);

		}catch(Exception e){
			e.printStackTrace();
		}
		return result;
	}
	
	@Override
	public void run() {
		// TODO Auto-generated method stub
		if(query.length>0)
		{
			int numOfDocs = getNumOfDocuments();
			
			for(int i=0; i<numOfDocs; i=i+numberOfDocuments)
			{
				offset = i;
				SolrInputDocument[] results = searchForQuery("AND");
//				System.out.println("Uploading " + results.length + "documents");
				updateSolrServer(results);
			}
		}else
		{
			System.out.println("Query Terms are empty for " + getSourceName());
		}
	}
}
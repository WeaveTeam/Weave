package infomap.admin;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URLEncoder;
import java.nio.charset.Charset;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.solr.common.SolrInputDocument;

import com.google.gson.Gson;

import flex.messaging.io.ArrayList;

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
	private static int numberOfDocumentsPerRequest = 100;
	
	@Override
	SolrInputDocument[] searchForQuery() {
		// TODO Auto-generated method stub
		System.out.println("IN BASE-SEARCHFORQUERY");
    	
		
		List<SolrInputDocument> results = new ArrayList();
		String reqURI ="";
		
		for(int i =0; i < requiredQueryTerms.length; i++)
		{
			int numOfDocs = getNumOfDocumentsForQuery(requiredQueryTerms[i]);
			for (int j =0; j<numOfDocs; j=j+numberOfDocumentsPerRequest)
			{
				reqURI = REQUEST_URL+"&query="+generateQuery(requiredQueryTerms[i]) + "&hits=" + numberOfDocumentsPerRequest + "&offset=" + j;
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
					
					BaseDataModel t = gson.fromJson(jsonString, BaseDataModel.class);
					SolrInputDocument d = null;
					for (int k =0; k<t.response.docs.length; k++)
					{
						d = new SolrInputDocument();
						
						d.addField("title", t.response.docs[k].dctitle);
						
						/* Adding link */ 
						d.addField("link", t.response.docs[k].dclink);
						
						/* Adding Description */
						d.addField("description", t.response.docs[k].dcdescription);
						
						/* Adding subject areas as keywords */
						if(t.response.docs[k].dcsubject !=null)
						{
							String[] keywordsArray = t.response.docs[k].dcsubject;
							String keywords="";
							if(keywordsArray.length > 0)
							{
								for (int l=0; l<keywordsArray.length; l++)
								{
									keywords += keywordsArray[l] + ",";
								}
								
								d.addField("attr_text_keywords",keywords);
							}
						}
						
						
						/* Setting date_added to current date */
						Date date_added = new Date();
						d.addField("date_added", date_added);	
						
						/* Setting published date */
						String pubDateString = t.response.docs[k].dcdate;
						Date pubDate = null;
						DateFormat format = null;
						
						if(pubDateString !=null)
						{
							
							
							if(pubDateString.matches("/[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$/"))//if dcdate is of form yyyy-mm-dd
							{
								format = new SimpleDateFormat("yyyy-MM-dd");
								pubDate = format.parse(pubDateString);
							}
							else if(pubDateString.matches("/[0-9]{4}-[0-9]{1,2}$/")) // if dcdate is of form yyyy-mm
							{
								format = new SimpleDateFormat("yyyy-MM");
								pubDate = format.parse(pubDateString);
							}
							else if(pubDateString.matches("/[0-9]{4}$/"))//if dcdate is of form yyyy
							{
								format = new SimpleDateFormat("yyyy");
								pubDate = format.parse(pubDateString);
							}
							
							d.addField("date_published", pubDate);
							
						}else
						{
							//System.out.println("DATE IS NULL for " + t.response.docs[i].dclink + "with " + t.response.docs[i].dcdate);
						}
						results.add(d);
					}
			
				}
				catch(Exception e)
				{
					e.printStackTrace();
				}
		
			}
		}
		System.out.println("BASE FOUND DOCUMENTS  " + results.size());
		return results.toArray(new SolrInputDocument[results.size()]);
	}
	
	private String generateQuery(String requiredTerm)
	{
		String result = "\"" + requiredTerm + "\"";
		
		/* If no related terms return only required term*/
		if(relatedQueryTerms == null || relatedQueryTerms.length == 0)
		{
			return result;
		}
		
		result +=  " AND (";
		
		for (int i = 0; i <relatedQueryTerms.length; i++)
		{
			result = result + "\""+relatedQueryTerms[i]+"\"";
			
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
		for (int i = 0; i <requiredQueryTerms.length; i++)
		{
			result += getNumOfDocumentsForQuery(requiredQueryTerms[i]);
		}
		return result;
	}
	
	private int getNumOfDocumentsForQuery(String requiredTerm)
	{
		String reqURI = REQUEST_URL+"&query="+generateQuery(requiredTerm);
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
}
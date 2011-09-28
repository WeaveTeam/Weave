package infomap.scheduler;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;

import org.quartz.Job;
import org.quartz.JobExecutionContext;

public class SolrIndexingJob implements Job{

	public SolrIndexingJob(){
		
	}
	
	public void execute(JobExecutionContext context)
	{
		try{
			System.out.println("making URL request");
			//TODO: abstract the URL
			URL url = new URL("http://localhost:8080/solr/select?clean=false&commit=true&qt=%2Fdataimport&command=full-import");
			URLConnection conn = url.openConnection();
			conn.setDoOutput(true);
			//read the response
			BufferedReader rd = new BufferedReader(new InputStreamReader(conn.getInputStream()));
			String line;
			
			while ((line = rd.readLine()) != null) {
				
				System.out.println(line);
			}
		}catch(Exception e){
				e.printStackTrace();
			}
		
		}
	}

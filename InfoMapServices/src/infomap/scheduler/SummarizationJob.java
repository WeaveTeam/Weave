package infomap.scheduler;

import java.util.Dictionary;
import java.util.Hashtable;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrQuery.ORDER;
import org.apache.solr.client.solrj.impl.ConcurrentUpdateSolrServer;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.impl.XMLResponseParser;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrDocumentList;
import org.apache.solr.common.SolrInputDocument;

import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;


import opennlp.tools.sentdetect.SentenceModel;
import opennlp.tools.tokenize.TokenizerModel;

public class SummarizationJob implements Job{

	public SummarizationJob() {
	
		//Reading and initializing Stop words from file
		stopWords = new Hashtable<String, Integer>();
		
		solrServerURL = "http://129.63.8.219:8080/solr/research_core/";
		
		try{
			
			BufferedReader stopWordsList = new BufferedReader(
					new InputStreamReader(getClass().getClassLoader().getResourceAsStream("infomap/resources/stopwords.txt")));
			String word = null;
			while ((word = stopWordsList.readLine()) != null) {
				stopWords.put(word, 1);
			}
			stopWordsList.close();
		}catch (Exception e) {
			// TODO: handle exception
			System.out.println("Error reading Stopwords file");
			return;
		}
		
		//Initializing token and sentences modules
		try{
			
			InputStream sentenceDetectorModelInput = getClass().getClassLoader().getResourceAsStream("infomap/resources/en-sent.bin");
			InputStream tokenizerModelInput = getClass().getClassLoader().getResourceAsStream("infomap/resources/en-token.bin");
			senModel = new SentenceModel(sentenceDetectorModelInput);
			tokeModel= new TokenizerModel(tokenizerModelInput);
		}catch (Exception e) {
			System.out.println("Error reading Token and Sentences modules");
			return;
		}
		
	}
	
	private Dictionary<String, Integer> stopWords;
	
	private SentenceModel senModel;
	
	private TokenizerModel tokeModel;
	
	public String solrServerURL;
	
	@Override
	public void execute(JobExecutionContext arg0) throws JobExecutionException {
		 
		System.out.println("Starting Summarization");
		
		HttpSolrServer server = new HttpSolrServer(solrServerURL);
		ConcurrentUpdateSolrServer updateServer = new ConcurrentUpdateSolrServer(solrServerURL, 100, 4);
		
		
		server.setParser(new XMLResponseParser());
		SolrQuery query = new SolrQuery();
		query.setQuery("hasSummary:false");
		query.addSortField("date_added", ORDER.asc);
		query.setStart(0);
		query.setRows(100);
		
		
		QueryResponse response = null;
		SolrDocumentList documents = null;
		Iterator<SolrDocument> itr = null;
		String description = "";
		String summary = "";
		String topicSentence = "";
		SolrInputDocument revisedDoc = null;
		
		int numOfSentencesInDescription = 1;
		int numOfSentencesInSummary = 1;
		
		SolrDocument doc = null;
		int doucumentSize = 1;
		Map<String, String> partialUpdateSummary = null;
		Map<String, String> partialUpdateTopicSentence = null;
		HashMap<String, Boolean> partialUpdateHasSummary = null;
		
		
//		while (true) {
			try{
				response = server.query(query);
				
				long totalNumberOfDocs = response.getResults().getNumFound();
				
				//We break it into chunk of requests of size 1 documents
				for (int k = 0; k<=totalNumberOfDocs; k++)
				{
					query.setStart(k);
					query.setRows(1);
					
					SolrInputDocument[] docsInCurrentChunk = new SolrInputDocument[2000];
					int count = 0;
					
					response = server.query(query);
					documents = response.getResults();
					doucumentSize = documents.size();
					itr = documents.iterator();
					if (doucumentSize > 0) {
						while (itr.hasNext()) 
						{
							revisedDoc = new SolrInputDocument();
							partialUpdateSummary = new HashMap<String, String>();
							partialUpdateTopicSentence = new HashMap<String, String>();
							partialUpdateHasSummary = new HashMap<String, Boolean>();
							doc = itr.next();
							if (doc.getFieldValue("description") != null) {
								description = doc.getFieldValue("description")
										.toString();
								numOfSentencesInDescription = Summarizer.Sentences(
										description, senModel).length;
								numOfSentencesInSummary = (int) Math.min(
										Math.ceil(numOfSentencesInDescription / 10.0),
										5);
								summary = Summarizer.SingleDocumentSummaryCalculator(
										description, numOfSentencesInSummary, senModel,
										tokeModel, stopWords);
								topicSentence = Summarizer.SingleDocumentSummaryCalculator(
										description, 1, senModel, tokeModel, stopWords);
								
								partialUpdateHasSummary.put("set", true);
								partialUpdateSummary.put("add", summary);
								partialUpdateTopicSentence.put("add", topicSentence);
								
								revisedDoc.addField("link", doc.getFieldValue("link"));
								revisedDoc.addField("attr_text_summary",
										partialUpdateSummary);
								revisedDoc.addField("attr_text_topicSentence",
										partialUpdateTopicSentence);
								revisedDoc.addField("hasSummary",
										partialUpdateHasSummary);
//								docsInCurrentChunk[count] = revisedDoc;
//								System.out.println("Summarized " + doc.getFieldValue("link") + "with" + summary);
								updateServer.add(revisedDoc);
							} else {
								revisedDoc.addField("link", doc.getFieldValue("link"));
								partialUpdateHasSummary.put("set", true);
								revisedDoc.addField("hasSummary",
										partialUpdateHasSummary);
								updateServer.add(revisedDoc);
//								docsInCurrentChunk[count] = revisedDoc;
							}
		
						}
//						updateServer.commit();
//						updateServer.add(Arrays.asList(docsInCurrentChunk),10000);
						
				}
				
				
				
				
			}
		}catch (Exception e) {
			System.out.println("Error Summarizing");
			}
//		}
		
		server.shutdown();
		updateServer.shutdown();
		return;
	}
}

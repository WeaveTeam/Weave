package infomap.scheduler;

import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.client.solrj.response.UpdateResponse;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrDocumentList;
import org.apache.solr.common.SolrInputDocument;
import org.quartz.Job;
import org.quartz.JobExecutionContext;

import weave.utils.CommandUtils;
import weave.utils.FileUtils;

import java.io.*;
import java.math.BigInteger;
import java.net.URL;
import java.security.MessageDigest;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import com.maxstocker.jdoctopdf.doctree.DocumentElement;
import com.maxstocker.jdoctopdf.parsers.DocParser;
import com.maxstocker.jdoctopdf.writers.PDFWriter;
import java.util.concurrent.Future;


/**
 * This class generates thumbnails from web documents, PDF and Doc files.
 * @author Sebastin
 *
 */
public class GenerateThumbnailJob implements Job{
	
	/**`
	 *The path to the wkhtmltoimage tool for creating thumbnail images from web documents on Linux/OS X machines
	**/
	private URL wkPath;
	
	/**`
	 *The path to the 64 bit wkhtmltoimage tool for creating thumbnail images from web documents on Linux/OS X machines
	**/
	private URL wkPath64;
	
	
	/**
	 *The path to the CutyCapt tool for creating thumbnail images from web documents on Windows machines
	**/
	private URL ccPath;
	
	/**
	 *The path to the pdfbox tool for creating images of PDF files.
	**/
	private URL pdf2ImgPath;
	
	/**
	 *The input stream of the file containing the config details
	**/
	private InputStream config;
	
	/**
	 *The path to store the thumbnails. Defaulted to ROOT/thumbnails directory in the Tomcat installation directory
	**/
	private String thumbnailPath;
	
	/**
	 *The image format. Default to JPG for smaller sized images.
	**/
	private String imgExtension = "jpg";
	
	public static void main(String[] args) {
		System.out.println();
	}
	
	private Boolean initialized = false;
	public GenerateThumbnailJob() {
		
		// initializing the file paths
		wkPath = getClass().getClassLoader().getResource("infomap/resources/wkhtmltoimage-i386");
		wkPath64 = getClass().getClassLoader().getResource("infomap/resources/wkhtmltoimage-amd64");
		ccPath = getClass().getClassLoader().getResource("/infomap/resources/CutyCapt.exe");
		pdf2ImgPath = getClass().getClassLoader().getResource("infomap/resources/pdfbox-app-1.6.0.jar");
		config = getClass().getClassLoader().getResourceAsStream("infomap/resources/config.properties");
		
		Properties prop = new Properties();
		
		try{
			
			prop.load(config);
			String tomcatPath = prop.getProperty("tomcatPath");
			
			solrServerURL = prop.getProperty("solrServerURL");
			
			//if thumbanail path is not provided then use thumbnails folder in tomcat root directory
			thumbnailPath = prop.getProperty("thumbnailPath");
			if(thumbnailPath == null)
				thumbnailPath = tomcatPath + "/webapps/ROOT/thumbnails/";
			
			File tbPath = new File(thumbnailPath);
			if(!tbPath.isDirectory())
			{
				Boolean createDir = tbPath.mkdir();
				if(!createDir)
				{
					System.out.println("Error creating thumbnail directory");
					return;
				}
				
			}
			if(!tbPath.canWrite())
			{
				System.out.println("No permission to create images in thumbnails folder");
				return;
			}
		}catch (Exception e) {
			System.out.println("Error loading GenerateThumbnail Properties files");
			e.printStackTrace();
			return;
		}
		
		
		if(wkPath==null || ccPath==null || pdf2ImgPath==null || config==null || solrServerURL==null)
		{
			System.out.println("Error Initializing GenerateThumbnail Resources");
			return;
		}
		
		initialized = true;
	}
	
	private String solrServerURL;
	public void execute(JobExecutionContext context)
	{
		if(!initialized)
			return;
		System.out.println("Executing ThumbnailJob");
		
		//GET LIST OF LINKS TO GENERATE THUMBNAILS
		HttpSolrServer server = new HttpSolrServer(solrServerURL);
		
		HttpSolrServer coreSolrServer = new HttpSolrServer(solrServerURL); 
		
		//query to check for documents whose imgName have not been set
		SolrQuery q = new SolrQuery();
		
		q.setQuery("!imgName:[\"\" TO *]");
		
		q.setSortField("date_added",SolrQuery.ORDER.asc);
		
		q.setFields("link");
		
		//query for documents whose imgName has been set as ERROR 
		
		SolrQuery qForErrorImg = new SolrQuery();
		
		qForErrorImg.setQuery("imgName:ERROR");
		qForErrorImg.setSortField("date_added",SolrQuery.ORDER.asc);
		qForErrorImg.setFields("link");
			
		try{
			System.out.println("MAKING THUMBNAIL QUERY " + q.toString());
			//Setting thumbnails for previously unset documents
			QueryResponse qResponse = coreSolrServer.query(q);
			
			long totalFound = qResponse.getResults().getNumFound();
			
			System.out.println("Total documents found with no thumbnails " + totalFound);
			
			//We break it into chunk of requests of size 1 documents
			for (int k = 0; k<=totalFound; k++)
			{
				q.setStart(k);
				q.setRows(1);
				
				QueryResponse totalQueryResponse = coreSolrServer.query(q);
				
				SolrDocumentList results = totalQueryResponse.getResults();
				
				Iterator<SolrDocument> docItr = results.iterator();
				
				while(docItr.hasNext())
				{
					SolrDocument d = docItr.next();
					
					String docURL = (String)d.getFieldValue("link");
					String imgName = FileUtils.generateUniqueNameFromURL(docURL);
					
					
					Boolean success = createImageForDocument(docURL, imgName);
					
					//update document with imgName. If no image was created updated with ERROR message
					SolrInputDocument dInput = new SolrInputDocument();
					dInput.addField("link", docURL);
					Map<String, String> mp = new HashMap<String, String>();
		       		if(success)
		       			mp.put("set",imgName+"." + imgExtension);
		       		else
		       			mp.put("set","ERROR");//Updated With ERROR string if creating thumbnail failed.
					dInput.addField("imgName", mp);
					UpdateResponse r = coreSolrServer.add(dInput);
					System.out.println("Document updated with status code "+r.getStatus()); 
				}
			}
			
			QueryResponse qWithErrorResponse = coreSolrServer.query(qForErrorImg);
			
			totalFound = qWithErrorResponse.getResults().getNumFound();
			
			for(int j =0; j<=totalFound; j++)
			{
				qForErrorImg.setStart(j);
				qForErrorImg.setRows(1);
				
				
				QueryResponse totalErrorQueryResponse = coreSolrServer.query(qForErrorImg);
				
				SolrDocumentList resultsForError = totalErrorQueryResponse.getResults();
				
				Iterator<SolrDocument> docItrForError = resultsForError.iterator();
				
				while(docItrForError.hasNext())
				{
					SolrDocument d = docItrForError.next();
					
					String docURLForError = (String)d.getFieldValue("link");
					String imgNameForError = FileUtils.generateUniqueNameFromURL(docURLForError);
					
					
					Boolean successForError = createImageForDocument(docURLForError, imgNameForError);
					
					//update document with imgName. If no image was created updated with ERROR message
					SolrInputDocument dInputForError = new SolrInputDocument();
					dInputForError.addField("link", docURLForError);
					Map<String, String> mpForError = new HashMap<String, String>();
		       		if(successForError)
		       			mpForError.put("set",imgNameForError+"." + imgExtension);
		       		else
		       			mpForError.put("set","ERROR");//Updated With ERROR string if creating thumbnail failed.
					dInputForError.addField("imgName", mpForError);
					UpdateResponse rForError = coreSolrServer.add(dInputForError);
					System.out.println("Document updated with status code "+rForError.getStatus()); 
				}
			}
				
			}catch (Exception e) {
				System.out.println("Error querying Core Solr Server");
				e.printStackTrace();
			}
			
		server.shutdown();
		return;
	}
	
	private Boolean createImageForDocument(String url, String imgName)
	{
		Boolean success = false;
		ArrayList<String> command = new ArrayList<String>();
		String docExtension = url.substring(url.length()-4, url.length());
		
		try
		{
			URL docURL = new URL(url);
			String protocol = docURL.getProtocol();
			String tempPDFFilePath;
			
			if(protocol != null) // if it is a web document 
			{
				//create a temporary local copy for DOC or PDF files and then delete it
				
				if(".pdf".equals(docExtension))
				{
					//create a temporary local pdf file using same image name
					tempPDFFilePath = thumbnailPath+ imgName+".pdf";
					FileUtils.copyFileFromURL(url,tempPDFFilePath);
					
					//create the image and delete the pdf file
					success = createImageFromLocalPdf(tempPDFFilePath,imgName,true);
				} 
				else if(".doc".equals(docExtension))
				{
					try{
						
						//create a temporary PDF file from the DOC file
						String tempDocFilePath = thumbnailPath+ imgName+".doc";
						FileUtils.copyFileFromURL(url,tempDocFilePath);
						createPDFFromLocalDocFile(tempDocFilePath,imgName);
						
						//create the image and delete the pdf file
						tempPDFFilePath = thumbnailPath+ imgName+".pdf";
						success = createImageFromLocalPdf(tempPDFFilePath, imgName, true);
						
					}catch(Exception e)
					{
						System.out.println("Error creating image from Doc file");
						e.printStackTrace();
					}
				}else{//any other web document
					
					String osName = System.getProperty("os.name");
					if(!osName.matches("(?i).*windows.*"))
					{
						if(System.getProperty("os.arch").equals("x86"))
						{
							command.add(wkPath.toURI().getPath());
						}
						else
						{
							command.add(wkPath64.toURI().getPath());
						}
						command.add("--disable-javascript");
						command.add("--load-error-handling");
						command.add("ignore");
						command.add("--quality");
						command.add("70");
						command.add("--height");
						command.add("800");
						command.add("--crop-w");
						command.add("800");	
						command.add(url);
						command.add(thumbnailPath + imgName + "." + imgExtension);
					}else //if Windows use CutyCapt
					{
						command.add(ccPath.toURI().getPath());
						command.add("--url="+url);
						command.add("--out="+thumbnailPath + imgName + "." + imgExtension);
					}
					success = runCommand(command);
					// ToDo Need to deal with success == false for local pdf, doc and etc.
					// This deals with the possible execution exception (success == false) and the wkPath64 still creates empty, access denied or looks correct image.
					if (!success) {
						File tempImg = new File(thumbnailPath + imgName + "." + imgExtension);
						if (tempImg.exists()) tempImg.delete();
					}
				}
			}
			else //if it is a local file path
			{
				if(".pdf".equals(docExtension))
				{
					//create the image and delete the pdf file
					success = createImageFromLocalPdf(url,imgName,false);
				} 
				else if(".doc".equals(docExtension))
				{
					try{
						
						createPDFFromLocalDocFile(url,imgName);
						
						//create the image and delete the pdf file
						tempPDFFilePath = thumbnailPath+ imgName+".pdf";
						success = createImageFromLocalPdf(tempPDFFilePath, imgName, true);//the PDF file created is a copy of the doc file so we delete it.
						
					}catch(Exception e)
					{
						System.out.println("Error creating image from Doc file");
						e.printStackTrace();
					}
				}
			}
			
		}catch(Exception e)
		{
			System.out.println("Document URL is invalid");
			e.printStackTrace();
		}
		
		return success;
	}
	
	
	private Boolean createPDFFromLocalDocFile(String docPath,String fileName)
	{
		Boolean success = false;
		try{
			
			//we don't have a tool to generate images from DOC files. So we convert to PDF file and generate images.
			DocParser parser = new DocParser();
			
			InputStream in = new FileInputStream(docPath);
			
			OutputStream pdfFileStream = new FileOutputStream(thumbnailPath + fileName+ ".pdf");
			
			DocumentElement doc = parser.parse(in,true,false);
			
			PDFWriter writer = new PDFWriter();
			
			writer.writeDocument(doc, pdfFileStream);
			in.close();
			pdfFileStream.close();
			success = true;
			
		}catch(Exception e)
		{
			System.out.println("Error creating image from PDF file using Doc file");
			e.printStackTrace();
		}
		
		return success;
	}
	
	private Boolean createImageFromLocalPdf(String filePath,String imgName, Boolean deleteOriginalFile)
	{
		Boolean success =false;
		
		ArrayList<String> command = new ArrayList<String>();
		
		command.add("java");
		command.add("-jar");
		command.add(pdf2ImgPath.getPath());
		command.add("PDFToImage");
		command.add("-imageType");
		command.add(imgExtension);
		command.add("-startPage");
		command.add("1");
		command.add("-endPage");
		command.add("1");
		command.add("-resolution");
		command.add("15");
		command.add(filePath);
		
		//Run the command to create the image
		success = runCommand(command);
		
		File pdf = new File(filePath);
		
		//Get the image file. It is stored in the same location as the PDF file.
		//The utility creates a JPG file with a same name and the number 1 appended in the end.
		File tempImg = new File(pdf.getParent()+ "/" + pdf.getName().substring(0, pdf.getName().length()-4) + "1." + imgExtension);
		
		//Copy the image with the auto generated unique name
		try{
			
			FileUtils.copy(tempImg.getAbsolutePath(), thumbnailPath + imgName +"." + imgExtension);
		}catch(Exception e)
		{
			System.out.println("Error Copying temp image file");
			System.out.println("filepathe: " + filePath + "pdffile: " + pdf.getAbsolutePath());
			e.printStackTrace();
			success = false;
		}
		
		//Delete the PDF file and the old image
		tempImg.delete();
		if(deleteOriginalFile)
			pdf.delete();
		
		return success;
	}
	
	private ExecutorService executor = Executors.newSingleThreadScheduledExecutor();
	private Boolean runCommand(ArrayList<String> command)
	{
		Boolean success = false;
		RunCommand task = new RunCommand();
		task.command = command;
		Future<Boolean> future = executor.submit(task);
		try{
			success = future.get(30, TimeUnit.SECONDS);
		}catch (Exception e) {
			System.out.println("Command could not be completed");
			System.out.println(command.toString());
			e.printStackTrace();
			success = false;
		}finally
		{
			future.cancel(true);
		}
		return success;
	}
	
	class RunCommand implements Callable<Boolean>{
		
		private ArrayList<String> command;
		public void setCommand(ArrayList<String> command) {
			this.command = command;
		}
		
		// Possible conditions
		// Time out exception (wait more than 30 seconds to create the file)
		// Execution exception (exit value is not 0 ; it is still possible to create an empty or access denied or looks correct image (wkPath64 bug))
		
		Boolean success = false;
		
		@Override
		public Boolean call() throws Exception {
			try
			{
				String[] commmandsToExec = new String[0];
				
				commmandsToExec = command.toArray(commmandsToExec);
				
				int result = CommandUtils.runCommand(commmandsToExec);
				if(result == 0)
					success = true;
				else
					throw new Exception(); // This deals with execution exception
				System.out.println("Result is " + result);
			}
			catch (Exception e){
				e.printStackTrace();
				throw new Exception(); // This deals with execution exception
			}
			return success;
		}
	}
	
	
}
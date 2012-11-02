package infomap.admin;

/**
 * This is the BASE Data model to extract the content from the JSON object returned by the API Service
 * @author Sebastin
 *
 */
public class BaseDataModel {
	public responseHeader responseHeader;
		
		public class responseHeader{
			/**
			 * This holds the value of the query status
			 */
			public String status;
		}
		
		public Response response;
		
		public class Response{
			/*
			 * Holds the result set of documents
			 */
			public Doc[] docs;
			/*
			 * Total number of matches found
			 */
			public String numFound;
		}
		
		public class Doc{
			/*
			 * The title of the document
			 */
			String dctitle;
			/*
			 * The link to the document;
			 */
			String dclink;
			/*
			 * The date the document was published/created
			 */
			String dcdate;
			/*
			 * Description/Summary of the document
			 */
			String dcdescription;
			
		}
}

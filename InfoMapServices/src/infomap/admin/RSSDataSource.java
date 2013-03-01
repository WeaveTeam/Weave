package infomap.admin;

import org.apache.solr.common.SolrInputDocument;

public class RSSDataSource  extends AbstractDataSource{

	@Override
	String getSourceName() {
		// TODO Auto-generated method stub
		return "RSS Data Source";
	}
	
	String[] feedURLs;
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

}

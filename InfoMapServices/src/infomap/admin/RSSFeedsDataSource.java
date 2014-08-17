package infomap.admin;

import org.apache.solr.common.SolrInputDocument;

public class RSSFeedsDataSource extends AbstractDataSource
{
	public String[] links;
	
	// ToDo yenfu SOURCE_NAME and SOURCE_TYPE might not be appropriate for rss data source
	public static String SOURCE_NAME = "RssFeeds";
	public static String SOURCE_TYPE = "RssFeeds";
	
	@Override
	String getSourceName() {
		return SOURCE_NAME;
	}
	
	@Override
	String getSourceType() {
		return SOURCE_TYPE;
	}

	@Override
	SolrInputDocument[] searchForQuery() {
		// Since RssFeedsJob keeps running on the server, there is no need to periodically retrieve and index new docs for RSSFeedsDataSource triggered by client side.
		return null;
	}

	// ToDo yenfu temporary solution
	// The getTotalNumberOfQueryResultsFromSource method in NodeHandler.mxml will call this method.
	// This method is called to check if there exists new related docs from data source when there is no related docs indexed in solr.
	@Override
	long getTotalNumberOfQueryResults() {
		return 0;
	}
}

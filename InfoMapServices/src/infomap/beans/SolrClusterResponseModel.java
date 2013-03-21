package infomap.beans;

public class SolrClusterResponseModel {
	public SolrResponseHeader responseHeader;
	public SolrResponseModel response;
	public SolrClusterObject[] clusters;

	public class SolrResponseHeader{
		public String status;
		public String QTime;
	}
	public class SolrResponseModel {
		public Object numFound;
		public Object start;
		public LinkObject[] docs;
	}
	public class LinkObject{
		public Object link;
	}

}

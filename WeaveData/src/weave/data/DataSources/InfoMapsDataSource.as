package weave.data.DataSources
{
	import weave.*;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IAttributeHierarchy;
	import weave.api.data.IColumnReference;
	import weave.api.data.IDataSource;
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;
	import weave.primitives.DateRangeFilter;

	public class InfoMapsDataSource implements IDataSource
	{
		public function InfoMapsDataSource()
		{
			solrURL.value = "http://129.63.8.219:8080/solr/select/?version=2.2";
		}
		
		public const solrURL:LinkableString = newLinkableChild(this,LinkableString);
		
		private var csvDataSource:CSVDataSource = new CSVDataSource();
		
		/**
		 * @return An AttributeHierarchy object that will be updated when new pieces of the hierarchy are filled in.
		 */
		public function get attributeHierarchy():IAttributeHierarchy
		{
			return csvDataSource.attributeHierarchy;
		}
		
		/**
		 * initializeHierarchySubtree
		 * @param subtreeNode A node in the hierarchy representing the root of the subtree to initialize, or null to initialize the root of the hierarchy.
		 */
		public function initializeHierarchySubtree(subtreeNode:XML = null):void
		{
			return csvDataSource.initializeHierarchySubtree(subtreeNode);
		}
		
		/**
		 * The parameter type is now temporarily Object during this transitional phase.
		 * In future versions, the parameter will be an IColumnReference object.
		 * @param columnReference A reference to a column in this IDataSource.
		 * @return An IAttributeColumn object that will be updated when the column data downloads.
		 */
		public function getAttributeColumn(columnReference:IColumnReference):IAttributeColumn
		{
			return csvDataSource.getAttributeColumn(columnReference);
		}
		
		public static function getDocumentsForQuery(query:String,operator:String,numberOfDocuments:int=100,startDate:DateRangeFilter=null,endDate:DateRangeFilter=null):void
		{
			
		}
	}
}
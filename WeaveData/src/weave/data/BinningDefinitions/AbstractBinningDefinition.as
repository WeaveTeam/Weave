package weave.data.BinningDefinitions
{
	import weave.api.core.ILinkableHashMap;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IBinningDefinition;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableString;
	import weave.data.CSVParser;

	public class AbstractBinningDefinition implements IBinningDefinition
	{
		public function AbstractBinningDefinition()
		{
		}
		
		public const overrideBinNames:LinkableString = registerLinkableChild(this, new LinkableString(''));
		
		private var csvParser:CSVParser = new CSVParser();
		protected function getNameFromOverrideString(binIndex:int):String
		{
			var names:Array = csvParser.parseCSV(overrideBinNames.value);
			
			if(names.length == 0)
				return '';
			
			if(names[0][binIndex])
				return names[0][binIndex];
			else 
				return '';
		}
		
		public function getBinClassifiersForColumn(column:IAttributeColumn, output:ILinkableHashMap):void
		{
			
		}
	}
}
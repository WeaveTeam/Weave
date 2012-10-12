package disabilityDictionary
{
	public class DisabilityObject implements IDisabilityObject
	{
		public function DisabilityObject()
		{
		}
		
		public var slope:Number;
		
		
		public function getProperties(propertyName:Object):Array
		{
			var propertyNames:Array = new Array();
			propertyNames.push(slope);
			
			return propertyNames;
		}
	}
}
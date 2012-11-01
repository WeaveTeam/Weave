package disabilityDictionary
{
	public class DisabilityObject 
	{
		//One disability object is made for every visualization tool
		public function DisabilityObject()
		{
		}
		
		//these are statistical calculations done in R
		public var properties:Array = new Array();//array of properties for one object eg slope, periodicty, frequency
		//this array contains all the characteristics of one visualization eg title, color
		public var vizDetails:Array = new Array(); 
	}
}
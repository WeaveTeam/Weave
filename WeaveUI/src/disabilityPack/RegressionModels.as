package disabilityPack
{
	public class RegressionModels
	{
		public var Name:String;
		public var dataValues:Array;
		
		public function RegressionModels(name:String)
		{
			Name = name;
			
			if(Name == "Linear")
			{
				dataValues = new Array(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20);
			}
			
			else if(Name == "NegativeLinear")
			{
				dataValues = new Array(20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1);
			}
			
			else if(Name ==  "Logarithmic")
			{
				dataValues = new Array(1,4,9,16,25,36,49,64,81,100,121,144,169,196,225,256,289,324,361,400);
			}
			
			else if(Name == "NegativeLogarithmic")
			{
				dataValues = new Array(400,361,324,289,256,225,196,169,144,121,100,81,64,49,36,25,16,9,4,1);
			}
			
			else if(Name == "Polynomial")
			{
				dataValues = new Array(0,0.693147181,1.098612289,1.386294361,1.609437912,1.791759469,1.945910149,2.079441542,2.19722457 ,
					2.302585093,2.397895273,2.48490665,2.564949357,2.63905733,2.708050201,2.772588722,2.833213344,2.890371758,2.944438979,2.995732274);
			}
			
			else if(Name == "NegativePolyomial")
			{
				dataValues = new Array(2.995732274,2.944438979,2.890371758,2.833213344,2.772588722,2.708050201,
					2.63905733,2.564949357,2.48490665,2.397895273,2.302585093,2.197224577,2.079441542,
					1.945910149,1.791759469,1.609437912,1.386294361,1.098612289,0.693147181,0);
			}
			
			else if(Name ==  "Exponential")
			{
				dataValues = new Array(2.718281828,7.389056099,20.08553692,54.59815003,148.4131591,403.4287935,1096.633158,2980.957987,8103.083928,22026.46579,59874.14172,162754.7914,442413.392,1202604.284,3269017.372,8886110.521,24154952.75,65659969.14,178482301,485165195.4);
			}
			
			else if(Name == "NegativeExponential")
			{
				dataValues = new Array(1,3,4,6);
			}
			
			else if(Name ==  "BellyCurve")
			{
				dataValues = new Array(1,3,4,6);
			}
			
			else if(Name ==  "NegativeBellyCurve")
			{
				dataValues = new Array(1,3,4,6);
			}
			
			else if(Name == "Stable")
			{
				dataValues = new Array(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
			}
			
		}
	}
	
	
}
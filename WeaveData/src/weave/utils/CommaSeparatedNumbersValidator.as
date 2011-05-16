/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/
package weave.utils
{
	import mx.validators.ValidationResult;
	import mx.validators.Validator;

	public class CommaSeparatedNumbersValidator extends Validator
	{
		public function CommaSeparatedNumbersValidator()
		{
			super();
		}
		
        // Define Array for the return value of doValidation().
        private var results:Array;

		public var minNumberAllowed:Number = Number.NEGATIVE_INFINITY;
		public var maxNumberAllowed:Number = Number.POSITIVE_INFINITY;

        override protected function doValidation(value:Object):Array 
        {
        	// no results so far
            results = [];
            
            // get any results from the super, return if there are any
            results = super.doValidation(value);        
            if (results.length > 0)
                return results;
             
            if(value is String)
            {
            	var numberList:String = value as String;
            	
            	var numbers:Array = numberList.split(",");
            	var prevNumber:int = Number.NEGATIVE_INFINITY;
            	
            	for (var i:int = 0; i < numbers.length; i++)
            	{
            		var num:String = numbers[i];
            		
            		
        			var thisNumber:Number = Number(num);
        			
        			if(num == "")
            			results.push(new ValidationResult(true, "", "badNumberInList", "The list must start and end with numbers.  Please be sure the list does not start or end with a comma."));
        			
        			// case when the user has non-numbers in the list
        			if( isNaN(thisNumber) )
        				results.push(new ValidationResult(true, "", "badNumberInList", "The list is not valid.  Please enter data in the format: #,#,#..."));
        			
        			// case when the number is less than or equal to the minimum allowed
        			if(thisNumber <= minNumberAllowed)
        				results.push(new ValidationResult(true, "", "badNumberInList", "A number is in the list that is less than the minimum data value as shown on the left.  Please enter values only greater than the minimum in order to split correctly."));
        			
        			
        			
        			// case when the number is less	than or equal to the previous number (wants an ordered list)
        			if(thisNumber <= prevNumber)
        				results.push(new ValidationResult(true, "", "badNumberInList", "The list must be ordered from low to high and between the minimum and maximum data values in order to split correctly."));
        			
        			// case when the number is more than or equal to the maximum allowed	
        			if(thisNumber >= maxNumberAllowed)
        				results.push(new ValidationResult(true, "", "badNumberInList", "A number is in the list that is greater than the maximum data value as shown on the right.  Please enter values only less than the maximum in order to split correctly."));
        			
        					
        			prevNumber = thisNumber;
            	}
            } 
            
            return results;
        }	
	}
}
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

package weave.services.beans
{
	import weave.data.AttributeColumns.NumberColumn;
	import weave.utils.VectorUtils;
	
	/**
	 * LinearRegressionResult
	 * The result of a call to a LinearRegression webservice call
	 */
	public class LinearRegressionResult
	{
		public function LinearRegressionResult(result:Object)
		{
			this.slope = result.slope;
			this.intercept = result.intercept;
			this.rSquared = result.RSquared;

			// convert arrays to vectors and store the residual values			
			//TODO: need residual.keyType
			//this.residual.updateRecords(Vector.<String>(result.keys), Vector.<Number>(result.residual), true);
		}
		
		public var slope:Number;
		public var intercept:Number;
		public var rSquared:Number;
		//public var summary:String;
		//public var residual:NumberColumn = new NumberColumn(<attribute name="Residual values"/>);
	}
}
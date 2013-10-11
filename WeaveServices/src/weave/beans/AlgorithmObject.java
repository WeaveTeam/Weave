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

package weave.beans;

import java.util.HashMap;

public class AlgorithmObject
{
	public AlgorithmObject()
	{
	}
	
	
	/**
	 *For each data mining algorithm selected, this object is created
	 * Parameters : parameterMapping which stores a mapping of name of parameter to its value
	 *             isSelectedInAlgorithmList tell us whether this algorithm has been selected to run or not
	 *             algoName tells us the name of the algorithm
	 **/
	
	//tells us the name of the algorithm
	public String algoName = "";
	
	//public var parameters:Array = new Array();// tells us the parameters needed for the algorithm. Each algorithm will have a different number of parameters
	
	
	/* default is false. When selected it becomes true
	 * tells us if an algorithm is selected in the list for running algorithms in R*/
	
	public boolean isSelectedInAlgorithmList = false; 
	
	//maps the name of the parameter to its value for a dataminingObject
	public HashMap<String, Object> parameterMapping = new HashMap<String, Object>();
	
	
	
}

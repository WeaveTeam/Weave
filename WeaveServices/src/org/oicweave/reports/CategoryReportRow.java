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

package org.oicweave.reports;

import java.io.Writer;
import java.util.ArrayList;

/** 
 * This class encapsulates the data for a category report row.  
 * It implements Comparable so that we can sort the row data as specified
 * by the client.  
 * @author Mary Beth
 */
public class CategoryReportRow implements Comparable<CategoryReportRow> 
{
	public ArrayList<String> catValues = new ArrayList<String>();
	public ArrayList<String> attrValues = new ArrayList<String>();

	public void writeLine(Writer writer)
	{
		try
		{
			writer.write("<tr frame=\"above\">");
			String value = attrValues.get(0);
			writer.write(String.format("<td style=\"font-size:8pt\" width=\"100\"><b>%s</td>", value));
			value = attrValues.get(1);
			writer.write(String.format("<td>%s</b></td>", value)); 
			writer.write("</tr>");
			
			//loop through remaining attrs
			for (int i = 2; i < attrValues.size(); i++)
			{
				value = attrValues.get(i);
				if ((value != null) && (value.length()!=0))
				{
					writer.write("<tr>");				
					writer.write("<td></td>");
					writer.write(String.format("<td  style=\"font-size:8pt\" width=\"90&#37\">%s</td>", value));
					writer.write("</tr>");
				}
			}
		}
		catch (Exception e)
		{
			
		}
	}
	
	public int compareTo(CategoryReportRow r)
	{
		try
		{
			//@TODO make this a loop through the category values
			int result = 0;
			String categoryValue = catValues.get(0);
			String rCategoryValue = r.catValues.get(0);
			if ((categoryValue != null) && (rCategoryValue!= null))
				result = categoryValue.compareTo(rCategoryValue);
			//if the values were equal
			if (result == 0)
			{
				categoryValue = catValues.get(1);
				rCategoryValue = r.catValues.get(1);
				if ((categoryValue != null) && (rCategoryValue != null))
					result = categoryValue.compareTo(rCategoryValue);
			}
			return result;
		}
		catch (Exception e)
		{
			return 1;
		}
	}


}

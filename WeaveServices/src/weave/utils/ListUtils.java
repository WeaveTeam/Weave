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

package weave.utils;

import java.util.Arrays;
import java.util.List;

/**
 * ListUtils
 * 
 * @author Andy Dufilie
 */
public class ListUtils
{
	@SuppressWarnings("unchecked")
	public static <T> List<T> copyArrayToList(Object[] input, List<T> output)
	{
		for (int i = 0; i < input.length; i++)
		{
			output.add((T)input[i]);
		}
		
		return output;
	}

	public static int[] copyIntegerArray(Object[] input, int[] output)
	{
		for (int i = 0; i < input.length; i++)
		{
			try
			{
				if (input[i] instanceof Number)
					output[i] = ((Number)input[i]).intValue();
				else
					output[i] = Integer.MIN_VALUE;
			}
			catch (ClassCastException e)
			{
				output[i] = Integer.MIN_VALUE;
			}
		}
		return output;
	}
	
	public static double[] copyDoubleArray(Object[] input, double[] output)
	{
		for (int i = 0; i < input.length; i++)
		{
			try
			{
				if (input[i] instanceof Number)
                    output[i] = ((Number)input[i]).doubleValue();
            else
                    output[i] = Double.NaN;
			}
			catch (ClassCastException e)
			{
				output[i] = Double.NaN;
			}
		}
		return output;
	}
	
	public static String[] copyStringArray(Object[] input, String[] output)
	{
		for (int i = 0; i < input.length; i++)
		{
			try
			{
				output[i] = (String)input[i];
			}
			catch (ClassCastException e)
			{
				output[i] = null;
			}
		}
		return output;
	}

	public static int[] toIntArray(Integer[] list)
	{
		int[] array = new int[list.length];
		for (int i = 0; i < array.length; i++)
			array[i] = list[i];
		return array;
	}
	public static float[] toFloatArray(Float[] list)
	{
		float[] array = new float[list.length];
		for (int i = 0; i < array.length; i++)
			array[i] = list[0];
		return array;
	}
	public static double[] toDoubleArray(Double[] list)
	{
		double[] array = new double[list.length];
		for (int i = 0; i < array.length; i++)
			array[i] = list[i];
		return array;
	}
	public static int[] toIntArray(List<Integer> list)
	{
		int[] array = new int[list.size()];
		for (int i = 0; i < array.length; i++)
			array[i] = list.get(i);
		return array;
	}
	public static float[] toFloatArray(List<Float> list)
	{
		float[] array = new float[list.size()];
		for (int i = 0; i < array.length; i++)
			array[i] = list.get(i);
		return array;
	}
	public static double[] toDoubleArray(List<Double> list)
	{
		double[] array = new double[list.size()];
		for (int i = 0; i < array.length; i++)
			array[i] = list.get(i);
		return array;
	}
	public static String[] toStringArray(List<String> list)
	{
		String[] array = new String[list.size()];
		for (int i = 0; i < array.length; i++)
			array[i] = list.get(i);
		return array;
	}
	public static Object[] toObjectArray(List<Object> list)
	{
		Object[] array = new Object[list.size()];
		for (int i = 0; i < array.length; i++)
			array[i] = list.get(i);
		return array;
	}
	/**
	 * findString
	 * @param needle A String to find with String.equals().
	 * @param haystack A list of String objects to search.
	 * @return The index of the first matching String, or -1 if it did not match anything in the List.
	 */
	public static int findString(String needle, String[] haystack)
	{
		for (int index = 0; index < haystack.length; index++)
		{
			String straw = haystack[index];
			if (needle == straw || (needle != null && needle.equals(straw)))
				return index;
		}
		return -1;
	}
	/**
	 * findString
	 * @param needle A String to find with String.equals().
	 * @param haystack A list of String objects to search.
	 * @return The index of the first matching String, or -1 if it did not match anything in the List.
	 */
	public static int findString(String needle, List<String> haystack)
	{
		if (needle == null)
			return haystack.indexOf(null);

		for (int index = 0; index < haystack.size(); index++)
			if (needle.equals(haystack.get(index)))
				return index;
		return -1;
	}
	public static int findIgnoreCase(String needle, String[] haystack)
	{
		return findIgnoreCase(needle, Arrays.asList(haystack));
	}
	/**
	 * findIgnoreCase
	 * @param needle A String to find with String.equalsIgnoreCase().
	 * @param haystack A list of String objects to search.
	 * @return The index of the first matching String, or -1 if it did not match anything in the List.
	 */
	public static int findIgnoreCase(String needle, List<String> haystack)
	{
		if (needle == null)
			return haystack.indexOf(null);
		
		for (int index = 0; index < haystack.size(); index++)
			if (needle.equalsIgnoreCase(haystack.get(index)))
				return index;
		return -1;
	}
	/**
	 * removeIgnoreCase
	 * @param needle A String to find with findIgnoreCase().
	 * @param haystack A list of String objects to search.
	 * @return The list with the first matching element removed, if it was found with findIgnoreCase().
	 */
	public static List<String> removeIgnoreCase(String needle, List<String> haystack)
	{
		int index = findIgnoreCase(needle, haystack);
		if (index >= 0)
			haystack.remove(index);
		return haystack;
	}
}

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

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

/**
 * ListUtils
 * 
 * @author Andy Dufilie
 */
public class ListUtils
{
	public static <T> T[] getItems(T[] items, int[] indices)
	{
		T[] result = Arrays.copyOf(items, indices.length);
		for (int i = 0; i < indices.length; i++)
			result[i] = items[indices[i]];
		return result;
	}
	
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
				{
					output[i] = ((Number)input[i]).intValue();
				}
				else if (input[i] instanceof String)
				{
					try
					{
						output[i] = Integer.parseInt((String)input[i]);
					}
					catch (Exception e)
					{
						output[i] = Integer.MIN_VALUE;
					}
				}
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
				{
                    output[i] = ((Number)input[i]).doubleValue();
				}
				else if (input[i] instanceof String)
				{
					try
					{
						output[i] = Double.parseDouble((String)input[i]);
					}
					catch (Exception e)
					{
						output[i] = Double.NaN;
					}
				}
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
	public static int[] toIntArray(Collection<Integer> list)
	{
		int[] array = new int[list.size()];
		int i = 0;
		for (int value : list)
			array[i++] = value;
		return array;
	}
	public static float[] toFloatArray(Collection<Float> list)
	{
		float[] array = new float[list.size()];
		int i = 0;
		for (float value : list)
			array[i++] = value;
		return array;
	}
	public static double[] toDoubleArray(Collection<Double> list)
	{
		double[] array = new double[list.size()];
		int i = 0;
		for (double value : list)
			array[i++] = value;
		return array;
	}
	public static String[] toStringArray(Collection<String> list)
	{
		String[] array = new String[list.size()];
		int i = 0;
		for (String value : list)
			array[i++] = value;
		return array;
	}
	public static Object[] toObjectArray(Collection<Object> list)
	{
		Object[] array = new Object[list.size()];
		int i = 0;
		for (Object value : list)
			array[i++] = value;
		return array;
	}
	/**
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
	
	public static <T extends Comparable<? super T>> T getFirstSortedItem(Collection<T> items, T defaultValue)
	{
		List<T> sortedItems = new ArrayList<T>(items);
		Collections.sort(sortedItems);
		for (T item : sortedItems)
			return item;
		return defaultValue;
	}
}

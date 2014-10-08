package infomap.utils;

public class ArrayUtils 
{
	public static String joinArrayElements(String[] array, String element)
	{
		String result ="";
		
		if(array== null)
			return result;
		
		if(array.length == 0)
			return result;
		
		for (int i = 0; i<array.length; i++)
		{
			result += array[i];
			if(i != array.length -1)
				result += element;
		}
		
		return result;
	}
}

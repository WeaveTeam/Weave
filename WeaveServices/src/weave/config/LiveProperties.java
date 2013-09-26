package weave.config;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Map;
import java.util.Properties;

/**
 * This is a Properties object which automatically refreshes when its source file changes, and saves automatically when properties are set.
 */
public class LiveProperties extends Properties
{
	private static final long serialVersionUID = 0L;
	
	private final File file;
	private long lastMod = 0L;

	/**
	 * @param file The file used to read/write properties.
	 */
	public LiveProperties(File file)
	{
		this.file = file;
	}
	
	/**
	 * @param file The file used to read/write properties.
	 * @param defaults Default property values.
	 */
	public LiveProperties(File file, Map<String,String> defaults)
	{
		this.file = file;
		this.defaults = new Properties();
		for (Map.Entry<String,String> entry : defaults.entrySet())
		{
			String key = entry.getKey();
			String value = entry.getValue();
			if (getProperty(key) == null)
				setProperty(key, value);
			this.defaults.setProperty(key, value);
		}
	}
	
	private void detectChange()
	{
		if (file.lastModified() != lastMod)
		{
			FileInputStream fis = null;
			try
			{
				load(fis = new FileInputStream(file));
				lastMod = file.lastModified();
			}
			catch (FileNotFoundException e)
			{
				e.printStackTrace();
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
			finally
			{
				try
				{
					if (fis != null)
						fis.close();
				}
				catch (IOException e)
				{
					e.printStackTrace();
				}
			}
		}
	}
	
	@Override
	public String getProperty(String key)
	{
		detectChange();
		return super.getProperty(key);
	}
	
	@Override
	public Object setProperty(String key, String value)
	{
		Object prevValue = super.setProperty(key, value);
		
		FileOutputStream fos = null;
		try
		{
			store(fos = new FileOutputStream(file), null);
		}
		catch (FileNotFoundException e)
		{
			e.printStackTrace();
		}
		catch (IOException e)
		{
			e.printStackTrace();
		}
		finally
		{
			try
			{
				if (fos != null)
					fos.close();
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
		}
		
		return prevValue;
	}
}
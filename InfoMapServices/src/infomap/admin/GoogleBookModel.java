package infomap.admin;

import infomap.utils.ArrayUtils;

public class GoogleBookModel 
{
	public VolumeInfo volumeInfo; 

	public String getTitle()
	{
		String fullTitle = "";
		
		if(volumeInfo.title != null && volumeInfo.title.length()>0)
			fullTitle = volumeInfo.title;
		
		if(volumeInfo.subtitle != null && volumeInfo.subtitle.length()>0)
			fullTitle += " - " + volumeInfo.subtitle ;
		
		if(volumeInfo.authors != null && volumeInfo.authors.length>0)
			fullTitle += " by " + ArrayUtils.joinArrayElements(volumeInfo.authors.clone(), ", ");
		
		return fullTitle;
	}
	
	public String getDate()
	{
		if(volumeInfo.publishedDate !=null && volumeInfo.publishedDate.length()>0)
			return volumeInfo.publishedDate;
		else
			return "";
	}
	
	public String getDescription()
	{
		if(volumeInfo.description !=null && volumeInfo.description.length()>0)
			return volumeInfo.description;
		else
			return "";
	}
	
	public String getKeywords()
	{
		return ArrayUtils.joinArrayElements(volumeInfo.categories, " ");
	}
	
	public String getImageURL()
	{
		if(volumeInfo.imageLinks ==null)
			return "";
		if(volumeInfo.imageLinks.smallThumbnail != null && volumeInfo.imageLinks.smallThumbnail.length() >0)
			return volumeInfo.imageLinks.smallThumbnail;
		
		if(volumeInfo.imageLinks.thumbnail != null && volumeInfo.imageLinks.thumbnail.length() >0)
			return volumeInfo.imageLinks.thumbnail;
		
		return "";
	}
	
	public String getURL()
	{
		if(volumeInfo.canonicalVolumeLink !=null && volumeInfo.canonicalVolumeLink.length()>0)
			return volumeInfo.canonicalVolumeLink;
		else
			return "";
	}
	
	public class VolumeInfo
	{
		public String title;
		
		public String subtitle;
		
		public String[] authors;
		
		public String publishedDate;
		
		public String description;
		
		public String[] categories;
		
		public ImageLinks imageLinks;
		
		public String canonicalVolumeLink;
	}
	
	public class ImageLinks
	{
		public String smallThumbnail;
		public String thumbnail;
	}
}

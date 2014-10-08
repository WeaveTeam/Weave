package infomap.admin;

public class BingAcademicSearchDataModel {

	public Integer getTotalItems()
	{
		return Integer.parseInt(d.Publication.TotalItem);
	}
	
	public Result[] getDocuments()
	{
		return d.Publication.Result;
	}
	public d d;
	
	public class d{
		
		public Publication Publication;
		
		public class Publication{
			
			public String TotalItem = "0";
			
			public Result[] Result;
			
			
		}
	}
	
	public class Result{
		public String Abstract;
		
		public String ID;
		
		public String getAuthors()
		{
			String result = "";
			
			if (Author == null)
			{
				return result;
			}
			for(int i = 0; i < Author.length; i++)
			{
				Author auth = Author[i];
				
				if(auth == null)
					continue;
				
				if(auth.FirstName != null)
					result += auth.FirstName + " ";
				if(auth.LastName != null)
					result += auth.LastName;
				
				if(i != Author.length-1)
				{
					result += ", ";
				}
				
			}
			
			return result;
		}
		
		public Author[] Author;
		
		public String[] FullVersionURL;
		
		public String getURL()
		{
			if(FullVersionURL != null && FullVersionURL.length >0)
			{
				return FullVersionURL[0];//return first URL
			}
			else
			{
				return null;
			}
		}
		
		public Keyword[] Keyword;
		
		public String getKeywords()
		{
			String result = "";
			
			if(Keyword == null)
			{
				return result;
			}
			
			for(int i = 0; i < Keyword.length; i++)
			{
				Keyword k = Keyword[i];
				
				if(k == null)
					continue;
				
				if(k.Name != null)
					result += k.Name;
				
				if(i != Keyword.length-1)
				{
					result += ", ";
				}
				
			}
			return result;
		}
		
		public String Title;
		
		public String Year;
		
	}
	
	public class Author{
		public String FirstName;
		public String LastName;
	}
	
	public class Keyword{
		public String Name;
	}
	
	
}

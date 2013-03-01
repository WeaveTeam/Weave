package infomap.utils;
import java.net.URLEncoder;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class QueryString {

    private String query = "";

    public QueryString(HashMap<String, String> map) {
        Iterator it = map.entrySet().iterator();
        while (it.hasNext()) {
           try{
        	   Map.Entry pairs = (Map.Entry)it.next();
        	   query += URLEncoder.encode((String)pairs.getKey(),"UTF-8") + "=" +         
        	   URLEncoder.encode((String)pairs.getValue(),"UTF-8");
        	   if (it.hasNext()) { query += "&"; }
           }catch (Exception e) {
			// TODO: handle exception
		}
        }
    }

    public QueryString(Object name, Object value) {
       try{
    	   query = URLEncoder.encode(name.toString(),"UTF-8") + "=" +         
    	   URLEncoder.encode(value.toString(),"UTF-8");
       }catch (Exception e) {
		// TODO: handle exception
	}
   }

   public QueryString() { query = ""; }

   public synchronized void add(Object name, Object value) {
	   try
	   {
		   if (!query.trim().equals("")) query += "&";
		   query += URLEncoder.encode(name.toString(),"UTF-8") + "=" +         
		   URLEncoder.encode(value.toString(),"UTF-8");
	   }catch (Exception e) {
		// TODO: handle exception
	}
   }

   public String toString() { return query; }
}
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

import java.text.SimpleDateFormat;
import java.util.Date;

public class UploadedFile {

	public String size;
	//public sizeObject size2;
	public String name;
	public String lastModified;
	//public dateObject lastModified2;
	
	private SimpleDateFormat format = new SimpleDateFormat("MM/dd/yyyy hh:mm a");

	public UploadedFile(String name, long size, long lastModified) {
		
		Date date = new Date(lastModified);
		String tempSize = getSize(size);
		
		this.name 		  		= name;
		this.size		  		= tempSize;
		//this.size2.size	  		= size;
		//this.size2.text	  		= tempSize;
		this.lastModified 		= format.format(date);
		//this.lastModified2.date = lastModified;
		//this.lastModified2.text = format.format(date);
	}

	private String getSize(long size) {
		
		if( size < 1024 ) return size + (( size == 1 ) ? " Byte" : " Bytes");
		size = size / 1024;
		if( size < 1024 ) return size + (( size == 1 ) ? " Kilobyte" : " Kilobytes");
		size = size / 1024;
		if( size < 1024 ) return size + (( size == 1 ) ? " Megabyte" : " Megabytes");
		size = size / 1024;
		return size + (( size == 1 ) ? " Gigabyte" : " Gigabytes");
	}
	
	public String toString() {
		return "name = " + name + ", size = " + size + ", last modified = " + lastModified;
	}
	
	public class sizeObject {
		public long size;
		public String text;
	}
	public class dateObject {
		public long date;
		public String text;
	}
}

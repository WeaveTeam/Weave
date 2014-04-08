/* ************************************************************************ */
/*																			*/
/*  FAR (Flash Archive) AS3 loader											*/
/*  Copyright (c)2007 Edwin van Rijkom										*/
/*  http://www.vanrijkom.org												*/
/*																			*/
/* This library is free software; you can redistribute it and/or			*/
/* modify it under the terms of the GNU Lesser General Public				*/
/* License as published by the Free Software Foundation; either				*/
/* version 2.1 of the License, or (at your option) any later version.		*/
/*																			*/
/* This library is distributed in the hope that it will be useful,			*/
/* but WITHOUT ANY WARRANTY; without even the implied warranty of			*/
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU		*/
/* Lesser General Public License or the LICENSE file for more details.		*/
/*																			*/
/* ************************************************************************ */

package org.vanrijkom.far
{

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.geom.Point;
import flash.net.URLRequest;
import flash.net.URLStream;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.Endian;

/**
 * Dispatched when the loader is done loading and parsing the FAR 
 * file table.
 * @eventType org.vanrijkom.far.FarEvent.TABLE_COMPLETE
 */	
[Event(name="farTableComplete",type="org.vanrijkom.far.FarEvent")]
/**
 * Dispatched when the loader is reading file data for an item in 
 * the arhive.
 * @eventType org.vanrijkom.far.FarEvent.ITEM_PROGRESS
 */	
[Event(name="farItemProgress",type="org.vanrijkom.far.FarEvent")]
/**
 * Dispatched when the loader is about the uncompress an item in 
 * the archive.
 * @eventType org.vanrijkom.far.FarEvent.ITEM_UNCOMPRESS
 */	
[Event(name="farItemUncompress",type="org.vanrijkom.far.FarEvent")]
/**
 * Dispatched when the loader has finished uncompressing an item in
 * the archive.
 * @eventType org.vanrijkom.far.FarEvent.ITEM_UNCOMPRESSED
 */	
[Event(name="farItemUncompressed",type="org.vanrijkom.far.FarEvent")]
/**
 * Dispatched when the loader has fully finished loading and possibly
 * uncompressing an item from the archive.
 * @eventType org.vanrijkom.far.FarEvent.ITEM_COMPLETE
 */	
[Event(name="farItemComplete",type="org.vanrijkom.far.FarEvent")]

// -- URLStream native events:
/**
 * <strong>EventDispatcher</strong> Dispatched when Flash Player gains 
 * operating system focus and becomes active.
 * @eventType flash.events.Event.ACTIVATE
 */
[Event(name="activate", type="flash.events.Event")]
/**
 * <strong>URLStream:</strong> Dispatched when data has loaded 
 * successfully. 
 * @eventType flash.events.Event.COMPLETE 
 */
[Event(name="complete", type="flash.events.Event")]
/**
 * <strong>EventDispatcher:</strong> Dispatched when Flash Player loses 
 * operating system focus and is becoming inactive.
 * @eventType flash.events.Event.DEACTIVATE
 */
[Event(name="deactivate", type="flash.events.Event")]
/**
 * <strong>URLStream:</strong> Dispatched if a call to URLStream.load() 
 * attempts to access data over HTTP, and the current Flash Player 
 * is able to detect and return the status code for the request.
 * @eventType flash.events.HTTPStatusEvent.HTTP_STATUS 
 */
[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]
/**
 * <strong>URLStream:</strong> Dispatched when an input/output error
 * occurs that causes a load operation to fail.
 * @eventType flash.events.IOErrorEvent.IO_ERROR  
 */
[Event(name="ioError", type="flash.events.IOErrorEvent")]
/**
 * <strong>URLStream:</strong> Dispatched when a load operation starts.
 * @eventType flash.events.Event.OPEN
 */
[Event(name="open", type="flash.events.Event")]
/**
 * <strong>URLStream:</strong> Dispatched when data is received
 * as the download operation progresses. Data that has 
 * been received can be read immediately using the methods of 
 * the URLStream class. 
 * @eventType flash.events.ProgressEvent.PROGRESS 
 */
[Event(name="progress", type="flash.events.ProgressEvent")]
/**
 * <strong>URLStream:</strong> Dispatched if a call to URLStream.load()
 * attempts to load data from a server outside the security sandbox. 
 * @eventType flash.events.SecurityErrorEvent.SECURITY_ERROR 
 */
[Event(name="securityError", type="flash.events.SecurityErrorEvent")]

/**
 * The FarStream class loads and parses FAR formatted archives created
 * with the FAR archive utility. Far extends flash.net.URLStream, and as 
 * such all of URLStream's public properties, methods and events are 
 * supported by FarStream.
 * <p>
 * The progress of an archive being streamed in can be monitored at two
 * levels: at archive level, by using URLStream's native events, or at
 * item level. 
 * </p>
 * <p>
 * Monitoring at item level can be done by obtaining FarItem instances using
 * the <code>item()</code> method, specifying an index expected to be
 * in the archive. By adding FarEvent.ITEM_XXX listeners to the obtained
 * FarItem instance, events will be triggered when more information becomes
 * available on the item as a result of the archive progressively streaming
 * in.
 * </p>
 * <p> 
 * Alternatively, FarEvent.XXX listeners can be added to the FarStream 
 * instance itself.  This way, event are received for all item events 
 * as they are triggered over time when the archive is progressively loaded
 * in.
 * @author Edwin van Rijkom
 * @see #item()
 * @see FarEvent
 * 
 */
public class FarStream extends URLStream
{				
	private var vMajor			: int;
	private var vMinor			: int;	
	private var tableSize		: int;
	private var table			: Array;
	private var dict			: Dictionary;	
	private var gotHeader		: Boolean;
	private var gotTable		: Boolean;
	
	private var bytesLoaded		: int;
	private var bytesTotal		: int;

	private function clearTable(): void {		
		table 		= [];
		dict 		= new Dictionary(true);		
	}
	
	private function onProgress(e: ProgressEvent): void {
		// store progress:
		bytesLoaded = e.bytesLoaded;
		bytesTotal = e.bytesTotal;
				
		if (!gotHeader && e.bytesLoaded >=9)
			readHeader(e);							
		
		if (gotHeader && !gotTable && bytesAvailable >= tableSize)
			readTable(e);							
		
		if (gotTable && e.bytesLoaded>tableSize)			
			readFileData(e);		
	}
	
	private function readHeader(e: ProgressEvent): void {
		// check header:
		if	(!	(	readByte()==0x46
				&&	readByte()==0x41
				&&	readByte()==0x52
				))	
		{
			dispatchEvent(new IOErrorEvent
				( IOErrorEvent.IO_ERROR
				, false,false
				, "File is not FAR formatted")
			);
			close();
			return;
		}
		// version:
		vMajor = readByte();
		vMinor = readByte();
		if (vMajor>VMAJOR) {
			dispatchEvent(new IOErrorEvent
				( IOErrorEvent.IO_ERROR
				, false,false
				, "Unsupported archive version (v."+vMajor+"."+vMinor+")")					
			);
			close();
			return;
		}					
		// table size:
		tableSize = readUnsignedInt();		
		// done processing header:			
		gotHeader= true;
	}
	
	private function readTable(e: ProgressEvent): void {
		
		var i	: FarItem;
		var evt	: FarEvent;
		var l	: int;
		// table is terminated by 4 zero's:
		while(0!=(l=readUnsignedInt())){
			if (!bytesAvailable) {
				dispatchEvent(new IOErrorEvent
					( IOErrorEvent.IO_ERROR
					, false,false
					, "Corrupted FAR table")
				);
				close();
				return;
			}
			var index: String 		= readUTFBytes(l);
			var offset: int 		= readUnsignedInt();
			var size: int 			= readUnsignedInt()
			var compressed: Boolean = readByte() != 0
			
			if ((i=dict[index])==undefined) {
				// create a new item:
				i = new FarItem(this,index);
				// add to table:					
				dict[i.index] = i;
				table.push(i);
			} 			
			i.size = size;
			i.setOffset(offset);
			i.setCompressed(compressed);			
		}
		// dispatch table complete event:
		evt = new FarEvent(FarEvent.TABLE_COMPLETE);	
		evt.file = this;
		evt.item = null;			
		dispatchEvent(evt);
		// done processing table:			
		gotTable=true;		
	}
	
	private function readFileData(e: ProgressEvent): void {
		
		var i	: FarItem;
		var c	: int;
		var evt	: FarEvent;
		
		for (var j: uint=0; j<table.length; j++) {
			i = table[j];
			c = e.bytesLoaded-bytesAvailable;
			if 	(	c >= i.offset 
				&& 	!i.loaded 
				&& 	i.offset != -1
				&&	i.size != -1
				) 
			{
				// read data to item:
				var count: int = Math.min
					( i.size-i.data.length	// req. bytes to complete
					, bytesAvailable		// avail. bytes
					);
				readBytes(i.data,i.data.length,count);
				// broadcast item load progress:
				evt = new FarEvent(FarEvent.ITEM_PROGRESS);	
				evt.file = this;
				evt.item = i;			
				dispatchEvent(evt);	
				// is the file fully loaded?
				if (i.data.length == i.size) {
					i.setLoaded(true);					
					if (i.compressed) {
						// broadcast item uncompression start:				
						evt = new FarEvent(FarEvent.ITEM_UNCOMPRESS);	
						evt.file = this;
						evt.item = i;			
						dispatchEvent(evt);							
						// check if we should still uncompress:
						if (evt.inflate) {
							i.data.uncompress();
							i.setCompressed(false);
							// broadcast item finished uncompressing:
							evt = new FarEvent(FarEvent.ITEM_UNCOMPRESSED);	
							evt.file = this;
							evt.item = i;			
							dispatchEvent(evt);
						}						
					}						
					// broadcast item completion:					
					evt = new FarEvent(FarEvent.ITEM_COMPLETE);	
					evt.file = this;
					evt.item = i;			
					dispatchEvent(evt);					
				}
				if (bytesAvailable) 
					readFileData(e);
			}	
		}
	}
	
	// -- public
	
	/**
	 * Highest FAR archive version this version of the API
	 * is capable of reading (major).
	 */	
	public static const VMAJOR: int = 0;
	/**
	 * Highest FAR archive version this version of the API
	 * is capable of reading (minor).
	 */
	public static const VMINOR: int = 1;
	
	/**
	 * Contruct a new FarLoader instance. FarStream extends 
	 * flash.net.URLStream.
	 * @return 
	 * @see flash.net.URLStream
	 */		
	public function FarStream() {
		super();
		clearTable();			
		addEventListener(ProgressEvent.PROGRESS, onProgress);			
	}
		
	/**
	 * <strong>URLStream:</strong> Begins downloading the URL specified
	 * in the request parameter.
	 * @param request
	 * @see flash.net.URLStream#load 
	 */		
	public override function load(request: URLRequest): void {
		endian		= Endian.LITTLE_ENDIAN;
		tableSize 	= vMajor = vMinor = 0;
		gotHeader	= false;
		gotTable	= false;
		bytesLoaded = -1;
		bytesTotal 	= -2;		
		
		super.load(request);
	}
	
	/**
	 * Begins downloading the arhive from the URL specified. Uses
	 * the load method internally, after creating an URLRequest
	 * instance from the URL string. The created URLRequest is
	 * passed as the return value.
	 * @param url
	 * @see flash.net.URLStream#load 
	 */		
	public function loadFromURL(url: String): URLRequest {
		var r: URLRequest = new URLRequest(url);
		load(r);
		return r;
	}
	
	/**
	 * <strong>URLStream:</strong> Immediately closes the stream and 
	 * cancels the download operation. No data can be read from the
	 * stream after the close() method is called.
	 * @see flash.net.URLStream#load 
	 */	
	public override function close(): void {
		clearTable();
		super.close();
	}
		
	/**
	 * Retreive loaded archive version. The returned Point's x member 
	 * reflects major version,y member minor version. Will return a
	 * <code>Point(0,0)</code> if the archive's header has not been 
	 * loaded yet.
	 * @return 
	 */	
	public function get version(): Point {
		if (tableSize==0)
			throw new Error("FAR archive header not loaded");	
		return new Point(vMajor,vMinor);
	}
	
	/**
	 * True if the archive's header has been fully loaded.
	 * @return
	 * @see #loaded
	 * @see #loadedTable
	 */	
	public function get loadedHeader(): Boolean {
		return gotHeader;
	}	
	
	/**
	 * True if the archive's file table has been fully loaded.
	 * @return 
	 * @see #loaded
	 * @see #loadedHeader
	 */	
	public function get loadedTable(): Boolean {
		return gotTable;	
	}
	
	/**
	 * True if the archive has been fully loaded into memory.
	 * @return  
	 * @see #loadedHeader
	 * @see #loadedTable
	 */	
	public function get loaded(): Boolean {
		return gotHeader && gotTable && bytesLoaded==bytesTotal;
	}
	
	/**
	 * Retreive the list of indices as currently stored in the in-memory
	 * file table.
	 * @return 
	 * 
	 * @see #loadedTable
	 * 
	 */	
	public function get indices(): Array {
		if (table==null)
			throw new Error("FAR archive table not loaded");
		var r: Array = [];
		for (var i: uint = 0; i< table.length; i++) {
			r.push(table[i].index);
		}
		return r;
	}
	
	/**
	 * True if the specified index is on the in-memory file table.
	 * <p>
	 * When invoked before having received the FarEvent.TABLE_COMPLETE
	 * event the method will only return true for indices that have been
	 * added using the <code>item</code> method. 
	 * </p>
	 * @param index
	 * @return 
	 * 
	 * @see #item()
	 * @see FarEvent#TABLE_COMPLETE
	 */	
	public function exists(index: String): Boolean {
		return dict[index]==undefined;
	}
	
	/**
	 * Retreive a FarItem object for the specified index name.
	 * <p>If the item is found in the in-memory file table, its associated FarItem is returned.</p>
	 * <p>
	 * If the item is not found because the archive file-table has not been fully 
	 * streamed in yet a new FarItem instance is created and added to the in-memory 
	 * file table. If the item index was not found in the archive file-table after 
	 * it has completed loading, the item will dispatch a IOErrorEvent.IO_ERROR event.
	 * </p>
	 * <p>
	 * If the item is not found and the archive file-table has been fully loaded
	 * the method will throw an exception.
	 * </p>
	 * @param index
	 * @return 
	 * 
	 * @see FarItem
	 * @see #loadedTable
	 * @see flash.events.IOErrorEvent#IO_ERROR
	 */	
	public function item(index: String): FarItem {
		var r: FarItem;	
		if ((r=dict[index])==undefined) {
			if (loaded)
				throw(new Error("Item "+index+" is not in the currently loaded archive file"));
			// unknown entry, add it:
			r = new FarItem(this,index,-1,-1,false);
			table.push(r);
			dict[index]=r;
		}	
		return r;	
	}
	
	/**
	 * Number of files stored in the in-memory archive file table.
	 * <p>
	 * Until the archive file-table has been fully loaded, the returned value only
	 * reflects the number of items that have been added to the in-memory file-table
	 * using the #item() method.
	 * </p>
	 * 
	 * @see #item()
	 * @see #loadedTable
	 * @return
	 */	
	public function get count(): uint {
		return table.length;	
	}
	
	/**
	 * Retreive FarItem by queue position. The index is zero based.
	 * <p>
	 * Until the archive file-table has been fully loaded, only items that have been
	 * added using the item method can be retreived.
	 * </p>
	 * 
	 * @param index
	 * @return
	 *  
	 * @see #item()
	 * @see #loadedTable
	 */	
	public function itemAt(index: uint): FarItem {
		if (index >= table.length)
			throw new Error("FAR item index out of bounds");	
		return table[index];	
	}	
}

} // package
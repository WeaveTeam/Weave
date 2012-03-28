/* ************************************************************************ */
/*																			*/
/*  FAR (Flash Archive) AS3 stream											*/
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

import flash.utils.ByteArray;
import flash.net.URLLoader;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.display.Loader;
import flash.system.LoaderContext;
import flash.media.Sound;
import flash.display.MovieClip;

/**
 * Dispatched when file data for this item is being read from 
 * the arhive.
 * @eventType flash.events.ProgressEvent.PROGRESS
 */	
[Event(name="progress",type="flash.events.ProgressEvent")]
/**
 * Dispatched when the loader is about the uncompress an item in 
 * the archive.
 * @eventType org.vanrijkom.far.FarEvent.ITEM_UNCOMPRESS
 */	
[Event(name="farItemUncompress",type="org.vanrijkom.far.FarEvent")]
/**
 * Dispatched when the loader has finished uncompressing an item in
 * the archive.
 * @eventType flash.events.Event.COMPLETE
 */	
[Event(name="complete",type="flash.events.Event")]
/**
 * Dispatched when the loader has fully finished loading and possibly
 * uncompressing an item from the archive.
 * @eventType org.vanrijkom.far.FarEvent.ITEM_COMPLETE
 */	
[Event(name="farItemComplete",type="org.vanrijkom.far.FarEvent")]
/**
 * Dispatched when an item was not found in the arhive's file table.
 * @eventType flash.events.IOErrorEvent.IO_ERROR  
 */
[Event(name="ioError", type="flash.events.IOErrorEvent")]

/**
 * The FarItem class represent an entry in a FAR file's file table.
 * FarItem instances can be obtained prior to the archive's file
 * table having streamed in from file. As a result, an item can be
 * bound to a non-existing index. Once an archives file table has
 * been fully loaded, the validity of the item's index is checked.
 * If the index is invalid, an IOErrorEvent is triggered.
 * 
 * @author Edwin van Rijkom
 * @see flash.events.IOErrorEvent
 * @see FarStream#item()
 */
public final class FarItem extends EventDispatcher
{
	/** @private */	
	internal var stream		: FarStream;
	
	/** @private */
	internal var size		: int;
	
	/** @private */
	internal var listening	: Boolean;
		
	/** @private */
	internal var offset		: int;		
	
	private var _index		: String;	
	private var _compressed	: Boolean;
	private var _loaded		: Boolean;	
	private var _data		: ByteArray;
		
	/**
	 * Don't use the constructor directly - use the FarStream.item method instead.
	 * @param stream managing the FAR file containing the item
	 * @param index item index in archive
	 * @param offset of file data in archive
	 * @param size of file data in archive
	 * @param compressed
	 * @return 
	 * 
	 * @see FarStream#item()
	 */	
	public function FarItem(ldr: FarStream, index: String, os: int=-1, sz: int=-1, compressed: Boolean=false) {
		stream 		= ldr;
		offset 		= os;
		size 		= sz;
		_loaded 	= false;
		_index 		= index;
		_compressed = compressed;		
		_data 		= new ByteArray();
		
		addListeners();
	}
	
	private function addListeners(): void {
		stream.addEventListener(FarEvent.TABLE_COMPLETE, onTable);
		stream.addEventListener(FarEvent.ITEM_PROGRESS, onProgress);
		stream.addEventListener(FarEvent.ITEM_UNCOMPRESS, forwardFarEvent);
		stream.addEventListener(FarEvent.ITEM_UNCOMPRESSED, forwardFarEvent);
		stream.addEventListener(FarEvent.ITEM_COMPLETE, onComplete);
		listening = true;
	}
	
	private function removeListeners(): void {
		if (listening) {
			stream.removeEventListener(FarEvent.TABLE_COMPLETE, onTable);
			stream.removeEventListener(FarEvent.ITEM_PROGRESS, onProgress);
			stream.removeEventListener(FarEvent.ITEM_UNCOMPRESS, forwardFarEvent);
			stream.removeEventListener(FarEvent.ITEM_UNCOMPRESSED, forwardFarEvent);
			stream.removeEventListener(FarEvent.ITEM_COMPLETE, onComplete);
			listening = false;
		}		
	}
	
	private function onTable(e: FarEvent): void {
		if (size==-1 || offset==-1) {
			var evt: IOErrorEvent = new IOErrorEvent
				( IOErrorEvent.IO_ERROR,false,false
				, "Item index not found in archive ("+_index+")"
				);
			dispatchEvent(evt);			
		}
	}
		
	private function onProgress(e: FarEvent): void {
		if (e.item == this) 
			dispatchProgress(); 
	}
	
	private function forwardFarEvent(e: FarEvent): void {
		if (e.item == this)
			dispatchEvent(e.clone());			
	}
		
	private function dispatchProgress(): void {
		var pe: ProgressEvent = new ProgressEvent
					( ProgressEvent.PROGRESS,false,false
					, bytesLoaded, size
					);
		dispatchEvent(pe);
	}
	
	private function onComplete(e: FarEvent): void {
		if (e.item == this) {
			dispatchComplete();
			removeListeners();
		}	
	}
	
	private function dispatchComplete(): void {
		var e: Event = new Event(Event.COMPLETE);
		dispatchEvent(e);		
	}
	
	// -- internal accessors
	
	/** @private */
	internal function setOffset(v: int): void {
		offset = v;
	}
	
	/** @private */
	internal function setCompressed(v: Boolean): void {
		_compressed = v;
	}
	
	/** @private */
	internal function setLoaded(v: Boolean): void {
		_loaded = v;
	}
	
	/** @private */
	internal function setData(v: ByteArray): void {
		_data = v;	
	}
	
	// -- public accessors
		
	/**
	 * Item file data, as loaded thus far from the archive.
	 * @return 
	 * 
	 */	
	public function get data(): ByteArray {
		return _data;	
	}
	
	/**
	 * Get the item file data as a String. Throws an exception if no data has been loaded yet.
	 * @return 
	 * 
	 */	
	public function asText(): String {
		if (!_loaded) 
			throw new Error("File not loaded");
		return _data.toString();
	}
	
	/**
	 * Get the item file data as a Bitmap. Throws an exception if no data has been loaded yet.
	 * @param context
	 * @return 
	 * 
	 */	
	public function asBitmap(context: LoaderContext=null): Bitmap {
		if (!_loaded) 
			throw new Error("File not loaded");
		var r: Bitmap = new Bitmap();
		r.loaderInfo.loader.loadBytes(_data,context);
		return r;
	}
	
	/**
	 * Get the item file data as a MovieClip. Throws an exception if no data has been loaded yet.
	 * @param context
	 * @return 
	 * 
	 */	
	public function asMovieClip(context: LoaderContext=null): MovieClip {
		if (!_loaded) 
			throw new Error("File not loaded");
		var m: MovieClip = new MovieClip();
		m.loaderInfo.loader.loadBytes(_data,context);
		return m;
	}
		
	/**
	 * The string uniquely identifying this item in the FAR archive.
	 * @return 
	 * 
	 */	
	public function get index(): String {
		return _index;
	}
		
	/**
	 * True if the file data belonging to this item is compressed in the archive.
	 * @return 
	 * 
	 */	
	public function get compressed(): Boolean {
		return _compressed;
	}
			
	/**
	 * True if the file data belonfing to this item has fully loaded from the archive.
	 * @return 
	 * 
	 */	
	public function get loaded(): Boolean {
		return _loaded;
	}
		
	/**
	 * Number of (possibly compressed) bytes read from the archive thus far.
	 * @return 
	 * 
	 */			
	public function get bytesLoaded(): Number {
		return _data.length;
	}
		
	/**
	 * Total item file data size (possibly compressed) as stored in
	 * the archive. Will return -1 if the item isn't in the archive,
	 * or if the arhive's file table has not been loaded yet.
	 * @return 
	 * 
	 */	
	public function get bytesTotal(): Number {
		return size;
	}
	
}
} // package
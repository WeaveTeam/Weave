/**
 * FontLoader 2.3 by Denis Kolyako. June 13, 2008. Last update: January 20, 2011.
 * Visit http://etcs.ru for documentation, updates and more free code.
 *
 * You may distribute this class freely, provided it is not modified in any way (including
 * removing this header or changing the package path).
 * 
 *
 * Please contact etc[at]mail.ru prior to distributing modified versions of this class.
 */
/**
 * The FontLoader class lets you load any swf movie (ver. 6 or later), which contains embedded fonts (CFF too) to use these fonts in your application.
 */
package ru.etcs.utils {
	import flash.display.Loader;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.Font;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	[Event("complete", type="flash.events.Event")]
	[Event("open", type="flash.events.Event")]
	[Event("ioError", type="flash.events.IOErrorEvent")]
	[Event("verifyError", type="flash.events.IOErrorEvent")]
	[Event("httpStatus", type="flash.events.HTTPStatusEvent")]
	[Event("progress", type="flash.events.ProgressEvent")]
	[Event("securityError", type="flash.events.SecurityErrorEvent")]
	/**
	 * FontLoader class
	 * 
	 * @author                    etc
	 * @version                    2.3
	 * @playerversion            Flash 9
	 * @langversion                3.0
	 */
	public class FontLoader extends EventDispatcher {
		
		/**
		 * @private
		 */
		private static const SWF_HEADER:ByteArray = new ByteArray();
		
		/**
		 * @private
		 */
		private static const CLASS_CODE:ByteArray = new ByteArray();
		
		/**
		 * @private
		 */
		private static const CLASS_NAME_PREFIX:String = 'Font$';
		
		/**
		 * @private
		 */
		private static const TAG_DO_ABC:uint = ((72 << 6) | 0x3F);
		
		/**
		 * @private
		 */
		private static const TAG_SYMBOL_CLASS:uint = ((76 << 6) | 0x3f);
		
		/**
		 * @private
		 */
		private static var _initialized:Boolean = false;
		
		/**
		 * @private
		 */
		private static function init():void {
			if (FontLoader._initialized) return;
			var ba:SWFByteArray = new SWFByteArray();
			ba.writeBytesFromString(
				'7800055F00000FA000000C01004411080000004302FFFFFFBF150B0000000100466F6E744C69620000' +
				'BF1461020000010000000010002E00000000191272752E657463732E7574696C733A466F6E7400432F' + 
				'55736572732F6574632F4465736B746F702F50726F6A656374732F466F6E744C6F616465724C69622F' + 
				'7372633B72752F657463732F7574696C733B466F6E742E61731772752E657463732E7574696C733A46' + 
				'6F6E742F466F6E74175B4F626A65637420466F6E7420666F6E744E616D653D2208666F6E744E616D65' + 
				'0D2220666F6E745374796C653D2209666F6E745374796C650C2220666F6E74547970653D2208666F6E' + 
				'745479706502225D1B72752E657463732E7574696C733A466F6E742F746F537472696E670653747269' + 
				'6E6708746F537472696E67175F5F676F5F746F5F646566696E6974696F6E5F68656C700466696C6543' + 
				'2F55736572732F6574632F4465736B746F702F50726F6A656374732F466F6E744C6F616465724C6962' + 
				'2F7372632F72752F657463732F7574696C732F466F6E742E617303706F73033636380D72752E657463' + 
				'732E7574696C7304466F6E740A666C6173682E74657874064F626A6563740335373006050116021614' + 
				'161618010201030A07020607020807020A07020D07020E070315070415091501070217040000020000' + 
				'00040000040C0000000200020F02101211130F02101211180106070905000101054100020100000001' + 
				'030106440000010104000101040503D03047000001010105060EF103F018D030F019D04900F01A4700' + 
				'00020201050620F103F01CD0302C05F01DD00401A02C07A0D00402A02C09A0D00403A02C0BA0480000' + 
				'030201010421D030F103F0165D085D096609305D076607305D07660758001D1D6806F103F00B470000'
			); // Magic bytes :-)
			ba.position = 0;
			ba.readBytes(FontLoader.SWF_HEADER);
			ba.length = 0;
			ba.writeBytesFromString(
				'392F55736572732F6574632F4465736B746F702F50726F6A656374732F466F6E744C6F616465724C69' + 
				'622F7372633B3B466F6E743030302E61730568656C6C6F2B48656C6C6F2C20776F726C642120497320' + 
				'616E79626F647920686572653F2057686F27732074686572653F0F466F6E743030302F466F6E743030' + 
				'300D72752E657463732E7574696C7304466F6E74064F626A6563740A666C6173682E74657874175F5F' + 
				'676F5F746F5F646566696E6974696F6E5F68656C700466696C65382F55736572732F6574632F446573' + 
				'6B746F702F50726F6A656374732F466F6E744C6F616465724C69622F7372632F466F6E743030302E61' + 
				'7303706F73023534060501160216071801160A00050702010703080702090705080300000200000006' + 
				'0000000200010B020C0E0D0F0101020904000100000001020101440100010003000101050603D03047' + 
				'0000010102060719F103F006D030EF01040008F007D049002C05F00885D5F009470000020201010527' + 
				'D030F103F00465005D036603305D046604305D026602305D02660258001D1D1D6801F103F002470000'
			); // Another magic bytes :-)
			ba.position = 0;
			ba.readBytes(FontLoader.CLASS_CODE);
			ba.length = 0;
			FontLoader._initialized = true;
		}
		
		/**
		 * Creates a new FontLoader object. If you pass a valid URLRequest object to the FontLoader constructor,
		 * the constructor automatically calls the load() function.
		 * If you do not pass a valid URLRequest object to the FontLoader constructor,
		 * you must call the load() function or the stream will not load. 
		 * 
		 * @param request (default = null) — The URL that points to an external SWF file. 
		 * @param autoRegister — Register loaded fonts automatically.
		 */
		public function FontLoader(request:URLRequest = null, autoRegister:Boolean = true) {
			super();
			FontLoader.init();
			this._loader.dataFormat = URLLoaderDataFormat.BINARY;
			this._loader.addEventListener(Event.COMPLETE,                         this.handler_complete);
			this._loader.addEventListener(Event.OPEN,                             super.dispatchEvent);
			this._loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,             super.dispatchEvent);
			this._loader.addEventListener(IOErrorEvent.IO_ERROR,                 super.dispatchEvent);
			this._loader.addEventListener(ProgressEvent.PROGRESS,                 super.dispatchEvent);
			this._loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,     super.dispatchEvent);
			if (request) this.load(request, autoRegister);
		}
		
		/**
		 * @private
		 */
		private const _loader:URLLoader = new URLLoader();
		
		/**
		 * @private
		 */
		private var _bytes:ByteArray;
		
		/**
		 * @private
		 */
		private var _libLoader:Loader;
		
		/**
		 * @private
		 */
		private var _fontCount:uint;
		
		/**
		 * @private
		 */
		private var _embeddedID:uint;
		
		/**
		 * @private
		 */
		private var _autoRegister:Boolean = true;
		
		/**
		 * Sets automatic font registration.
		 */
		public function set autoRegister(value:Boolean):void {
			if (this._autoRegister == value) return;
			this._autoRegister = value;
			if (value) this.registerFonts();
		}
		
		public function get autoRegister():Boolean {
			return this._autoRegister;
		}
		
		public function get bytesLoaded():uint {
			return this._loader.bytesLoaded;
		}
		
		public function get bytesTotal():uint {
			return this._loader.bytesTotal;
		}
		
		/**
		 * @private
		 */
		private const _fonts:Array = new Array();
		
		/**
		 * Returns an array of font classes, which you can use to register any extracted font.
		 */
		public function get fonts():Array {
			return this._fonts.concat();
		}
		
		/**
		 * Initiates loading of an external SWF file from the specified URL. You can load another swf file, when previous operation completed (or stream closed by user).
		 * 
		 * @param request:URLRequest — A URLRequest object specifying the URL to download. If the value of this parameter or the URLRequest.url property of the URLRequest object passed are null, Flash Player throws a null pointer error.  
		 * @param autoRegister — Register loaded fonts automatically.
		 * 
		 * @event complete:Event — Dispatched after data has loaded and parsed successfully.
		 * @event httpStatus:HTTPStatusEvent — If access is by HTTP, and the current Flash Player environment supports obtaining status codes, you may receive these events in addition to any complete or error event.
		 * @event ioError:IOErrorEvent — The load operation could not be completed.
		 * @event verifyError:IOErrorEvent — Dispatched when a parse operation fails (data has incorrect format).
		 * @event open:Event — Dispatched when a load operation starts.
		 * @event securityError:SecurityErrorEvent — A load operation attempted to retrieve data from a server outside the caller's security sandbox. This may be worked around using a policy file on the server. 
		 */
		public function load(request:URLRequest, autoRegister:Boolean = true):void {
			this.close();
			this._fonts.length = 0;
			this._fontCount = 0;
			this._autoRegister = autoRegister;
			this._loader.load(request);
		}
		
		/**
		 * Loads from binary data stored in a ByteArray object.
		 * 
		 * @param bytes:URLRequest — A ByteArray object. The specified ByteArray must contain valid SWF file. 
		 * @param autoRegister — Register loaded fonts automatically.
		 * 
		 * @event complete:Event — Dispatched after data has loaded and parsed successfully.
		 * @event httpStatus:HTTPStatusEvent — If access is by HTTP, and the current Flash Player environment supports obtaining status codes, you may receive these events in addition to any complete or error event.
		 * @event ioError:IOErrorEvent — The load operation could not be completed.
		 * @event verifyError:IOErrorEvent — Dispatched when a parse operation fails (data has incorrect format).
		 * @event open:Event — Dispatched when a load operation starts.
		 * @event securityError:SecurityErrorEvent — A load operation attempted to retrieve data from a server outside the caller's security sandbox. This may be worked around using a policy file on the server. 
		 */
		public function loadBytes(bytes:ByteArray, autoRegister:Boolean = true):void {
			this.close();
			this._fonts.length = 0;
			this._fontCount = 0;
			this._autoRegister = autoRegister;
			this.analyze(bytes, true);
		}
		
		/**
		 * Closes the stream, causing any download of data to cease.
		 */
		public function close():void {
			try {
				this._loader.close();
			} catch (error:Error) {}
			
			if (this._libLoader) {
				this._libLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, this.handler_libComplete);
				
				try {
					this._libLoader.close();
				} catch (error:Error) {}
				
				try {
					this._libLoader.unload();
				} catch (error:Error) {}
				
				this._libLoader = null;
			}
		}
		
		/**
		 * Registers all loaded fonts.
		 */        
		public function registerFonts():void {
			for each (var font:Font in this._fonts) {
				Font.registerFont((font as Object).constructor);
			}
		}
		
		/**
		 * @private
		 */
		private function analyze(bytes:ByteArray, delayed:Boolean = false):void {
			var o:Object;
			var stringID:String;
			var id:uint;
			var tempData:ByteArray;
			var fontSWF:ByteArray;
			var context:LoaderContext;
			var data:ByteArray;
			
			try {
				data = new SWFByteArray(bytes);
			} catch (error:Error) {
				if (delayed) {
					this._libLoader = new Loader();
					this._libLoader.addEventListener(Event.ENTER_FRAME, this.handler_delayedVerifyError);
				} else {
					this.close();
					super.dispatchEvent(new IOErrorEvent(IOErrorEvent.VERIFY_ERROR));
				}
				
				return;
			}
			
			var fontData:Object = new Object();
			var classCodeLength:uint = FontLoader.CLASS_CODE.length;
			this._embeddedID = 0;
			
			this.processSWF(data, fontData);
			
			tempData = new ByteArray();
			tempData.endian = Endian.LITTLE_ENDIAN;
			tempData.writeBytes(FontLoader.SWF_HEADER);
			id = 0;
			
			for (o in fontData) {
				data = fontData[o] as ByteArray;
				
				if (data) {
					stringID = id.toString();
					while (stringID.length < 3) stringID = '0' + stringID;
					stringID = FontLoader.CLASS_NAME_PREFIX + stringID;
					tempData.writeShort(FontLoader.TAG_DO_ABC);
					tempData.writeUnsignedInt(10 + stringID.length + classCodeLength);
					tempData.writeUnsignedInt(0x002E0010);
					tempData.writeUnsignedInt(0x10000000);
					tempData.writeByte(stringID.length);
					tempData.writeUTFBytes(stringID);
					tempData.writeByte(0);
					tempData.writeBytes(FontLoader.CLASS_CODE);
					tempData.writeBytes(data);
					tempData.writeShort(FontLoader.TAG_SYMBOL_CLASS);
					tempData.writeUnsignedInt(5 + stringID.length);
					tempData.writeShort(1);
					tempData.writeShort(o as uint);
					tempData.writeUTFBytes(stringID);
					tempData.writeByte(0);
					id++;
				}
			}
			
			this._fontCount = id;
			
			if (this._fontCount) {
				tempData.writeUnsignedInt(0x00000040);
				fontSWF = new ByteArray();
				fontSWF.endian = Endian.LITTLE_ENDIAN;
				fontSWF.writeUTFBytes('FWS');
				fontSWF.writeByte(9);
				fontSWF.writeUnsignedInt(tempData.length + 8);
				fontSWF.writeBytes(tempData);
				this._libLoader = new Loader();
				this._libLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.handler_libComplete);
				context = new LoaderContext();
				
				if ('allowLoadBytesCodeExecution' in context) { // AIR compatibility
					context['allowLoadBytesCodeExecution'] = true;
				}
				
				this._libLoader.loadBytes(fontSWF, context);
			} else {
				if (delayed) {
					this._libLoader = new Loader();
					this._libLoader.addEventListener(Event.ENTER_FRAME, this.handler_delayedComplete);
				} else {
					this.close();
					super.dispatchEvent(new Event(Event.COMPLETE));
				}
			}            
		}
		
		/**
		 * @private
		 */
		private function processSWF(data:ByteArray, fontData:Object, startFontID:uint = 0):void {
			var fontID:uint;
			var id:uint;
			var tag:uint
			var length:uint;
			var pos:Number;
			var tempData:ByteArray;
			
			while (data.bytesAvailable) {
				tag = data.readUnsignedShort();
				id = tag >> 6;
				length = ((tag & 0x3F) == 0x3F) ? data.readUnsignedInt() : (tag & 0x3F);
				pos = data.position;
				
				switch (id) {
					case 13:
					case 48:
					case 62:
					case 73:
					case 75:
					case 88:
					case 91:
						fontID = data.readUnsignedShort() + startFontID;
						tempData = fontData[fontID] as ByteArray;
						
						if (!tempData) {
							tempData = new ByteArray();
							tempData.endian = Endian.LITTLE_ENDIAN;
							fontData[fontID] = tempData;
						}
						
						if ((tag & 0x3F) == 0x3F) {
							tempData.writeShort((id << 6) | 0x3F);
							tempData.writeUnsignedInt(length);
						} else {
							tempData.writeShort((id << 6) | (length & 0x3F));
						}
						
						tempData.writeShort(fontID);
						tempData.writeBytes(data, data.position, length - 2);
						break;
					case 87: // DefineBinaryData
						tempData = new ByteArray();
						tempData.endian = Endian.LITTLE_ENDIAN;
						data.readUnsignedShort(); // tag
						data.readUnsignedInt(); // reserved
						tempData.writeBytes(data, data.position, length - 6);
						tempData.position = 0;
						
						try {
							tempData = new SWFByteArray(tempData);
							this._embeddedID += 1;
							this.processSWF(tempData, fontData, startFontID + 2000 * this._embeddedID);
						} catch (error:ArgumentError) {
							// Not SWF. Do nothing.
						}
						
						break;
				}
				
				data.position = pos + length;
			}
		}
		
		/**
		 * @private
		 */
		private function handler_delayedComplete(event:Event):void {
			this._libLoader.removeEventListener(Event.ENTER_FRAME, this.handler_delayedComplete);
			this._libLoader = null;
			this.close();
			super.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * @private
		 */
		private function handler_delayedVerifyError(event:Event):void {
			this._libLoader.removeEventListener(Event.ENTER_FRAME, this.handler_delayedVerifyError);
			this._libLoader = null;
			this.close();
			super.dispatchEvent(new IOErrorEvent(IOErrorEvent.VERIFY_ERROR));
		}
		
		/**
		 * @private
		 */
		private function handler_complete(event:Event):void {
			this.analyze(this._loader.data as ByteArray);
		}
		
		/**
		 * @private
		 */
		private function handler_libComplete(event:Event):void {
			var id:String;
			var i:uint;
			var fontClass:Class;
			var font:Font;
			var domain:ApplicationDomain = this._libLoader.contentLoaderInfo.applicationDomain;
			
			for (i = 0;i < this._fontCount;i++) {
				id = i.toString();
				while (id.length < 3) id = '0' + id;
				id = FontLoader.CLASS_NAME_PREFIX + id;
				
				if (domain.hasDefinition(id)) {
					fontClass = domain.getDefinition(id) as Class;
					font = new fontClass() as Font;
					
					if (font && font.fontName) { // Skip static fonts
						this._fonts.push(font);
						if (this._autoRegister) Font.registerFont(fontClass);
					}
				}
			}
			
			this.close();
			super.dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}

import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.geom.Rectangle;

internal class SWFByteArray extends ByteArray {
	
	/**
	 * @private
	 */
	private static const TAG_SWF:String = 'FWS';
	
	/**
	 * @private
	 */
	private static const TAG_SWF_COMPRESSED:String = 'CWS';
	
	public function SWFByteArray(data:ByteArray=null):void {
		super();
		super.endian = Endian.LITTLE_ENDIAN;
		var endian:String;
		var tag:String;
		var position:uint;
		
		if (data) {
			endian = data.endian;
			position = data.position;
			data.endian = Endian.LITTLE_ENDIAN;
			data.position = 0;
			
			if (data.bytesAvailable > 26) {
				tag = data.readUTFBytes(3);
				
				if (tag == SWFByteArray.TAG_SWF || tag == SWFByteArray.TAG_SWF_COMPRESSED) {
					this._version = data.readUnsignedByte();
					data.readUnsignedInt();
					data.readBytes(this);
					if (tag == SWFByteArray.TAG_SWF_COMPRESSED) super.uncompress();
				} else throw new ArgumentError('Error #2124: Loaded file is an unknown type.');
				
				this.readHeader();
			} else {
				throw new ArgumentError('Insufficient data.');
			}
			
			data.endian = endian;
			data.position = position;
		}
	}
	
	/**
	 * @private
	 */
	private var _bitIndex:uint;
	
	/**
	 * @private
	 */
	private var _version:uint;
	
	public function get version():uint {
		return this._version;
	}
	
	/**
	 * @private
	 */
	private var _frameRate:Number;
	
	public function get frameRate():Number {
		return this._frameRate;    
	}
	
	/**
	 * @private
	 */
	private var _rect:Rectangle;
	
	public function get rect():Rectangle {
		return this._rect;
	}
	
	public function writeBytesFromString(bytesHexString:String):void {
		var length:uint = bytesHexString.length;
		
		for (var i:uint = 0;i<length;i += 2) {
			var hexByte:String = bytesHexString.substr(i, 2);
			var byte:uint = parseInt(hexByte, 16);
			writeByte(byte);
		}
	}
	
	public function readRect():Rectangle {
		var pos:uint = super.position;
		var byte:uint = this[pos];
		var bits:uint = byte >> 3;
		var xMin:Number = this.readBits(bits, 5) / 20;
		var xMax:Number = this.readBits(bits) / 20;
		var yMin:Number = this.readBits(bits) / 20;
		var yMax:Number = this.readBits(bits) / 20;
		super.position = pos + Math.ceil(((bits * 4) - 3) / 8) + 1;
		return new Rectangle(xMin, yMin, xMax - xMin, yMax - yMin);
	}
	
	public function readBits(length:uint, start:int = -1):Number {
		if (start < 0) start = this._bitIndex;
		this._bitIndex = start;
		var byte:uint = this[super.position];
		var out:Number = 0;
		var shift:Number = 0;
		var currentByteBitsLeft:uint = 8 - start;
		var bitsLeft:Number = length - currentByteBitsLeft;
		
		if (bitsLeft > 0) {
			super.position++;
			out = this.readBits(bitsLeft, 0) | ((byte & ((1 << currentByteBitsLeft) - 1)) << (bitsLeft));
		} else {
			out = (byte >> (8 - length - start)) & ((1 << length) - 1);
			this._bitIndex = (start + length) % 8;
			if (start + length > 7) super.position++;
		}
		
		return out;
	}
	
	public function traceArray(array:ByteArray):String { // for debug
		var out:String = '';
		var pos:uint = array.position;
		var i:uint = 0;
		array.position = 0;
		
		while (array.bytesAvailable) {
			var str:String = array.readUnsignedByte().toString(16).toUpperCase();
			str = str.length < 2 ? '0'+str : str;
			out += str+' ';
		}
		
		array.position = pos;
		return out;
	}
	
	/**
	 * @private
	 */
	private function readFrameRate():void {
		if (this._version < 8) {
			this._frameRate = super.readUnsignedShort();
		} else {
			var fixed:Number = super.readUnsignedByte() / 0xFF;
			this._frameRate = super.readUnsignedByte() + fixed;
		}
	}
	
	/**
	 * @private
	 */
	private function readHeader():void {
		this._rect = this.readRect();
		this.readFrameRate();        
		super.readShort(); // num of frames
	}
}


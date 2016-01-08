package weavejs.util
{
	public class StringView
	{
		private static const ArrayBuffer:Class = JS.global.ArrayBuffer;
		private static const Uint32Array:Class = JS.global.Uint32Array;
		private static const Uint16Array:Class = JS.global.Uint16Array;
		private static const Uint8Array:Class = JS.global.Uint8Array;
		
		public var buffer:*, bufferView:Array, rawData:Array;
		
		/*\
		|*|
		|*|  :: Number.isInteger() polyfill ::
		|*|
		|*|  https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isInteger
		|*|
		\*/
		private static function Number_isInteger(nVal:Number):Boolean {
			return typeof nVal === "number" && isFinite(nVal) && nVal > -9007199254740992 && nVal < 9007199254740992 && Math.floor(nVal) === nVal;
		}
		
		/*\
		|*|
		|*|  StringView - Mozilla Developer Network
		|*|
		|*|  Revision #8, October 6, 2014
		|*|
		|*|  https://developer.mozilla.org/en-US/docs/Web/JavaScript/Typed_arrays/StringView
		|*|  https://developer.mozilla.org/en-US/docs/User:fusionchess
		|*|
		|*|  This framework is released under the GNU Lesser General Public License, version 3 or later.
		|*|  http://www.gnu.org/licenses/lgpl-3.0.html
		|*|
		\*/
		
		public function StringView (vInput, sEncoding = undefined/* optional (default: UTF-8) */, nOffset = undefined/* optional */, nLength = undefined/* optional */) {
			
			var fTAView:Class, aWhole:Array, aRaw:Array, fPutOutptCode:Function, fGetOutptChrSize:Function, nInptLen:int, nStartIdx:int = isFinite(nOffset) ? nOffset : 0, nTranscrType:int = 15;
			
			if (sEncoding) { this.encoding = sEncoding.toString(); }
			
			encSwitch: switch (this.encoding) {
				case "UTF-8":
					fPutOutptCode = StringView.putUTF8CharCode;
					fGetOutptChrSize = StringView.getUTF8CharLength;
					fTAView = Uint8Array;
					break encSwitch;
				case "UTF-16":
					fPutOutptCode = StringView.putUTF16CharCode;
					fGetOutptChrSize = StringView.getUTF16CharLength;
					fTAView = Uint16Array;
					break encSwitch;
				case "UTF-32":
					fTAView = Uint32Array;
					nTranscrType &= 14;
					break encSwitch;
				default:
					/* case "ASCII", or case "BinaryString" or unknown cases */
					fTAView = Uint8Array;
					nTranscrType &= 14;
			}
			
			typeSwitch: switch (typeof vInput) {
				case "string":
					/* the input argument is a primitive string: a new buffer will be created. */
					nTranscrType &= 7;
					break typeSwitch;
				case "object":
					classSwitch: switch (vInput.constructor) {
						case StringView:
							/* the input argument is a stringView: a new buffer will be created. */
							nTranscrType &= 3;
							break typeSwitch;
						case String:
							/* the input argument is an objectified string: a new buffer will be created. */
							nTranscrType &= 7;
							break typeSwitch;
						case ArrayBuffer:
							/* the input argument is an arrayBuffer: the buffer will be shared. */
							aWhole = new fTAView(vInput);
							nInptLen = this.encoding === "UTF-32" ?
							vInput.byteLength >>> 2
							: this.encoding === "UTF-16" ?
							vInput.byteLength >>> 1
							:
							vInput.byteLength;
							aRaw = nStartIdx === 0 && (!isFinite(nLength) || nLength === nInptLen) ?
							aWhole
							: new fTAView(vInput, nStartIdx, !isFinite(nLength) ? nInptLen - nStartIdx : nLength);
							
							break typeSwitch;
						case Uint32Array:
						case Uint16Array:
						case Uint8Array:
							/* the input argument is a typedArray: the buffer, and possibly the array itself, will be shared. */
							fTAView = vInput.constructor;
							nInptLen = vInput.length;
							aWhole = vInput.byteOffset === 0 && vInput.length === (
								fTAView === Uint32Array ?
								vInput.buffer.byteLength >>> 2
								: fTAView === Uint16Array ?
								vInput.buffer.byteLength >>> 1
								:
								vInput.buffer.byteLength
							) ? vInput : new fTAView(vInput.buffer);
							aRaw = nStartIdx === 0 && (!isFinite(nLength) || nLength === nInptLen) ?
							vInput
							: vInput.subarray(nStartIdx, isFinite(nLength) ? nStartIdx + nLength : nInptLen);
							
							break typeSwitch;
						default:
							/* the input argument is an array or another serializable object: a new typedArray will be created. */
							aWhole = new fTAView(vInput);
							nInptLen = aWhole.length;
							aRaw = nStartIdx === 0 && (!isFinite(nLength) || nLength === nInptLen) ?
							aWhole
							: aWhole.subarray(nStartIdx, isFinite(nLength) ? nStartIdx + nLength : nInptLen);
					}
					break typeSwitch;
				default:
					/* the input argument is a number, a boolean or a function: a new typedArray will be created. */
					aWhole = aRaw = new fTAView(Number(vInput) || 0);
					
			}
			
			if (nTranscrType < 8) {
				
				var vSource:*, nOutptLen:int, nCharStart:int, nCharEnd:int, nEndIdx:int, fGetInptChrSize:Function, fGetInptChrCode:Function;
				
				if (nTranscrType & 4) { /* input is string */
					
					vSource = vInput;
					nOutptLen = nInptLen = vSource.length;
					nTranscrType ^= this.encoding === "UTF-32" ? 0 : 2;
					/* ...or...: nTranscrType ^= Number(this.encoding !== "UTF-32") << 1; */
					nStartIdx = nCharStart = nOffset ? Math.max((nOutptLen + nOffset) % nOutptLen, 0) : 0;
					nEndIdx = nCharEnd = (Number_isInteger(nLength) ? Math.min(Math.max(nLength, 0) + nStartIdx, nOutptLen) : nOutptLen) - 1;
					
				} else { /* input is stringView */
					
					vSource = vInput.rawData;
					nInptLen = vInput.makeIndex();
					nStartIdx = nCharStart = nOffset ? Math.max((nInptLen + nOffset) % nInptLen, 0) : 0;
					nOutptLen = Number_isInteger(nLength) ? Math.min(Math.max(nLength, 0), nInptLen - nCharStart) : nInptLen;
					nEndIdx = nCharEnd = nOutptLen + nCharStart;
					
					if (vInput.encoding === "UTF-8") {
						fGetInptChrSize = StringView.getUTF8CharLength;
						fGetInptChrCode = StringView.loadUTF8CharCode;
					} else if (vInput.encoding === "UTF-16") {
						fGetInptChrSize = StringView.getUTF16CharLength;
						fGetInptChrCode = StringView.loadUTF16CharCode;
					} else {
						nTranscrType &= 1;
					}
					
				}
				
				if (nOutptLen === 0 || nTranscrType < 4 && vSource.encoding === this.encoding && nCharStart === 0 && nOutptLen === nInptLen) {
					
					/* the encoding is the same, the length too and the offset is 0... or the input is empty! */
					
					nTranscrType = 7;
					
				}
				
				conversionSwitch: switch (nTranscrType) {
					
					case 0:
						
						/* both the source and the new StringView have a fixed-length encoding... */
						
						aWhole = new fTAView(nOutptLen);
						for (var nOutptIdx:int = 0; nOutptIdx < nOutptLen; aWhole[nOutptIdx] = vSource[nStartIdx + nOutptIdx++]);
						break conversionSwitch;
					
					case 1:
						
						/* the source has a fixed-length encoding but the new StringView has a variable-length encoding... */
						
						/* mapping... */
						
						nOutptLen = 0;
						
						for (var nInptIdx:int = nStartIdx; nInptIdx < nEndIdx; nInptIdx++) {
							nOutptLen += fGetOutptChrSize(vSource[nInptIdx]);
						}
						
						aWhole = new fTAView(nOutptLen);
						
						/* transcription of the source... */
						
						for (nInptIdx = nStartIdx, nOutptIdx = 0; nOutptIdx < nOutptLen; nInptIdx++) {
							nOutptIdx = fPutOutptCode(aWhole, vSource[nInptIdx], nOutptIdx);
						}
						
						break conversionSwitch;
					
					case 2:
						
						/* the source has a variable-length encoding but the new StringView has a fixed-length encoding... */
						
						/* mapping... */
						
						nStartIdx = 0;
						
						var nChrCode:int;
						
						for (nChrIdx = 0; nChrIdx < nCharStart; nChrIdx++) {
							nChrCode = fGetInptChrCode(vSource, nStartIdx);
							nStartIdx += fGetInptChrSize(nChrCode);
						}
						
						aWhole = new fTAView(nOutptLen);
						
						/* transcription of the source... */
						
						for (nInptIdx = nStartIdx, nOutptIdx = 0; nOutptIdx < nOutptLen; nInptIdx += fGetInptChrSize(nChrCode), nOutptIdx++) {
							nChrCode = fGetInptChrCode(vSource, nInptIdx);
							aWhole[nOutptIdx] = nChrCode;
						}
						
						break conversionSwitch;
					
					case 3:
						
						/* both the source and the new StringView have a variable-length encoding... */
						
						/* mapping... */
						
						nOutptLen = 0;
						
						var nChrIdx:int;
						
						for (nChrIdx = 0, nInptIdx = 0; nChrIdx < nCharEnd; nInptIdx += fGetInptChrSize(nChrCode)) {
							nChrCode = fGetInptChrCode(vSource, nInptIdx);
							if (nChrIdx === nCharStart) { nStartIdx = nInptIdx; }
							if (++nChrIdx > nCharStart) { nOutptLen += fGetOutptChrSize(nChrCode); }
						}
						
						aWhole = new fTAView(nOutptLen);
						
						/* transcription... */
						
						for (nInptIdx = nStartIdx, nOutptIdx = 0; nOutptIdx < nOutptLen; nInptIdx += fGetInptChrSize(nChrCode)) {
							nChrCode = fGetInptChrCode(vSource, nInptIdx);
							nOutptIdx = fPutOutptCode(aWhole, nChrCode, nOutptIdx);
						}
						
						break conversionSwitch;
					
					case 4:
						
						/* DOMString to ASCII or BinaryString or other unknown encodings */
						
						aWhole = new fTAView(nOutptLen);
						
						/* transcription... */
						
						for (var nIdx:int = 0; nIdx < nOutptLen; nIdx++) {
							aWhole[nIdx] = vSource.charCodeAt(nIdx) & 0xff;
						}
						
						break conversionSwitch;
					
					case 5:
						
						/* DOMString to UTF-8 or to UTF-16 */
						
						/* mapping... */
						
						nOutptLen = 0;
						
						for (var nMapIdx:int = 0; nMapIdx < nInptLen; nMapIdx++) {
							if (nMapIdx === nCharStart) { nStartIdx = nOutptLen; }
							nOutptLen += fGetOutptChrSize(vSource.charCodeAt(nMapIdx));
							if (nMapIdx === nCharEnd) { nEndIdx = nOutptLen; }
						}
						
						aWhole = new fTAView(nOutptLen);
						
						/* transcription... */
						
						for (nOutptIdx = 0, nChrIdx = 0; nOutptIdx < nOutptLen; nChrIdx++) {
							nOutptIdx = fPutOutptCode(aWhole, vSource.charCodeAt(nChrIdx), nOutptIdx);
						}
						
						break conversionSwitch;
					
					case 6:
						
						/* DOMString to UTF-32 */
						
						aWhole = new fTAView(nOutptLen);
						
						/* transcription... */
						
						for (nIdx = 0; nIdx < nOutptLen; nIdx++) {
							aWhole[nIdx] = vSource.charCodeAt(nIdx);
						}
						
						break conversionSwitch;
					
					case 7:
						
						aWhole = new fTAView(nOutptLen ? vSource : 0);
						break conversionSwitch;
					
				}
				
				aRaw = nTranscrType > 3 && (nStartIdx > 0 || nEndIdx < aWhole.length - 1) ? aWhole.subarray(nStartIdx, nEndIdx) : aWhole;
				
			}
			
			this.buffer = aWhole.buffer;
			this.bufferView = aWhole;
			this.rawData = aRaw;
		}
		
		/* CONSTRUCTOR'S METHODS */
		
		public static function loadUTF8CharCode(aChars, nIdx):int {
			
			var nLen:int = aChars.length, nPart:int = aChars[nIdx];
			
			return nPart > 251 && nPart < 254 && nIdx + 5 < nLen ?
				/* (nPart - 252 << 30) may be not safe in ECMAScript! So...: */
				/* six bytes */ (nPart - 252) * 1073741824 + (aChars[nIdx + 1] - 128 << 24) + (aChars[nIdx + 2] - 128 << 18) + (aChars[nIdx + 3] - 128 << 12) + (aChars[nIdx + 4] - 128 << 6) + aChars[nIdx + 5] - 128
				: nPart > 247 && nPart < 252 && nIdx + 4 < nLen ?
				/* five bytes */ (nPart - 248 << 24) + (aChars[nIdx + 1] - 128 << 18) + (aChars[nIdx + 2] - 128 << 12) + (aChars[nIdx + 3] - 128 << 6) + aChars[nIdx + 4] - 128
				: nPart > 239 && nPart < 248 && nIdx + 3 < nLen ?
				/* four bytes */(nPart - 240 << 18) + (aChars[nIdx + 1] - 128 << 12) + (aChars[nIdx + 2] - 128 << 6) + aChars[nIdx + 3] - 128
				: nPart > 223 && nPart < 240 && nIdx + 2 < nLen ?
				/* three bytes */ (nPart - 224 << 12) + (aChars[nIdx + 1] - 128 << 6) + aChars[nIdx + 2] - 128
				: nPart > 191 && nPart < 224 && nIdx + 1 < nLen ?
				/* two bytes */ (nPart - 192 << 6) + aChars[nIdx + 1] - 128
				:
				/* one byte */ nPart;
			
		};
		
		public static function putUTF8CharCode(aTarget, nChar, nPutAt):int {
			
			var nIdx:int = nPutAt;
			
			if (nChar < 0x80 /* 128 */) {
				/* one byte */
				aTarget[nIdx++] = nChar;
			} else if (nChar < 0x800 /* 2048 */) {
				/* two bytes */
				aTarget[nIdx++] = 0xc0 /* 192 */ + (nChar >>> 6);
				aTarget[nIdx++] = 0x80 /* 128 */ + (nChar & 0x3f /* 63 */);
			} else if (nChar < 0x10000 /* 65536 */) {
				/* three bytes */
				aTarget[nIdx++] = 0xe0 /* 224 */ + (nChar >>> 12);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 6) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + (nChar & 0x3f /* 63 */);
			} else if (nChar < 0x200000 /* 2097152 */) {
				/* four bytes */
				aTarget[nIdx++] = 0xf0 /* 240 */ + (nChar >>> 18);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 12) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 6) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + (nChar & 0x3f /* 63 */);
			} else if (nChar < 0x4000000 /* 67108864 */) {
				/* five bytes */
				aTarget[nIdx++] = 0xf8 /* 248 */ + (nChar >>> 24);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 18) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 12) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 6) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + (nChar & 0x3f /* 63 */);
			} else /* if (nChar <= 0x7fffffff) */ { /* 2147483647 */
				/* six bytes */
				aTarget[nIdx++] = 0xfc /* 252 */ + /* (nChar >>> 30) may be not safe in ECMAScript! So...: */ (nChar / 1073741824);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 24) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 18) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 12) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + ((nChar >>> 6) & 0x3f /* 63 */);
				aTarget[nIdx++] = 0x80 /* 128 */ + (nChar & 0x3f /* 63 */);
			}
			
			return nIdx;
			
		};
		
		public static function getUTF8CharLength(nChar):int {
			return nChar < 0x80 ? 1 : nChar < 0x800 ? 2 : nChar < 0x10000 ? 3 : nChar < 0x200000 ? 4 : nChar < 0x4000000 ? 5 : 6;
		};
		
		public static function loadUTF16CharCode(aChars, nIdx):int {
			
			/* UTF-16 to DOMString decoding algorithm */
			var nFrstChr:int = aChars[nIdx];
			
			return nFrstChr > 0xD7BF /* 55231 */ && nIdx + 1 < aChars.length ?
				(nFrstChr - 0xD800 /* 55296 */ << 10) + aChars[nIdx + 1] + 0x2400 /* 9216 */
				: nFrstChr;
			
		};
		
		public static function putUTF16CharCode(aTarget, nChar, nPutAt):int {
			
			var nIdx:int = nPutAt;
			
			if (nChar < 0x10000 /* 65536 */) {
				/* one element */
				aTarget[nIdx++] = nChar;
			} else {
				/* two elements */
				aTarget[nIdx++] = 0xD7C0 /* 55232 */ + (nChar >>> 10);
				aTarget[nIdx++] = 0xDC00 /* 56320 */ + (nChar & 0x3FF /* 1023 */);
			}
			
			return nIdx;
			
		};
		
		public static function getUTF16CharLength(nChar):int {
			return nChar < 0x10000 ? 1 : 2;
		};
		
		/* Array of bytes to base64 string decoding */
		
		public static function b64ToUint6(nChr):int {
			
			return nChr > 64 && nChr < 91 ?
				nChr - 65
				: nChr > 96 && nChr < 123 ?
				nChr - 71
				: nChr > 47 && nChr < 58 ?
				nChr + 4
				: nChr === 43 ?
				62
				: nChr === 47 ?
				63
				:
				0;
			
		};
		
		public static function uint6ToB64(nUint6):int {
			
			return nUint6 < 26 ?
				nUint6 + 65
				: nUint6 < 52 ?
				nUint6 + 71
				: nUint6 < 62 ?
				nUint6 - 4
				: nUint6 === 62 ?
				43
				: nUint6 === 63 ?
				47
				:
				65;
			
		};
		
		/* Base64 string to array encoding */
		
		public static function bytesToBase64(aBytes):String {
			
			var sB64Enc:String = "";
			
			for (var nMod3:int, nLen:int = aBytes.length, nUint24:int = 0, nIdx:int = 0; nIdx < nLen; nIdx++) {
				nMod3 = nIdx % 3;
				if (nIdx > 0 && (nIdx * 4 / 3) % 76 === 0) { sB64Enc += "\r\n"; }
				nUint24 |= aBytes[nIdx] << (16 >>> nMod3 & 24);
				if (nMod3 === 2 || aBytes.length - nIdx === 1) {
					sB64Enc += String.fromCharCode(StringView.uint6ToB64(nUint24 >>> 18 & 63), StringView.uint6ToB64(nUint24 >>> 12 & 63), StringView.uint6ToB64(nUint24 >>> 6 & 63), StringView.uint6ToB64(nUint24 & 63));
					nUint24 = 0;
				}
			}
			
			return sB64Enc.replace(/A(?=A$|$)/g, "=");
			
		};
		
		
		public static function base64ToBytes(sBase64, nBlockBytes = undefined):Array {
			
			var
			sB64Enc:String = sBase64.replace(/[^A-Za-z0-9\+\/]/g, ""), nInLen:int = sB64Enc.length,
				nOutLen:int = nBlockBytes ? Math.ceil((nInLen * 3 + 1 >>> 2) / nBlockBytes) * nBlockBytes : nInLen * 3 + 1 >>> 2,
				aBytes:Array = new Uint8Array(nOutLen);
			
			for (var nMod3:int, nMod4:int, nUint24:int = 0, nOutIdx:int = 0, nInIdx:int = 0; nInIdx < nInLen; nInIdx++) {
				nMod4 = nInIdx & 3;
				nUint24 |= StringView.b64ToUint6(sB64Enc.charCodeAt(nInIdx)) << 18 - 6 * nMod4;
				if (nMod4 === 3 || nInLen - nInIdx === 1) {
					for (nMod3 = 0; nMod3 < 3 && nOutIdx < nOutLen; nMod3++, nOutIdx++) {
						aBytes[nOutIdx] = nUint24 >>> (16 >>> nMod3 & 24) & 255;
					}
					nUint24 = 0;
				}
			}
			
			return aBytes;
			
		};
		
		public static function makeFromBase64(sB64Inpt, sEncoding, nByteOffset, nLength):StringView {
			
			return new StringView(sEncoding === "UTF-16" || sEncoding === "UTF-32" ? StringView.base64ToBytes(sB64Inpt, sEncoding === "UTF-16" ? 2 : 4).buffer : StringView.base64ToBytes(sB64Inpt), sEncoding, nByteOffset, nLength);
			
		};
		
		/* DEFAULT VALUES */
		
		public var encoding:String = "UTF-8"; /* Default encoding... */
		
		/* INSTANCES' METHODS */
		
		public function makeIndex(nChrLength = undefined, nStartFrom = undefined):int {
			
			var
			
			aTarget:Array = this.rawData, nChrEnd:int, nRawLength:int = aTarget.length,
				nStartIdx:int = nStartFrom || 0, nIdxEnd:int = nStartIdx, nStopAtChr:int = isNaN(nChrLength) ? Infinity : nChrLength;
			
			if (nChrLength + 1 > aTarget.length) { throw new RangeError("public function makeIndex - The offset can\'t be major than the length of the array - 1."); }
			
			switch (this.encoding) {
				
				case "UTF-8":
					
					var nPart:int;
					
					for (nChrEnd = 0; nIdxEnd < nRawLength && nChrEnd < nStopAtChr; nChrEnd++) {
						nPart = aTarget[nIdxEnd];
						nIdxEnd += nPart > 251 && nPart < 254 && nIdxEnd + 5 < nRawLength ? 6
							: nPart > 247 && nPart < 252 && nIdxEnd + 4 < nRawLength ? 5
							: nPart > 239 && nPart < 248 && nIdxEnd + 3 < nRawLength ? 4
							: nPart > 223 && nPart < 240 && nIdxEnd + 2 < nRawLength ? 3
							: nPart > 191 && nPart < 224 && nIdxEnd + 1 < nRawLength ? 2
							: 1;
					}
					
					break;
				
				case "UTF-16":
					
					for (nChrEnd = nStartIdx; nIdxEnd < nRawLength && nChrEnd < nStopAtChr; nChrEnd++) {
						nIdxEnd += aTarget[nIdxEnd] > 0xD7BF /* 55231 */ && nIdxEnd + 1 < aTarget.length ? 2 : 1;
					}
					
					break;
				
				default:
					
					nIdxEnd = nChrEnd = isFinite(nChrLength) ? nChrLength : nRawLength - 1;
					
			}
			
			if (nChrLength) { return nIdxEnd; }
			
			return nChrEnd;
			
		};
		
		public function toBase64(bWholeBuffer):String {
			
			return StringView.bytesToBase64(
				bWholeBuffer ?
				(
					this.bufferView.constructor === Uint8Array ?
					this.bufferView
					:
					new Uint8Array(this.buffer)
				)
				: this.rawData.constructor === Uint8Array ?
				this.rawData
				:
				new Uint8Array(this.buffer, this.rawData.byteOffset, this.rawData.length << (this.rawData.constructor === Uint16Array ? 1 : 2))
			);
			
		};
		
		public function subview(nCharOffset /* optional */, nCharLength /* optional */):StringView {
			
			var
			
			nChrLen:int, nCharStart:int, nStrLen:int, bVariableLen:Boolean = this.encoding === "UTF-8" || this.encoding === "UTF-16",
				nStartOffset:int = nCharOffset, nStringLength:int, nRawLen:int = this.rawData.length;
			
			if (nRawLen === 0) {
				return new StringView(this.buffer, this.encoding);
			}
			
			nStringLength = bVariableLen ? this.makeIndex() : nRawLen;
			nCharStart = nCharOffset ? Math.max((nStringLength + nCharOffset) % nStringLength, 0) : 0;
			nStrLen = Number_isInteger(nCharLength) ? Math.max(nCharLength, 0) + nCharStart > nStringLength ? nStringLength - nCharStart : nCharLength : nStringLength;
			
			if (nCharStart === 0 && nStrLen === nStringLength) { return this; }
			
			if (bVariableLen) {
				nStartOffset = this.makeIndex(nCharStart);
				nChrLen = this.makeIndex(nStrLen, nStartOffset) - nStartOffset;
			} else {
				nStartOffset = nCharStart;
				nChrLen = nStrLen - nCharStart;
			}
			
			if (this.encoding === "UTF-16") {
				nStartOffset <<= 1;
			} else if (this.encoding === "UTF-32") {
				nStartOffset <<= 2;
			}
			
			return new StringView(this.buffer, this.encoding, nStartOffset, nChrLen);
			
		}
		
		public function forEachChar(fCallback, oThat, nChrOffset, nChrLen):void {
			
			var aSource:Array = this.rawData, nRawEnd:int, nRawIdx:int;
			
			if (this.encoding === "UTF-8" || this.encoding === "UTF-16") {
				
				var fGetInptChrSize:Function, fGetInptChrCode:Function;
				
				if (this.encoding === "UTF-8") {
					fGetInptChrSize = StringView.getUTF8CharLength;
					fGetInptChrCode = StringView.loadUTF8CharCode;
				} else if (this.encoding === "UTF-16") {
					fGetInptChrSize = StringView.getUTF16CharLength;
					fGetInptChrCode = StringView.loadUTF16CharCode;
				}
				
				nRawIdx = isFinite(nChrOffset) ? this.makeIndex(nChrOffset) : 0;
				nRawEnd = isFinite(nChrLen) ? this.makeIndex(nChrLen, nRawIdx) : aSource.length;
				
				for (var nChrCode:int, nChrIdx:int = 0; nRawIdx < nRawEnd; nChrIdx++) {
					nChrCode = fGetInptChrCode(aSource, nRawIdx);
					fCallback.call(oThat || null, nChrCode, nChrIdx, nRawIdx, aSource);
					nRawIdx += fGetInptChrSize(nChrCode);
				}
				
			} else {
				
				nRawIdx = isFinite(nChrOffset) ? nChrOffset : 0;
				nRawEnd = isFinite(nChrLen) ? nChrLen + nRawIdx : aSource.length;
				
				for (nRawIdx; nRawIdx < nRawEnd; nRawIdx++) {
					fCallback.call(oThat || null, aSource[nRawIdx], nRawIdx, nRawIdx, aSource);
				}
				
			}
			
		};
		
		public function toString():String {
			
			if (this.encoding !== "UTF-8" && this.encoding !== "UTF-16") {
				/* ASCII, UTF-32 or BinaryString to DOMString */
				return String.fromCharCode.apply(null, this.rawData);
			}
			
			var fGetCode:Function, fGetIncr:Function, sView:String = "";
			
			if (this.encoding === "UTF-8") {
				fGetIncr = StringView.getUTF8CharLength;
				fGetCode = StringView.loadUTF8CharCode;
			} else if (this.encoding === "UTF-16") {
				fGetIncr = StringView.getUTF16CharLength;
				fGetCode = StringView.loadUTF16CharCode;
			}
			
			for (var nChr:int, nLen:int = this.rawData.length, nIdx:int = 0; nIdx < nLen; nIdx += fGetIncr(nChr)) {
				nChr = fGetCode(this.rawData, nIdx);
				sView += String.fromCharCode(nChr);
			}
			
			return sView;
			
		}
	}
}

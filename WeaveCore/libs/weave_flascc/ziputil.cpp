/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * ***** END LICENSE BLOCK ***** */

#include "miniz.h"
#include <stdlib.h>
#include "AS3/AS3.h"
#include "tracef.h"

// https://github.com/adobe-flash/crossbridge/blob/master/posix/

// https://obtw.wordpress.com/2013/04/03/making-bytearray-faster/

// http://bruce-lab.blogspot.com/2012/12/migrating-from-alchemy-to-flascc.html
// http://blog.debit.nl/2009/03/using-bytearrays-in-actionscript-and-alchemy/

// FlasCC AS3.h API Reference:  http://www.adobe.com/devnet-docs/flascc/docs/capidocs/as3.html

// http://www.adobe.com/devnet-docs/flascc/docs/apidocs/com/adobe/flascc/CModule.html
// http://www.adobe.com/devnet-docs/flascc/docs/Reference.html#section_swig
// http://stackoverflow.com/questions/14326828/how-to-pass-bytearray-to-c-code-using-flascc
// http://forums.adobe.com/message/4969630

// sample miniz read: https://github.com/drhelius/Gearboy/blob/master/src/Cartridge.cpp#L146
// sample miniz write: https://github.com/r-lyeh/moon9/blob/master/src/moon9/io/pak/pak.cpp#L140

/**
 * Extracts files from an archive.
 * @param archive The bytes of a ZIP archive.
 * @param filterFilePathsToReadAsObject A function like function(path:String):Boolean which returns true if the file should be read as an AMF object.
 * @return An object mapping each file path contained in the archive to a ByteArray (or a decoded AMF object).
 */
void readZip() __attribute__((used,
	annotate("as3sig:public function readZip(byteArray:ByteArray, filterFilePathsToReadAsObject:Function = null):Object"),
	annotate("as3package:weave.flascc"),
	annotate("as3import:flash.utils.ByteArray")));
void readZip()
{
	inline_as3(
		"var zip:uint = openZip(byteArray);"
		"if (!zip) return null;"
		"var out:Object = {};"
		"for each (var filePath:String in listFiles(zip))"
		"    if (filterFilePathsToReadAsObject != null && filterFilePathsToReadAsObject(filePath))"
		"        out[filePath] = readObject(zip, filePath);"
		"    else"
		"        out[filePath] = readFile(zip, filePath);"
		"closeZip(zip);"
		"return out;"
	);
}

/**
 * Returns a pointer to an mz_zip_archive structure, or 0 if byteArray was not a valid zip archive.
 */
void openZip() __attribute__((used,
	annotate("as3sig:internal function openZip(byteArray:ByteArray):uint"),
	annotate("as3package:weave.flascc"),
	annotate("as3import:flash.utils.ByteArray")));
void openZip()
{
	void *byteArray_ptr;
	size_t byteArray_len;

	inline_nonreentrant_as3("%0 = byteArray.length;" : "=r"(byteArray_len));
	byteArray_ptr = malloc(byteArray_len);

	inline_as3(
		"ram_init.position = %0;"
		"ram_init.writeBytes(byteArray);"
			: : "r"(byteArray_ptr)
	);

	mz_zip_archive *zip_archive = (mz_zip_archive*)malloc(sizeof(zip_archive));
	memset(zip_archive, 0, sizeof(mz_zip_archive));

	mz_bool status = mz_zip_reader_init_mem(zip_archive, byteArray_ptr, byteArray_len, 0);
	if (!status)
	{
		free(zip_archive);
		free(byteArray_ptr);
		//tracef("Invalid archive. byteArray.length=%u", byteArray_len);
		AS3_Return(0);
	}

	AS3_Return(zip_archive);
}

/**
 * Gets a list of files in a zip
 */
void listFiles() __attribute__((used,
	annotate("as3sig:internal function listFiles(_zip_archive:uint):Array"),
	annotate("as3package:weave.flascc")));
void listFiles()
{
	mz_zip_archive *zip_archive;
	AS3_GetScalarFromVar(zip_archive, _zip_archive);

	char str[MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE];
	AS3_DeclareVar(filePath, String);
	inline_nonreentrant_as3("var result:Array = [];");
	int n = mz_zip_reader_get_num_files(zip_archive);
	for (unsigned int i = 0; i < n; i++)
	{
		AS3_CopyCStringToVar(filePath, str, mz_zip_reader_get_filename(zip_archive, i, str, MZ_ZIP_MAX_ARCHIVE_FILENAME_SIZE) - 1);
		inline_nonreentrant_as3("result.push(filePath);");
	}

	AS3_ReturnAS3Var(result);
}

void readFile() __attribute__((used,
	annotate("as3sig:internal function readFile(_zip_archive:uint, _fileName:String):ByteArray"),
	annotate("as3package:weave.flascc"),
	annotate("as3import:flash.utils.ByteArray")));
void readFile()
{
	mz_zip_archive *zip_archive;
	AS3_GetScalarFromVar(zip_archive, _zip_archive);
	char *fileName;
	AS3_MallocString(fileName, _fileName);

	void* uncomp_file;
	size_t uncomp_size;

	uncomp_file = mz_zip_reader_extract_file_to_heap(zip_archive, fileName, &uncomp_size, MZ_ZIP_FLAG_CASE_SENSITIVE);
	inline_as3(
		"var byteArray:ByteArray = new ByteArray();"
		"ram_init.position = %0;"
		"ram_init.readBytes(byteArray, 0, %1);"
			 : : "r"(uncomp_file), "r"(uncomp_size)
	);
	free(uncomp_file);
	free(fileName);
	AS3_ReturnAS3Var(byteArray);
}

void readObject() __attribute__((used,
		annotate("as3sig:internal function readObject(_zip_archive:uint, _fileName:String):Object"),
		annotate("as3package:weave.flascc")));
void readObject()
{
	mz_zip_archive *zip_archive;
	AS3_GetScalarFromVar(zip_archive, _zip_archive);
	char *fileName;
	AS3_MallocString(fileName, _fileName);

	void* uncomp_file;
	size_t uncomp_size;

	uncomp_file = mz_zip_reader_extract_file_to_heap(zip_archive, fileName, &uncomp_size, MZ_ZIP_FLAG_CASE_SENSITIVE);
	AS3_DeclareVar(result, Object);
	inline_as3(
		"try {"
		"    ram_init.position = %0;"
		"    result = ram_init.readObject();"
		"} catch (e:Error) { }"
			: : "r"(uncomp_file)
	);
	free(uncomp_file);
	free(fileName);
	AS3_ReturnAS3Var(result);
}

void closeZip() __attribute__((used,
	annotate("as3sig:internal function closeZip(_zip_archive:uint):Boolean"),
	annotate("as3package:weave.flascc")));
void closeZip()
{
	mz_zip_archive *zip_archive;
	AS3_GetScalarFromVar(zip_archive, _zip_archive);

	free(zip_archive->m_pState->m_pMem);
	mz_bool status = mz_zip_reader_end(zip_archive);
	free(zip_archive);
	AS3_Return(status);
}

/**
 * Creates a ZIP archive.
 * @param files An object mapping each file path contained in the archive to a ByteArray (or an Object to be encoded as AMF).
 * @return The bytes of a ZIP archive.
 */
void writeZip() __attribute__((used,
		annotate("as3sig:public function writeZip(files:Object):ByteArray"),
		annotate("as3package:weave.flascc"),
		annotate("as3import:flash.utils.ByteArray")));
void writeZip()
{
	// initialize byteArray to null
	AS3_DeclareVar(byteArray, ByteArray);

	// initialize archive writer
	mz_zip_archive zip_archive;
	memset(&zip_archive, 0, sizeof(mz_zip_archive));
	if (!mz_zip_writer_init_heap(&zip_archive, 0, 128 * 1024))
	{
		tracef("mz_zip_writer_init_heap() failed!");
		AS3_ReturnAS3Var(byteArray);
	}

	// write files to archive
	inline_as3(
		"for (var fileName:String in files)"
		"    if (!writeFile(%0, fileName, files[fileName]))"
		"        return false;"
		: : "r"(&zip_archive)
	);

	// finalize archive
	void *byteArray_ptr;
	size_t byteArray_len;
	mz_bool status1 = mz_zip_writer_finalize_heap_archive(&zip_archive, &byteArray_ptr, &byteArray_len);
	mz_bool status2 = mz_zip_writer_end(&zip_archive);

	// return archive as ByteArray
	if (!status1 || !status2)
	{
		if (!status1)
			tracef("mz_zip_writer_finalize_heap_archive() failed! zip=%u, ptr=%u, len=%u", &zip_archive, byteArray_ptr, byteArray_len);
		if (!status2)
			tracef("mz_zip_writer_end() failed! zip=%u", &zip_archive);
		AS3_ReturnAS3Var(byteArray);
	}
	inline_as3(
		"byteArray = new ByteArray();"
		"ram_init.position = %0;"
		"ram_init.readBytes(byteArray, 0, %1);"
			: : "r"(byteArray_ptr), "r"(byteArray_len)
	);
	AS3_ReturnAS3Var(byteArray);
}

void writeFile() __attribute__((used,
		annotate("as3sig:internal function writeFile(_zip_archive:uint, _fileName:String, _fileContent:Object):Boolean"),
		annotate("as3package:weave.flascc"),
		annotate("as3import:flash.utils.ByteArray")));
void writeFile()
{
	mz_zip_archive *zip_archive;
	AS3_GetScalarFromVar(zip_archive, _zip_archive);

	// copy _fileContent from AS3 to C
	size_t contentLength;
	inline_nonreentrant_as3(
		"var byteArray:ByteArray = _fileContent as ByteArray;"
		"if (!byteArray)"
		"{"
		"    byteArray = new ByteArray();"
		"    byteArray.writeObject(_fileContent);"
		"}"
		"%0 = byteArray.length;" : "=r"(contentLength)
	);
	void *fileContent = malloc(contentLength);
	inline_as3(
		"ram_init.position = %0;"
		"ram_init.writeBytes(byteArray);"
			: : "r"(fileContent)
	);

	// write the file
	char *fileName;
	AS3_MallocString(fileName, _fileName);
	mz_bool status = mz_zip_writer_add_mem(zip_archive, fileName, fileContent, contentLength, MZ_DEFAULT_COMPRESSION);
	free(fileContent);
	free(fileName);
	if (!status)
		tracef("Failed to add file to zip: %s (%u bytes)", fileName, contentLength);
	AS3_Return(status);
}


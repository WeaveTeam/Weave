weave.GoogleDrive = {};

var authWin = null;
var activeFileID;

var openedFileUrl;
var checkAuthCallCount = 0;
var expires_in_millisecs;


var CLIENT_ID = '377791640380-2ndttp4bqp4nos7u2lu145ntdg2iv90c.apps.googleusercontent.com';
var SCOPES = [
              'https://www.googleapis.com/auth/drive',
              'https://www.googleapis.com/auth/drive.file',
              'https://www.googleapis.com/auth/userinfo.email',
              'https://www.googleapis.com/auth/userinfo.profile',
              ];
var boundary = '-------314159265358979323846';
var delimiter = "\r\n--" + boundary + "\r\n";
var close_delim = "\r\n--" + boundary + "--";

//Step 1: get authorization to use private data
weave.GoogleDrive.init = function( ) {
	console.log("init");	
	gapi.auth.authorize(  {'client_id': CLIENT_ID, 'scope': SCOPES.join(' '), 'immediate': false}, handleAuthResult);
};

// automated authorization based on token expiry time
function checkAuth() {
	checkAuthCallCount++;
	console.log('checkAuth: ' + checkAuthCallCount);
    gapi.auth.authorize({'client_id': CLIENT_ID, 'scope': SCOPES.join(' '), 'immediate': true}, handleAuthResult);
}

//Step 2: Load the Google drive API
/**
 * Called when authorization server replies. *
 * @param {Object} authResult Authorization result.
 */
function handleAuthResult(authResult) {
	if (authResult && !authResult.error) {			
		expires_in_millisecs = authResult.expires_in * 1000;
		console.log(expires_in_millisecs);
		gapi.client.load('drive', 'v2', handleClientLoad);
	} 
	else{
		weave.path().getValue('import "weave.services.GoogleDrive";\
		GoogleDrive.busy = false;');
	}
};

function handleClientLoad() {
	// call for authorization 1 minute before token expiry time
    window.setTimeout(checkAuth,expires_in_millisecs - 60000);
    readStateObject();
}

function readStateObject(  ) {
	weave.path().getValue('import "weave.services.GoogleDrive";\
			import "weave.Weave";\
			GoogleDrive.isAuthorized = true;\
			GoogleDrive.busy = false;\
			Weave.properties.version.triggerCallbacks();');
	var paramObj  = 	getParams();
	var stateJson = paramObj['state'];
	var jsonObj = JSON.parse(stateJson);
	if(jsonObj && jsonObj.action == 'open'){
		activeFileID = jsonObj.ids[0];
		loadWeaveFile(activeFileID);
	}
	else {
		weave.GoogleDrive.insertWeaveFile();
	}		
};
function getParams() {
	var params = {};
	var queryString = window.location.search;
	if (queryString) {
		var paramStrs = queryString.slice(1).split("&");
		for (var i = 0; i < paramStrs.length; i++) {
			var paramStr = paramStrs[i].split("=");
			params[paramStr[0]] = unescape(paramStr[1]);
		}
	}			 
	return params;
};

function loadWeaveFile(fileId) {
	// Step 3: Assemble the API request
	var request = gapi.client.drive.files.get({  'fileId': fileId  });
	// Step 4 (Final): Execute the API request
	request.execute(function(resp) {
		console.log('loadWeaveFile:');
		console.log(resp);
		openedFileUrl = resp.downloadUrl;
		var accessToken = gapi.auth.getToken().access_token;
		var urlObject = {"url": openedFileUrl, "requestHeaders": {"Authorization": "Bearer "  + accessToken}};
		weave.loadFile(urlObject);
	});
};

function generateFileMetadata(isNewFile){
	var rawBase64 = weave.evaluateExpression(null, 'getBase64Image(Application.application)', null, ['weave.utils.BitmapUtils', 'mx.core.Application']);
	var thumbnailData = rawBase64.replace(/\+/g, '-').replace(/\//g, '_');
	var indexableTextArray = getIndexableText();
	var indexableText = new String(indexableTextArray.join());
	console.log(indexableText);
	var metadata;
	if(isNewFile){
		metadata = {
				'title': generateWeaveFileName(),
				'mimeType': 'application/octet-stream',
				'thumbnail': {
				    'image': thumbnailData,
				    'mimeType': 'image/png'
				  }	,
				  "indexableText": {
					    "text": indexableText.
				  }
		};
	}
	else{
		metadata = {
				'thumbnail': {
				    'image': thumbnailData,
				    'mimeType': 'image/png'
				  }	,
				  "indexableText": {
					    "text": indexableText
				  }
		};
	}
	
	return metadata;
}

/**
 * Called from AS3, after user gives name for the new file.
 * @param {base64EncodedData} base64EncodedData Binary-String object to insert to drive.
 * @param {fileName} File name given by the user.
 */
weave.GoogleDrive.insertWeaveFile = function() {	
	//console.log('inserting weave file to google drive');
	var request = getDriveRequest(generateWeaveArchive(),'POST',generateFileMetadata(true));		    
	request.execute(saveFileID);
};

/**
 * Called from AS3, for auto saving.
 * @param {base64EncodedData} base64EncodedData Binary-String object to insert to drive.
 */
weave.GoogleDrive.updateWeaveFile = function(){  
	var request = getDriveRequest(generateWeaveArchive(),'PUT',generateFileMetadata(false),activeFileID);
	request.execute(saveFileID);
};

function saveFileID(file){
	activeFileID = file.id;
};

function generateWeaveArchive(){
	return weave.path().getValue('import "weave.compiler.StandardLib";\
			import "weave.core.WeaveArchive";\
			return StandardLib.btoa(WeaveArchive.createWeaveFileContent());');
};
function generateWeaveFileName(){
	return weave.path().getValue('import "weave.Weave";\
			return Weave.fileName;');
}

function getDriveRequest(base64Data,requestMethod,fileMetadata,fileID){
	var path =  '/upload/drive/v2/files';
	var params = {'uploadType': 'multipart'};
	if(fileID && requestMethod == 'PUT'){
		path = path +'/' + fileID;
		params = {'uploadType': 'multipart', 'alt': 'json'};
	}

	var multipartRequestBody = 	delimiter +  'Content-Type: application/json\r\n\r\n' +   
								JSON.stringify(fileMetadata) +  
								delimiter +  'Content-Type: ' + 'application/octet-stream' + '\r\n' + 
								'Content-Transfer-Encoding: base64\r\n' +   '\r\n' +  base64Data + close_delim;
	var request = gapi.client.request({
		'path': path,
		'method': requestMethod,
		'params': params,
		'headers': {
			'Content-Type': 'multipart/mixed; boundary="' + boundary + '"'
		},
		'body': multipartRequestBody});
	return request;
}

function getIndexableText() {
	return weave.path().getValue("\
		import 'weave.ui.DraggablePanel';\
		import 'weave.api.data.IAttributeColumn';\
		import 'weave.utils.VectorUtils';\
		var sm = WeaveAPI.SessionManager;\
		var panels = sm.getLinkableDescendants(WeaveAPI.globalHashMap, DraggablePanel);\
		var columns = sm.getLinkableDescendants(WeaveAPI.globalHashMap, IAttributeColumn);\
		var panelTitles = panels.map(function(panel){ return panel.title; });\
		var columnTitles = columns.map(function(column){ return column.getMetadata('title'); });\
		return VectorUtils.union(panelTitles, columnTitles);\
	");
}

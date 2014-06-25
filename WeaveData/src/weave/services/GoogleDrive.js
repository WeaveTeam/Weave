weave.GoogleDrive = {};

var authWin = null;
var activeFileID;

var openedFileTitle;
var openedFileUrl;


var CLIENT_ID = '377791640380-2ndttp4bqp4nos7u2lu145ntdg2iv90c.apps.googleusercontent.com';
var SCOPES = [
              'https://www.googleapis.com/auth/drive',
              'https://www.googleapis.com/auth/drive.file',
              'https://www.googleapis.com/auth/userinfo.email',
              'https://www.googleapis.com/auth/userinfo.profile',
              ];
const boundary = '-------314159265358979323846';
const delimiter = "\r\n--" + boundary + "\r\n";
const close_delim = "\r\n--" + boundary + "--";

weave.GoogleDrive.init = function( ) {
	console.log("init");	
	gapi.auth.authorize(  {'client_id': CLIENT_ID, 'scope': SCOPES.join(' '), 'immediate': false}, handleAuthResult);
};




/**
 * Called when authorization server replies.
 *
 * @param {Object} authResult Authorization result.
 */
function handleAuthResult(authResult) {

	if (authResult) {
		console.log('Authorization Result:');
		console.log(authResult);
		gapi.client.load('drive', 'v2', readStateObject);
	} 
	else{
		weave.path().getValue('import "weave.services.GoogleDrive";\
		GoogleDrive.busy = false;');
	}
};



function readStateObject(  ) {
	weave.path().getValue('import "weave.services.GoogleDrive";\
			import "weave.Weave";\
			GoogleDrive.isAuthorized = true;\
			GoogleDrive.busy = false;\
			Weave.properties.version.triggerCallbacks();');
	var paramObj  = 	getParams();
	var stateJson = paramObj['state'];
	console.log('Reading State Object: ');
	var jsonObj = JSON.parse(stateJson);
	if(jsonObj && jsonObj.action == 'open'){
		activeFileID = jsonObj.ids[0];
		loadWeaveFile(activeFileID);
	}
	else {
		weave.GoogleDrive.insertWeaveFile();
	}		
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
function getParams() {
	var params = {};
	var queryString = window.location.search;
	if (queryString) {
		console.log('queryString: ' + queryString);
		// split up the query string and store in an object
		var paramStrs = queryString.slice(1).split("&");
		for (var i = 0; i < paramStrs.length; i++) {
			var paramStr = paramStrs[i].split("=");
			params[paramStr[0]] = unescape(paramStr[1]);
		}
	}			 
	console.log(params);
	return params;
};

function loadWeaveFile(fileId) {
	console.log('fileId: ' + fileId);
	var request = gapi.client.drive.files.get({  'fileId': fileId  });
	request.execute(function(resp) {
		openedFileTitle =  resp.title;
		openedFileUrl = resp.downloadUrl;
		console.log('Title: ' + resp.title);
		var accessToken = gapi.auth.getToken().access_token;
		var urlObject = {"url": resp.downloadUrl, "requestHeaders": {"Authorization": "Bearer "  + accessToken}};
		weave.loadFile(urlObject);
	});
};



/**
 * Called from AS3, after user gives name for the new file.
 *
 * @param {base64EncodedData} base64EncodedData Binary-String object to insert to drive.
 * @param {fileName} File name given by the user.
 */
weave.GoogleDrive.insertWeaveFile = function() {	
	console.log('inserting weave file to google drive');
	var metadata = {
			'title': generateWeaveFileName(),
			'mimeType': 'application/octet-stream'
	};
	
	var request = getDriveRequest(generateWeaveArchive(),'POST',metadata);		    
	request.execute(saveFileID);
};

function saveFileID(file){
	activeFileID = file.id;
	console.log(activeFileID);
	console.log(file);
};


/**
 * Called from AS3, for auto saving.
 *
 * @param {base64EncodedData} base64EncodedData Binary-String object to insert to drive.
 */
weave.GoogleDrive.updateWeaveFile = function(){   
	var request = gapi.client.drive.files.get({'fileId': activeFileID});
	request.execute(function(resp) {
		console.log('file Meta data: ');
		console.log(resp);
		updateFile(activeFileID,resp,generateWeaveArchive(),changesSaved);
	});
};

function changesSaved(){
	console.log('Update Successfull');
};

function updateFile(fileId, fileMetadata, fileData, callback) {

	var request = getDriveRequest(fileData,'PUT',fileMetadata,fileId);
	request.execute(saveFileID);
};





function getDriveRequest(base64Data,requestMethod,fileMetadata,fileID){
	var path =  '/upload/drive/v2/files';
	var params = {'uploadType': 'multipart'};
	if(fileID && requestMethod == 'PUT'){
		//requestMethod = 'POST';
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
};

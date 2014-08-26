weave.Oauth = {};

var authWin = null;


weave.Oauth.openAuth = function( url, width, height ) {
//	if(document.domain != "")
//		document.domain = window.location.hostname.replace( "www.", "" );
	/*
	 * popup blockers cause window.open to return null. Obviously.
	 * The window is opened once the user allows it, at which point we've
	 * lost the reference and this code stops working
	 */
	authWin = window.open( url, "oauthWin", "width=" + width + ", height=" + height );
	watchWindow();
};

var timeout;
function watchWindow() {
	
	/*
	 * there's no reference to popup window, an error has occurred.	 * 
	 * Known instances of this issue occurring are when a popup
	 * blocker prevents/delays the auth window from opening
	 */
	if( !authWin ) {
		weave.windowError();
		return;
	}	
	if( authWin &&	authWin.closed ) {
		//notify weave.swf that window has closed
		weave.windowClosed();
		authWin = null;
		return;
	}	
	try {		
		var href = authWin.location.href;		
		if( href != "about:blank" &&
			document.domain != "" &&
			href.indexOf( document.domain ) != -1 ) {							
			//redirect has occurred
			weave.setResponse( href );
			authWin.close();
			authWin = null;			
			return;
		}		
	}catch( err ){}
	
	setTimeout( watchWindow, 250 );
};
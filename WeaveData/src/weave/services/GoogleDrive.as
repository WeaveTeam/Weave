package weave.services
{
	
	
	
	
	
	

	public class GoogleDrive
	{
		[Embed(source="GoogleDrive.js", mimeType="application/octet-stream")]
		public static const GoogleDrive_js:Class;
		
		public static function openedFromDrive(flashVars:Object):Boolean{
			try{
				if(flashVars.state){
					var stateObj:Object = JavaScript.exec({obj:flashVars.state},"return JSON.parse(obj);")
					return stateObj.action && stateObj.userId;
				}
				
			}
			catch(e:Error){
			
			}
			
			return false;
		}
		
		
		
		public static var isAuthorized:Boolean ;
		public static var busy:Boolean;
		/*public static function authorize(fileId):void{
			if(!busy && !isAuthorized){
				busy = true;
				var googleService:GoogleServlet = new GoogleServlet("/GoogleServices/DriveService");
				googleService.getFileMetaData(fileId);
			}
			
		}
		
		public static function saveToDrive():void{
			if(isAuthorized){
				//JavaScript.exec('this.GoogleDrive.updateWeaveFile()');
			}
		}*/
		
		//javascript version
		public static function authorize():void{
			if(!busy && !isAuthorized){
				busy = true;
				WeaveAPI.initializeJavaScript(GoogleDrive_js);
				JavaScript.registerMethod( "windowClosed", windowClosed );
				JavaScript.registerMethod( "windowError", windowError );
				JavaScript.registerMethod( "setResponse", setResponse );
				
				JavaScript.exec('this.GoogleDrive.init()');
			}
			
		}
		
		public static function saveToDrive():void{
			if(isAuthorized){
				JavaScript.exec('this.GoogleDrive.updateWeaveFile()');
			}
		}
		
		
		
		
		public static function openOauthWindow(queryStr:String, width:Number,height:Number):void{
					
			JavaScript.exec({"args": [queryStr, width, height]},
			"this.GoogleDrive.openAuth.apply(this, args);"
			);
			
		}
		
		
		private static function setResponse( url:String ):void
		{
			var params : Object = extractQueryParams( url );
			//trace(params);
		}
		
		
		private static function windowClosed():void
		{
			trace("window closed");
		}
		
		
		private static function windowError():void
		{
			trace("window error");
		}
		
		protected static function extractQueryParams( url:String ):Object
		{
			var delimiter:String = ( url.indexOf( "?" ) > 0 ) ? "?" : "#";
			var queryParamsString:String = url.split( delimiter )[ 1 ];
			var queryParamsArray:Array = queryParamsString.split( "&" );
			var queryParams:Object = new Object();
			
			for each( var queryParam:String in queryParamsArray )
			{
				var keyValue:Array = queryParam.split( "=" );
				queryParams[ keyValue[ 0 ] ] = keyValue[ 1 ];	
			}
			
			return queryParams;
		}
	
		
		
		
	}
}
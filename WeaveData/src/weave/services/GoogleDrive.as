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
		public static function authorize(fileId):void{
			if(!busy && !isAuthorized){
				busy = true;
				var googleService:GoogleServlet = new GoogleServlet("/GoogleServices/DriveService");
				googleService.getFileMetaData(fileId);
				//WeaveAPI.initializeJavaScript(GoogleDrive_js);
				//JavaScript.exec('this.GoogleDrive.init()');
			}
			
		}
		
		public static function saveToDrive():void{
			if(isAuthorized){
				//JavaScript.exec('this.GoogleDrive.updateWeaveFile()');
			}
		}
		
		//javascript version
		/*public static function authorize():void{
			if(!busy && !isAuthorized){
				busy = true;
				WeaveAPI.initializeJavaScript(GoogleDrive_js);
				JavaScript.exec('this.GoogleDrive.init()');
			}
			
		}
		
		public static function saveToDrive():void{
			if(isAuthorized){
				JavaScript.exec('this.GoogleDrive.updateWeaveFile()');
			}
		}*/
	
		
		
		
	}
}
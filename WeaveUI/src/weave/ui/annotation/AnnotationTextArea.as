package weave.ui.annotation
{
	import mx.controls.TextArea;
	import mx.utils.ObjectUtil;
	
	import weave.Weave;
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.core.SessionManager;
	import weave.core.weave_internal;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.primitives.AttributeHierarchy;
	import weave.utils.ColumnUtils;
	
	use namespace weave_internal;
	
	public class AnnotationTextArea extends TextArea
	{
		private var annotationText:String;
		
		public function AnnotationTextArea()
		{
			super();
			
		}
		
		
		//Toggle between editable and uneditable, updating the variables whenever editing are complete
		override public function set editable(value:Boolean) : void
		{
			super.editable = value;
			
			//While being edited, update the htmlText
			if(value==true){				
				htmlText = annotationText;
			}
			//Once finished editing, update the value of annotationText and get the values of the variables
			else{
				annotationText = htmlText;
				resolveVariables();
				trace("turned off editing");
			}
				//Event listener for every time the session state is changed so the values will be updated
				getCallbackCollection(Weave.root).addGroupedCallback(this,updateVariables);
			
		}
		
		//When the session state changes, resolve the values of all variables
		private function updateVariables(): void
		{
			trace("updating when session state changes");
			if(!editable){
				htmlText = annotationText;
				resolveVariables();
			}
			
		}
		
		//		override public function set htmlText(value:String):void
		//		{
		//			super.htmlText = value;
		//			annotationText = htmlText;
		//		}
		
		//Convert the variable name contained within {} to it's actual value
		private function resolveVariables():void
		{
			if(editable)
				return;
			trace("html text is " + this.htmlText);
			//Find first occurence of { }
			var startIndex:int = this.htmlText.search("{");
			var endIndex:int = htmlText.search("}") + 1;
			//Get the global session manager in order to get anything from the session state
			var sessionManager:SessionManager = (WeaveAPI.SessionManager as SessionManager);
			
			//Iterate through each {variable} in the user entered text
			//startIndex is -1 when it reaches the end of the string
			while(startIndex!=-1){

				//Get the start index of the next variable
				startIndex = this.htmlText.search("{");
				//If startIndex is -1 we don't want to continue
				if(startIndex == -1) break;
				endIndex = htmlText.search("}") + 1;
				//Contains each variable the user entered with {}
				var variableTag:String = this.htmlText.substring(startIndex, endIndex);
				
				var strippedVariableTag:String = variableTag.replace(/<[^>]*>/g, "");
				
				//Removes the {} from variableTag
				var variable:String = strippedVariableTag.substring(1, strippedVariableTag.length-1);

				//Obtains the path the user entered
				var path:Array = variable.split("/");
				//The session state associated with each variable in the path
				var state:Object = null;
				//If user is requesting a value from a column, get the specific value to replace the variable with
				if(path[0].toString().search("getValueAt")>=0){
					state = getValueFromTag(path[0].toString());
				}
					//Otherwise, resolve the variable to a path from the session state
				else {
					//Try to get the object associated with the first variable in the path from the root session state
					var root:ILinkableObject = Weave.root.getObject(path[0]);
				trace("root is " + root);
					//If the requested object is contained in the root, get the session state for that object
					if(root){
						//Get the session state associated with the first item in the path
						state =  sessionManager.getSessionState(root);
						//Iterate through the rest of the items in the path
						for(var i:int=1;i<path.length;i++){						
							state = state[path[i]];
							
							if(state == null)
								break;
						}
					}
				}
				//If the user entered an invalid path/variable, alert them
				if(root==null)
					state = "~" + variable + "~";
				if(state==null)
					state = "null";
				
				trace("variable tag and state " + this.htmlText + " " + variableTag + " " + state);


				this.htmlText = this.htmlText.replace(variableTag,state);
				//Replace the current variable tag with the resolved variable value
//				this.htmlText = this.htmlText.("[[","{");				
//				this.htmlText = this.htmlText.replace("]]","}");
				
			}
		}
		
		
		private const DATA_SOURCE:int = 0;
		private const COLUMN_NAME:int = 1;
		private const ROW_IDENTIFIER:int = 2;
		private const NUM_PARAMS:int = 3;
		
		private function getValueFromTag(tag:String):String
		{
			var params:Array = tag.replace("getValueAt(", "").replace(")","").split(",");
			//User needs to enter a value for data source, column name and either a key or row index
			if(params.length!=NUM_PARAMS)
				return null;
			
			return getValueAt(params[DATA_SOURCE], params[COLUMN_NAME], params[ROW_IDENTIFIER]);
		}
		
		/*
		{getValueAt(obesity.csv,State,39)}
		*/
		
		private function getValueAt(dataSourceName:String, columnName:String, key:String):String {
			var dataSource:IDataSource = Weave.root.getObject(dataSourceName) as IDataSource;
			var columnList:XMLList = (dataSource.attributeHierarchy as AttributeHierarchy).value.descendants("attribute");
			var columnReference:HierarchyColumnReference = new HierarchyColumnReference();
			columnReference.dataSourceName.value = dataSourceName;
			columnReference.hierarchyPath.value = columnList.(@csvColumn == columnName)[0];
			var column:IAttributeColumn = WeaveAPI.AttributeColumnCache.getColumn(columnReference);
			var type:String = ColumnUtils.getKeyType(column);
			
			return column.getValueFromKey(WeaveAPI.QKeyManager.getQKey(type,key));;
		}
	}
}
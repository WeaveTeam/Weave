angular.module('aws.configure.metadata', [])

	.service("metadataManagerService", ['$q', '$rootScope', function($q, scope) {
	
	var that = this;
	
	this.dataObject = {};
	
	/**
	  * This function makes nested async calls to the aws function getEntityChildIds and
	  * getDataColumnEntities in order to get an array of dataColumnEntities children of the given id.
	  * We use angular deferred/promises so that the UI asynchronously wait for the data to be available...
	  */
	this.getDataColumnsEntitiesFromId = function(id, forceUpdate) {
        
		if(!forceUpdate) {
    		if (this.dataObject.columns) {
    			return this.dataObject.columns;
    		}
		}

		var deferred = $q.defer();
		
        aws.DataClient.getEntityChildIds(id, function(idsArray) {
            scope.$apply(function() {
                deferred.resolve(idsArray);
            });
        });
        
        var deferred2 = $q.defer();
        
        deferred.promise.then(function(idsArray) {
        	
        	aws.DataClient.getDataColumnEntities(idsArray, function(dataEntityArray) {
        		
        		that.dataObject.columns = dataEntityArray;
        		
        		scope.$apply(function() {
                	deferred2.resolve(dataEntityArray);
                });
            });
        });
        
        return deferred2.promise;

    };
    
    /**
     * This function wraps the async aws getDataTableList to get the list of all data tables
     * again angular defer/promise so that the UI asynchronously wait for the data to be available...
     */
    this.getDataTableList = function(){
        
    	if (this.dataObject.dataTableList) {
    		return this.dataObject.dataTableList;
    	}
    	
    	var deferred = $q.defer();
        
        aws.DataClient.getDataTableList(function(EntityHierarchyInfoArray){
            
        	that.dataObject.dataTableList = EntityHierarchyInfoArray;
        	
        	scope.$apply(function(){
                deferred.resolve(EntityHierarchyInfoArray);
            });
        });
            
        return deferred.promise;

    };
    
    this.getEntityChildIds = function(ids) {
		
    	var deferred = $q.defer();
        
        aws.DataClient.getEntityChildIds(ids, function(DataEntity){
            
        	scope.$apply(function(){
                deferred.resolve(DataEntity);
            });
        });
            
        return deferred.promise;
    }
    
    this.updateEntity = function(user, password, entityId, diff) {

    	var deferred = $q.defer();
        
        aws.AdminClient.updateEntity(user, password, entityId, diff, function(){
            
        	scope.$apply(function(){
                deferred.resolve();
            });
        });
        return deferred.promise;
    };
    
    
     // Source: http://www.bennadel.com/blog/1504-Ask-Ben-Parsing-CSV-Strings-With-Javascript-Exec-Regular-Expression-Command.htm
     // This will parse a delimited string into an array of
     // arrays. The default delimiter is the comma, but this
     // can be overriden in the second argument.
 
 
    this.CSVToArray = function(strData, strDelimiter) {
        // Check to see if the delimiter is defined. If not,
        // then default to comma.
        strDelimiter = (strDelimiter || ",");
        // Create a regular expression to parse the CSV values.
        var objPattern = new RegExp((
        // Delimiters.
        "(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +
        // Quoted fields.
        "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +
        // Standard fields.
        "([^\"\\" + strDelimiter + "\\r\\n]*))"), "gi");
        // Create an array to hold our data. Give the array
        // a default empty first row.
        var arrData = [[]];
        // Create an array to hold our individual pattern
        // matching groups.
        var arrMatches = null;
        // Keep looping over the regular expression matches
        // until we can no longer find a match.
        while (arrMatches = objPattern.exec(strData)) {
            // Get the delimiter that was found.
            var strMatchedDelimiter = arrMatches[1];
            // Check to see if the given delimiter has a length
            // (is not the start of string) and if it matches
            // field delimiter. If id does not, then we know
            // that this delimiter is a row delimiter.
            if (strMatchedDelimiter.length && (strMatchedDelimiter != strDelimiter)) {
                // Since we have reached a new row of data,
                // add an empty row to our data array.
                arrData.push([]);
            }
            // Now that we have our delimiter out of the way,
            // let's check to see which kind of value we
            // captured (quoted or unquoted).
            if (arrMatches[2]) {
                // We found a quoted value. When we capture
                // this value, unescape any double quotes.
                var strMatchedValue = arrMatches[2].replace(
                new RegExp("\"\"", "g"), "\"");
            } else {
                // We found a non-quoted value.
                var strMatchedValue = arrMatches[3];
            }
            // Now that we have our value string, let's add
            // it to the data array.
            arrData[arrData.length - 1].push(strMatchedValue);
        }
        // Return the parsed data.
        return (arrData);
    }
}]);

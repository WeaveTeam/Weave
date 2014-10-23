angular.module('aws.configure.metadata').service("metadataManagerService", ['$q', '$rootScope','runQueryService', function($q, scope, runQueryService) {
	 var that = this;//saving pointer for async promises
	 this.statScript = " frame <- data.frame(myMatrix)\n" +
		"normandBin <- function(frame)\n" +  
		"structure(list(counts = getCounts(frame), breaks = getBreaks(frame)), class = \"normandBin\");\n"+
		"getNorm <- function(frame){\n" +				
		"myRows <- nrow(frame)\n" +
		"myColumns <- ncol(frame)\n" +
		"for (z in 1:myColumns ){\n" +
		"maxr <- max(frame[z])\n" +
		"minr <- min(frame[z])\n" +
		"for(i in 1:myRows ){\n" +
		"frame[i,z] <- (frame[i,z] - minr) / (maxr - minr)\n" +
		" }\n" +
		"}\n" +
		"return(frame)\n" +
		"}\n" +
		"getCounts <- function(normFrame){\n" +
		"normFrame <- getNorm(frame)\n" +
		"c <- ncol(normFrame)\n" +
		"histoInfo <- list()\n" +
		"answerCounts <- list()\n" +
		"for( s in 1:c){\n" + 
		"histoInfo[[s]] <- hist(normFrame[[s]], plot = FALSE)\n" + 
		"answerCounts[[s]] <- histoInfo[[s]]$counts\n" +
		"}\n" +
		"return(answerCounts)\n" +
		"}\n" +
		"getBreaks <- function(frame){\n" +
		"normFrame <- getNorm(frame)\n" +
		" c <- ncol(normFrame)\n" +
		"histoInfo <- list()\n" +
		"answerBreaks <- list()\n" +
		"for( i in 1:c){\n" +
		"histoInfo[[i]] <- hist(normFrame[[i]], plot = FALSE)\n" +
		"answerBreaks[[i]] <- histoInfo[[i]]$breaks\n" +
		"}\n" +
		"return(answerBreaks)\n" +
		"}\n" +
		"finalResult <- normandBin(frame)\n" +
		"lappend <- function(lst, stat, name) {\n" +
		"lst[name] <- stat\n" +
		"return(lst)}\n" +
		"getAllColumnStats <- function(myMatrix){\n" +
		"allColumnStats <- list()\n" +
		"oneColumnStat <- list()\n" +
		"answer <- list()\n" +
		"columnName <- \"\"\n" +
		"stgOne <- \"ColumnMaximum\"\n" +
		"stgTwo <- \"ColumnMinimum\"\n" +
		"stgThree <- \"ColumnMean\"\n" +
		"stgFour <- \"ColumnVariance\"\n" +
		"for( i in 1:length(myMatrix)){\n" +
		"columName <- \"\"\n" +
		"answer <- lappend(answer, colMax <- max(myMatrix[[i]]), stgOne)\n" +
		"answer <- lappend(answer, colMin <- min(myMatrix[[i]]), stgTwo)\n" +
		"answer <- lappend(answer, colMean <- mean(myMatrix[[i]]), stgThree)\n" +
		"answer <- lappend(answer, colVariance <- var(myMatrix[[i]]), stgFour)\n" +
		"columnName <- sprintf(\"Column%.0f\",i)\n" +
		"oneColumnStat <- list(answer)\n" +
		"allColumnStats[columnName] <- oneColumnStat\n" +
		"}\n" +
		"return(allColumnStats)\n" +
		"}\n" +
		"finalStatResult <- getAllColumnStats(frame)\n";
	 
//     this.calculateStatistics = function(){
//    	 //if the dataset is the same then cache the statistics
//    	 
//    		//functions for column statistics and distributions
//    		
//    			//pick all numerical columns
//    			//create a matrix
//    			//run script
//    	 		runQueryService.queryRequest(computationServiceURL, 'calculateColumnStats', [matrix], function(result){
//    	 			console.log("got the stats", result);
//    	 			that.data.columnStats = result;
//    	 		});
//    			//display in grid
//     };
    
}]);

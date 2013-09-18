
getColumns <- function(query)
{
	final <- dbGetQuery(con, paste(query))
	return(final)
}
params <- c(col1, col2, col3, col4, col5)
runbrfss <- function(query,params)
{	
	
	#final <- getColumns(query)
	    
	system.time(final <- getColumns(query))

	#l.year<-sort(unique(final$"year"))
	 tempYear <- unique(final[,params[[1]]])
	tempYear <- as.numeric(tempYear)
	l.year <- sort(tempYear)
	
	
	system.time(
		for(i in 1:length(l.year)-1)#one loop for every year
		{
			indata2<-final[final[,params[[1]]]==l.year[i],]
			
			mypsu <- as.numeric(indata2[,params[[2]]])
			mysrstr <- as.numeric(indata2[,params[[4]]])
			mywgt <- as.numeric(indata2[,params[[3]]])
			myindicator <- as.numeric(indata2[,params[[5]]])
			
			dstrat<-svydesign(id = mypsu, strata = mysrstr, data=indata2, weights= mywgt, nest=TRUE)
			prev_pct<-round(as.data.frame(svymean(~factor(myindicator), na.rm=TRUE, dstrat))$mean*100,1)
			cint<-round((1.96*as.data.frame(svymean(~factor(myindicator), na.rm=TRUE, dstrat))$SE*100), 1)
			
			conf_int_low<-prev_pct-cint

			conf_int_hi<-prev_pct+cint
			
			if(i==1)
			 {
				prev.data<-data.frame(l.year[i], sort(unique(factor(myindicator))), prev_pct,conf_int_low, conf_int_hi)
				names(prev.data)<-c("fips", "response", "prev.percent", "CI_LOW", "CI_HI")
			 } 
		  else 
			 {
				t.prev.data<-data.frame(l.year[i], sort(unique(factor(myindicator))), prev_pct, conf_int_low, conf_int_hi)
				names(t.prev.data)<-c("fips", "response", "prev.percent", "CI_LOW", "CI_HI")
				prev.data<-rbind(prev.data, t.prev.data)
			 }
		})# end of for loop
		#cat(date())
		
		#dbDisconnect(con)
		

	 prev.data<-prev.data[prev.data$response==1,]
        
	
	 return(prev.data)

}# end of function

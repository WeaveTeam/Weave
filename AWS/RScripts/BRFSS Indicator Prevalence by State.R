library(survey)
runbrfss <- function(dataset)
{
    names(dataset)<-c("col 1", "col 2", "col 3", "col 4", "col 5")

	#l.state<-sort(unique(dataset$"_STATE"))
    tempState <- unique(dataset[,1])
	tempState <- as.numeric(tempState)
	l.state <- sort(tempState)
	
	system.time(
		
		for(i in 1:length(l.state))#one loop for every state
		{
			indata2<-dataset[dataset[,1]==l.state[i],]
			mypsu <- as.numeric(indata2[,2])
			mywgt <- as.numeric(indata2[,3])
            mysrstr <- as.numeric(indata2[,4])
			myindicator <- as.numeric(indata2[,5])
			
            dstrat<-svydesign(id = mypsu, strata = mysrstr, data=indata2, weights= mywgt, nest=TRUE)
			prev_pct<- round(as.data.frame(svymean(~factor(myindicator), na.rm=TRUE, design = dstrat))$mean*100,1)
            cint<- round((1.96*as.data.frame(svymean(~factor(myindicator), na.rm=TRUE, design = dstrat))$SE*100), 1)
    
            conf_int_low<-prev_pct-cint

			conf_int_hi<-prev_pct+cint
            
			if(i==1)
			 {
				prev.data<-data.frame(l.state[i], sort(unique(factor(myindicator))), prev_pct, conf_int_low, conf_int_hi)
				names(prev.data)<-c("fips", "response", "prev.percent", "CI_LOW", "CI_HI")
			 }
		  else 
			 {
				t.prev.data<-data.frame(l.state[i], sort(unique(factor(myindicator))), prev_pct, conf_int_low, conf_int_hi)
				names(t.prev.data)<-c("fips", "response", "prev.percent", "CI_LOW", "CI_HI")
				prev.data<-rbind(prev.data, t.prev.data)
			 }
		})# end of for loop
		
        
		state<-c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", 

	"IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", 

	"NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", 

	"UT", "VT", "VA", "WA", "WV", "WI", "WY", "GU", "PR", "VI")

	 fips<-data.frame(l.state)
	 names(fips)<-c("fips")
	 
	 prev.data<-merge(fips, prev.data)
	 prev.data$Year<-2010
	 prev.data<-prev.data[prev.data$response==1,]
     prev.data<-prev.data[prev.data$fips<=56,]
     print(prev.data)
	 return(prev.data)

}# end of function

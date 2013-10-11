library(survey)

runbrfss <- function(data)
{	
	
	system.time(final <- data
	
    
	#l.state<-sort(unique(final$"_STATE"))
	 tempState <- unique(final[,params[[1]]])
	tempState <- as.numeric(tempState)
	l.state <- sort(tempState)
	
	system.time(
		
		for(i in 1:length(l.state))#one loop for every state
		{
			indata2<-final[final[,params[[1]]]==l.state[i],]
			
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
				prev.data<-data.frame(l.state[i], sort(unique(factor(myindicator))), prev_pct,conf_int_low, conf_int_hi)
				names(prev.data)<-c("fips", "response", "prev.percent", "CI_LOW", "CI_HI")
			 } 
		  else 
			 {
				t.prev.data<-data.frame(l.state[i], sort(unique(factor(myindicator))), prev_pct, conf_int_low, conf_int_hi)
				names(t.prev.data)<-c("fips", "response", "prev.percent", "CI_LOW", "CI_HI")
				prev.data<-rbind(prev.data, t.prev.data)
			 }
		})# end of for loop
		
		
		#dbDisconnect(con)
		
		state<-c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", 

	"IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", 

	"NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", 

	"UT", "VT", "VA", "WA", "WV", "WI", "WY", "GU", "PR", "VI")

	 state<-data.frame(l.state, state)
	 names(state)<-c("fips", "State")
	 
	 prev.data<-merge(state, prev.data)
	 prev.data$Year<-2010
	 prev.data<-prev.data[prev.data$response==1,]
         prev.data<-prev.data[prev.data$fips<=56,]
	 return(prev.data)

}# end of function

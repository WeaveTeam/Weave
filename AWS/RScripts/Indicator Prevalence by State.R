library(survey)
library(foreach)
library(doParallel)
cl <- makeCluster(3)
registerDoParallel(cl)

runbrfss <- function(year, state, PSU, FinalWt, StStr, indicator)
{
    data <- data.frame(year, state, PSU, FinalWt, StStr, indicator)
    #INCLUDE THE NEXT LINE WHEN USING THE ONE YEAR FILE, OTHERWISE WILL ERROR BECAUSE IN 2011 SOME STATES HAVE A SINGLE DIABETES RESPONSE CODE
    #mydata <- subset(mydata,mydata[,1]==2010) # 1 year data
    data$yearstate <- as.numeric(paste(data$year, data$state, sep=""))
    l.year <- sort(as.numeric(unique(data$year)))
  
    l.state <- sort(as.numeric(unique(data$state)))
    
    l.yearstate <- sort(as.numeric(unique(data$yearstate)))
    
    # FUNCTION TO CALCULATE PREV PERCENT AND CI, FOR SELECTED DIABETES RESPONSE
    prev.calc <- function(df)
    {
        indata <- subset(df, df$yearstate == l.yearstate[i])
        myyear <- as.numeric(indata$year[1])
        mystate <- as.numeric(indata$state[1])
        
        mypsu <- as.numeric(indata$PSU)
        mywgt <- as.numeric(indata$FinalWt)
        mysrstr <- as.numeric(indata$StStr)
        myindicator <- as.numeric(indata$indicator)
        
        dstrat<-svydesign(id = mypsu, strata = mysrstr, data=indata, weights= mywgt, nest=TRUE)
        
        svyresult <- as.data.frame(svymean(~factor(myindicator), na.rm=TRUE, design = dstrat))
        x.svyresult<-list(sort(unique(myindicator)), svyresult$mean, svyresult$SE)
        names(x.svyresult)<-c("myindicator","mean","SE")
        condition <- x.svyresult$myindicator#choosing the indicator column
        index <- which(condition == 1)# choosing indicator(diabetes) reponse ==1 (from choice of 1,2,3,4,7,9), returns index of the response
        x.svyresult <- sapply(x.svyresult, "[", c(index))#subset according to condition
        prev_pct <- round((x.svyresult["mean"]*100), 1)
        cint<- round(1.96*(x.svyresult["SE"]*100), 1)
        d <-  c(mystate, myyear, prev_pct, cint)
        names(d) <- NULL#parts of the vector have names, hence remove them
        
        
        #if(is.element(NA, d) == TRUE){
        #missingIndex <- which(is.na(d))
        #d[missingIndex] <- 0 # substituing now with 0
        #}
        
        c(d)#pure vector
    }
    # DISTRIBUTED PROCESSING OF SURVEY FUNCTION
    prevcalc.data <- foreach(i=1:length(l.yearstate), .packages="survey", .combine='rbind') %dopar% prev.calc(data)
    stopCluster(cl)
    prevcalc.data <- data.frame(prevcalc.data)
    names(prevcalc.data)<-c("fips","year","prev.percent", "cint")
    
    # CODE TO FORMAT OUTPUT FOR DIMENSION SLIDER
    # FIRST STEP IS TO SEPATE INTO FILES BY YEAR
    dflist <- vector('list', length(l.year))
    for(i in 1:length(l.year))
    {
        dfnam <- paste("df",l.year[i],sep=".")
        prevnam <- paste("prev.pct",l.year[i],sep=".")
        cintnam <- paste("cint",l.year[i],sep=".")
        
        df <- data.frame(subset(prevcalc.data,(prevcalc.data[,2]==l.year[i])))
        #we do not need to show the year column in this format
        df$year <- NULL
        names(df) <- c("fips", prevnam, cintnam)
        dflist[[i]] <- df
        
        assign(dfnam, df)
        
    }
    
    # SECOND STEP IS TO MERGE FILES ON FIPS, IF ROWS ARE UNEQUAL MISSING DATA IS FILLED IN WITH NA
    prev.data <- data.frame(l.state)
    names(prev.data) <- "fips"
    
    for (i in 1:length(dflist))
    {
        prev.data<-merge(prev.data, dflist[[i]], by="fips", all=TRUE)
    }
    
    # FINALLY ADD STATENAME TO FILE THAT WILL BE RETURNED
    #have removed statenames for now as column not helful in generating results in this script
statecode <-c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL",

"IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV",

"NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX",

"UT", "VT", "VA", "WA", "WV", "WI", "WY")


    statecode<-data.frame(statecode)
    names(statecode)<-c("labels")
    prev.data<-cbind(statecode, prev.data)
    prev.data <- prev.data[-12,]#temporary hack TODO: get rid of this for handling missing data
    prev.data<-prev.data[prev.data$fips<=56,]

    #print(prev.data)
    return(prev.data)

}
result = runbrfss(year, state, PSU, FinalWt, StStr, indicator)
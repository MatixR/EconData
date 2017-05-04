




# this file contains functions to build RDatasets
# from raw data



#' get package root
#' 
#' @param your_root where you develop this package.
getRoot <- function(your_root="~/git/EconData"){
	return(your_root)
}

#' make all datasets
#'
#' This builds all datasets in this package from its raw source. Most of the data come installed with package as excel or csv files. Some are downloaded from online sources. 
#' @family makers
#' @export
makeAllData <- function(){
	cat('building all datasets\n')
    dir.create(file.path(getRoot(), "data"), showWarnings = FALSE)
	
	makeAbbreviations()
	makeMedianIncome()
	makeFHFA()
	makeLincolnHomeValues()
	makeUS_coordinates()
	makeUS_coordinates(agg="Division")
  	makeUS_distance()
  	makeUS_distance(agg="Division")
	makeCPIUS()
	makeMORTGAGE30US()
	makeInterstateMig()
	makeOwnershipRates()
	makeBEAincome()
	makeBEA_PCincome()
    make_bankruptcy()
	
	#cat("building population counts, may take a little.\n")
	#makePopulation()
	cat("Done.\n")
	cat(paste0("You should now devtools:::install(",getRoot(),")\n"))
	
	return(TRUE)
}

#' makes Correspondance of US State with FIPS code, Census Region and Division 
#'
#' produces a data.table with state names and FIPS 
#' abbreviations. Also includes census region and division.
#'
#' you will most likely want to merge this table into some 
#' dataset you come across and which is missing full state names,
#' or abbreviations, or FIPS code etc.
#'
#' @param url https://www.census.gov/geo/reference/ansi_statetables.html
#' @return NULL. saves data to data/
#' @family makers
makeAbbreviations <- function(){
  
    url="https://www.census.gov/geo/reference/ansi_statetables.html"

	# get abbreviations
	tab <- readHTMLTable(getURL(url))
	states <- data.table(tab[[1]])
	setnames(states,c("STATE","FIPS","Abbreviation"))
	states[,STATE := toupper(as.character(STATE))]
	states[,Abbreviation:= as.character(Abbreviation)]
	states[,FIPS := as.numeric(as.character(FIPS))]

	# manually add PSID codes
	states[,                               PSID := 0]
	states[STATE=="ALABAMA",               PSID := 1]
	states[STATE=="ARIZONA",               PSID := 2]
	states[STATE=="ARKANSAS",              PSID := 3]
	states[STATE=="CALIFORNIA",            PSID := 4]
	states[STATE=="COLORADO",              PSID := 5]
	states[STATE=="CONNECTICUT",           PSID := 6]
	states[STATE=="DELAWARE",              PSID := 7]
	states[STATE=="DISCTRICT OF COLUMBIA", PSID := 8]
	states[STATE=="FLORIDA",               PSID := 9]
	states[STATE=="GEORGIA",               PSID := 10]
	states[STATE=="IDAHO",                 PSID := 11]
	states[STATE=="ILLINOIS",              PSID := 12]
	states[STATE=="INDIANA",               PSID := 13]
	states[STATE=="IOWA",                  PSID := 14]
	states[STATE=="KANSAS",                PSID := 15]
	states[STATE=="KENTUCKY",              PSID := 16]
	states[STATE=="LOUISIANA",             PSID := 17]
	states[STATE=="MAINE",                 PSID := 18]
	states[STATE=="MARYLAND",              PSID := 19]
	states[STATE=="MASSACHUSETTS",         PSID := 20]
	states[STATE=="MICHIGAN",              PSID := 21]
	states[STATE=="MINNESOTA",             PSID := 22]
	states[STATE=="MISSISSIPPI",           PSID := 23]
	states[STATE=="MISSOURI",              PSID := 24]
	states[STATE=="MONTANA",               PSID := 25]
	states[STATE=="NEBRASKA",              PSID := 26]
	states[STATE=="NEVADA",                PSID := 27]
	states[STATE=="NEW HAMPSHIRE",         PSID := 28]
	states[STATE=="NEW JERSEY",            PSID := 29]
	states[STATE=="NEW MEXICO",            PSID := 30]
	states[STATE=="NEW YORK",              PSID := 31]
	states[STATE=="NORTH CAROLINA",        PSID := 32]
	states[STATE=="NORTH DAKOTA",          PSID := 33]
	states[STATE=="OHIO",                  PSID := 34]
	states[STATE=="OKLAHOMA",              PSID := 35]
	states[STATE=="OREGON",                PSID := 36]
	states[STATE=="PENNSYLVANIA",          PSID := 37]
	states[STATE=="RHODE ISLAND",          PSID := 38]
	states[STATE=="SOUTH CAROLINA",        PSID := 39]
	states[STATE=="SOUTH DAKOTA",          PSID := 40]
	states[STATE=="TENNESSEE",             PSID := 41]
	states[STATE=="TEXAS",                 PSID := 42]
	states[STATE=="UTAH",                  PSID := 43]
	states[STATE=="VERMONT",               PSID := 44]
	states[STATE=="VIRGINIA",              PSID := 45]
	states[STATE=="WASHINGTON",            PSID := 46]
	states[STATE=="WEST VIRGINIA",         PSID := 47]
	states[STATE=="WISCONSIN",             PSID := 48]
	states[STATE=="WYOMING",               PSID := 49]
	states[STATE=="ALASKA",                PSID := 50]
	states[STATE=="HAWAII",                PSID := 51]
	setkey(states,FIPS)

	st <- data.table(read_excel(file.path(getRoot(),"inst","extdata","census","state_geocodes_v2011.xls"),sheet=2))
	st[, c("Reg_ID","Div_ID","FIPS") := lapply(st[,list(Reg_ID,Div_ID,FIPS)], function(x) as.numeric(as.character(x)))]
	st[, c("Region","Division","State") := lapply(st[,list(Region,Division,State)], function(x) as.character(x))]

	st[,State := NULL]

	
	setkey(st,FIPS)

	US_states <- st[states]
	setnames(US_states,"Abbreviation","state")
	setcolorder(US_states,c("FIPS","PSID","STATE","state","Reg_ID","Region","Div_ID","Division"))

	save(US_states,file=file.path(getRoot(),"data/US_states.RData"))

	return(US_states)
}





#' make dataset of median income by US state and year
#'
#' produce dataset in current and 2012 dollars of
#' median household income by US state.
#'
#' saves 2 lists \code{current} and \code{in2012}, each 
#' with elements zinc, zse, incl, sel. Those elements are
#' \enumerate{
#' \item zinc: a zoo object of median income
#' \item zse: a zoo object of it's standard error
#' \item incl: data.frame with median income in long format
#' \item sel: data.frame with standard error of median income in long format
#' }
#' 
#' source: census bureau
#' @return NULL. 
#' @family makers
#' @references \url{http://www.census.gov/hhes/www/income/data/historical/household/}
makeMedianIncome <- function(){

	yrs <- 2012:1984

	# indices
	cols <- list()
	cols$inc <- c(1,seq(from=3,to=60,by=2))
	cols$se  <- c(1,seq(from=4,to=60,by=2))

	# current dollars
	rows <- 8:59

	current = list()
	tmp <- read_excel(file.path(getRoot(),"inst","extdata","census","H08_2012.xls"),sheet=1,range = cell_limits(c(8,1),c(59,60)),col_names=FALSE)
	current$inc <- tmp[,cols$inc]
	current$se  <- tmp[,cols$se]
	names(current$inc) <- c("State",paste0(yrs))
	names(current$se) <- c("State",paste0(yrs))

	# get long dataset
	current$incl <- melt(current$inc,id.vars="State")
	names(current$incl)[2:3] <- c("Year","medinc")
	current$incl$State <- str_trim(current$incl$State)
	current$Year <- as.character(current$Year)
	current$sel <- melt(current$se,id.vars="State")
	names(current$sel)[2:3] <- c("Year","se")

	# make zoo object
	rownames(current$inc) <- current$inc$State
	rownames(current$se) <- current$se$State
	current$inc <- current$inc[,-1]
	current$se <- current$se[,-1]

	current$inc <- t(current$inc)
	current$se <- t(current$se)

	current$zinc <- as.zoo(ts(current$inc[nrow(current$inc):1,],start=1984))
	current$zse <- as.zoo(ts(current$se[nrow(current$se):1,],start=1984))

	current$inc <- NULL
	current$se <- NULL

	medinc_current <- current


	# 2012 dollars
	rows <- rows + 53

	in2012 <- lapply(cols,function(x) read_excel(file=file.path(getRoot(),"inst","extdata","census","H08_2012.xls"),sheet=1,rowIndex=rows,colIndex=x,header=FALSE))
	names(in2012$inc) <- c("State",paste0(yrs))
	names(in2012$se) <- c("State",paste0(yrs))

	# get long dataset
	in2012$incl <- melt(in2012$inc,id.vars="State")
	names(in2012$incl)[2:3] <- c("Year","medinc")
	in2012$Year <- as.character(in2012$Year)
	in2012$sel <- melt(in2012$se,id.vars="State")
	names(in2012$sel)[2:3] <- c("Year","se")

	# make zoo object
	rownames(in2012$inc) <- in2012$inc$State
	rownames(in2012$se) <- in2012$se$State
	in2012$inc <- in2012$inc[,-1]
	in2012$se <- in2012$se[,-1]

	in2012$inc <- t(in2012$inc)
	in2012$se <- t(in2012$se)

	in2012$zinc <- as.zoo(ts(in2012$inc[nrow(in2012$inc):1,],start=1984))
	in2012$zse <- as.zoo(ts(in2012$se[nrow(in2012$se):1,],start=1984))

	in2012$inc <- NULL
	in2012$se <- NULL
	
	medinc_2012 <- in2012

	# Census Region level medians in current
# 	reg <- read_excel(file=file.path(root,"inst/extdata/census/H06AR_2011.xls"),sheet=1,rowIndex=c(7:43,45:81,83:119,121:157,159:195),colIndex=3,header=FALSE)
# 	reg$year <- c(rep(2011:1975,5))
# 	reg$region <- c(rep("USA",length(2011:1975)),rep("Northeast",length(2011:1975)),rep("Midwest",length(2011:1975)),rep("South",length(2011:1975)),rep("West",length(2011:1975)))
# 	reg_current = as.data.table(reg)
# 	setcolorder(reg_current,c(2,3,1))
# 	setnames(reg_current,"V3","medinc")
# 
# 
# 	save(reg_current,file=file.path(getRoot(),"data","US_medinc_reg.RData"))
	save(medinc_2012,file=file.path(getRoot(),"data","US_medinc_2012.RData"))
	save(medinc_current,file=file.path(getRoot(),"data","US_medinc_current.RData"))
	return(NULL)
}




#' make FHFA expanded house price indices
#' 
#' downloads and builds FHFA 
#' Expanded-Data Indexes (Estimated using 
#' Enterprise, FHA, and Real Property County Recorder 
#' Data Licensed from DataQuick). Data is quarterly.
#'
#' @return NULL. 
#' @family makers
#' @family FHFAs 
#' @references \url{http://www.fhfa.gov/Default.aspx?Page=87}
makeFHFA <- function(){

	states <- list()
	msa50  <- list()
	USDiv  <- list()
  
	
	states$qtr <- data.table(read.table("https://www.fhfa.gov/DataTools/Downloads/Documents/HPI/HPI_EXP_state.txt",sep="\t",header=TRUE))
	msa50$qtr <- data.table(read.table("https://www.fhfa.gov/DataTools/Downloads/Documents/HPI/HPI_EXP_metro.txt",sep="\t",header=TRUE))
	USDiv$qtr <- data.table(read.table("https://www.fhfa.gov/DataTools/Downloads/Documents/HPI/HPI_EXP_us_and_census.txt",sep="\t",header=TRUE))
	setnames(USDiv$qtr,c("Division","yr","qtr","index_nsa","index_sa","note"))

	states$yr <- states$qtr[,list(index_nsa=mean(index_nsa),index_sa=mean(index_sa)),by=list(state,yr)]
	msa50$yr <- msa50$qtr[,list(index_nsa=mean(index_nsa),index_sa=mean(index_sa)),by=list(metro_name,yr)]
	USDiv$yr <- USDiv$qtr[,list(index_nsa=mean(index_nsa),index_sa=mean(index_sa)),by=list(Division,yr)]

	# create date variable in qtr
	states$qtr[, quarter := as.yearqtr(paste0(yr," Q",qtr))]
	states$qtr[, Date    := as.Date(quarter)]
	states$qtr[, c("yr","qtr") := NULL]
	msa50$qtr[, quarter := as.yearqtr(paste0(yr," Q",qtr))]
	msa50$qtr[, Date    := as.Date(quarter)]
	msa50$qtr[, c("yr","qtr") := NULL]
	USDiv$qtr[, quarter := as.yearqtr(paste0(yr," Q",qtr))]
	USDiv$qtr[, Date    := as.Date(quarter)]
	USDiv$qtr[, c("yr","qtr") := NULL]

	# rename
	FHFA_states <- states
	FHFA_msa50 <- msa50
	FHFA_Div   <- USDiv

	save(FHFA_msa50,file=file.path(getRoot(),"data","FHFA_msa50.RData"))
	save(FHFA_Div,file=file.path(getRoot(),"data","FHFA_Div.RData"))
	save(FHFA_states,file=file.path(getRoot(),"data","FHFA_states.RData"))
}
	




#' make Lincoln Institute Home and Land Value Dataset
#' 
#' reads data from the Lincoln Institute xls file.
#'
#' @return NULL. 
#' @family makers
#' @references \url{https://www.lincolninst.edu/subcenters/land-values/}
makeLincolnHomeValues <- function(){

	d <- fread(input=file.path(getRoot(),"inst","extdata","lincolninst","landdata-states-2013q1.csv"),skip=1)
	d[,qtr := as.yearqtr(Date)]
	d[,Date := NULL]
	setnames(d,c("State","Home.Value","Structure.Cost","Land.Value","Land.Share","Home.Price.Index","Land.Price.Index","qtr"))
	warning("amounts in HomeValues are current dollars.")
	HomeValues <- d
	save(HomeValues,file=file.path(getRoot(),"data","HomeValues.RData"))
}


#' make several US inflation datasets
#'
#' download data from FRED with quantmod package
#'
#' saves cpi for all urban consumers 
#' and housing cpi to disk
#' @family makers
#' @family FREDs
#' @references \url{http://research.stlouisfed.org/fred2/series/CPIAUCSL} 
#'             \url{http://research.stlouisfed.org/fred2/series/CPIHOSSL} 
#'             \url{http://research.stlouisfed.org/fred2/series/USSTHPI} 
makeCPIUS <- function(){

	getSymbols('CPIAUCSL',src='FRED')
	getSymbols('CPIHOSSL',src='FRED')
	getSymbols('USSTHPI',src='FRED')

	save(CPIAUCSL,file=file.path(getRoot(),"data","CPIAUCSL.RData"))
	save(CPIHOSSL,file=file.path(getRoot(),"data","CPIHOSSL.RData"))
	save(USSTHPI,file=file.path(getRoot(),"data","USSTHPI.RData"))
	
}


#' make 30 year FRM rates dataset
#'
#' saves the Freddie Mac 30 year FRM index
#' to disk
#' @family makers
#' @family FREDs
#' @references \url{http://research.stlouisfed.org/fred2/series/MORTGAGE30US} 
#' download data from FRED with quantmod package
makeMORTGAGE30US <- function(){

	getSymbols('MORTGAGE30US',src='FRED')

	save(MORTGAGE30US,file=file.path(getRoot(),"data","US_MortgageRates.RData"))

}


#' Haversine Distance function
#'
#' use the haversine formula to compute distance
#' between 2 locations
#'
#' @references \url{http://www.r-bloggers.com/great-circle-distance-calculations-in-r/}
gcd.hf <- function(long1, lat1, long2, lat2) {
  R <- 6371 # Earth mean radius [km]
  delta.long <- (long2 - long1)
  delta.lat <- (lat2 - lat1)
  a <- sin(delta.lat/2)^2 + cos(lat1) * cos(lat2) * sin(delta.long/2)^2
  c <- 2 * asin(min(1,sqrt(a)))
  d = R * c
  return(d) # Distance in km
}


# Calculates the geodesic distance between two points specified by radian latitude/longitude using the
# Spherical Law of Cosines (slc)
gcd.slc <- function(long1, lat1, long2, lat2) {
  R <- 6371 # Earth mean radius [km]
  d <- acos(sin(lat1)*sin(lat2) + cos(lat1)*cos(lat2) * cos(long2-long1)) * R
  return(d) # Distance in km
}

deg2rad <- function(deg) return(deg*pi/180)






#' make Coordinate of US State centers
#'
#' optionally one can supply a list that groups states together. like census divisions.
#' the relevant location is then just the average of the coordinates of the constituting states
#'
#' @param agg list of character vectors of state abbreviations that should be aggregated into one location
#' @references \url{http://staff.washington.edu/glynn/dist_matrix.pdf}
#' @family makers
#' @examples
#' all <- makeUS_coordinates()
#' aggregated <- makeUS_coordinates(agg=list(c("ME","VT"),c("ND","SD","WY")))
#' Divisions <- makeUS_coordinates(agg=list(c("ME","VT"),c("ND","SD","WY")))
makeUS_coordinates <- function(agg=NULL){
	coordStates <- data.table(read.table("http://staff.washington.edu/glynn/state.data",header=FALSE))
	setnames(coordStates,c("state","FIPS","lat","long"))
	coordStates$state <- as.character(coordStates$state)

	if (is.null(agg)){

		save(coordStates,file=file.path(getRoot(),"data","coordStates.RData"))
		return(coordStates)

	} else if (is.list(agg)){

	
		# custom aggregation

		# drop FIPS
		coordStates[, FIPS := NULL]

		l <- list()
		for (i in 1:length(agg)){
			l[[i]] <- copy(coordStates[ state %in% agg[[i]] , list(lat=mean(lat),long=mean(long)) ])
			l[[i]][, state := paste(agg[[i]],collapse=".")]
			setcolorder(l[[i]],c("state","lat","long"))
		}

		# remove individual states
		# and add to list
		if (nrow(coordStates[ !state %in% unlist(agg) ]) > 0){

			l[[length(agg) + 1]] <- coordStates[ !state %in% unlist(agg) ]
			coordStates_agg <- rbindlist(l)

		}

		save(coordStates_agg,file=file.path(getRoot(),"data","coordStates_agg.RData"))
		return(coordStates_agg)

	} else if (!is.null(agg) & agg=="Division"){
		load(file.path(getRoot(),"data","US_states.RData"))
		US_states[,Division := abbreviate(Division,minlength=3)]

		setkey(US_states,FIPS)
		setkey(coordStates,FIPS)
		coordStates <- coordStates[ US_states ]

		coordStates <- coordStates[!is.na(Division),list(lat=mean(lat),long=mean(long)),by=Division]
   		coordStates <- coordStates[order(Division)]
		setnames(coordStates,"Division","state")

		save(coordStates,file=file.path(getRoot(),"data","coordDivision.RData"))
		return(coordStates)
	}

}



#' make Distance between US state centers
#'
#' @param agg list of character vectors of state abbreviations that should be aggregated into one location
#' @family makers
#' @examples
#' all <- makeUS_distance()
#' aggregated <- makeUS_distance(agg=list(c("ME","VT"),c("ND","SD","WY")))
makeUS_distance <- function(agg=NULL){

	if (is.null(agg)){

		cSt <- makeUS_coordinates(agg=NULL)

	} else if(is.list(agg)){

		cSt <- makeUS_coordinates(agg=agg)
	} else if (agg=="Division"){
	
		cSt <- makeUS_coordinates(agg="Division")

	} 

	# convert degrees to radians
	cSt[ ,lat := deg2rad(lat)]
	cSt[ ,long := deg2rad(long)]

	n <- nrow(cSt)

	m <- matrix(0,n,n)

	for (i in 1:n) {

		for (j in 1:n){

			if (i!=j) {

				m[i,j] <- round(gcd.hf(long1=cSt[i,]$long,
								 lat1=cSt[i,]$lat,
								 long2=cSt[j,]$long,
								 lat2=cSt[j,]$lat))
			}
		}
	}
	rownames(m) <- cSt$state
	colnames(m) <- cSt$state
	if (is.null(agg)){

		State_distMat <- m
		save(State_distMat,file=file.path(getRoot(),"data","State_distMat.RData"))

		State_distTable = data.table(melt(State_distMat))
		setnames(State_distTable,c("from","to","km"))
		save(State_distTable,file=file.path(getRoot(),"data","State_distTable.RData"))

		return(list(mat=State_distMat,tab=State_distTable))

	} else if (is.list(agg)){
		State_distMat_agg <- m
		save(State_distMat_agg,file=file.path(getRoot(),"data","State_distMat_agg.RData"))

		State_distTable_agg = data.table(melt(State_distMat_agg))
		setnames(State_distTable_agg,c("from","to","km"))
		save(State_distTable_agg,file=file.path(getRoot(),"data","State_distTable_agg.RData"))

		return(list(mat=State_distMat_agg,tab=State_distTable_agg))

	} else if (agg=="Division"){
		Division_distMat <- m
		save(Division_distMat,file=file.path(getRoot(),"data","Division_distMat.RData"))
		return(m)
	

	}

}


#' make Interstate Migration Transition Matrix
#'
#' @param root name of package root directory
makeInterstateMig <- function(){

	idx <- seq(from=13,to=21,by=2)
	while (tail(idx,1) < 121) {
		newfrom <- tail(idx,1) + 3
		newto <- newfrom + 8
		idx <- c(idx,seq(newfrom,newto,by=2))
	}
	idx <- idx[idx<121]


	d <- read_excel(file=file.path(getRoot(),"inst","extdata","census","State_to_State_Migrations_Table_2012.xls"),
				   sheet=1,
				   rowIndex=c(12:16,18:22,24:28,30:34,36:40,42,43,49:53,55:59,61:65,67:71,73:76),
				   colIndex=c(1,2,6,10,idx),header=FALSE)

	names(d) <- c("current","pop.current","mig.within",as.character(d[,1]))

	load(file.path(getRoot(),"data","US_states.RData"))
	abbr <- US_states[,list(State=tolower(STATE),state)]

	snames <- names(d)
	snames <- sub("\\s+$", '',snames)	# remove white space at end of string
	snames <- data.frame(State=tolower(snames))
	snames <- merge(snames,abbr,"State")

	names(d)[4:ncol(d)] <- as.character(snames$state)
	d[,1] <- names(d)[4:ncol(d)]
	d[,-1] <- apply(d[,-1],2,as.numeric)
	frac <- as.matrix(d[,-1])

	# as percentage of current population
	dd <- d
	dd[,-1] <- t(apply(frac,1,function(X) X / X[1]))

	m <- melt(dd[,-c(2,3)],"current")
	w.own <- m
	w.own[w.own$current==w.own$variable,]$value <- dd$instate.mig

	level <- d
	props <- m
	props2 <- w.own
	state.migration <- list(level=level,props=props,props.with.own=props2)

	save(state.migration,file=file.path(getRoot(),"data","Migration.RData"))
	return(state.migration)
}


#' make Homeownership rates by state over time
#'
#' @param root directory of package
makeOwnershipRates <- function(){
	rows <- list(9:59,70:120,131:181,192:242,253:303,314:364,375:425,436:486)
	years <- 2012:2005

	tabs <- list()
	for (i in 1:length(years)){
		cat("reading year",years[i],"\n")
		tabs[[i]]          <- read_excel(file=file.path(getRoot(),"inst","extdata","census","tab3_state05_2012_hmr.xls"),sheetName="A",rowIndex=rows[[i]],colIndex=c(1,seq(2,8,by=2)),header=FALSE)
		tmp                <- read_excel(file=file.path(getRoot(),"inst","extdata","census","tab3_state05_2012_hmr.xls"),sheetName="A",rowIndex=rows[[i]],colIndex=c(1,seq(3,9,by=2)),header=FALSE)
		tabs[[i]][,1]      <- gsub("\\.+$","",tabs[[i]][,1])
		tmp[,1]            <- gsub("\\.+$","",tmp[,1])
		names(tabs[[i]])   <- c("State",paste(years[i]," Q",1:4,sep=""))
		names(tmp)         <- c("State",paste(years[i]," Q",1:4,sep=""))
		tabs[[i]]          <- melt(tabs[[i]],"State")
		tabs[[i]]$variable <- as.Date(as.yearqtr(tabs[[i]]$variable))
		names(tabs[[i]])   <- c("State","Date","own.rate")
		tmp                <- melt(tmp,"State")
		tabs[[i]]$se       <- tmp$value
	}

	names(tabs) <- paste("y",years,sep="")
	Ownership <- rbindlist(tabs)

	save(Ownership,file=file.path(getRoot(),"data","Ownership.RData"))
}


#' Census Population Count by state for 1948-2012
#' 
#' takes data from US census bureau intercensal 
#' sites at
#' http://www.census.gov/popest/data/state/asrh/1980s/80s_st_totals.html
#' http://www.census.gov/popest/data/state/asrh/1980s/tables/8090com.txt
#' http://www.census.gov/popest/data/state/totals/1990s/tables/ST-99-03.txt
#' http://www.census.gov/popest/data/intercensal/state/tables/ST-EST00INT-01.xls
#' http://www.census.gov/popest/data/national/totals/2015/files/NST-EST2015-alldata.csv
#' where the last two have been manually cleaned in inst/extdata as \code{pop2000.csv} and \code{pop2010.csv}
makePopulation <- function(){

	# raw data
	r = list()

	# 1900-1905
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st0009ts.txt",skip=17,nrows=55,widths=c(19,9,9,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1900:1905))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:7] <- apply(tmp[,2:7],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1900_1905 <- data.table(tmp)

	# 1906-09
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st0009ts.txt",skip=75,nrows=55,widths=c(19,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1906:1909))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:5] <- apply(tmp[,2:5],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1906_1909 <- data.table(tmp)


	# 1910-1915
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st1019ts.txt",skip=17,nrows=55,widths=c(18,9,9,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1910:1915))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:7] <- apply(tmp[,2:7],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1910_1915 <- data.table(tmp)

	# 1916-19
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st1019ts.txt",skip=75,nrows=55,widths=c(18,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1916:1919))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:5] <- apply(tmp[,2:5],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1916_1919 <- data.table(tmp)


	# 1920-25
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st2029ts.txt",skip=17,nrows=55,widths=c(18,9,9,9,9,9,8),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1920:1925))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:7] <- apply(tmp[,2:7],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1920_1925 <- data.table(tmp)

	# 1926-29
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st2029ts.txt",skip=75,nrows=55,widths=c(18,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1926:1929))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:5] <- apply(tmp[,2:5],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1926_1929 <- data.table(tmp)

	# 1930-35
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st3039ts.txt",skip=17,nrows=55,widths=c(18,9,9,9,9,9,8),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1930:1935))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:7] <- apply(tmp[,2:7],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1930_1935 <- data.table(tmp)

	# 1936-39
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st3039ts.txt",skip=76,nrows=55,widths=c(18,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1936:1939))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:5] <- apply(tmp[,2:5],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1936_1939 <- data.table(tmp)
	
	# 1940-45
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st4049ts.txt",skip=17,nrows=55,widths=c(18,9,9,9,9,9,8),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1940:1945))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:7] <- apply(tmp[,2:7],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1940_1945 <- data.table(tmp)

	# 1936-39
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st4049ts.txt",skip=75,nrows=55,widths=c(18,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1946:1949))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:5] <- apply(tmp[,2:5],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1946_1949 <- data.table(tmp)

	# 1950-54
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st5060ts.txt",skip=17,nrows=61,widths=c(16,8,8,9,9,8,9),strip.white=TRUE,stringsAsFactors=FALSE)
	tmp = tmp[,-2]
	names(tmp) <- c("state",paste0(1950:1954))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:6] <- apply(tmp[,2:6],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1950_1954 <- data.table(tmp)

	# 1955-69
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st5060ts.txt",skip=83,nrows=60,widths=c(16,8,8,9,9,8),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1955:1959))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:6] <- apply(tmp[,2:6],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1955_1959 <- data.table(tmp)

	# 1960-64
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st6070ts.txt",skip=17,nrows=58,widths=c(13,9,9,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	tmp = tmp[,-2]
	names(tmp) <- c("state",paste0(1960:1964))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:6] <- apply(tmp[,2:6],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1960_1964 <- data.table(tmp)

	# 1965-69
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st6070ts.txt",skip=80,nrows=60,widths=c(13,9,9,9,9,9),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1965:1969))
	tmp <- tmp[complete.cases(tmp),]
	tmp[,2:6] <- apply(tmp[,2:6],2,function(x) as.numeric(gsub("\\,","",x)) * 1000)   # data in thousands
	tmp[1,1] <- "US"
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1965_1969 <- data.table(tmp)

	# 1970-75
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st7080ts.txt",skip=14,nrows=52,widths=c(3,3,10,10,10,10,10,10),strip.white=TRUE,stringsAsFactors=FALSE)
	tmp = tmp[,-1]
	names(tmp) <- c("state",paste0(1970:1975))
	tmp <- tmp[complete.cases(tmp),]
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1970_1975 <- data.table(tmp)

	# 1976-79
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st7080ts.txt",skip=67,nrows=52,widths=c(3,3,10,10,10,10),strip.white=TRUE,stringsAsFactors=FALSE)
	tmp = tmp[,-1]
	names(tmp) <- c("state",paste0(1976:1979))
	tmp <- tmp[complete.cases(tmp),]
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1976_1979 <- data.table(tmp)

	# 1980-84
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st8090ts.txt",skip=10,nrows=52,widths=c(2,11,10,10,10,10),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1980:1984))
	tmp <- tmp[complete.cases(tmp),]
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1980_1984 <- data.table(tmp)

	# 1985-89
	tmp <- read.fwf("http://www.census.gov/popest/data/state/asrh/1980s/tables/st8090ts.txt",skip=69,nrows=52,widths=c(2,11,10,10,10,10),strip.white=TRUE,stringsAsFactors=FALSE)
	names(tmp) <- c("state",paste0(1985:1989))
	tmp <- tmp[complete.cases(tmp),]
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	r$y1985_1989 <- data.table(tmp)


	# ----------------
	# long state names
	# ----------------

	l <- list()

	# 1999-1994
	tmp <- read.fwf("http://www.census.gov/popest/data/state/totals/1990s/tables/ST-99-03.txt",skip=13,nrows=65,widths=c(7,27,9,12,12,12,12,12),strip.white=TRUE,stringsAsFactors=FALSE)
	tmp = tmp[,-1]
	names(tmp) <- c("state",paste0(1999:1994))
	tmp <- tmp[complete.cases(tmp),]
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	l$y1999_1994 <- data.table(tmp)

	# 1993-1990
	tmp <- read.fwf("http://www.census.gov/popest/data/state/totals/1990s/tables/ST-99-03.txt",skip=87,nrows=65,widths=c(7,27,9,12,12,12,12),strip.white=TRUE,stringsAsFactors=FALSE)
	tmp = tmp[,-c(1,7)]
	names(tmp) <- c("state",paste0(1993:1990))
	tmp <- tmp[complete.cases(tmp),]
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	l$y1993_1990 <- data.table(tmp)

	# 2000s
	#' http://www.census.gov/popest/data/intercensal/state/tables/ST-EST00INT-01.xls
	tmp <- read_excel(file.path(root,"inst/extdata/census/ST-EST00INT-01.xls"),sheet=1,rowIndex = 4:60,colIndex=c(1,3:12),header = TRUE)
	
	names(tmp) <- c("state",paste0(2000:2009))
	tmp$state = gsub("\\.","",tmp$state)
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	l$y2000s = data.table(tmp)

	# 2010s
	#' http://www.census.gov/popest/data/state/totals/2012/tables/NST-EST2012-01.csv
	tmp <- read.csv("http://www.census.gov/popest/data/national/totals/2015/files/NST-EST2015-alldata.csv",stringsAsFactors=FALSE,header=TRUE)
	tmp = tmp[,-c(1:4,7,8,14:91)]
	names(tmp) <- c("state",paste0(2010:2015))
	tmp <- melt(tmp,"state")
	names(tmp)[c(2,3)] <- c("year","population")
	tmp$year = as.integer(as.character(tmp$year))
	l$y2010s = data.table(tmp)


	l = rbindlist(l)

	l[,STATE := toupper(state)]
	l[,state := NULL]
	setkey(l,STATE)

	data(US_states)
	US_states = US_states[,list(STATE,state)]
	setkey(US_states,STATE)
	l = l[US_states]
	l[,STATE:=NULL]
	setcolorder(l,c(3,1,2))
	r$y9020s <- l

	population = rbindlist(r)

	# throw out some states
	population = population[!state %in% c("AS","GU","PR","VI","West","Midwest","North Central","Northeast","South")]
	setkey(population,state,year)

	save(population,file=file.path(getRoot(),"data","Population.RData"))

	return(population)
}


#' Per Capita annual personal income and per capita disposable income by state for 1949-now
#'
#' data obtained from query to \url{http://bea.gov/iTable}, and
#' \url{http://bea.gov/iTable/iTable.cfm?reqid=70&step=1&isuri=1&acrdn=5}
# and hand cleaned in as \code{inst/extdata/BEA/BEA-SA1.csv} and \code{inst/extdata/BEA/BEA-SA51.csv}
# Both tables are in current dollars
makeBEA_PCincome <- function(){

	p = read.csv(file.path(getRoot(),"inst","extdata","BEA","BEA-SA1.csv"),skip=4,header=TRUE,na.strings="(NA)")

	p = p[,-1]
	names(p)[1] <- c("state")
	names(p)[-1] <- gsub("X","",names(p)[-1])
	p = melt(p,id.vars = "state")
	names(p) = c("STATE","year","income")
	p$STATE = toupper(as.character(p$STATE))
	p$year = as.numeric(as.character(p$year))
	p = data.table(p)
	setkey(p,STATE,year)

	data(US_states)
	US_states = US_states[,list(STATE,state)]
	setkey(US_states,STATE)
	p = p[US_states]
	p[,STATE := NULL]
	pers_income_current = p[!state %in% c("AS","GU","PR","VI")]
	
	# do same for per capita disposable income
	p = read.csv(file.path(getRoot(),"inst","extdata","BEA","BEA-SA51.csv"),skip=4,header=TRUE,na.strings="(NA)")
	p = p[,-1]
	names(p)[1] <- c("state")
	names(p)[-1] <- gsub("X","",names(p)[-1])
	p = melt(p,id.vars = "state")
	names(p) = c("STATE","year","income")
	p$STATE = toupper(as.character(p$STATE))
	p$year = as.numeric(as.character(p$year))
	p = data.table(p)
	setkey(p,STATE,year)
	
	data(US_states)
	US_states = US_states[,list(STATE,state)]
	setkey(US_states,STATE)
	p = p[US_states]
	p[,STATE := NULL]
	dispo_income_current = p[!state %in% c("AS","GU","PR","VI")]

	save(pers_income_current,file=file.path(getRoot(),"data","pers_income_current.RData"))
	save(dispo_income_current,file=file.path(getRoot(),"data","dispo_income_current.RData"))
	return(list(pers_income_current,dispo_income_current))


}

#' Get BEA annual personal income by state for 1949-now
#'
#' data obtained from query to
#' \url{http://www.bea.gov/iTable/iTableHtml.cfm?reqid=70&step=30&isuri=1&7022=36&7023=0&7033=-1&7024=non-industry&7025=0&7026=xx&7027=-1&7001=336&7028=10&7031=0&7040=-1&7083=levels&7029=36&7090=70}
# and hand cleaned in as \code{inst/extdata/BEA/personal_income.csv}
# these are thousands of current dollars
makeBEAincome <- function(){
  
  p = read.csv(file.path(getRoot(),"inst","extdata","BEA","BEA-SQ1.csv"),skip=4,header=TRUE,na.strings="(NA)")
  p = p[,-1]
  names(p)[1] <- c("state")
  names(p)[-1] <- as.yearqtr(gsub("X","",names(p)[-1]),format="%YQ%q")
  p = melt(p,"state")
  names(p) = c("STATE","year.qtr","income")
  p$STATE = toupper(as.character(p$STATE))
  p$year  = floor(as.numeric(as.character(p$year.qtr)))
  p = data.table(p)
  
  p = p[,list(income=mean(income,na.rm=T)),by=list(year,STATE)]
  setkey(p,STATE,year)
  
  data(US_states)
  US_states = US_states[,list(STATE,state)]
  setkey(US_states,STATE)
  p = p[US_states]
  p[,STATE := NULL]
  pers_income = p[!state %in% c("AS","GU","PR","VI")]
  
  save(pers_income,file=file.path(getRoot(),"data","PersonalIncome.RData"))
}


#' get US inflation indexed to a base year
#' 
#' returns US CPI from http://research.stlouisfed.org/fred2/series/CPIAUCSL indexed at idx and at frequency freq = "monthly", "quartrely" or "yearly".
#' @export
#' @examples 
#' getUS_inflation(idx="1996-01-01",freq="monthly")
#' getUS_inflation(idx="1996 Q3",freq="quarterly")
#' getUS_inflation(idx="1996",freq="yearly")
getUS_inflation <- function(idx="2012 Q1",freq="quarterly"){
  data(CPIAUCSL,package="EconData",envir = environment())
  cpi <- CPIAUCSL
  if (freq=="quarterly"){
    cpi <- to.quarterly(cpi)
    cpi <- cpi$cpi.Open
    names(cpi) <- "cpi"
    coredata(cpi) <- coredata(cpi)/as.numeric(cpi[as.yearqtr(idx)])	# base year 2012
    # cpi <- cpi$cpi.Open
    cpi <- data.table(qtr=as.yearqtr(index(cpi)),cpi=as.numeric(cpi),key="qtr")
    
  } else if (freq=="yearly"){
    cpi <- to.yearly(cpi)
    cpi <- cpi$cpi.Open
    names(cpi) <- "cpi"
    coredata(cpi) <- coredata(cpi)/as.numeric(cpi[idx])	# base year 2012
    cpi <- data.table(year=year(index(cpi)),cpi=as.numeric(cpi),key="year")
  } else {
    names(cpi) <- "cpi"
    coredata(cpi) <- coredata(cpi)/as.numeric(cpi[idx])	# base year 2012
    cpi <- data.table(date=as.Date(index(cpi)),cpi=as.numeric(cpi),key="date")
  }
  return(cpi)
}



#' Make state panel for bankruptcy filings
#' @export
make_bankruptcy <- function(){
	# bankruptcy by chapter, state and time
  l = list()
	l$tot = read_excel(file.path(getRoot(),"inst","extdata","AmericanBankruptcyInstitute","state_bankruptcy_foreclosure.xlsx"),sheet="total_nonbusiness filing")
	l$ch7 = read_excel(file.path(getRoot(),"inst","extdata","AmericanBankruptcyInstitute","state_bankruptcy_foreclosure.xlsx"),sheet="chapter 7")
	l$ch7_rate = read_excel(file.path(getRoot(),"inst","extdata","AmericanBankruptcyInstitute","state_bankruptcy_foreclosure.xlsx"),sheet="chap 7 filing rate")
	l$ch13 = read_excel(file.path(getRoot(),"inst","extdata","AmericanBankruptcyInstitute","state_bankruptcy_foreclosure.xlsx"),sheet="chapter13 filings")
	l$ch13_rate = read_excel(file.path(getRoot(),"inst","extdata","AmericanBankruptcyInstitute","state_bankruptcy_foreclosure.xlsx"),sheet="chapter 13 filing rate")
	l$fore_rate = read_excel(file.path(getRoot(),"inst","extdata","AmericanBankruptcyInstitute","state_bankruptcy_foreclosure.xlsx"),sheet="foreclosure start rate")
	l$fore_rate$V52 <- NULL
	l$pop_count = read_excel(file.path(getRoot(),"inst","extdata","AmericanBankruptcyInstitute","state_bankruptcy_foreclosure.xlsx"),sheet="resident population")

	
	# fix names
	n <- lapply(l,names)
	n$fore_rate <- gsub("L14F@MBAMTG","",n$fore_rate)
	n$tot <- gsub("NB@BANKRUPT","",n$tot)
	n$ch7 <- gsub("NB7@BANKRUPT","",n$ch7)
	n$ch13 <- gsub("NB3@BANKRUPT","",n$ch13)
	n$ch13_rate <- n$ch13
	n$ch7_rate <- n$ch7
	n$pop_count <- gsub("RBT@USPOP","",n$pop_count)
	
	# change names, drop first row, convert to numeric
	for (nn in names(l)){
	  names(l[[nn]]) <- n[[nn]]
	  l[[nn]] <- l[[nn]][-1, ]
	  names(l[[nn]])[1] <- "year"
	  l[[nn]] <- as.data.frame(sapply(l[[nn]],as.numeric))
	}
	m <- lapply(l,function(x){melt(x,id.vars=c("year"),variable.name = "state")})
	
	# save
	ABI_tot       = l$tot
	ABI_ch7       = l$ch7
	ABI_ch13      = l$ch13
	ABI_ch7_rate  = l$ch7_rate
	ABI_ch13_rate = l$ch13_rate
	MBA_fore_rate = l$fore_rate
	Fed_pop_count = l$pop_count
	MBA_fore_rate$V52 <- NULL
	
	cat("saving now bk\n")
	
	save(ABI_tot,file=file.path(getRoot(),"data","ABI_tot.RData"))
	save(ABI_ch7      ,file=file.path(getRoot(),"data","ABI_ch7.RData"))
	save(ABI_ch13     ,file=file.path(getRoot(),"data","ABI_ch13.RData"))
	save(ABI_ch7_rate ,file=file.path(getRoot(),"data","ABI_ch7_rate.RData"))
	save(ABI_ch13_rate,file=file.path(getRoot(),"data","ABI_ch13_rate.RData"))
	save(MBA_fore_rate,file=file.path(getRoot(),"data","MBA_fore_rate.RData"))
	save(Fed_pop_count,file=file.path(getRoot(),"data","Fed_pop_count.RData"))
	
}





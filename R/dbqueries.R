# common database queries
highScores <- function(what="user_name,score_1",order = "score_1", n=150,db="nihnetworks") {
	require(RPostgreSQL)
	drv <- dbDriver("PostgreSQL")
	con <- dbConnect(drv, dbname=db)
	t <- 2
	result <- matrix()
	while (nrow(result)<25 && t<24) {
		query <- paste("select ", what, " from networks WHERE n_node = ",n," AND network_date > (NOW() - INTERVAL '",t," hour') AND score_1 > 0.8 ORDER BY ",order," DESC LIMIT 25",sep="")
		result <- dbGetQuery(con,query)
		t = t+1
	}
	lapply(dbListConnections(drv),function(i)dbDisconnect(i))
	dbUnloadDriver(drv)
	return(list(result)[[1]])
}

getHigh <- function(what,by,db="nihnetworks",n=150) {
	require(RPostgreSQL)
	drv <- dbDriver("PostgreSQL")
	con <- dbConnect(drv, dbname=db)
	query <- paste("select ", what, " from networks where ", by, " = (select max(", by ,") from networks WHERE n_node = ",n,") AND n_node = ",n," LIMIT 1",sep="")
	result <- dbGetQuery(con,query)
	lapply(dbListConnections(drv),function(i)dbDisconnect(i))
	dbUnloadDriver(drv)
	return(list(result))
}

getLow <- function(what,by,db="nihnetworks",n=150) {
	require(RPostgreSQL)
	drv <- dbDriver("PostgreSQL")
	con <- dbConnect(drv, dbname=db)
	query <- paste("select ", what, " from networks where ", by, " = (select min(", by ,") from networks WHERE n_node = ",n,") AND n_node = ",n," LIMIT 1",sep="")
	result <- dbGetQuery(con,query)
	lapply(dbListConnections(drv),function(i)dbDisconnect(i))
	dbUnloadDriver(drv)
	return(list(result))
}

getYours <- function(what,by="network_id",db="nihnetworks") {
	require(RPostgreSQL)
	drv <- dbDriver("PostgreSQL")
	con <- dbConnect(drv, dbname=db)
	query <- paste("select ", what, " from networks order by network_id desc limit 1",sep="")
	result <- dbGetQuery(con,query)
	lapply(dbListConnections(drv),function(i)dbDisconnect(i))
	dbUnloadDriver(drv)
	return(list(result))
}

getAll <- function(what,db="nihnetworks",n=150) {
	require(RPostgreSQL)
	drv <- dbDriver("PostgreSQL")
	con <- dbConnect(drv, dbname=db)
	query <- paste("select ", what, " from networks where n_node =",n,"ORDER BY network_id",sep="")
	result <- dbGetQuery(con,query)
	lapply(dbListConnections(drv),function(i)dbDisconnect(i))
	dbUnloadDriver(drv)
	return(list(result))
}

compileBasicStatsHist <- function(what,by,db="nihnetworks",hist=F,bins=20,n=150){
		# compile all vs your score for a measure
		# format for JSON and plotting in nvd3
		require(RPostgreSQL)
		options(stringsAsFactors=FALSE)
		high = as.numeric(sapply(getHigh(what,by,n=n)[[1]][[1]],strsplit,split=",")[[1]])
		low = as.numeric(sapply(getLow(what,by,n=n)[[1]][[1]],strsplit,split=",")[[1]])
		yours = as.numeric(sapply(getYours(what)[[1]],strsplit,split=",")[[1]])
		x <- seq(min(high,low,yours),max(high,low,yours),1)
		# format vals
		if (hist) {
			high_hist <- hist(high,bins)
			high_f <- cbind(high_hist$mids,high_hist$counts); colnames(high_f) <- c("x","y")
			high_f <- data.frame(high_f)
			low_hist <- hist(low,bins)
			low_f <- cbind(low_hist$mids,low_hist$counts); colnames(low_f) <- c("x","y")
			low_f <- data.frame(low_f)
			yours_hist <- hist(yours,bins)
			yours_f <- cbind(yours_hist$mids,yours_hist$counts); colnames(yours_f) <- c("x","y")
			yours_f <- data.frame(yours_f)
		} else {
			f_tmp <- data.frame(cbind(x,0)); colnames(f_tmp) = c("x","y")
			high_f <- f_tmp
			high_f[,2] <- sapply(high_f[,1],function(i){sum(high==i)})
			low_f <- f_tmp
			low_f[,2] <- sapply(low_f[,1],function(i){sum(low==i)})
			yours_f <- f_tmp
			yours_f[,2] <- sapply(yours_f[,1],function(i){sum(yours==i)})
		}
		to.r <- data.frame(key = c("Your Network","Highest Scoring Network","Lowest Scoring Network"))
		to.r$values = list(yours_f,high_f,low_f)
		return(to.r)
}


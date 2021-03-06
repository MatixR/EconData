% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/doc_bankruptcy.r
\docType{data}
\name{ABI_ch13_rate}
\alias{ABI_ch13_rate}
\title{Chapter 13 bankruptcy Rate by State}
\format{Data frame with one column per state. Data are percent of local population in bankruptcy. The rates are obtained by dividing \code{\link{ABI_ch13}} by \code{\link{Fed_pop_count}}.}
\source{
\url{http://www.abi.org/newsroom/bankruptcy-statistics}, but syndicated via the Federal Reserve System, so more data than contained in the public website.
}
\usage{
data(ABI_ch13_rate)
}
\description{
Annual dataset of the Chapter 13 bankruptcy Rate for 1991-2016 by US state. The Rate is defined in percent of local population. I.e. a value of 0.27 means that 0.27% of the population of a given state in a given year is in chapter 13 bankruptcy.
}
\author{
Florian Oswald
}
\keyword{datasets}


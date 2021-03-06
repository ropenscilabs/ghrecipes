# function for iterating a query
# only works for a query with one cursor and one hasNextPage
iterate <- function(query) {
  out <- ""
  last_cursor <- ""
  hasNextPage <- TRUE
  i <- 0
  while (hasNextPage) {
    i <- i + 1
    qry <- ghql::Query$new()
    qry$query('foobar', sprintf(query, last_cursor))
    res <- create_client()$exec(qry$queries$foobar)
    if(stringr::str_detect(res, "\\{\"data\":null,\"errors\"")) {
      res_json <- jsonlite::fromJSON(res)
      stop(res_json$errors$message)
    }
    last_cursor <- jqr::jq(res, "[..|.cursor?|select(.!=null)][-1]")
    last_cursor <- paste0 (", after: ", last_cursor)
    hasNextPage <- as.logical(jqr::jq(res, "..|.hasNextPage?|select(.!=null)"))
    if(length(hasNextPage) == 0){
      stop("Invalid query detected. Does the specified owner and/or repo exist?")
    }
    out <- paste0(out, res)
  }
  return(out)
}

#check for token; some calls work only with specific scopes
get_token <- function() {
  token <- Sys.getenv("GITHUB_GRAPHQL_TOKEN")
  if(token == ""){
    token <- Sys.getenv("GITHUB_TOKEN", Sys.getenv("GITHUB_PAT"))
  }
  if(token == ""){
    stop("Please set your GITHUB_GRAPHQL_TOKEN environment variable.")
  }
  return(token)
}

# function for creating the client
# it first checks whether there's a token
# and then only creates the client if it doesn't already exist
create_client <- function(){
  token <- get_token()

  if(!exists("ghql_gh_cli")){
    ghql_gh_cli <- ghql::GraphqlClient$new(
      url = "https://api.github.com/graphql",
      headers = list(Authorization = paste0("Bearer ", token))
    )
    ghql_gh_cli$load_schema()
    ghql_gh_cli <<- ghql_gh_cli

  }
  return(ghql_gh_cli)
}

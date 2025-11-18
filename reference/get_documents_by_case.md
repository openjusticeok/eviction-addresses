# Get Documents by Case

Get all documents for a given case

## Usage

``` r
get_documents_by_case(db, id)
```

## Arguments

- db:

  A database connection pool created with
  [`pool::dbPool`](http://rstudio.github.io/pool/reference/dbPool.md)

- id:

  The id of the case for which to return documents

## Value

A data.frame of documents

Tests and Coverage
================
08 September, 2022 13:59:59

-   <a href="#coverage" id="toc-coverage">Coverage</a>
-   <a href="#unit-tests" id="toc-unit-tests">Unit Tests</a>

This output is created by
[covrpage](https://github.com/yonicd/covrpage).

## Coverage

Coverage summary is created using the
[covr](https://github.com/r-lib/covr) package.

    ## ⚠️ Not All Tests Passed
    ##   Coverage statistics are approximations of the non-failing tests.
    ##   Use with caution
    ## 
    ##  For further investigation check in testthat summary tables.

| Object                                                    | Coverage (%) |
|:----------------------------------------------------------|:------------:|
| evictionAddresses                                         |    13.78     |
| [R/add_session_to_db.R](../R/add_session_to_db.R)         |     0.00     |
| [R/boto3.R](../R/boto3.R)                                 |     0.00     |
| [R/dashboard_server.R](../R/dashboard_server.R)           |     0.00     |
| [R/dashboard_ui.R](../R/dashboard_ui.R)                   |     0.00     |
| [R/get_case_from_queue.R](../R/get_case_from_queue.R)     |     0.00     |
| [R/get_documents_by_case.R](../R/get_documents_by_case.R) |     0.00     |
| [R/get_sessions_from_db.R](../R/get_sessions_from_db.R)   |     0.00     |
| [R/get_users_from_db.R](../R/get_users_from_db.R)         |     0.00     |
| [R/handle_hydrate.R](../R/handle_hydrate.R)               |     0.00     |
| [R/handle_pings.R](../R/handle_pings.R)                   |     0.00     |
| [R/handle_refresh.R](../R/handle_refresh.R)               |     0.00     |
| [R/new_db_connection.R](../R/new_db_connection.R)         |     0.00     |
| [R/run_api.R](../R/run_api.R)                             |     0.00     |
| [R/run_dashboard.R](../R/run_dashboard.R)                 |     0.00     |
| [R/zzz.R](../R/zzz.R)                                     |     0.00     |
| [R/mturk.R](../R/mturk.R)                                 |    45.73     |
| [R/postgrid.R](../R/postgrid.R)                           |    46.34     |
| [R/utils.R](../R/utils.R)                                 |    64.71     |

<br>

## Unit Tests

Unit Test summary is created using the
[testthat](https://github.com/r-lib/testthat) package.

| file                                        |   n |  time | error | failed | skipped | warning | icon |
|:--------------------------------------------|----:|------:|------:|-------:|--------:|--------:|:-----|
| [test-boto3.R](testthat/test-boto3.R)       |   1 | 0.019 |     0 |      0 |       0 |       0 |      |
| [test-mturk.R](testthat/test-mturk.R)       |  15 | 1.241 |     1 |      1 |       0 |       0 | 🛑   |
| [test-postgrid.R](testthat/test-postgrid.R) |   4 | 0.051 |     0 |      0 |       0 |       0 |      |
| [test-utils.R](testthat/test-utils.R)       |   2 | 0.004 |     0 |      0 |       0 |       0 |      |

<details open>
<summary>
Show Detailed Test Results
</summary>

| file                                                | context  | test                                                              | status |   n |  time |
|:----------------------------------------------------|:---------|:------------------------------------------------------------------|:-------|----:|------:|
| [test-boto3.R](testthat/test-boto3.R#L2)            | boto3    | multiplication works                                              | PASS   |   1 | 0.019 |
| [test-mturk.R](testthat/test-mturk.R#L15)           | mturk    | MTurk auth succeeds with valid config                             | PASS   |   1 | 0.004 |
| [test-mturk.R](testthat/test-mturk.R#L28)           | mturk    | MTurk auth fails on no config or env variables                    | PASS   |   1 | 0.002 |
| [test-mturk.R](testthat/test-mturk.R#L36_L39)       | mturk    | Create HIT Type works as expected                                 | PASS   |   1 | 0.799 |
| [test-mturk.R](testthat/test-mturk.R#L50_L53)       | mturk    | Create HIT Type fails with no aws keys                            | PASS   |   1 | 0.019 |
| [test-mturk.R](testthat/test-mturk.R#L62)           | mturk    | Create HIT Type returns a string                                  | PASS   |   1 | 0.325 |
| [test-mturk.R](testthat/test-mturk.R#L71)           | mturk    | Create HIT Type fails on bad response from pyMTurkR               | PASS   |   6 | 0.038 |
| [test-mturk.R](testthat/test-mturk.R#L115)          | mturk    | Create HIT Type returns correct value with mock pyMTurkR response | PASS   |   1 | 0.036 |
| [test-mturk.R](testthat/test-mturk.R#L120)          | mturk    | Render document links rejects args correctly                      | ERROR  |   2 | 0.016 |
| [test-mturk.R](testthat/test-mturk.R#L135_L138)     | mturk    | Render documents returns expected value with sample links         | PASS   |   1 | 0.002 |
| [test-postgrid.R](testthat/test-postgrid.R#L38)     | postgrid | postgrid formatting succeeds with line vars                       | PASS   |   1 | 0.015 |
| [test-postgrid.R](testthat/test-postgrid.R#L65)     | postgrid | postgrid formatting succeeds with street vars                     | PASS   |   1 | 0.003 |
| [test-postgrid.R](testthat/test-postgrid.R#L69_L78) | postgrid | postgrid formatting fails with line and street vars               | PASS   |   1 | 0.017 |
| [test-postgrid.R](testthat/test-postgrid.R#L82_L88) | postgrid | postgrid formatting errors with neither vars                      | PASS   |   1 | 0.016 |
| [test-utils.R](testthat/test-utils.R#L8)            | utils    | Has names works as expected                                       | PASS   |   1 | 0.002 |
| [test-utils.R](testthat/test-utils.R#L13)           | utils    | Has names fails as expected                                       | PASS   |   1 | 0.002 |

</details>
<details>
<summary>
Session Info
</summary>

| Field    | Value                        |
|:---------|:-----------------------------|
| Version  | R version 4.2.1 (2022-06-23) |
| Platform | x86_64-pc-linux-gnu (64-bit) |
| Running  | Arch Linux                   |
| Language | en_US                        |
| Timezone | America/New_York             |

| Package  | Version |
|:---------|:--------|
| testthat | 3.1.4   |
| covr     | 3.6.1   |
| covrpage | 0.1     |

</details>
<!--- Final Status : error/failed --->

Tests and Coverage
================
28 November, 2022 23:45:21

- <a href="#coverage" id="toc-coverage">Coverage</a>
- <a href="#unit-tests" id="toc-unit-tests">Unit Tests</a>

This output is created by
[covrpage](https://github.com/yonicd/covrpage).

## Coverage

Coverage summary is created using the
[covr](https://github.com/r-lib/covr) package.

| Object                                                        | Coverage (%) |
|:--------------------------------------------------------------|:------------:|
| evictionAddresses                                             |     9.36     |
| [R/case.R](../R/case.R)                                       |     0.00     |
| [R/dashboard_auth.R](../R/dashboard_auth.R)                   |     0.00     |
| [R/dashboard_server.R](../R/dashboard_server.R)               |     0.00     |
| [R/dashboard_ui.R](../R/dashboard_ui.R)                       |     0.00     |
| [R/db.R](../R/db.R)                                           |     0.00     |
| [R/document.R](../R/document.R)                               |     0.00     |
| [R/handle_address_validate.R](../R/handle_address_validate.R) |     0.00     |
| [R/handle_pings.R](../R/handle_pings.R)                       |     0.00     |
| [R/handle_refresh.R](../R/handle_refresh.R)                   |     0.00     |
| [R/minute.R](../R/minute.R)                                   |     0.00     |
| [R/queue.R](../R/queue.R)                                     |     0.00     |
| [R/run_api.R](../R/run_api.R)                                 |     0.00     |
| [R/run_dashboard.R](../R/run_dashboard.R)                     |     0.00     |
| [R/zzz.R](../R/zzz.R)                                         |     0.00     |
| [R/postgrid.R](../R/postgrid.R)                               |    44.19     |
| [R/utils.R](../R/utils.R)                                     |    62.96     |

<br>

## Unit Tests

Unit Test summary is created using the
[testthat](https://github.com/r-lib/testthat) package.

| file                                        |   n |  time | error | failed | skipped | warning |
|:--------------------------------------------|----:|------:|------:|-------:|--------:|--------:|
| [test-postgrid.R](testthat/test-postgrid.R) |   4 | 0.329 |     0 |      0 |       0 |       0 |
| [test-utils.R](testthat/test-utils.R)       |   6 | 0.147 |     0 |      0 |       0 |       0 |

<details closed>
<summary>
Show Detailed Test Results
</summary>

| file                                                | context  | test                                                | status |   n |  time |
|:----------------------------------------------------|:---------|:----------------------------------------------------|:-------|----:|------:|
| [test-postgrid.R](testthat/test-postgrid.R#L38)     | postgrid | postgrid formatting succeeds with line vars         | PASS   |   1 | 0.195 |
| [test-postgrid.R](testthat/test-postgrid.R#L65)     | postgrid | postgrid formatting succeeds with street vars       | PASS   |   1 | 0.024 |
| [test-postgrid.R](testthat/test-postgrid.R#L69_L78) | postgrid | postgrid formatting fails with line and street vars | PASS   |   1 | 0.070 |
| [test-postgrid.R](testthat/test-postgrid.R#L82_L88) | postgrid | postgrid formatting errors with neither vars        | PASS   |   1 | 0.040 |
| [test-utils.R](testthat/test-utils.R#L8)            | utils    | Has names works as expected                         | PASS   |   1 | 0.004 |
| [test-utils.R](testthat/test-utils.R#L13)           | utils    | Has names fails as expected                         | PASS   |   1 | 0.003 |
| [test-utils.R](testthat/test-utils.R#L23)           | utils    | Lat/Lon match test works                            | PASS   |   4 | 0.140 |

</details>
<details>
<summary>
Session Info
</summary>

| Field    | Value                            |
|:---------|:---------------------------------|
| Version  | R version 4.2.1 (2022-06-23)     |
| Platform | x86_64-apple-darwin17.0 (64-bit) |
| Running  | macOS Ventura 13.0.1             |
| Language | en_US                            |
| Timezone | America/Detroit                  |

| Package  | Version |
|:---------|:--------|
| testthat | 3.1.4   |
| covr     | 3.6.1   |
| covrpage | 0.1     |

</details>
<!--- Final Status : pass --->

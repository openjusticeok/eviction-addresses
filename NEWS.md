<!-- NEWS.md is maintained by https://cynkra.github.io/fledge, do not edit -->

# evictionAddresses 0.1.0

## New Features
- Updated `get_pay_period()` function with improved weekly default behavior
- Added flexible `period` parameter supporting lubridate-style period strings
- Changed default pay period from bi-weekly (14 days) to weekly (7 days)  
- Updated pay periods to use Sunday-Saturday schedule (start date changed from 2023-01-02 to 2023-01-01)
- Added comprehensive test coverage for `get_pay_period()` function with 23 test cases

## Improvements
- Maintains full backward compatibility with existing code
- Enhanced documentation for pay period functions

# evictionAddresses 0.0.0.9003
- Removed Amazon MTurk integration
- Cleaned and updated dependencies

# evictionAddresses 0.0.0.9002
- Added `boto3` Python library detection and installation

# evictionAddresses 0.0.0.9001
- Added tests for `mturk.R` functions
- Added `{webmockr}` and `{vcr}` as `Suggests` in `DESCRIPTION`

# evictionAddresses 0.0.0.9000

- Added a `NEWS.md` file to track changes to the package.

# Setting Up Coverage Reporting with GitHub Actions

This document explains how to set up the coverage reporting workflow with GitHub Actions.

## Prerequisites

1. A GitHub repository with your Solidity smart contracts
2. A GitHub account with permissions to manage the repository

## Workflow File

The workflow file is already set up in `.github/workflows/test-coverage.yml`. It will:

1. Run on pull requests to the `master` branch
2. Run tests and generate a coverage report
3. Check if coverage meets the minimum thresholds
4. Comment on the pull request with the coverage results

## Error Handling

The workflow includes robust error handling to deal with potential issues:

- Checks if the coverage.json file exists
- Validates the structure of the coverage data
- Provides fallbacks for missing metrics
- Logs detailed information for debugging

If the coverage report cannot be generated or parsed correctly, the workflow will fail with a descriptive error message.

## Customizing Thresholds

You can customize the coverage thresholds in the workflow file:

```yaml
# Define minimum thresholds
MIN_STATEMENTS=85
MIN_BRANCHES=60
MIN_FUNCTIONS=80
MIN_LINES=85
```

Adjust these values based on your project's requirements.

## Coverage Report

The workflow generates a detailed coverage report and uploads it as an artifact. You can view this report by:

1. Going to the GitHub Actions run
2. Clicking on the "Artifacts" section
3. Downloading the "coverage-report" artifact

For pull requests, a comment will be added with a summary of the coverage metrics and whether they pass the thresholds.

## Troubleshooting

If you encounter issues with the workflow:

1. Check the GitHub Actions logs for error messages
2. Make sure your tests are properly configured
3. Verify that the coverage report is being generated correctly
4. Look for the "Coverage JSON structure" output in the logs to understand the format of your coverage data

For more information, refer to the [GitHub Actions documentation](https://docs.github.com/en/actions). 
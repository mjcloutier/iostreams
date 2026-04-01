# Code Coverage with SimpleCov

This project uses [SimpleCov](https://github.com/simplecov-ruby/simplecov) to track code coverage and ensure comprehensive testing.

## Quick Start

### Run Tests with Coverage Analysis
```bash
# Generate coverage report
rake coverage

# Open coverage report in browser (macOS)
rake coverage_open
```

### Manual Usage
```bash
# Set environment variable and run tests
COVERAGE=true rake test

# Or using bundle exec
COVERAGE=true bundle exec rake test
```

## Coverage Reports

### Current Coverage
- **Total Coverage**: 33.33% (393 of 1179 lines)
- **Location**: `coverage/index.html`
- **Groups**: Core, Paths, Tabular modules

### Coverage Thresholds
- **Minimum overall coverage**: 80%
- **Minimum per-file coverage**: 60%

*Note: Current coverage is below thresholds - this indicates areas needing more tests.*

## Understanding the Report

The HTML report provides:

1. **Overview**: Total coverage percentage and line counts
2. **File List**: Coverage percentage for each file
3. **Group View**: Coverage organized by logical code groups
4. **Detailed View**: Line-by-line coverage showing:
   - ✅ **Green lines**: Covered by tests
   - ❌ **Red lines**: Not covered by tests
   - **Gray lines**: Non-executable (comments, end statements)

## Coverage Groups

- **Core**: Main IOStreams functionality (`lib/io_streams/`)
- **Paths**: Path handling implementations (`lib/io_streams/paths/`)
- **Tabular**: Data parsing and formatting (`lib/io_streams/tabular/`)

## Improving Coverage

### Find Untested Code
1. Open `coverage/index.html` in a browser
2. Click on files with low coverage percentages
3. Look for red (uncovered) lines
4. Write tests for those code paths

### Focus Areas
Based on current coverage, prioritize:
1. Files with 0% or very low coverage
2. Critical path functionality
3. Error handling code
4. Edge cases and boundary conditions

## Integration with CI

The coverage tool is configured to run automatically when:
- `ENV["COVERAGE"]` is set to "true"
- `ENV["CI"]` is present (CI environments)

Add this to your CI pipeline:
```yaml
# Example for GitHub Actions
- name: Run tests with coverage
  run: |
    COVERAGE=true bundle exec rake test
```

## Configuration

Coverage settings are in `test/test_helper.rb`:

```ruby
SimpleCov.start do
  add_group "Core", "lib/io_streams"
  add_group "Paths", "lib/io_streams/paths"
  add_group "Tabular", "lib/io_streams/tabular"
  
  add_filter "/test/"
  add_filter "/vendor/"
  add_filter "version.rb"
  
  minimum_coverage 80
  minimum_coverage_by_file 60
end
```

## Troubleshooting

### Coverage Not Generated
- Ensure `COVERAGE=true` environment variable is set
- Check that SimpleCov gem is installed: `bundle install`

### Tests Pass but Coverage Fails
- Coverage thresholds may be set too high
- Adjust thresholds in `test/test_helper.rb`

### Files Missing from Report
- Check SimpleCov filters in `test/test_helper.rb`
- Ensure files are loaded during test execution

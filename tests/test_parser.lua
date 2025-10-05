--- Tests for parser module
-- @module tests.test_parser

package.path = "./lua/?.lua;./tests/?.lua;" .. package.path

local test_framework = require("tests.init")
local fixtures = require("tests.fixtures.sample_docs")

-- Setup test environment
test_framework.setup_vim_mock()

local parser = require("terrareg.parser")

local function test_extract_description()
  local description = parser.extract_description(fixtures.aws_s3_bucket_markdown)
  test_framework.assert_equal(
    "Provides a S3 bucket resource.",
    description,
    "Should extract correct description"
  )
end

local function test_extract_arguments()
  local arguments = parser.extract_arguments(fixtures.aws_s3_bucket_markdown)

  test_framework.assert_equal(5, #arguments, "Should extract 5 arguments")

  -- Test first argument
  local bucket_arg = arguments[1]
  test_framework.assert_equal("bucket", bucket_arg.name, "First argument should be 'bucket'")
  test_framework.assert_equal("Optional", bucket_arg.required, "Bucket should be Optional")
  test_framework.assert_true(bucket_arg.forces_new, "Bucket should force new resource")

  -- Test argument with default value
  local force_destroy_arg = arguments[3]
  test_framework.assert_equal(
    "force_destroy",
    force_destroy_arg.name,
    "Third argument should be 'force_destroy'"
  )
  test_framework.assert_equal(
    "false",
    force_destroy_arg.default,
    "force_destroy should have default 'false'"
  )
  test_framework.assert_false(
    force_destroy_arg.forces_new,
    "force_destroy should not force new resource"
  )
end

local function test_extract_examples()
  local examples = parser.extract_examples(fixtures.aws_s3_bucket_markdown)

  test_framework.assert_true(#examples > 0, "Should extract at least one example")
  test_framework.assert_true(
    examples[1]:match('resource "aws_s3_bucket"'),
    "Example should contain resource declaration"
  )
end

local function test_extract_description_aws_instance()
  local description = parser.extract_description(fixtures.aws_instance_markdown)
  test_framework.assert_true(
    description:match("Provides an EC2 instance resource"),
    "Should extract EC2 instance description"
  )
end

-- Run all parser tests
local function run_parser_tests()
  print("=== Running Parser Tests ===")
  test_framework.reset()

  test_framework.run_test("extract_description", test_extract_description)
  test_framework.run_test("extract_arguments", test_extract_arguments)
  test_framework.run_test("extract_examples", test_extract_examples)
  test_framework.run_test("extract_description_aws_instance", test_extract_description_aws_instance)

  test_framework.print_results()
end

-- Export test runner
return {
  run = run_parser_tests,
}

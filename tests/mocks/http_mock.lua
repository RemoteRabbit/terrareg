--- HTTP mock for testing
-- @module tests.mocks.http_mock

local fixtures = require("tests.fixtures.sample_docs")

local M = {}

-- Mock responses for different URLs
M.responses = {
  ["https://registry.terraform.io/v1/providers/hashicorp/aws/versions"] = {
    body = fixtures.provider_versions_json,
    code = 200,
  },
  ["https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/website/docs/r/s3_bucket.html.markdown"] = {
    body = fixtures.aws_s3_bucket_markdown,
    code = 200,
  },
  ["https://raw.githubusercontent.com/hashicorp/terraform-provider-aws/main/website/docs/r/instance.html.markdown"] = {
    body = fixtures.aws_instance_markdown,
    code = 200,
  },
  ["https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/aws_s3_bucket"] = {
    body = "<html><head><title>Terraform Registry</title></head><body>JavaScript required</body></html>",
    code = 200,
  },
}

-- Mock network delays
M.delays = {}

-- Mock failures
M.failures = {}

--- Set a mock response for a URL
function M.set_response(url, response)
  M.responses[url] = response
end

--- Set a mock failure for a URL
function M.set_failure(url, error_message)
  M.failures[url] = error_message
end

--- Set a mock delay for a URL
function M.set_delay(url, delay_ms)
  M.delays[url] = delay_ms
end

--- Mock HTTP get function
function M.get(url, callback)
  -- Simulate network delay if configured
  local delay = M.delays[url] or 0
  if delay > 0 then
    vim.defer_fn(function()
      M._handle_request(url, callback)
    end, delay)
  else
    M._handle_request(url, callback)
  end
end

--- Handle the actual mock request
function M._handle_request(url, callback)
  -- Check for configured failure
  if M.failures[url] then
    callback(false, nil, M.failures[url])
    return
  end

  -- Return mock response if available
  local response = M.responses[url]
  if response then
    callback(true, response, nil)
  else
    callback(false, nil, "Mock: URL not found: " .. url)
  end
end

--- Mock synchronous HTTP get
function M.get_sync(url)
  local result = {}
  local done = false

  M.get(url, function(success, response, error)
    result.success = success
    result.response = response
    result.error = error
    done = true
  end)

  -- Simulate waiting for async operation
  local attempts = 0
  while not done and attempts < 100 do
    attempts = attempts + 1
    if attempts > 50 then
      break
    end -- Prevent infinite loop
  end

  return result.success, result.response, result.error
end

--- Reset all mocks
function M.reset()
  M.responses = {}
  M.delays = {}
  M.failures = {}
end

return M

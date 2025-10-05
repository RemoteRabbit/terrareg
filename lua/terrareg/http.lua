--- HTTP client for terrareg.nvim
-- @module terrareg.http

local M = {}

--- Check if curl is available
-- @return boolean True if curl is available
local function is_curl_available()
  local handle = io.popen("which curl 2>/dev/null")
  local result = handle:read("*a")
  handle:close()
  return result and result:gsub("%s+", "") ~= ""
end

--- Make an HTTP GET request using curl
-- @param url string The URL to fetch
-- @param callback function Callback function that receives (success, response, error)
function M.get(url, callback)
  -- Check if curl is available
  if not is_curl_available() then
    callback(false, nil, "curl command not found. Please install curl to fetch documentation.")
    return
  end

  local curl_cmd = string.format(
    'curl -s -w "%%{http_code}" -H "User-Agent: TerraregNvim/1.0" '
      .. '-H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" '
      .. '-L --max-time 30 "%s"',
    url
  )

  local stdout_data = {}
  local stderr_data = {}

  -- Debug output
  if vim.g.terrareg_debug then
    print("HTTP Request: " .. url)
    print("Curl command: " .. curl_cmd)
  end

  local job_id = vim.fn.jobstart(curl_cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, exit_code)
      if vim.g.terrareg_debug then
        print("Curl exit code: " .. exit_code)
        print("Stdout lines: " .. #stdout_data)
        print("Stderr lines: " .. #stderr_data)
      end

      -- Handle curl exit codes with more specific messages
      if exit_code ~= 0 then
        local error_msg = "curl failed with exit code: " .. exit_code
        if exit_code == 6 then
          error_msg = error_msg .. " (Could not resolve host)"
        elseif exit_code == 7 then
          error_msg = error_msg .. " (Failed to connect to host)"
        elseif exit_code == 28 then
          error_msg = error_msg .. " (Operation timeout)"
        elseif exit_code == 35 then
          error_msg = error_msg .. " (SSL connect error)"
        elseif #stderr_data > 0 then
          error_msg = error_msg .. " - " .. table.concat(stderr_data, "\n")
        end
        callback(false, nil, error_msg)
        return
      end

      -- Process stdout data
      if #stdout_data == 0 then
        callback(false, nil, "No data received from curl")
        return
      end

      local full_response = table.concat(stdout_data, "\n")

      if vim.g.terrareg_debug then
        print("Response length: " .. #full_response)
        print("Response preview: " .. full_response:sub(1, 200) .. "...")
      end

      -- Extract HTTP status code (last 3 characters)
      if #full_response < 3 then
        callback(false, nil, "Invalid response from server")
        return
      end

      local status_code = string.sub(full_response, -3)
      local body = string.sub(full_response, 1, -4)

      local status_num = tonumber(status_code)
      if not status_num then
        callback(false, nil, "Could not parse HTTP status code: " .. status_code)
        return
      end

      if status_num >= 200 and status_num < 300 then
        callback(true, { body = body, code = status_num }, nil)
      elseif status_num == 404 then
        callback(false, nil, "Documentation not found (HTTP 404)")
      elseif status_num == 500 then
        callback(false, nil, "Server error (HTTP 500)")
      else
        callback(false, nil, "HTTP request failed with status code: " .. status_code)
      end
    end,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_data, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_data, line)
          end
        end
      end
    end,
  })

  if job_id == 0 then
    callback(false, nil, "Failed to start curl process")
    return
  end

  if vim.g.terrareg_debug then
    print("Started curl job with ID: " .. job_id)
  end
end

--- Make a synchronous HTTP GET request
-- @param url string The URL to fetch
-- @return boolean success, table|nil response, string|nil error
function M.get_sync(url)
  local result = {}
  local done = false

  M.get(url, function(success, response, error)
    result.success = success
    result.response = response
    result.error = error
    done = true
  end)

  -- Wait for completion (with timeout)
  local timeout = 30000 -- 30 seconds
  local start_time = vim.loop.now()

  while not done and (vim.loop.now() - start_time) < timeout do
    vim.wait(10)
  end

  if not done then
    return false, nil, "Request timeout"
  end

  return result.success, result.response, result.error
end

return M

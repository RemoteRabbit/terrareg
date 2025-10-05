--- Smart caching system for terrareg.nvim
-- @module terrareg.cache

local M = {}

-- Cache configuration
M.config = {
  ttl = 3600, -- Time to live in seconds (1 hour)
  max_entries = 1000, -- Maximum cache entries
  cache_dir = vim.fn.stdpath("cache") .. "/terrareg",
}

-- In-memory cache
M.memory_cache = {}

-- Cache statistics
M.stats = {
  hits = 0,
  misses = 0,
  total_requests = 0,
}

--- Initialize cache system
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Create cache directory
  vim.fn.mkdir(M.config.cache_dir, "p")
end

--- Generate cache key for a resource
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param version string|nil Provider version
-- @return string Cache key
local function generate_cache_key(resource_type, resource_name, version)
  version = version or "latest"
  return string.format("%s_%s_%s", resource_type, resource_name, version)
end

--- Generate file path for persistent cache
-- @param cache_key string Cache key
-- @return string File path
local function get_cache_file_path(cache_key)
  return M.config.cache_dir .. "/" .. cache_key .. ".json"
end

--- Check if cache entry is valid (not expired)
-- @param entry table Cache entry with timestamp
-- @return boolean True if entry is valid
local function is_cache_valid(entry)
  if not entry or not entry.timestamp then
    return false
  end

  local current_time = os.time()
  local age = current_time - entry.timestamp
  return age < M.config.ttl
end

--- Load cache entry from disk
-- @param cache_key string Cache key
-- @return table|nil Cache entry or nil if not found/invalid
local function load_from_disk(cache_key)
  local file_path = get_cache_file_path(cache_key)

  if vim.fn.filereadable(file_path) == 0 then
    return nil
  end

  local ok, content = pcall(vim.fn.readfile, file_path)
  if not ok or not content or #content == 0 then
    return nil
  end

  local json_str = table.concat(content, "\n")
  local ok_decode, entry = pcall(vim.fn.json_decode, json_str)

  if ok_decode and is_cache_valid(entry) then
    return entry
  end

  -- Remove invalid cache file
  pcall(vim.fn.delete, file_path)
  return nil
end

--- Save cache entry to disk
-- @param cache_key string Cache key
-- @param entry table Cache entry
local function save_to_disk(cache_key, entry)
  local file_path = get_cache_file_path(cache_key)
  local json_str = vim.fn.json_encode(entry)

  pcall(vim.fn.writefile, { json_str }, file_path)
end

--- Get cached documentation
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param version string|nil Provider version
-- @return table|nil Cached documentation or nil if not found
function M.get(resource_type, resource_name, version)
  M.stats.total_requests = M.stats.total_requests + 1

  local cache_key = generate_cache_key(resource_type, resource_name, version)

  -- Check memory cache first
  local memory_entry = M.memory_cache[cache_key]
  if memory_entry and is_cache_valid(memory_entry) then
    M.stats.hits = M.stats.hits + 1
    return memory_entry.data
  end

  -- Check disk cache
  local disk_entry = load_from_disk(cache_key)
  if disk_entry then
    -- Load into memory cache
    M.memory_cache[cache_key] = disk_entry
    M.stats.hits = M.stats.hits + 1
    return disk_entry.data
  end

  M.stats.misses = M.stats.misses + 1
  return nil
end

--- Store documentation in cache
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param version string|nil Provider version
-- @param doc_data table Documentation data
function M.set(resource_type, resource_name, version, doc_data)
  local cache_key = generate_cache_key(resource_type, resource_name, version)

  local entry = {
    data = doc_data,
    timestamp = os.time(),
    resource_type = resource_type,
    resource_name = resource_name,
    version = version,
  }

  -- Store in memory cache
  M.memory_cache[cache_key] = entry

  -- Store on disk asynchronously
  vim.schedule(function()
    save_to_disk(cache_key, entry)
  end)

  -- Cleanup old entries if cache is getting too large
  M._cleanup_if_needed()
end

--- Check if resource is cached
-- @param resource_type string "resource" or "data"
-- @param resource_name string Name of the resource
-- @param version string|nil Provider version
-- @return boolean True if cached and valid
function M.has(resource_type, resource_name, version)
  return M.get(resource_type, resource_name, version) ~= nil
end

--- Cleanup old cache entries
function M._cleanup_if_needed()
  local memory_count = 0
  for _ in pairs(M.memory_cache) do
    memory_count = memory_count + 1
  end

  if memory_count <= M.config.max_entries then
    return
  end

  -- Remove oldest entries from memory cache
  local entries_by_time = {}
  for key, entry in pairs(M.memory_cache) do
    table.insert(entries_by_time, { key = key, timestamp = entry.timestamp })
  end

  table.sort(entries_by_time, function(a, b)
    return a.timestamp < b.timestamp
  end)

  -- Remove oldest 10% of entries
  local to_remove = math.floor(memory_count * 0.1)
  for i = 1, to_remove do
    local key = entries_by_time[i].key
    M.memory_cache[key] = nil
  end
end

--- Clear all cache
function M.clear()
  M.memory_cache = {}

  -- Clear disk cache
  local cache_files = vim.fn.glob(M.config.cache_dir .. "/*.json", false, true)
  for _, file in ipairs(cache_files) do
    pcall(vim.fn.delete, file)
  end

  -- Reset stats
  M.stats = {
    hits = 0,
    misses = 0,
    total_requests = 0,
  }
end

--- Get cache statistics
-- @return table Cache statistics
function M.get_stats()
  local hit_rate = M.stats.total_requests > 0 and (M.stats.hits / M.stats.total_requests * 100) or 0

  return {
    hits = M.stats.hits,
    misses = M.stats.misses,
    total_requests = M.stats.total_requests,
    hit_rate = hit_rate,
    memory_entries = vim.tbl_count(M.memory_cache),
  }
end

--- Preload popular resources
function M.preload_popular()
  local popular_resources = {
    { "resource", "aws_s3_bucket" },
    { "resource", "aws_instance" },
    { "resource", "aws_vpc" },
    { "resource", "aws_subnet" },
    { "resource", "aws_security_group" },
    { "data", "aws_ami" },
    { "data", "aws_vpc" },
    { "data", "aws_availability_zones" },
  }

  for _, resource_info in ipairs(popular_resources) do
    if not M.has(resource_info[1], resource_info[2]) then
      -- Load asynchronously in background
      vim.schedule(function()
        require("terrareg.docs").fetch_documentation(
          resource_info[1],
          resource_info[2],
          nil,
          function(success, doc_data, error)
            if success then
              M.set(resource_info[1], resource_info[2], nil, doc_data)
            end
          end
        )
      end)
    end
  end
end

return M

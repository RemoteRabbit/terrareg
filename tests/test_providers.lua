--- Tests for provider system
-- @module test_providers

local assert = require("luassert")
local providers = require("terrareg.providers")
local aws_provider = require("terrareg.providers.aws")
local kubernetes_provider = require("terrareg.providers.kubernetes")
local hashicorp_provider = require("terrareg.providers.hashicorp")

describe("Providers System", function()
  before_each(function()
    -- Reset providers
    providers.providers = {}
  end)

  it("should register providers correctly", function()
    providers.register_provider("aws", aws_provider)
    providers.register_provider("kubernetes", kubernetes_provider)

    local available = providers.get_available_providers()
    assert.are.same({ "aws", "kubernetes" }, available)
  end)

  it("should get provider by name", function()
    providers.register_provider("aws", aws_provider)

    local provider = providers.get_provider("aws")
    assert.are.equal(aws_provider, provider)

    local missing = providers.get_provider("missing")
    assert.is_nil(missing)
  end)

  it("should get all resources from all providers", function()
    providers.register_provider("aws", aws_provider)
    providers.register_provider("kubernetes", kubernetes_provider)

    local all_resources = providers.get_all_resources()
    assert.is_true(#all_resources > 0)

    -- Check that provider field is added
    for _, resource in ipairs(all_resources) do
      assert.is_not_nil(resource.provider)
      assert.is_true(resource.provider == "aws" or resource.provider == "kubernetes")
    end
  end)

  it("should search across all providers", function()
    providers.register_provider("aws", aws_provider)
    providers.register_provider("kubernetes", kubernetes_provider)

    local results = providers.search_all_providers("s3")
    assert.is_true(#results > 0)

    -- Should find AWS S3 resources
    local found_s3 = false
    for _, resource in ipairs(results) do
      if resource.name:find("s3") then
        found_s3 = true
        break
      end
    end
    assert.is_true(found_s3)
  end)
end)

describe("AWS Provider", function()
  it("should have basic structure", function()
    assert.is_function(aws_provider.get_resources)
    assert.is_function(aws_provider.search_resources)
    assert.is_function(aws_provider.fetch_documentation)
  end)

  it("should return AWS resources", function()
    local resources = aws_provider.get_resources()
    assert.is_true(#resources > 0)

    -- Check that all resources have required fields
    for _, resource in ipairs(resources) do
      assert.is_string(resource.name)
      assert.is_string(resource.type)
      assert.is_string(resource.category)
      assert.is_string(resource.description)
      assert.is_true(resource.name:match("^aws_"))
    end
  end)

  it("should search AWS resources", function()
    local results = aws_provider.search_resources("ec2")
    assert.is_true(#results > 0)

    for _, resource in ipairs(results) do
      local matches = resource.name:lower():find("ec2")
        or resource.description:lower():find("ec2")
        or resource.category:lower():find("ec2")
      assert.is_true(matches ~= nil)
    end
  end)
end)

describe("Kubernetes Provider", function()
  it("should have basic structure", function()
    assert.is_function(kubernetes_provider.get_resources)
    assert.is_function(kubernetes_provider.search_resources)
    assert.is_function(kubernetes_provider.fetch_documentation)
  end)

  it("should return Kubernetes resources", function()
    local resources = kubernetes_provider.get_resources()
    assert.is_true(#resources > 0)

    -- Check that all resources have required fields
    for _, resource in ipairs(resources) do
      assert.is_string(resource.name)
      assert.is_string(resource.type)
      assert.is_string(resource.category)
      assert.is_string(resource.description)
      assert.is_true(resource.name:match("^kubernetes_"))
    end
  end)

  it("should detect service correctly", function()
    assert.is_true(kubernetes_provider.has_resource("kubernetes_deployment"))
    assert.is_false(kubernetes_provider.has_resource("aws_instance"))
  end)

  it("should get resource info", function()
    local info = kubernetes_provider.get_resource_info("kubernetes_deployment")
    assert.is_not_nil(info)
    assert.are.equal("kubernetes_deployment", info.name)
    assert.are.equal("Workloads", info.category)
  end)
end)

describe("HashiCorp Provider", function()
  it("should have basic structure", function()
    assert.is_function(hashicorp_provider.get_resources)
    assert.is_function(hashicorp_provider.search_resources)
    assert.is_function(hashicorp_provider.fetch_documentation)
  end)

  it("should detect service from resource name", function()
    assert.are.equal("vault", hashicorp_provider.detect_service("vault_policy"))
    assert.are.equal("consul", hashicorp_provider.detect_service("consul_service"))
    assert.are.equal("nomad", hashicorp_provider.detect_service("nomad_job"))
    assert.is_nil(hashicorp_provider.detect_service("aws_instance"))
  end)

  it("should return HashiCorp resources", function()
    local resources = hashicorp_provider.get_resources()
    assert.is_true(#resources > 0)

    -- Check that all resources have required fields
    for _, resource in ipairs(resources) do
      assert.is_string(resource.name)
      assert.is_string(resource.type)
      assert.is_string(resource.category)
      assert.is_string(resource.description)
      assert.is_string(resource.service)
      assert.are.equal("hashicorp", resource.provider)
    end
  end)

  it("should get available services", function()
    local services = hashicorp_provider.get_services()
    assert.is_true(#services > 0)

    local service_names = {}
    for _, service in ipairs(services) do
      table.insert(service_names, service.name)
    end

    assert.is_true(vim.tbl_contains(service_names, "vault"))
    assert.is_true(vim.tbl_contains(service_names, "consul"))
    assert.is_true(vim.tbl_contains(service_names, "nomad"))
  end)

  it("should get resources by service", function()
    local vault_resources = hashicorp_provider.get_resources_by_service("vault")
    assert.is_true(#vault_resources > 0)

    for _, resource in ipairs(vault_resources) do
      assert.are.equal("vault", resource.service)
      assert.is_true(resource.name:match("^vault_"))
    end
  end)
end)

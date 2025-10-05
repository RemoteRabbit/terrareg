--- Tests for export functionality
-- @module test_export

local assert = require("luassert")
local export = require("terrareg.export")

-- Sample documentation data for testing
local sample_doc_data = {
  title = "aws_instance",
  resource_type = "resource",
  resource_name = "aws_instance",
  provider = "aws",
  description = "Provides an EC2 instance resource. This allows instances to be created, updated, and deleted.",
  url = "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance",
  arguments = {
    {
      name = "ami",
      required = "Required",
      description = "AMI to use for the instance.",
      type = "string",
    },
    {
      name = "instance_type",
      required = "Required",
      description = "Type of instance to start.",
      type = "string",
    },
    {
      name = "key_name",
      required = "Optional",
      description = "Key name of the Key Pair to use for the instance.",
      type = "string",
      default = "",
    },
    {
      name = "vpc_security_group_ids",
      required = "Optional",
      description = "List of security group IDs to associate with.",
      type = "list(string)",
      default = "[]",
    },
  },
  attributes = {
    {
      name = "id",
      description = "The instance ID.",
      type = "string",
    },
    {
      name = "arn",
      description = "The ARN of the instance.",
      type = "string",
    },
  },
  example = [[resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.example.id]

  tags = {
    Name = "ExampleInstance"
  }
}]],
  import = "terraform import aws_instance.example i-1234567890abcdef0",
}

describe("Export Module", function()
  it("should format documentation as markdown", function()
    local markdown = export.format_as_markdown(sample_doc_data)

    assert.is_string(markdown)
    assert.is_true(markdown:find("# aws_instance") ~= nil)
    assert.is_true(markdown:find("## Description") ~= nil)
    assert.is_true(markdown:find("## Arguments") ~= nil)
    assert.is_true(markdown:find("### Required") ~= nil)
    assert.is_true(markdown:find("### Optional") ~= nil)
    assert.is_true(markdown:find("- **ami**:") ~= nil)
    assert.is_true(markdown:find("- **instance_type**:") ~= nil)
    assert.is_true(markdown:find("## Example Usage") ~= nil)
    assert.is_true(markdown:find("```hcl") ~= nil)
    assert.is_true(markdown:find("## Import") ~= nil)
  end)

  it("should format documentation as JSON", function()
    local json_str = export.format_as_json(sample_doc_data)

    assert.is_string(json_str)

    local json_data = vim.json.decode(json_str)
    assert.are.equal(sample_doc_data.title, json_data.title)
    assert.are.equal(sample_doc_data.description, json_data.description)
    assert.is_table(json_data.arguments)
    assert.is_table(json_data._export)
    assert.are.equal("terrareg.nvim", json_data._export.tool)
    assert.are.equal("json", json_data._export.format)
  end)

  it("should format documentation as HTML", function()
    local html = export.format_as_html(sample_doc_data)

    assert.is_string(html)
    assert.is_true(html:find("<!DOCTYPE html>") ~= nil)
    assert.is_true(html:find("<title>aws_instance</title>") ~= nil)
    assert.is_true(html:find("<h1>aws_instance</h1>") ~= nil)
    assert.is_true(html:find("<h2>Description</h2>") ~= nil)
    assert.is_true(html:find("<h2>Arguments</h2>") ~= nil)
    assert.is_true(html:find('class="required"') ~= nil)
    assert.is_true(html:find('class="optional"') ~= nil)
    assert.is_true(html:find("</html>") ~= nil)
  end)

  it("should format documentation as Terraform template", function()
    local terraform = export.format_as_terraform(sample_doc_data)

    assert.is_string(terraform)
    assert.is_true(terraform:find("# aws_instance") ~= nil)
    assert.is_true(terraform:find('resource "aws_instance" "example"') ~= nil)
    assert.is_true(terraform:find('ami = ""') ~= nil)
    assert.is_true(terraform:find('instance_type = ""') ~= nil)
    assert.is_true(terraform:find("# key_name = ") ~= nil)
    assert.is_true(terraform:find("# vpc_security_group_ids = ") ~= nil)
  end)

  it("should get default values for different types", function()
    assert.are.equal('""', export.get_default_value_for_type("string"))
    assert.are.equal("0", export.get_default_value_for_type("number"))
    assert.are.equal("false", export.get_default_value_for_type("bool"))
    assert.are.equal("[]", export.get_default_value_for_type("list"))
    assert.are.equal("{}", export.get_default_value_for_type("map"))
    assert.are.equal('""', export.get_default_value_for_type(nil))
    assert.are.equal('""', export.get_default_value_for_type("unknown"))
  end)

  it("should handle empty documentation data", function()
    local empty_data = {}

    local markdown = export.format_as_markdown(empty_data)
    assert.is_string(markdown)
    assert.is_true(markdown:find("# Terraform Resource Documentation") ~= nil)

    local json_str = export.format_as_json(empty_data)
    assert.is_string(json_str)

    local html = export.format_as_html(empty_data)
    assert.is_string(html)
    assert.is_true(html:find("<h1>Terraform Resource Documentation</h1>") ~= nil)
  end)

  it("should handle missing arguments", function()
    local data_without_args = {
      title = "test_resource",
      description = "A test resource",
    }

    local markdown = export.format_as_markdown(data_without_args)
    assert.is_string(markdown)
    -- Should not contain arguments section
    assert.is_false(markdown:find("## Arguments") ~= nil)

    local terraform = export.format_as_terraform(data_without_args)
    assert.is_string(terraform)
    -- Should have basic resource block
    assert.is_true(terraform:find('resource "test_resource"') ~= nil)
  end)
end)

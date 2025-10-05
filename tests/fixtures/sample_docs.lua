--- Test fixtures for documentation content
-- @module tests.fixtures.sample_docs

local M = {}

M.aws_s3_bucket_markdown = [[---
subcategory: "S3 (Simple Storage)"
layout: "aws"
page_title: "AWS: aws_s3_bucket"
description: |-
  Provides a S3 bucket resource.
---

# Resource: aws_s3_bucket

Provides a S3 bucket resource.

## Example Usage

### Private Bucket With Tags

```terraform
resource "aws_s3_bucket" "example" {
  bucket = "my-tf-test-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
```

## Argument Reference

This resource supports the following arguments:

* `bucket` - (Optional, Forces new resource) Name of the bucket. If omitted, Terraform will assign a random, unique name. Must be lowercase and less than or equal to 63 characters in length.
* `bucket_prefix` - (Optional, Forces new resource) Creates a unique bucket name beginning with the specified prefix. Conflicts with `bucket`. Must be lowercase and less than or equal to 37 characters in length.
* `force_destroy` - (Optional, Default:`false`) Boolean that indicates all objects (including any locked objects) should be deleted from the bucket when the bucket is destroyed so that the bucket can be destroyed without error.
* `object_lock_enabled` - (Optional, Forces new resource) Indicates whether this bucket has an Object Lock configuration enabled. Valid values are `true` or `false`. This argument is not supported in all regions or partitions.
* `tags` - (Optional) Map of tags to assign to the bucket. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.

## Attribute Reference

This resource exports the following attributes in addition to the arguments above:

* `id` - Name of the bucket.
* `arn` - ARN of the bucket. Will be of format `arn:aws:s3:::bucketname`.
* `bucket_domain_name` - Bucket domain name. Will be of format `bucketname.s3.amazonaws.com`.
]]

M.aws_instance_markdown = [[---
subcategory: "EC2 (Elastic Compute Cloud)"
layout: "aws"
page_title: "AWS: aws_instance"
description: |-
  Provides an EC2 instance resource.
---

# Resource: aws_instance

Provides an EC2 instance resource. This allows instances to be created, updated, and deleted.

## Example Usage

```terraform
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}
```

## Argument Reference

This resource supports the following arguments:

* `ami` - (Required) AMI to use for the instance. Required unless `launch_template` is specified and the Launch Template specifies an AMI.
* `instance_type` - (Required) Type of instance to start. Updates to this field will trigger a stop/start of the EC2 instance.
* `availability_zone` - (Optional) AZ to start the instance in.
* `subnet_id` - (Optional) VPC Subnet ID to launch in.
* `vpc_security_group_ids` - (Optional) List of security group IDs to associate with.
* `key_name` - (Optional) Key name of the Key Pair to use for the instance.
* `tags` - (Optional) Map of tags to assign to the resource.
]]

M.provider_versions_json = [[{
  "versions": [
    {
      "version": "5.56.0",
      "protocols": ["5.0"]
    },
    {
      "version": "5.55.0",
      "protocols": ["5.0"]
    },
    {
      "version": "5.54.0",
      "protocols": ["5.0"]
    }
  ]
}]]

M.expected_parsed_arguments = {
  {
    name = "bucket",
    required = "Optional",
    default = "",
    description = "Name of the bucket. If omitted, Terraform will assign a random, unique name. Must be lowercase and less than or equal to 63 characters in length.",
    forces_new = true,
  },
  {
    name = "bucket_prefix",
    required = "Optional",
    default = "",
    description = "Creates a unique bucket name beginning with the specified prefix. Conflicts with `bucket`. Must be lowercase and less than or equal to 37 characters in length.",
    forces_new = true,
  },
  {
    name = "force_destroy",
    required = "Optional",
    default = "false",
    description = "Boolean that indicates all objects (including any locked objects) should be deleted from the bucket when the bucket is destroyed so that the bucket can be destroyed without error.",
    forces_new = false,
  },
  {
    name = "object_lock_enabled",
    required = "Optional",
    default = "",
    description = "Indicates whether this bucket has an Object Lock configuration enabled. Valid values are `true` or `false`. This argument is not supported in all regions or partitions.",
    forces_new = true,
  },
  {
    name = "tags",
    required = "Optional",
    default = "",
    description = "Map of tags to assign to the bucket. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level.",
    forces_new = false,
  },
}

return M

--- AWS resources list for terrareg.nvim
-- @module terrareg.aws_resources

local M = {}

--- Common AWS resources and data sources
M.resources = {
  -- Compute
  {
    name = "aws_instance",
    type = "resource",
    category = "EC2",
    description = "Provides an EC2 instance resource",
  },
  {
    name = "aws_launch_template",
    type = "resource",
    category = "EC2",
    description = "Provides an EC2 Launch Template resource",
  },
  {
    name = "aws_autoscaling_group",
    type = "resource",
    category = "EC2",
    description = "Provides an Auto Scaling Group resource",
  },
  {
    name = "aws_key_pair",
    type = "resource",
    category = "EC2",
    description = "Provides an EC2 key pair resource",
  },
  {
    name = "aws_security_group",
    type = "resource",
    category = "EC2",
    description = "Provides a security group resource",
  },
  {
    name = "aws_security_group_rule",
    type = "resource",
    category = "EC2",
    description = "Provides a security group rule resource",
  },

  -- Storage
  {
    name = "aws_s3_bucket",
    type = "resource",
    category = "S3",
    description = "Provides a S3 bucket resource",
  },
  {
    name = "aws_s3_bucket_policy",
    type = "resource",
    category = "S3",
    description = "Attaches a policy to an S3 bucket resource",
  },
  {
    name = "aws_s3_bucket_versioning",
    type = "resource",
    category = "S3",
    description = "Provides an S3 bucket versioning resource",
  },
  {
    name = "aws_s3_object",
    type = "resource",
    category = "S3",
    description = "Provides a S3 bucket object resource",
  },
  {
    name = "aws_ebs_volume",
    type = "resource",
    category = "EC2",
    description = "Manages a single EBS volume",
  },
  {
    name = "aws_volume_attachment",
    type = "resource",
    category = "EC2",
    description = "Provides an AWS EBS Volume Attachment",
  },

  -- Database
  {
    name = "aws_db_instance",
    type = "resource",
    category = "RDS",
    description = "Provides an RDS instance resource",
  },
  {
    name = "aws_db_subnet_group",
    type = "resource",
    category = "RDS",
    description = "Provides an RDS DB subnet group resource",
  },
  {
    name = "aws_db_parameter_group",
    type = "resource",
    category = "RDS",
    description = "Provides an RDS DB parameter group resource",
  },
  {
    name = "aws_dynamodb_table",
    type = "resource",
    category = "DynamoDB",
    description = "Provides a DynamoDB table resource",
  },

  -- Networking
  {
    name = "aws_vpc",
    type = "resource",
    category = "VPC",
    description = "Provides a VPC resource",
  },
  {
    name = "aws_subnet",
    type = "resource",
    category = "VPC",
    description = "Provides an VPC subnet resource",
  },
  {
    name = "aws_internet_gateway",
    type = "resource",
    category = "VPC",
    description = "Provides a resource to create a VPC Internet Gateway",
  },
  {
    name = "aws_route_table",
    type = "resource",
    category = "VPC",
    description = "Provides a resource to create a VPC routing table",
  },
  {
    name = "aws_route",
    type = "resource",
    category = "VPC",
    description = "Provides a resource to create a routing table entry",
  },
  {
    name = "aws_nat_gateway",
    type = "resource",
    category = "VPC",
    description = "Provides a resource to create a VPC NAT Gateway",
  },
  {
    name = "aws_elastic_ip",
    type = "resource",
    category = "EC2",
    description = "Provides an Elastic IP resource",
  },
  {
    name = "aws_lb",
    type = "resource",
    category = "ELB",
    description = "Provides a Load Balancer resource",
  },
  {
    name = "aws_lb_target_group",
    type = "resource",
    category = "ELB",
    description = "Provides a Load Balancer Target Group resource",
  },

  -- IAM
  {
    name = "aws_iam_role",
    type = "resource",
    category = "IAM",
    description = "Provides an IAM role",
  },
  {
    name = "aws_iam_policy",
    type = "resource",
    category = "IAM",
    description = "Provides an IAM policy",
  },
  {
    name = "aws_iam_user",
    type = "resource",
    category = "IAM",
    description = "Provides an IAM user",
  },
  {
    name = "aws_iam_group",
    type = "resource",
    category = "IAM",
    description = "Provides an IAM group",
  },
  {
    name = "aws_iam_role_policy_attachment",
    type = "resource",
    category = "IAM",
    description = "Attaches a Managed IAM Policy to an IAM role",
  },

  -- Lambda
  {
    name = "aws_lambda_function",
    type = "resource",
    category = "Lambda",
    description = "Provides a Lambda Function resource",
  },
  {
    name = "aws_lambda_permission",
    type = "resource",
    category = "Lambda",
    description = "Creates a Lambda permission",
  },
  {
    name = "aws_lambda_alias",
    type = "resource",
    category = "Lambda",
    description = "Creates a Lambda function alias",
  },

  -- CloudWatch
  {
    name = "aws_cloudwatch_log_group",
    type = "resource",
    category = "CloudWatch",
    description = "Provides a CloudWatch Log Group resource",
  },
  {
    name = "aws_cloudwatch_metric_alarm",
    type = "resource",
    category = "CloudWatch",
    description = "Provides a CloudWatch Metric Alarm resource",
  },

  -- Data Sources
  {
    name = "aws_ami",
    type = "data",
    category = "EC2",
    description = "Get information on an Amazon Machine Image (AMI)",
  },
  {
    name = "aws_availability_zones",
    type = "data",
    category = "EC2",
    description = "Provides a list of Availability Zones",
  },
  {
    name = "aws_vpc",
    type = "data",
    category = "VPC",
    description = "Provides details about a specific VPC",
  },
  {
    name = "aws_subnet",
    type = "data",
    category = "VPC",
    description = "Provides details about a specific subnet",
  },
  {
    name = "aws_security_group",
    type = "data",
    category = "EC2",
    description = "Provides details about a specific security group",
  },
  {
    name = "aws_instance",
    type = "data",
    category = "EC2",
    description = "Get information on an Amazon EC2 Instance",
  },
  {
    name = "aws_caller_identity",
    type = "data",
    category = "IAM",
    description = "Get information about the caller identity",
  },
  {
    name = "aws_region",
    type = "data",
    category = "AWS",
    description = "Provides details about the region",
  },
  {
    name = "aws_s3_bucket",
    type = "data",
    category = "S3",
    description = "Provides details about a specific S3 bucket",
  },
}

--- Get all resources
-- @return table List of all AWS resources
function M.get_all_resources()
  return M.resources
end

--- Get resources by category
-- @param category string Category to filter by
-- @return table List of resources in the category
function M.get_resources_by_category(category)
  local filtered = {}
  for _, resource in ipairs(M.resources) do
    if resource.category == category then
      table.insert(filtered, resource)
    end
  end
  return filtered
end

--- Get resources by type
-- @param resource_type string "resource" or "data"
-- @return table List of resources of the specified type
function M.get_resources_by_type(resource_type)
  local filtered = {}
  for _, resource in ipairs(M.resources) do
    if resource.type == resource_type then
      table.insert(filtered, resource)
    end
  end
  return filtered
end

--- Search resources by name or description
-- @param query string Search query
-- @return table List of matching resources
function M.search_resources(query)
  local results = {}
  local lower_query = query:lower()

  for _, resource in ipairs(M.resources) do
    if
      resource.name:lower():find(lower_query, 1, true)
      or resource.description:lower():find(lower_query, 1, true)
      or resource.category:lower():find(lower_query, 1, true)
    then
      table.insert(results, resource)
    end
  end

  return results
end

return M

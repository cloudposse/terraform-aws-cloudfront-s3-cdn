# Take advantage of null-label for handling role names

locals {
  test_deployment_role_prefix_map = local.enabled ? {
    deploy_alpha = [""]
    cicd_role    = ["prefix1/", "prefix2/"]
  } : {}

  our_account_id            = local.enabled ? data.aws_caller_identity.current[0].account_id : ""
  our_role_arn_prefix       = "arn:${join("", data.aws_partition.current[*].partition)}:iam::${local.our_account_id}:role"
  role_names                = { for k, v in local.test_deployment_role_prefix_map : k => module.role_labels[k].id }
  deployment_principal_arns = { for k, v in local.role_names : format("%v/%v", local.our_role_arn_prefix, v) => local.test_deployment_role_prefix_map[k] }
}

data "aws_caller_identity" "current" {
  count = local.enabled ? 1 : 0
}

# The following instantiations of null-label require Terraform >= 0.13.0
module "sid_labels" {
  for_each = local.test_deployment_role_prefix_map
  source   = "cloudposse/label/null"
  version  = "0.25.0"

  attributes          = split("-", each.key)
  delimiter           = ""
  label_value_case    = "title"
  regex_replace_chars = "/[^a-zA-Z0-9]/"

  context = module.this.context
}

module "role_labels" {
  for_each = local.test_deployment_role_prefix_map
  source   = "cloudposse/label/null"
  version  = "0.25.0"

  attributes = concat(split("-", each.key), module.this.attributes)

  context = module.this.context
}

data "aws_iam_policy_document" "assume_role" {
  for_each = module.sid_labels

  statement {
    sid = "Enable${each.value.id}"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type = "AWS"

      identifiers = [local.our_account_id]
    }
  }
}


resource "aws_iam_role" "test_role" {
  for_each = module.role_labels

  name = module.role_labels[each.key].id

  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json
}

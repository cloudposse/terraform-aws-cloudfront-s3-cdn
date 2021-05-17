# Take advantage of null-label for handling role names

locals {
  test_deployment_role_prefix_map = local.enabled ? {
    deploy_alpha = [""]
    cicd_role    = ["prefix1/", "prefix2/"]
  } : {}

  our_account_id            = local.enabled ? data.aws_caller_identity.current[0].account_id : ""
  our_role_arn_prefix       = "arn:aws:iam::${local.our_account_id}:role"
  deployment_principal_arns = { for k, v in local.test_deployment_role_prefix_map : format("%v/%v", local.our_role_arn_prefix, k) => v }
}

data "aws_caller_identity" "current" {
  count = local.enabled ? 1 : 0
}


module "statement_ids" {
  for_each = local.test_deployment_role_prefix_map
  source   = "cloudposse/label/null"
  version  = "0.24.1" # requires Terraform >= 0.13.0

  attributes          = split("-", each.key)
  delimiter           = ""
  label_value_case    = "title"
  regex_replace_chars = "/[^a-zA-Z0-9]/"

  context = module.this.context
}

data "aws_iam_policy_document" "assume_role" {
  for_each = local.test_deployment_role_prefix_map

  statement {
    sid = "Enable${module.statement_ids[each.key].id}"
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
  for_each = local.test_deployment_role_prefix_map

  name = each.key

  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json
}

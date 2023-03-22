data "archive_file" "lambda_zip" {
  for_each = { for k, v in local.functions : k => v if v.source != null || v.source_dir != null }

  dynamic "source" {
    for_each = coalesce(each.value.source, [])

    content {
      content  = source.value.content
      filename = source.value.filename
    }
  }

  source_dir       = each.value.source_dir
  type             = "zip"
  output_file_mode = "0666"
  output_path      = "${path.module}/archives/${each.key}.zip"
}

data "local_file" "lambda_zip" {
  for_each = { for k, v in local.functions : k => v if v.source_zip != null }

  filename = each.value.source_zip
}

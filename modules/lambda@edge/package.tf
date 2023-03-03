data "archive_file" "lambda_zip" {
  for_each = local.functions

  dynamic "source" {
    for_each = can(var.functions[each.key].source) ? each.value.source : null

    content {
      content  = source.value.content
      filename = source.value.filename
    }
  }

  source_dir       = can(var.functions[each.key].source_dir) ? each.value.source_dir : null
  type             = "zip"
  output_file_mode = "0666"
  output_path      = "${path.module}/archives/${each.key}.zip"
}

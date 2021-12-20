data "archive_file" "lambda_zip" {
  for_each = local.functions

  type             = "zip"
  source_dir       = each.value.local_path
  output_file_mode = "0666"
  output_path      = "${path.module}/archives/${each.key}.zip"
}



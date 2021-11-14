resource "aws_s3_bucket_object" "index" {
  bucket       = module.venom_cloud.s3_bucket
  key          = "index.html"
  source       = "${path.cwd}/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.cwd}/index.html") # changes file to latest version
}

resource "aws_s3_bucket_object" "error" {
  bucket       = module.venom_cloud.s3_bucket
  key          = "error.html"
  source       = "${path.cwd}/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.cwd}/index.html") # changes file to latest version
}

resource "aws_s3_bucket_object" "images" {
  for_each = fileset("${path.cwd}/images/", "*")

  bucket = module.venom_cloud.s3_bucket
  key    = "/images/${each.value}"
  source = "${path.cwd}/images/${each.value}"
  content_type = "image/jpg"
  etag   = filemd5("${path.cwd}/images/${each.value}") # changes file to latest version
}

resource "aws_s3_bucket_object" "assets" {
  for_each = fileset("${path.cwd}/assets/", "**")

  bucket = module.venom_cloud.s3_bucket
  key           = "assets/${each.value}"
  source = "${path.cwd}/assets/${each.value}"
  etag   = filemd5("${path.cwd}/assets/${each.value}") # changes file to latest version
}
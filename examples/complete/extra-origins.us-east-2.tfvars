region = "us-east-2"

namespace = "eg"

stage = "test"

name = "cf-s3-cdn-extra" # name needs to be shortened due to s3 bucket name length restrictions

parent_zone_name = "testing.cloudposse.co"

additional_custom_origins_enabled = true
additional_s3_origins_enabled     = true

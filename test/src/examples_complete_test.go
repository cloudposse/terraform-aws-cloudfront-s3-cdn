package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-west-1.tfvars"},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	cloudFrontId := terraform.Output(t, terraformOptions, "cf_id")

	expectedCloudFrontId := "eg-test-cloudfront-s3-cdn"
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedCloudFrontId, cloudFrontId)

	// Run `terraform output` to get the value of an output variable
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket")

	expectedS3BucketName := "eg-test-cloudfront-s3-cdn-origin"
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedS3BucketName, s3BucketName)
}

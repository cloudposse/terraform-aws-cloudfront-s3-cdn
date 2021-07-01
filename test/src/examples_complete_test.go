package test

import (
	"encoding/json"
	"math/rand"
	"reflect"
	"sort"
	"strconv"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

type OriginGroup struct {
	FailoverCriteria []FailoverCriteria `json:"failover_criteria"`
	Member           []Origin           `json:"member"`
	OriginId         string             `json:"origin_id"`
}

type FailoverCriteria struct {
	StatusCodes []int `json:"status_codes"`
}

type Origin struct {
	OriginId string `json:"origin_id"`
}

func TestExamplesComplete(t *testing.T) {
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
	}

	terraform.Init(t, terraformOptions)
	// Run tests in parallel
	t.Run("Enabled", testExamplesCompleteEnabled)
	t.Run("Disabled", testExamplesCompleteDisabled)
}

// Test the Terraform module in examples/complete using Terratest.
func testExamplesCompleteEnabled(t *testing.T) {
	t.Parallel()

	rand.Seed(time.Now().UnixNano())

	attributes := []string{strconv.Itoa(rand.Intn(100000))}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	cfArn := terraform.Output(t, terraformOptions, "cf_arn")
	// Verify we're getting back the outputs we expect
	assert.Contains(t, cfArn, "arn:aws:cloudfront::")

	// Run `terraform output` to get the value of an output variable
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket")
	expectedS3BucketName := "eg-test-cloudfront-s3-cdn-" + attributes[0] + "-origin"
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedS3BucketName, s3BucketName)

	policyString := terraform.Output(t, terraformOptions, "s3_bucket_policy")
	assert.NotPanics(t, func() { getTestResource(policyString) }, "Could not parse S3 Bucket Policy")
	defer func() { recover() }()
	assert.Equal(t, `arn:aws:s3:::`+expectedS3BucketName+`/testprefix/*`, getTestResource(policyString),
		"Templating of var.additional_bucket_policy failed")

	validateOriginIDs(t, terraformOptions)
}

func testExamplesCompleteDisabled(t *testing.T) {
	t.Parallel()

	// We do not need a random attribute, because this test should never create anything

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		EnvVars: map[string]string{
			"TF_CLI_ARGS": "-state=terraform-disabled-test.tfstate",
		},
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
		Vars: map[string]interface{}{
			"enabled": "false",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	cfArn := terraform.Output(t, terraformOptions, "cf_arn")
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket")
	// Verify we're getting back the outputs we expect
	assert.Empty(t, cfArn)
	assert.Empty(t, s3BucketName)
}

// Test the Terraform module in examples/complete with extra origins (extra-origins.us-east-2.tfvars)
func TestExamplesCompleteExtraOrigins(t *testing.T) {
	t.Parallel()

	rand.Seed(time.Now().UnixNano() + 1)

	attributes := []string{strconv.Itoa(rand.Intn(100000))}

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/complete",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"extra-origins.us-east-2.tfvars"},
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.Apply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	cfArn := terraform.Output(t, terraformOptions, "cf_arn")
	// Verify we're getting back the outputs we expect
	assert.Contains(t, cfArn, "arn:aws:cloudfront::")

	// Run `terraform output` to get the value of an output variable
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket")
	expectedS3BucketName := "eg-test-cf-s3-cdn-extra-" + attributes[0] + "-origin"
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedS3BucketName, s3BucketName)

	policyString := terraform.Output(t, terraformOptions, "s3_bucket_policy")
	assert.NotPanics(t, func() { getTestResource(policyString) }, "Could not parse S3 Bucket Policy")
	defer func() { recover() }()
	assert.Equal(t, `arn:aws:s3:::`+expectedS3BucketName+`/testprefix/*`, getTestResource(policyString),
		"Templating of var.additional_bucket_policy failed")

	validateOriginIDs(t, terraformOptions)
}

func getTestResource(jsonString string) string {
	var js interface{}

	err := json.Unmarshal([]byte(jsonString), &js)
	if err != nil {
		return ""
	}
	policy := js.(map[string]interface{})
	statements := policy["Statement"].([]interface{})
	for _, statement := range statements {
		s := statement.(map[string]interface{})
		if s["Sid"].(string) != "TemplateTest" {
			continue
		}
		return s["Resource"].(string)
	}

	return ""
}

func validateOriginIDs(t *testing.T, terraformOptions *terraform.Options) {
	// Validate that Origins are in Origin Groups
	originGroups := []OriginGroup{}
	terraform.OutputStruct(t, terraformOptions, "cf_origin_groups", &originGroups)
	originIds := terraform.OutputList(t, terraformOptions, "cf_origin_ids")
	originIdsInGroups := []string{}
	for _, originGroup := range originGroups {
		for _, member := range originGroup.Member {
			originIdsInGroups = append(originIdsInGroups, member.OriginId)
		}
	}
	sort.Strings(originIds)
	sort.Strings(originIdsInGroups)
	assert.True(t, reflect.DeepEqual(originIds, originIdsInGroups))
}

provider "aws" {
  region = "us-east-2"
}

module "oidc_provider" {
  source = "github.com/brikis98/devops-book//ch5/tofu/modules/github-aws-oidc"

  provider_url = "https://token.actions.githubusercontent.com" 

}

module "iam_roles" {
  source = "github.com/brikis98/devops-book//ch5/tofu/modules/gh-actions-iam-roles"

  name              = "lambda-sample"                           
  oidc_provider_arn = module.oidc_provider.oidc_provider_arn    

  enable_iam_role_for_testing = true                            

  github_repo      = "ilyasgdo/ESIEE_2526_devops" 
  lambda_base_name = "lambda-sample"                            

  enable_iam_role_for_plan  = true                                
  enable_iam_role_for_apply = true                                

  tofu_state_bucket         = "tofu-state-118499504231-ilyasgdo" 
  tofu_state_dynamodb_table = "tofu-state-118499504231-ilyasgdo" 
}

terraform {
  backend "s3" {
    bucket         = "tofu-state-118499504231-ilyasgdo" 
    key            = "td5/tofu/live/tofu-state"          
    region         = "us-east-2"                         
    encrypt        = true                                
    dynamodb_table = "tofu-state-118499504231-ilyasgdo" 
  }
}
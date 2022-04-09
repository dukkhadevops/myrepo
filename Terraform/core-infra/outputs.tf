output "resource_group_id" {
  description = "Resource group ID"
  value       = module.coreInfraResourceGroup.resource_group_id
}

output "storage_account_id" {
  description = "Storage account ID"
  value       = module.coreInfraStorageAccount.storage_account_id
}
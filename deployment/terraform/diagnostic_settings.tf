# Configure diagnostic settings for AI Services using the latest format
resource "azurerm_monitor_diagnostic_setting" "ai_diagnostics_v2" {
  name                       = "ai-diagnostics-v2"
  target_resource_id         = azurerm_cognitive_account.ai_services.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  # Use the newer format to avoid deprecation warnings
  enabled_log {
    category_group = "audit"
  }

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  depends_on = [
    azurerm_cognitive_account.ai_services,
    azurerm_log_analytics_workspace.law
  ]
}

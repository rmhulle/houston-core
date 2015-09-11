Rails.application.config.assets.precompile += %w{
  vendor.js
  vendor.css
  dashboard.js
  dashboard.css
}

Rails.application.config.assets.paths << Rails.root.join("app", "assets", "fonts")

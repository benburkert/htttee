on_app_servers do
  env_custom = "#{shared_path}/config/env.custom"
  run "echo 'export APP_CURRENT_PATH=\"#{current_path}\"' > #{env_custom}"
end

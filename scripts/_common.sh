#!/bin/bash

# Register the bundled icon for this private package (no catalog logo).
# Older YunoHost releases do not expose the custom permission logo option.
admin_lova_install_logo() {
	local logo_path="${1:-../conf/logo.png}"
	if yunohost user permission update --help | grep -- '--logo' >/dev/null; then
		yunohost user permission update "$app.main" --logo "$logo_path"
	else
		ynh_print_warn --message="This YunoHost version does not support custom portal icons."
	fi
}

# Runs npm ci + npm run build with the env vars that must be baked into
# the build (NEXT_BASE_PATH/NEXT_PUBLIC_BASE_PATH affect next.config.ts
# at build time and cannot be changed afterwards without rebuilding).
admin_lova_build() {
	pushd "$install_dir" || ynh_die --message="Cannot cd into $install_dir"

	ynh_exec_warn_less ynh_exec_as "$app" $ynh_node_load_PATH $ynh_npm ci --production=false
	ynh_exec_as "$app" $ynh_node_load_PATH NEXT_BASE_PATH="$next_base_path" NEXT_PUBLIC_BASE_PATH="$next_base_path" $ynh_npm run build

	popd || ynh_die --message="Cannot leave $install_dir"
}

# Regenerates the app's .env file from the template, substituting every
# setting placeholder. Shared by install/upgrade/change_url to avoid drift.
admin_lova_write_env() {
	local env_path="$install_dir/.env"
	local ollama_url="${ollama_base_url:-}"
	# Optional input may be empty or the literal string "undefined".
	# The app validates this URL even when Mistral is selected.
	case "$ollama_url" in
		""|undefined) ollama_url="http://127.0.0.1:11434" ;;
	esac
	cp ../conf/.env.template "$env_path"
	ynh_replace_string --match_string="__DB_USER__" --replace_string="$db_user" --target_file="$env_path"
	ynh_replace_string --match_string="__DB_PWD__" --replace_string="$db_pwd" --target_file="$env_path"
	ynh_replace_string --match_string="__DB_NAME__" --replace_string="$db_name" --target_file="$env_path"
	ynh_replace_string --match_string="__PORT__" --replace_string="$port" --target_file="$env_path"
	ynh_replace_string --match_string="__SESSION_SECRET__" --replace_string="$session_secret" --target_file="$env_path"
	ynh_replace_string --match_string="__APP_ENCRYPTION_KEY__" --replace_string="$app_encryption_key" --target_file="$env_path"
	ynh_replace_string --match_string="__MISTRAL_API_KEY__" --replace_string="$mistral_api_key" --target_file="$env_path"
	ynh_replace_string --match_string="__OLLAMA_BASE_URL__" --replace_string="$ollama_url" --target_file="$env_path"
	ynh_replace_string --match_string="__DOMAIN__" --replace_string="$domain" --target_file="$env_path"
	ynh_replace_string --match_string="__PATH__" --replace_string="${path%/}" --target_file="$env_path"
	ynh_replace_string --match_string="__NEXT_BASE_PATH__" --replace_string="$next_base_path" --target_file="$env_path"
	chmod 600 "$env_path"
	chown "$app:$app" "$env_path"
}

# Loads the key encrypting secrets stored in the database, generating it once.
# Changing it makes stored secrets unreadable (the admin must re-enter them).
admin_lova_encryption_key() {
	app_encryption_key=$(ynh_app_setting_get --app=$app --key=app_encryption_key)
	if [ -z "$app_encryption_key" ]; then
		app_encryption_key=$(openssl rand -base64 32)
		ynh_app_setting_set --app=$app --key=app_encryption_key --value="$app_encryption_key"
	fi
}

# Installs (or refreshes) the Framateam bot service. It stays idle until an
# account is configured in the admin area.
admin_lova_add_bot_service() {
	ynh_add_systemd_config --service="$app-framateam" --template="framateam.service"
	yunohost service add "$app-framateam" --description="Assistant Fablab — bot Framateam" --log="/var/log/$app/framateam.log"
}

# Computes next_base_path from YunoHost's $path variable ("" for root,
# "/assistant" for a sub-path — Next.js basePath must never be a bare "/").
compute_next_base_path() {
	if [ "$path" = "/" ]; then
		next_base_path=""
	else
		next_base_path="${path%/}"
	fi
}

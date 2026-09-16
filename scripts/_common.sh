#!/bin/bash

ADMIN_LOVA_REPO="https://github.com/nrineau/AdminLova"
ADMIN_LOVA_REF="main"

# Runs npm ci + npm run build with the env vars that must be baked into
# the build (NEXT_BASE_PATH/NEXT_PUBLIC_BASE_PATH affect next.config.ts
# at build time and cannot be changed afterwards without rebuilding).
admin_lova_build() {
	pushd "$install_dir" || ynh_die --message="Cannot cd into $install_dir"

	ynh_hide_warnings ynh_exec_as "$app" env PATH="$PATH" npm ci --production=false
	NEXT_BASE_PATH="$next_base_path" \
		NEXT_PUBLIC_BASE_PATH="$next_base_path" \
		ynh_exec_as "$app" env PATH="$PATH" npm run build

	popd || ynh_die --message="Cannot leave $install_dir"
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

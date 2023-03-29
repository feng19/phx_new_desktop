
dev-server:
	iex -S mix phx.server

dev-ui:
	cargo tauri dev

dev-self:
	TAURI_SKIP_DEVSERVER_CHECK=true cargo tauri dev

release:
	mix assets.deploy
	mix release --force --overwrite

release-all: release
	cargo tauri build
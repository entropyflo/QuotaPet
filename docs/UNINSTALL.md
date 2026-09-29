# Uninstall

1. Open the QuotaPet menu and turn off **Launch at Login**.
2. Choose **Quit** so the Codex App Server child process is terminated.
3. Move `QuotaPet.app` to Trash.
4. Optionally remove saved window/display preferences:

   ```sh
   defaults delete community.quotapet.app
   ```

If a development build used SwiftPM directly, remove this project's `.build` and `build` directories if desired. QuotaPet creates no account database, token store, network service, kernel extension, or background daemon.

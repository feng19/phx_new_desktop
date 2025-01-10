# phx.new desktop

[Video Demo](https://twitter.com/kevin52069370/status/1641352557842014208)

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start build with `make release-all`

## Requirements

  * erlang & elixir
  * rust

## Usage

### Windows & Linux

Download the latest release from [here](https://github.com/feng19/phx_new_desktop/releases).

### MacOS

After MacOS 10.15.7, the app is not allowed to run, you need to bypass Gatekeeper.

- Open Terminal
- Run the following command

  For the current installed version:
    ```bash    
    sudo xattr -c '/Applications/phx_new_desktop.app'
    ```

  For all versions of the app:
    ```bash
    sudo xattr -r -d com.apple.quarantine '/Applications/phx_new_desktop.app'
    ```
- After that, you can run the desktop GUI.

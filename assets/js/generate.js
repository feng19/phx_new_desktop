const Generate = {
  mounted() {
    let hook = this
    this.el.addEventListener("click", _info => select_dir(hook))
  }
};

async function select_dir(hook) {
  const { dialog, path } = window.__TAURI__

  // Open a selection dialog for directories
  const selected = await dialog.open({
    directory: true,
    multiple: false,
    defaultPath: await path.homeDir(),
  })

  console.log("select dir: ", selected)
  selected && hook.pushEvent("generate", {dir: selected}, function(resp){
    if(resp.exit_status == 0) {
      console.log(resp.result)
      alert("Generate Success!")
    }
  })
}

export default Generate;
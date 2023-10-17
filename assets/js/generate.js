const Generate = {
  mounted() {
    let hook = this
    this.el.addEventListener("click", _info => select_dir(hook))
    this.handleEvent("dialog", show_dialog)
    this.handleEvent("exec_done", alert_result)
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
    console.log(resp.cmd)
  })
}

function alert_result({exit_status}) {
  if(exit_status == 0) {
    alert("Generate Success!")
  } else {
    alert("Generate failed!")
  }
}

function show_dialog({message}) {
  alert(message)
}

export default Generate;
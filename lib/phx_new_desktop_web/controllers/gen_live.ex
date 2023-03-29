defmodule PhxNewDesktopWeb.GenLive do
  use PhxNewDesktopWeb, :live_view
  require Logger

  @default %{
    assets: true,
    esbuild: true,
    tailwind: true,
    ecto: true,
    database: "postgres",
    binary_id: false,
    app: "",
    app_errors: [],
    app_as_module?: true,
    module: "",
    module_errors: [],
    html: true,
    live: true,
    umbrella: false,
    verbose: true,
    install: false,
    gettext: true,
    dashboard: true,
    mailer: true,
    can?: false,
    help_doc: "",
    result: nil
  }
  @help_docs %{
    umbrella:
      "Generate an umbrella project, with one application for your domain, and a second application for the web interface.",
    app: "The name of the OTP application.",
    module: "The name of the base module in the generated skeleton.",
    ecto: "Generate Ecto files",
    database:
      {:safe,
       """
       <div class="text-3xl">
       Specify the database adapter for Ecto. One of:

         <ul class="text-blue-600 underline">
           <li><a href="https://github.com/elixir-ecto/postgrex" target="_blank">postgres</a></li>
           <li><a href="https://github.com/elixir-ecto/myxql" target="_blank">mysql</a></li>
           <li><a href="https://github.com/livehelpnow/tds" target="_blank">mssql</a></li>
           <li><a href="https://github.com/elixir-sqlite/ecto_sqlite3" target="_blank">sqlite3</a></li>
         </ul>

       Please check the driver docs for more information and requirements.
       </div>
       """},
    binary_id: "use `binary_id` as primary key type in Ecto schemas",
    esbuild: """
    Include esbuild dependencies and assets.
    We do recommend setting this option, unless for API only applications.
    """,
    tailwind: "Include tailwind dependencies and assets.",
    gettext: "Generate gettext files.",
    mailer: "Generate Swoosh mailer files.",
    dashboard: "Include Phoenix.LiveDashboard",
    html: "Generate HTML views.",
    live: "if disable it, will comment out LiveView socket setup in assets/js/app.js."
  }

  @impl true
  def mount(_params, _session, socket) do
    # check erl
    # check elixir
    # check mix
    # check phx_new
    socket = assign(socket, @default)
    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"_target" => [target], "app" => app, "module" => module}, socket) do
    socket =
      case target do
        "app" ->
          errors = check_app_name(app) |> List.wrap()

          if socket.assigns.app_as_module? do
            app_mod = Macro.camelize(app)
            module_errors = check_module_name(app_mod)
            assign(socket, module: app_mod, module_errors: module_errors)
          else
            socket
          end
          |> assign(app: app, app_errors: errors)

        "module" ->
          errors = check_module_name(module)
          assign(socket, module: module, module_errors: errors, app_as_module?: false)
      end

    %{app: app, app_errors: app_errors, module: module, module_errors: module_errors} =
      socket.assigns

    can? = app != "" and Enum.empty?(app_errors) and module != "" and Enum.empty?(module_errors)
    socket = assign(socket, can?: can?)

    {:noreply, socket}
  end

  def handle_event("help", params, socket) do
    key =
      Map.get_lazy(params, "key", fn -> Map.get(params, "value") end) |> String.to_existing_atom()

    {:noreply, assign_help_doc(socket, key)}
  end

  def handle_event("toggle", %{"key" => key}, socket) do
    toggle(socket, key)
  end

  def handle_event("toggle", %{"value" => key}, socket) do
    toggle(socket, key)
  end

  def handle_event("set", %{"key" => key, "value" => value}, socket) do
    key = String.to_existing_atom(key)

    value =
      case value do
        "true" -> true
        "false" -> false
        other -> other
      end

    socket = assign(socket, key, value) |> assign_help_doc(key)
    {:noreply, socket}
  end

  def handle_event("generate", %{"dir" => dir}, socket) do
    app_dir = Path.join([dir, socket.assigns.app])

    if File.dir?(app_dir) do
      result = """
      The directory #{app_dir} already exists.
      Please select another directory for installation.
      """

      socket =
        socket
        |> assign(result: "")
        |> stream(:results, [result], dom_id: &dom_id/1)
        |> push_event("exec_done", %{exit_status: 1})

      {:reply, %{cmd: ""}, socket}
    else
      {task, reply} = generate(socket.assigns, dir)

      result = """
      cd #{dir}
      #{reply.cmd}

      """

      socket =
        socket |> assign(task: task, result: "") |> stream(:results, [result], dom_id: &dom_id/1)

      {:reply, reply, socket}
    end
  end

  @impl true
  def handle_info({:io_stream, :done}, socket) do
    await_task(socket)
  end

  def handle_info({:io_stream, :halt}, socket) do
    await_task(socket)
  end

  def handle_info({:io_stream, msg}, socket) do
    {:noreply, stream_insert(socket, :results, msg)}
  end

  def handle_info(info, socket) do
    Logger.error("handle unknown info: #{inspect(info)}")
    {:noreply, socket}
  end

  defp check_app_name(name) do
    unless name =~ Regex.recompile!(~r/^[a-z][\w_]*$/) do
      "Application name must start with a letter and have only lowercase " <>
        "letters, numbers and underscore, got: #{inspect(name)}"
    end
  end

  defp check_module_name(module) do
    module = Module.concat([module])

    with error when not is_binary(error) <- check_module_name_validity(module),
         error when not is_binary(error) <- check_module_name_availability(module) do
      []
    else
      error -> [error]
    end
  end

  defp check_module_name_validity(name) do
    unless inspect(name) =~ Regex.recompile!(~r/^[A-Z]\w*(\.[A-Z]\w*)*$/) do
      "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
    end
  end

  defp check_module_name_availability(name) do
    [name]
    |> Module.concat()
    |> Module.split()
    |> Enum.reduce([], fn name, acc ->
      mod = Module.concat([Elixir, name | acc])

      if Code.ensure_loaded?(mod) do
        "Module name #{inspect(mod)} is already taken, please choose another name"
      else
        [name | acc]
      end
    end)
  end

  defp toggle(socket, key) do
    key = String.to_existing_atom(key)
    socket = assign(socket, key, not socket.assigns[key]) |> assign_help_doc(key)
    {:noreply, socket}
  end

  defp assign_help_doc(socket, key) do
    doc = Map.get(@help_docs, key)
    assign(socket, :help_doc, doc)
  end

  defp generate(assigns, dir) do
    %{app: app, app_as_module?: app_as_module?, module: module, ecto: ecto} = assigns

    args =
      assigns
      |> Map.take([
        :assets,
        :esbuild,
        :tailwind,
        :html,
        :install,
        :gettext,
        :dashboard,
        :mailer,
        :ecto
      ])
      |> Enum.map(fn {key, bool} ->
        unless bool, do: "--no-#{key}"
      end)
      |> Enum.reject(&is_nil/1)

    args =
      if app_as_module? do
        args
      else
        ["--module", module]
      end
      |> then(&if assigns.umbrella, do: ["--umbrella" | &1], else: &1)
      |> then(&if assigns.html and not assigns.live, do: ["--no-live" | &1], else: &1)
      |> then(fn acc ->
        if ecto do
          acc
        else
          if assigns.binary_id do
            ["--database", assigns.database, "--binary-id" | acc]
          else
            ["--database", assigns.database | acc]
          end
        end
      end)

    args = ["phx.new", app, "--verbose" | args]
    cmd = Enum.join(["mix" | args], " ")

    topic = "t:#{inspect(self())}"
    Phoenix.PubSub.subscribe(PhxNewDesktop.PubSub, topic)
    io = %PhxNewDesktop.TopicStream{topic: topic}

    task =
      Task.async(fn ->
        Logger.info("exec cmd: #{cmd}")
        System.cmd("mix", args, cd: dir, env: exec_env(), into: io)
      end)

    {task, %{cmd: cmd, topic: topic}}
  end

  def await_task(socket) do
    {_result, exit_status} = Task.await(socket.assigns.task)
    {:noreply, push_event(socket, "exec_done", %{exit_status: exit_status})}
  end

  defp exec_env do
    if release_root = System.get_env("RELEASE_ROOT") do
      path =
        System.get_env("PATH")
        |> String.split(":")
        |> Enum.reject(&String.starts_with?(&1, release_root))
        |> Enum.join(":")

      Logger.info("change PATH: #{path}")
      [{"PATH", path}]
    else
      []
    end
  end

  defp dom_id(_) do
    System.unique_integer() |> to_string()
  end
end

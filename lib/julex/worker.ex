defmodule Julex.Worker do
  use GenServer

  @default_nprocs :erlang.system_info(:logical_processors)

  ##############
  # Client API #
  ##############

  def call(pid, method, params \\ [], timeout \\ 10000) do
    GenServer.call(pid, {method, params}, timeout)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def nprocs() do
    nprocs = Application.get_env(:julex, __MODULE__)[:nprocs]
    case nprocs do
      nil ->
        @default_nprocs
      _ ->
        nprocs
    end
  end

  ####################
  # Server Callbacks #
  ####################

  def init(_) do
    port = start_port()
    {:ok, %{port: port, next_id: 1, awaiting: %{}}}
  end

  def handle_call({method, params}, from, state) do
    {id, state} = send_request(state, method, params)
    {:noreply, %{state | awaiting: Map.put(state.awaiting, id, from)}}
  end

  def handle_info({port, {:data, response}}, %{port: port} = state) do
    data = :erlang.binary_to_term(response)

    case data do
      {:log, message} ->
        IO.puts(message)
        {:noreply, state}

      _ ->
        handle_response(state, data)
    end
  end

  def handle_info({port, {:exit_status, status}}, %{port: port}) do
    :erlang.error({:port_exit, status})
  end

  def handle_info(_, state), do: {:noreply, state}

  def terminate(_, state) do
    Port.close(state.port)
  end

  #############
  # Internals #
  #############

  defp start_port() do
    path = System.find_executable("julia")
    project = Application.get_env(:julex, __MODULE__)[:project]
    module = Application.get_env(:julex, __MODULE__)[:module]

    case path do
      nil ->
        raise("The julia executable is not on the path.")

      _ ->
        case System.cmd(path, init_args(project)) do
          {_, 0} ->
            Port.open(
              {:spawn_executable, path},
              [
                :binary,
                args: run_args(module),
                env: [{'JULIA_PROJECT', String.to_charlist(project)}]
              ]
            )

          _ ->
            raise("Julia Worker could not be started.")
        end
    end
  end

  defp serialize_command(id, method, params) do
    %{id: id, method: method, params: params}
    |> :erlang.term_to_binary()
  end

  defp send_request(state, method, params) do
    id = state.next_id
    cmd = serialize_command(id, method, params)
    Port.command(state.port, cmd)
    {id, %{state | next_id: id + 1}}
  end

  defp handle_response(state, %{id: id, result: result}) do
    send_response(state, :ok, id, result)
  end

  defp handle_response(state, %{id: id, error: error}) do
    send_response(state, :error, id, error)
  end

  defp send_response(state, code, id, result) do
    case state.awaiting[id] do
      nil ->
        {:noreply, state}

      caller ->
        GenServer.reply(caller, {code, result})
        {:noreply, %{state | awaiting: Map.delete(state.awaiting, id)}}
    end
  end

  defp init_args(project) do
    ["--project=#{project}", "-e", "\"import Pkg; Pkg.instantiate()\""]
  end

  defp run_args(module) do
    [
      "--color=yes",
      "--procs=#{nprocs() - 1}",
      "-e",
      "using Julex, #{module}; Julex.run_loop()"
    ]
  end
end

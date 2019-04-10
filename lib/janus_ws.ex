defmodule Janus.WS do
  @moduledoc File.read!("README.md")
  use WebSockex

  defstruct [:registry, pending_txs: %{}]

  @type client :: WebSockex.client()
  @type session_id :: integer
  @type handle_id :: integer
  @type tx_id :: String.t()
  @type send_result ::
          {:ok, tx_id}
          | {:error,
             %WebSockex.FrameEncodeError{}
             | %WebSockex.ConnError{}
             | %WebSockex.NotConnectedError{}
             | %WebSockex.InvalidFrameError{}}

  @doc """
  Example:

      Registry.start_link(keys: :duplicate, name: Janus.WS.Session.Registry)
      Janus.WS.start_link(url: "ws://localhost:8188", registry: Janus.WS.Session.Registry)

  """
  def start_link(opts) do
    websockex_opts = [
      name: opts[:name],
      extra_headers: [{"Sec-WebSocket-Protocol", "janus-protocol"}],
      debug: opts[:debug]
    ]

    websockex_opts = Enum.reject(websockex_opts, fn {_k, v} -> is_nil(v) end)

    WebSockex.start_link(
      opts[:url],
      __MODULE__,
      opts[:state] || %__MODULE__{registry: opts[:registry]},
      websockex_opts
    )
  end

  @impl true
  def handle_frame(
        {:text, msg},
        %__MODULE__{pending_txs: pending_txs, registry: registry} = state
      ) do
    case Jason.decode!(msg) do
      %{"session_id" => session_id} = msg ->
        if registry, do: _broadcast(registry, session_id, msg)
        {:ok, state}

      %{"transaction" => transaction} = msg ->
        {maybe_from, pending_txs} = Map.pop(pending_txs, transaction)
        if maybe_from, do: send(maybe_from, {:janus_ws, msg})
        {:ok, %{state | pending_txs: pending_txs}}
    end
  end

  @impl true
  def handle_cast({cmd, tx_id, pid}, %__MODULE__{pending_txs: pending_txs} = state) do
    msg =
      case cmd do
        :create_session -> %{"janus" => "create"}
        :info -> %{"janus" => "info"}
      end

    msg = Map.put(msg, "transaction", tx_id)

    {:reply, {:text, Jason.encode!(msg)},
     %{state | pending_txs: Map.put(pending_txs, tx_id, pid)}}
  end

  @doc "To fetch info about the janus instance"
  @spec info(client) :: send_result
  @spec info(client, pid) :: send_result
  def info(client, pid \\ self()) do
    tx_id = tx_id()
    :ok = WebSockex.cast(client, {:info, tx_id, pid})
    {:ok, tx_id}
  end

  @doc "To create a janus session"
  @spec create_session(client) :: send_result
  @spec create_session(client, pid) :: send_result
  def create_session(client, pid \\ self()) do
    tx_id = tx_id()
    :ok = WebSockex.cast(client, {:create_session, tx_id, pid})
    {:ok, tx_id}
  end

  @doc "To destroy a janus session"
  @spec destroy_session(client, session_id) :: send_result
  def destroy_session(client, session_id) do
    _send(client, %{"janus" => "destroy", "session_id" => session_id})
  end

  @doc "To attach a plugin to a janus session"
  @spec attach(client, session_id, String.t()) :: send_result
  def attach(client, session_id, plugin) do
    _send(client, %{"janus" => "attach", "session_id" => session_id, "plugin" => plugin})
  end

  @doc "To detach a plugin from a janus session"
  @spec detach(client, session_id, handle_id) :: send_result
  def detach(client, session_id, handle_id) do
    _send(client, %{"janus" => "detach", "session_id" => session_id, "handle_id" => handle_id})
  end

  @doc "To send a trickle candidate for a session"
  @spec send_trickle_candidate(client, session_id, handle_id, [map]) :: send_result
  def send_trickle_candidate(client, session_id, handle_id, candidates)
      when is_list(candidates) do
    message = %{
      "janus" => "trickle",
      "session_id" => session_id,
      "handle_id" => handle_id,
      "candidates" => candidates
    }

    _send(client, message)
  end

  @spec send_trickle_candidate(client, session_id, handle_id, map) :: send_result
  def send_trickle_candidate(client, session_id, handle_id, candidate) when is_map(candidate) do
    message = %{
      "janus" => "trickle",
      "session_id" => session_id,
      "handle_id" => handle_id,
      "candidate" => candidate
    }

    _send(client, message)
  end

  @doc "To send a message to a handle in a session"
  @spec send_message(client, session_id, handle_id, map) :: send_result
  def send_message(client, session_id, handle_id, data) do
    msg =
      %{
        "janus" => "message",
        "session_id" => session_id,
        "handle_id" => handle_id
      }
      |> Map.merge(Map.take(data, ["body", "jsep"]))

    _send(client, msg)
  end

  @doc "To send a keepalive for a session"
  @spec send_keepalive(client, session_id) :: send_result
  def send_keepalive(client, session_id) do
    _send(client, %{"janus" => "keepalive", "session_id" => session_id})
  end

  @spec _send(client, map) :: send_result
  defp _send(client, msg) do
    tx_id = tx_id()
    msg = Map.put(msg, "transaction", tx_id)

    with :ok <- WebSockex.send_frame(client, {:text, Jason.encode!(msg)}) do
      {:ok, tx_id}
    end
  end

  @spec _broadcast(module, session_id(), map) :: :ok
  defp _broadcast(registry, session_id, message) when not is_nil(registry) do
    Registry.dispatch(registry, session_id, fn entries ->
      Enum.each(entries, fn {pid, _} ->
        send(pid, {:janus_ws, message})
      end)
    end)
  end

  @spec tx_id :: tx_id
  defp tx_id do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode64(padding: false)
  end
end

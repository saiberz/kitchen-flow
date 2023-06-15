defmodule KitchenFlow.Broker.ConnectionManager do
  use GenServer
  require Logger

  @stations ~w(grill cold bar pastry)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_channel do
    GenServer.call(__MODULE__, :get_channel)
  end

  @impl true
  def init(_opts) do
    config = Application.get_env(:kitchen_flow, :broker, [])

    if Keyword.get(config, :enabled, true) do
      send(self(), :connect)
    end

    {:ok, %{conn: nil, chan: nil, config: config}}
  end

  @impl true
  def handle_call(:get_channel, _from, %{chan: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(:get_channel, _from, %{chan: chan} = state) do
    {:reply, {:ok, chan}, state}
  end

  @impl true
  def handle_info(:connect, %{config: config} = state) do
    url = Keyword.get(config, :url, "amqp://guest:guest@localhost:5672")

    case AMQP.Connection.open(url) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:ok, chan} = AMQP.Channel.open(conn)
        setup_topology(chan, config)
        Logger.info("Connected to RabbitMQ broker and initialized kitchen topology")
        {:noreply, %{state | conn: conn, chan: chan}}

      {:error, reason} ->
        Logger.warn("Failed to connect to RabbitMQ (#{inspect(reason)}), retrying in 3s")
        Process.send_after(self(), :connect, 3_000)
        {:noreply, %{state | conn: nil, chan: nil}}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.warn("RabbitMQ connection lost (#{inspect(reason)}), scheduling reconnect")
    Process.send_after(self(), :connect, 2_000)
    {:noreply, %{state | conn: nil, chan: nil}}
  end

  def setup_topology(chan, config) do
    exchange = Keyword.get(config, :exchange, "kitchen.events")
    dlx = Keyword.get(config, :dlx_exchange, "kitchen.dlx")
    dlq = Keyword.get(config, :dlq_queue, "kitchen.dlq")

    :ok = AMQP.Exchange.declare(chan, dlx, :fanout, durable: true)
    {:ok, _} = AMQP.Queue.declare(chan, dlq, durable: true)
    :ok = AMQP.Queue.bind(chan, dlq, dlx)

    :ok = AMQP.Exchange.declare(chan, exchange, :topic, durable: true)

    Enum.each(@stations, fn station ->
      queue = "kitchen.station.#{station}"

      {:ok, _} =
        AMQP.Queue.declare(chan, queue,
          durable: true,
          arguments: [{"x-dead-letter-exchange", :longstr, dlx}]
        )

      :ok = AMQP.Queue.bind(chan, queue, exchange, routing_key: "ticket.routed.#{station}")
    end)
  end
end

defmodule KitchenFlow.Orders do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias KitchenFlow.Repo
  alias KitchenFlow.Catalog.MenuItem
  alias KitchenFlow.Orders.{Order, StationTicket}

  def list_orders do
    Order
    |> preload([:items, :station_tickets])
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  def get_order!(id) do
    Order
    |> preload([:items, :station_tickets])
    |> Repo.get!(id)
  end

  def list_station_tickets(opts \\ []) do
    StationTicket
    |> maybe_filter_station(opts[:station])
    |> maybe_filter_status(opts[:status])
    |> order_by([t], asc: t.inserted_at)
    |> Repo.all()
  end

  def get_station_ticket!(id), do: Repo.get!(StationTicket, id)

  def create_order(attrs) do
    enriched_attrs = enrich_order_items(attrs)

    Multi.new()
    |> Multi.insert(:order, Order.changeset(%Order{}, enriched_attrs))
    |> Multi.run(:station_tickets, fn repo, %{order: order} ->
      insert_station_tickets(repo, order)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{order: order, station_tickets: tickets}} ->
        {:ok, %{order | station_tickets: tickets}}

      {:error, :order, changeset, _} ->
        {:error, changeset}

      {:error, _, reason, _} ->
        {:error, reason}
    end
  end

  def transition_ticket(%StationTicket{} = ticket, next_status) do
    if StationTicket.valid_transition?(ticket.status, next_status) do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      timestamps = transition_timestamps(next_status, now)

      ticket
      |> StationTicket.changeset(Map.put(timestamps, :status, next_status))
      |> Repo.update()
    else
      {:error, :invalid_transition}
    end
  end

  defp transition_timestamps("preparing", now), do: %{started_at: now}
  defp transition_timestamps("ready", now), do: %{ready_at: now}
  defp transition_timestamps("served", now), do: %{served_at: now}
  defp transition_timestamps(_, _), do: %{}

  defp insert_station_tickets(repo, %Order{} = order) do
    grouped = Enum.group_by(order.items, & &1.station)

    tickets =
      Enum.map(grouped, fn {station, items} ->
        max_prep = items |> Enum.map(& &1.prep_time_seconds) |> Enum.max(fn -> 300 end)

        payload =
          Enum.map(items, fn item ->
            %{
              "id" => item.id,
              "menu_item_id" => item.menu_item_id,
              "name" => item.item_name,
              "quantity" => item.quantity,
              "notes" => item.notes
            }
          end)

        %StationTicket{}
        |> StationTicket.changeset(%{
          order_id: order.id,
          station: station,
          status: "queued",
          table_number: order.table_number,
          items_payload: payload,
          target_prep_seconds: max_prep
        })
        |> repo.insert!()
      end)

    {:ok, tickets}
  end

  defp enrich_order_items(attrs) do
    raw_items = Map.get(attrs, "items") || Map.get(attrs, :items) || []
    menu_ids = Enum.map(raw_items, fn i -> i["menu_item_id"] || i[:menu_item_id] end) |> Enum.reject(&is_nil/1)

    menu_map =
      if menu_ids == [] do
        %{}
      else
        MenuItem
        |> where([m], m.id in ^menu_ids)
        |> Repo.all()
        |> Map.new(&{&1.id, &1})
      end

    enriched_items =
      Enum.map(raw_items, fn item ->
        mid = item["menu_item_id"] || item[:menu_item_id]
        qty = item["quantity"] || item[:quantity] || 1
        notes = item["notes"] || item[:notes]

        case Map.get(menu_map, mid) do
          %MenuItem{} = m ->
            %{
              menu_item_id: m.id,
              quantity: qty,
              notes: notes,
              station: m.station,
              item_name: m.name,
              prep_time_seconds: m.prep_time_seconds
            }

          nil ->
            %{menu_item_id: mid, quantity: qty, notes: notes}
        end
      end)

    attrs
    |> Map.new(fn {k, v} -> {to_string(k), v} end)
    |> Map.put("items", enriched_items)
  end

  defp maybe_filter_station(query, nil), do: query
  defp maybe_filter_station(query, station), do: where(query, [t], t.station == ^station)

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [t], t.status == ^status)
end

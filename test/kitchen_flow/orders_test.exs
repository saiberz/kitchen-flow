defmodule KitchenFlow.OrdersTest do
  use KitchenFlow.DataCase, async: true

  alias KitchenFlow.Catalog
  alias KitchenFlow.Orders

  setup do
    {:ok, steak} =
      Catalog.create_menu_item(%{
        sku: "GRILL-01",
        name: "Ribeye Steak",
        station: "grill",
        course: "main",
        prep_time_seconds: 900,
        price_cents: 3200
      })

    {:ok, ipa} =
      Catalog.create_menu_item(%{
        sku: "BAR-01",
        name: "House IPA",
        station: "bar",
        course: "drinks",
        prep_time_seconds: 120,
        price_cents: 850
      })

    %{steak: steak, ipa: ipa}
  end

  test "create_order/1 splits items into station tickets", %{steak: steak, ipa: ipa} do
    attrs = %{
      "table_number" => 12,
      "notes" => "Window table",
      "items" => [
        %{"menu_item_id" => steak.id, "quantity" => 2, "notes" => "Medium rare"},
        %{"menu_item_id" => ipa.id, "quantity" => 2}
      ]
    }

    assert {:ok, order} = Orders.create_order(attrs)
    assert order.table_number == 12
    assert length(order.station_tickets) == 2

    stations = Enum.map(order.station_tickets, & &1.station) |> Enum.sort()
    assert stations == ["bar", "grill"]
  end

  test "transition_ticket/2 updates status and timestamps", %{steak: steak} do
    {:ok, order} =
      Orders.create_order(%{
        "table_number" => 4,
        "items" => [%{"menu_item_id" => steak.id, "quantity" => 1}]
      })

    [ticket] = order.station_tickets
    assert ticket.status == "queued"

    assert {:ok, preparing} = Orders.transition_ticket(ticket, "preparing")
    assert preparing.status == "preparing"
    assert preparing.started_at != nil

    assert {:ok, ready} = Orders.transition_ticket(preparing, "ready")
    assert ready.status == "ready"
    assert ready.ready_at != nil
  end
end

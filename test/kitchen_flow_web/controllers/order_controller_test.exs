defmodule KitchenFlowWeb.OrderControllerTest do
  use KitchenFlowWeb.ConnCase, async: true

  alias KitchenFlow.Catalog

  setup %{conn: conn} do
    {:ok, item} =
      Catalog.create_menu_item(%{
        sku: "COLD-01",
        name: "Caesar Salad",
        station: "cold",
        course: "starter",
        prep_time_seconds: 240,
        price_cents: 1400
      })

    {:ok, conn: put_req_header(conn, "accept", "application/json"), item: item}
  end

  test "POST /api/orders creates order and returns station tickets", %{conn: conn, item: item} do
    payload = %{
      "order" => %{
        "table_number" => 7,
        "items" => [%{"menu_item_id" => item.id, "quantity" => 1}]
      }
    }

    conn = post(conn, Routes.order_path(conn, :create), payload)
    assert %{"id" => _id, "table_number" => 7, "station_tickets" => [ticket]} = json_response(conn, 201)["data"]
    assert ticket["station"] == "cold"
    assert ticket["status"] == "queued"
  end
end

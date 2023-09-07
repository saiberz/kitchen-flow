defmodule KitchenFlowWeb.Plugs.LocalePlugTest do
  use KitchenFlowWeb.ConnCase, async: true

  alias KitchenFlow.Catalog

  setup do
    {:ok, item} =
      Catalog.create_menu_item(%{
        sku: "GRILL-02",
        name: "Grilled Entrecote",
        name_translations: %{
          "en" => "Grilled Entrecote",
          "es" => "Entrecot a la parrilla",
          "sv" => "Grillad entrecote"
        },
        station: "grill",
        course: "main",
        prep_time_seconds: 600,
        price_cents: 2950
      })

    %{item: item}
  end

  test "GET /api/menu-items returns localized display_name via lang param", %{conn: conn} do
    conn_es = get(conn, "/api/menu-items?lang=es")
    assert [%{"display_name" => "Entrecot a la parrilla"}] = json_response(conn_es, 200)["data"]

    conn_sv = get(conn, "/api/menu-items?lang=sv")
    assert [%{"display_name" => "Grillad entrecote"}] = json_response(conn_sv, 200)["data"]
  end
end

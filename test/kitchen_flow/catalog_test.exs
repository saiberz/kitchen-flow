defmodule KitchenFlow.CatalogTest do
  use KitchenFlow.DataCase, async: true
  alias KitchenFlow.Catalog

  test "list_menu_items/0 returns all menu items" do
    assert Catalog.list_menu_items() == []

    {:ok, item} =
      Catalog.create_menu_item(%{
        sku: "TEST-01",
        name: "Test Burger",
        station: "grill",
        course: "main",
        prep_time_seconds: 300,
        price_cents: 1200
      })

    assert [found] = Catalog.list_menu_items()
    assert found.id == item.id
  end
end

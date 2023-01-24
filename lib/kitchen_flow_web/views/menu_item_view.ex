defmodule KitchenFlowWeb.MenuItemView do
  use KitchenFlowWeb, :view

  def render("index.json", %{menu_items: items}) do
    %{data: render_many(items, __MODULE__, "menu_item.json", as: :menu_item)}
  end

  def render("show.json", %{menu_item: item}) do
    %{data: render_one(item, __MODULE__, "menu_item.json", as: :menu_item)}
  end

  def render("menu_item.json", %{menu_item: item}) do
    %{
      id: item.id,
      sku: item.sku,
      name: item.name,
      station: item.station,
      course: item.course,
      prep_time_seconds: item.prep_time_seconds,
      price_cents: item.price_cents,
      available: item.available
    }
  end
end

defmodule KitchenFlowWeb.MenuItemView do
  use KitchenFlowWeb, :view
  alias KitchenFlow.Catalog.MenuItem

  def render("index.json", %{menu_items: items} = assigns) do
    locale = Map.get(assigns, :locale) || Gettext.get_locale(KitchenFlowWeb.Gettext)
    %{data: Enum.map(items, &render_item(&1, locale))}
  end

  def render("show.json", %{menu_item: item} = assigns) do
    locale = Map.get(assigns, :locale) || Gettext.get_locale(KitchenFlowWeb.Gettext)
    %{data: render_item(item, locale)}
  end

  defp render_item(item, locale) do
    %{
      id: item.id,
      sku: item.sku,
      name: item.name,
      display_name: MenuItem.localized_name(item, locale),
      name_translations: item.name_translations,
      station: item.station,
      course: item.course,
      prep_time_seconds: item.prep_time_seconds,
      price_cents: item.price_cents,
      available: item.available
    }
  end
end

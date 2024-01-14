alias KitchenFlow.Catalog
alias KitchenFlow.Catalog.MenuItem
alias KitchenFlow.Orders
alias KitchenFlow.Repo

seed_items = [
  %{
    sku: "GRILL-101",
    name: "Charcoal Ribeye",
    name_translations: %{
      "en" => "Charcoal Ribeye",
      "es" => "Entrecot a las brasas",
      "sv" => "Kolgrillad entrecote"
    },
    station: "grill",
    course: "main",
    prep_time_seconds: 720,
    price_cents: 3400
  },
  %{
    sku: "GRILL-102",
    name: "Iberian Pork Pluma",
    name_translations: %{
      "en" => "Iberian Pork Pluma",
      "es" => "Pluma ibérica a la parrilla",
      "sv" => "Grillad iberico pluma"
    },
    station: "grill",
    course: "main",
    prep_time_seconds: 600,
    price_cents: 2950
  },
  %{
    sku: "GRILL-103",
    name: "Wood-Fired Octopus",
    name_translations: %{
      "en" => "Wood-Fired Octopus",
      "es" => "Pulpo a la brasa",
      "sv" => "Vedugnsgrillad bläckfisk"
    },
    station: "grill",
    course: "main",
    prep_time_seconds: 540,
    price_cents: 2600
  },
  %{
    sku: "COLD-101",
    name: "Sea Bass Ceviche",
    name_translations: %{
      "en" => "Sea Bass Ceviche",
      "es" => "Ceviche de corvina",
      "sv" => "Havsabborre ceviche"
    },
    station: "cold",
    course: "starter",
    prep_time_seconds: 300,
    price_cents: 1850
  },
  %{
    sku: "COLD-102",
    name: "Beef Tartare & Egg Yolk",
    name_translations: %{
      "en" => "Beef Tartare & Egg Yolk",
      "es" => "Steak tartar con yema curada",
      "sv" => "Råbiff med gravad äggula"
    },
    station: "cold",
    course: "starter",
    prep_time_seconds: 360,
    price_cents: 1950
  },
  %{
    sku: "COLD-103",
    name: "Burrata & Heirloom Tomato",
    name_translations: %{
      "en" => "Burrata & Heirloom Tomato",
      "es" => "Burrata con tomate antiguo",
      "sv" => "Burrata med kulturtomat"
    },
    station: "cold",
    course: "starter",
    prep_time_seconds: 240,
    price_cents: 1650
  },
  %{
    sku: "BAR-101",
    name: "Smoked Negroni",
    name_translations: %{
      "en" => "Smoked Negroni",
      "es" => "Negroni ahumado",
      "sv" => "Rökt Negroni"
    },
    station: "bar",
    course: "drinks",
    prep_time_seconds: 120,
    price_cents: 1450
  },
  %{
    sku: "BAR-102",
    name: "Mezcal Paloma",
    name_translations: %{
      "en" => "Mezcal Paloma",
      "es" => "Paloma de mezcal",
      "sv" => "Mezcal Paloma"
    },
    station: "bar",
    course: "drinks",
    prep_time_seconds: 120,
    price_cents: 1400
  },
  %{
    sku: "BAR-103",
    name: "Sea Buckthorn Sour",
    name_translations: %{
      "en" => "Sea Buckthorn Sour",
      "es" => "Sour de espino amarillo",
      "sv" => "Havtorn Sour"
    },
    station: "bar",
    course: "drinks",
    prep_time_seconds: 150,
    price_cents: 1500
  },
  %{
    sku: "PASTRY-101",
    name: "Basque Cheesecake",
    name_translations: %{
      "en" => "Basque Cheesecake",
      "es" => "Tarta de queso vasca",
      "sv" => "Baskisk cheesecake"
    },
    station: "pastry",
    course: "dessert",
    prep_time_seconds: 240,
    price_cents: 1250
  },
  %{
    sku: "PASTRY-102",
    name: "Dark Chocolate Fondant",
    name_translations: %{
      "en" => "Dark Chocolate Fondant",
      "es" => "Coulant de chocolate negro",
      "sv" => "Chokladfondant"
    },
    station: "pastry",
    course: "dessert",
    prep_time_seconds: 420,
    price_cents: 1350
  },
  %{
    sku: "PASTRY-103",
    name: "Cardamom Crème Brûlée",
    name_translations: %{
      "en" => "Cardamom Crème Brûlée",
      "es" => "Crème brûlée de cardamomo",
      "sv" => "Kardemumma crème brûlée"
    },
    station: "pastry",
    course: "dessert",
    prep_time_seconds: 240,
    price_cents: 1200
  }
]

was_empty = Catalog.list_menu_items() == []

items_by_sku =
  Map.new(seed_items, fn attrs ->
    item =
      case Repo.get_by(MenuItem, sku: attrs.sku) do
        nil ->
          {:ok, created} = Catalog.create_menu_item(attrs)
          created

        existing ->
          existing
      end

    {attrs.sku, item}
  end)

if was_empty and System.get_env("SEED_DEMO_ORDERS") == "true" do
  {:ok, _order} =
    Orders.create_order(%{
      "table_number" => 5,
      "notes" => "Allergy: peanuts",
      "items" => [
        %{"menu_item_id" => items_by_sku["GRILL-101"].id, "quantity" => 2, "notes" => "Medium rare"},
        %{"menu_item_id" => items_by_sku["COLD-101"].id, "quantity" => 1},
        %{"menu_item_id" => items_by_sku["BAR-101"].id, "quantity" => 2}
      ]
    })
end

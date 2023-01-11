defmodule KitchenFlow.Repo.Migrations.CreateMenuItems do
  use Ecto.Migration

  def change do
    create table(:menu_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sku, :string, null: false
      add :name, :string, null: false
      add :station, :string, null: false
      add :course, :string, null: false, default: "main"
      add :prep_time_seconds, :integer, null: false, default: 300
      add :price_cents, :integer, null: false
      add :available, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:menu_items, [:sku])
    create index(:menu_items, [:station])
  end
end

defmodule KitchenFlow.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :table_number, :integer, null: false
      add :status, :string, null: false, default: "open"
      add :notes, :string

      timestamps()
    end

    create index(:orders, [:table_number])
    create index(:orders, [:status])

    create table(:order_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quantity, :integer, null: false, default: 1
      add :notes, :string
      add :station, :string, null: false
      add :item_name, :string, null: false
      add :prep_time_seconds, :integer, null: false, default: 300
      add :order_id, references(:orders, on_delete: :delete_all, type: :binary_id), null: false
      add :menu_item_id, references(:menu_items, on_delete: :restrict, type: :binary_id), null: false

      timestamps()
    end

    create index(:order_items, [:order_id])
    create index(:order_items, [:station])
  end
end

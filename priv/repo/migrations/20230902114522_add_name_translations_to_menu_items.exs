defmodule KitchenFlow.Repo.Migrations.AddNameTranslationsToMenuItems do
  use Ecto.Migration

  def change do
    alter table(:menu_items) do
      add :name_translations, :map, null: false, default: %{}
    end
  end
end

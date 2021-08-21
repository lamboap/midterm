defmodule Midterm.Repo.Migrations.AddWalletsTable do
  use Ecto.Migration

  def change do
    create table(:wallets) do
    add :balance, :float
    add :currency, :text, null: false
    add :user_id, references(:users, on_delete: :delete_all)
    end

    create unique_index(:wallets, [:user_id, :currency], name: :user_currency_uniq_index)

  end

end

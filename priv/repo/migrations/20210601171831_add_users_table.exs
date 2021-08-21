defmodule Midterm.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :text, null: false
      add :email, :text, null: false
    end

  end
end

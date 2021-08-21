defmodule Midterm.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    has_many :wallet, Midterm.Accounts.Wallet
  end

  @available_fields [:email, :name]

  def create_changeset(params) do
    changeset(%Midterm.Accounts.User{}, params)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, @available_fields)
    |> validate_required(@available_fields)
  end
end

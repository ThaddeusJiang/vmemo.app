defmodule Vmemo.Repo.Migrations.UsersFieldsUsernameDisplayname do
  use Ecto.Migration

  def change do
    alter table(:account_users) do
      add :display_name, :string, null: true
    end
  end
end

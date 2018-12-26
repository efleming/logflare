defmodule Logflare.Repo.Migrations.SourcesToUsers do
  use Ecto.Migration

  def change do
    alter table(:sources) do
      add :user_id, references (:users)
    end
  end
end

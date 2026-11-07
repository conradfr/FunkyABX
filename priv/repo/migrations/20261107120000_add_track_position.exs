defmodule FunkyABX.Repo.Migrations.AddTrackPosition do
  use Ecto.Migration

  def up do
    alter table("track") do
      add :position, :integer, default: nil, null: true
    end

    flush()

    # Keep the order tracks currently appear in (physical order, as there was no ORDER BY before)
    execute("""
    UPDATE track t SET position = s.rn
    FROM (
      SELECT id, row_number() OVER (PARTITION BY test_id ORDER BY ctid) - 1 AS rn
      FROM track
    ) s
    WHERE t.id = s.id
    """)

    create index("track", [:test_id, :position])
  end

  def down do
    drop index("track", [:test_id, :position])

    alter table("track") do
      remove :position
    end
  end
end

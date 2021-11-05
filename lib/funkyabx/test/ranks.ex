defmodule FunkyABX.Ranks do
  import Ecto.Query, only: [from: 2]
  alias FunkyABX.Repo
  alias FunkyABX.Track
  alias FunkyABX.Rank

  def get_ranks(test) do
    query =
      from r in Rank,
        join: t in Track,
        on: t.id == r.track_id,
        where: r.test_id == ^test.id,
        group_by: [r.rank, r.track_id, r.count, t.title],
        order_by: [asc: r.rank, desc: r.count],
        select: %{
          track_id: fragment("distinct on (?) ?", r.rank, r.track_id),
          track_title: t.title,
          rank: r.rank,
          count: fragment("MAX(?)", r.count)
        }

    Repo.all(query)
  end
end

#
# select distinct on (r.rank) r.track_id, r.rank, MAX(r.count) as count
#                                                             from rank r
#                                                             inner join track t on t.id = r.track_id
# where r.test_id = 3
# group by rank, r.track_id, r.count
#               order by r.rank asc, r.count desc;

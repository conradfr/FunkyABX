defmodule FunkyABX.Comments do
  require Logger
  import Ecto.Query, only: [from: 2, dynamic: 2, limit: 3]

  alias Ecto.UUID
  alias FunkyABX.Repo
  alias FunkyABX.{Test, Comment}
  alias FunkyABX.Notifier.Email

  def get_comments(%Test{} = test) do
    query =
      from(c in Comment,
        where: c.test_id == ^test.id,
        order_by: [asc: c.inserted_at],
        select: c
      )

    Repo.all(query)
  end

  def comment_posted(%Test{} = test, %Comment{} = comment) do
    FunkyABXWeb.Endpoint.broadcast!(test.id, "comment_posted", nil)
    if test.user != nil, do: Email.comment_posted(test, comment)
  end
end

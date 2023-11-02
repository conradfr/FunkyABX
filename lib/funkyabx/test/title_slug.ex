defmodule FunkyABX.Test.TitleSlug do
  import Ecto.Query
  use EctoAutoslugField.Slug, from: :title, to: :slug
  alias FunkyABX.Repo
  alias FunkyABX.Test

  # The slug library does not implements auto-increment if the slug already exists so we do it here instead
  def build_slug(sources, %Ecto.Changeset{} = changeset) do
    slug = super(sources, changeset)

    count =
      Repo.one(
        from t in Test,
          select: fragment("count(?)", t.id),
          where: fragment("? ~ ('^' || ? || '(-[0-9]{1,}){0,}$')", t.slug, ^slug)
      )

    case count do
      0 -> slug
      _ -> get_next_available_slug(slug, count)
    end
  end

  defp get_next_available_slug(slug, starting_point) do
    increment = starting_point + 1
    next_slug = slug <> "-" <> Integer.to_string(increment)

    case Repo.get_by(Test, slug: next_slug) do
      nil -> next_slug
      _ -> get_next_available_slug(slug, increment)
    end
  end

end

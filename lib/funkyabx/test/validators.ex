defmodule FunkyABX.Tests.Validators do
  import Ecto.Changeset

  # ---------- DATA ----------

  def ensure_regular_type(changeset) do
    rating = get_field(changeset, :rating)

    case rating do
      false -> put_change(changeset, :regular_type, nil)
      _ -> changeset
    end
  end

  def ensure_not_public_when_password_and_encode(changeset) do
    changeset
    |> get_field(:password_enabled)
    |> password_values(changeset)
  end

  defp password_values(password_enabled, changeset) when password_enabled == false do
    changeset
    |> put_change(:password_enabled, password_enabled)
    |> put_change(:password_length, nil)
    |> put_change(:password, nil)
  end

  defp password_values(password_enabled, changeset) do
    current_password = get_field(changeset, :password_length)

    password =
      changeset
      |> get_field(:password_input)
      |> case do
        nil ->
          nil

        value ->
          String.trim(value)
      end
      |> case do
        nil -> nil
        "" -> nil
        value -> value
      end

    case password do
      nil when is_nil(current_password) ->
        add_error(changeset, :password_input, "Password can't be empty")

      nil ->
        changeset

      value ->
        changeset
        |> put_change(:password_length, String.length(value))
        |> put_change(:password_enabled, password_enabled)
        |> put_change(:password, Pbkdf2.hash_pwd_salt(value))
        |> put_change(:public, false)
    end
  end

  def ensure_no_notification_when_not_logged(changeset) do
    case get_field(changeset, :user) do
      nil ->
        put_change(changeset, :email_notification, false)

      _ ->
        changeset
    end
  end

  defp at_least_one_regular(changeset) do
    rating = get_field(changeset, :rating)
    identification = get_field(changeset, :identification)

    unless rating == false and identification == false do
      changeset
    else
      add_error(changeset, :type, "Select at least one option.")
    end
  end

  # ---------- VALIDATE ----------

  def validate_general_type(changeset) do
    type = get_field(changeset, :type)

    case type do
      :regular ->
        changeset
        |> at_least_one_regular()

      _ ->
        changeset
    end
  end

  def validate_ranking_extremities(changeset, minimum_tracks_count) do
    tracks = get_field(changeset, :tracks)
    rating = get_field(changeset, :rating)
    regular_type = get_field(changeset, :regular_type)
    ranking_only_extremities = get_field(changeset, :ranking_only_extremities)

    if rating == true and regular_type == :raking and
         Kernel.length(tracks) < minimum_tracks_count and
         ranking_only_extremities == true do
      add_error(changeset, :type, "Ranking only top/worst tracks is only allowed with 10+ tracks")
    else
      changeset
    end
  end

  def validate_anonymized(changeset) do
    type = get_field(changeset, :type)

    case type do
      :regular -> put_change(changeset, :anonymized_track_title, true)
      :listening -> put_change(changeset, :anonymized_track_title, false)
      :abx -> changeset
    end
  end

  def validate_nb_rounds(changeset) do
    type = get_field(changeset, :type)

    case type do
      :abx -> changeset
      _ -> put_change(changeset, :nb_of_rounds, 1)
    end
  end
end

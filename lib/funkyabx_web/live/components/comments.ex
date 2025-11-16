defmodule CommentsComponent do
  use FunkyABXWeb, :live_component
  import Phoenix.HTML.Form
  alias FunkyABX.Repo
  use PhoenixHTMLHelpers

  alias FunkyABX.{Test, Comment}
  alias FunkyABX.Accounts.User
  alias FunkyABX.Comments

  attr :test, Test, required: true
  attr :user, User, required: false, default: nil
  attr :timezone, :string, required: true
  attr :ip_address, :string, required: true

  @impl true
  def render(assigns) do
    ~H"""
    <div class="test-comments my-5" phx-hook="Comments" id="comments">
      <h5 class="header-neon mb-3">{dgettext("comments", "Comments")}</h5>
      <div :if={length(@comments) == 0} class="fs-7 text-body-secondary">
        {dgettext("test", "No comments yet.")}
      </div>
      <div :if={length(@comments) > 0} class="row">
        <div class="col-md-8">
          <%= for comment <- @comments do %>
            <div class="comment mb-3">
              <div class="d-flex justify-content-between align-items-center">
                <div class="comment-author mb-1 text-body-secondary header-texgyreadventor">
                  {comment.author}
                </div>
                <div
                  :if={comment.id in @editable_comments}
                  class="text-muted cursor-pointer"
                  phx-click="edit"
                  phx-value-comment_id={comment.id}
                  phx-target={@myself}
                >
                  <small>{dgettext("comments", "edit comment")}</small>
                </div>
                <div
                  :if={comment.id in @editable_comments}
                  class="text-muted cursor-pointer"
                  phx-click="delete"
                  phx-value-comment_id={comment.id}
                  phx-target={@myself}
                  data-confirm={
                    dgettext(
                      "comments",
                      "Are you sure you want to delete this comment?"
                    )
                  }
                >
                  <small>{dgettext("comments", "delete comment")}</small>
                </div>
                <div class="text-extra-muted">
                  <small>
                    <%= if comment.inserted_at == comment.updated_at do %>
                      {raw(
                        dgettext(
                          "comments",
                          "Posted on <time datetime=\"%{created_at}\">%{created_at_format}</time>",
                          created_at: comment.inserted_at,
                          created_at_format:
                            format_date_time(comment.inserted_at, timezone: @timezone)
                        )
                      )}
                    <% else %>
                      {raw(
                        dgettext(
                          "test",
                          "Updated on <time datetime=\"%{updated_at}\">%{updated_at_format}</time>",
                          updated_at: comment.updated_at,
                          updated_at_format: format_date_time(comment.updated_at, timezone: @timezone)
                        )
                      )}
                    <% end %>
                  </small>
                </div>
              </div>
              <div class="comment-text py-2 px-2">
                {comment.comment
                |> html_escape()
                |> safe_to_string()
                |> AutoLinker.link(rel: false, scheme: true)
                |> text_to_html(escape: false)}
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <h5 class="header-neon mt-4 mb-2">{dgettext("test", "Post a comment")}</h5>
      <.form
        :let={f}
        for={@changeset}
        phx-change="validate"
        phx-submit="post"
        phx-target={@myself}
        id="comment-form"
        class="mt-3"
      >
        <input
          type="hidden"
          id={input_id(f, :test_id)}
          name={input_name(f, :test_id)}
          value={input_value(f, :test_id)}
        />

        <div class="mb-2 col-md-4">
          <.input
            field={f[:author]}
            type="text"
            label={dgettext("test", "Name:")}
            required
          />
        </div>

        <div class="mb-3 col-md-8">
          <.input
            field={f[:comment]}
            type="textarea"
            label={dgettext("test", "Comment")}
            rows="5"
          />
        </div>

        <button
          type="submit"
          class="btn btn-primary"
          phx-disable-with="Saving..."
          disabled={!@changeset.valid?}
        >
          {dgettext("test", "Post comment")}
        </button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  # This is a hack to respond to a refresh comments from the LiveView
  @impl true
  def update(%{update_comments: true} = assigns, socket) do
    {:ok, assign(socket, :comments, Comments.get_comments(socket.assigns.test))}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:editable_comments, fn -> [] end)
     |> assign_new(:comments, fn -> Comments.get_comments(assigns.test) end)
     |> assign_new(:comment, fn ->
       Comment.new(%{test: assigns.test, ip_address: assigns.ip_address, user: assigns.user})
     end)
     |> assign_new(:changeset, fn ->
       %{test: assigns.test, ip_address: assigns.ip_address, user: assigns.user}
       |> Comment.new()
       |> Comment.changeset()
     end)}
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params, "_target" => target}, socket) do
    changeset = Comment.changeset(socket.assigns.comment, comment_params)

    {:noreply,
     assign(socket,
       changeset: changeset
     )}
  end

  @impl true
  def handle_event("comment_author", params, socket) do
    comment = %{socket.assigns.comment | author: params["author"]}

    changeset =
      comment
      |> Comment.changeset()

    {:noreply, assign(socket, comment: comment, changeset: changeset)}
  end

  @impl true
  def handle_event(
        "post",
        %{"comment" => comment_params},
        %{assigns: %{test: test, comment: comment}} = socket
      ) do
    is_edit = comment.id != nil

    insert =
      case is_edit do
        false ->
          socket.assigns.comment
          |> Comment.changeset(comment_params)
          |> Repo.insert()

        true ->
          socket.assigns.comment
          |> Comment.changeset(comment_params)
          |> Repo.update()
      end

    case insert do
      {:ok, comment} ->
        init_comment =
          Comment.new(%{
            test: test,
            ip_address: socket.assigns.ip_address,
            author: comment.author,
            user: socket.assigns.user
          })

        changeset = Comment.changeset(init_comment, %{})
        comments = Comments.get_comments(test)

        if is_edit == false do
          send(
            self(),
            {:put_flash, [:success, dgettext("comments", "Your comment has been posted.")]}
          )

          spawn(fn ->
            Comments.comment_posted(test, comment)
          end)
        else
          send(
            self(),
            {:put_flash, [:success, dgettext("comments", "Your comment has been updated.")]}
          )
        end

        {:noreply,
         socket
         |> push_event("save_comment_author", %{author: comment.author})
         |> assign(
           editable_comments: socket.assigns.editable_comments ++ [comment.id],
           author: comment.author,
           comments: comments,
           comment: init_comment,
           changeset: changeset
         )}

      _ ->
        send(self(), {:put_flash, [:error, dgettext("comments", "An error occurred.")]})
        {:noreply, assign(socket, comment: comment)}
    end
  end

  @impl true
  def handle_event("edit", %{"comment_id" => string_comment_id} = _value, socket) do
    with comment_id <- String.to_integer(string_comment_id),
         true <- comment_id in socket.assigns.editable_comments,
         %Comment{} = comment <- Repo.get(Comment, comment_id) do
      changeset = Comment.changeset(comment, %{})
      {:noreply, assign(socket, comment: comment, changeset: changeset)}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete", %{"comment_id" => string_comment_id} = _value, socket) do
    with comment_id <- String.to_integer(string_comment_id),
         true <- comment_id in socket.assigns.editable_comments,
         %Comment{} = comment <- Repo.get(Comment, comment_id),
         {:ok, _comment} <- Repo.delete(comment) do
      send(
        self(),
        {:put_flash, [:success, dgettext("comments", "Your comment has been deleted.")]}
      )

      {:noreply, assign(socket, :comments, Comments.get_comments(socket.assigns.test))}
    else
      _ -> {:noreply, socket}
    end
  end
end

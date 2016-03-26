defmodule Rumbl.VideoController do
  use Rumbl.Web, :controller
  alias Rumbl.Video
  alias Rumbl.Category

  plug :scrub_params, "video" when action in [:create, :update]
  plug :load_categories when action in [:new, :create, :edit, :update]

  # Every controller has its own default action function, which is a plug that dispatches
  # to the proper action at the end of the controller pipeline. This will replace that default
  # action function and pass a third variable to every function: conn.assigns.current_user.
  # Every function had to be changed to accept this new variable.
  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, user) do
    videos = Repo.all(user_videos(user))
    render(conn, "index.html", videos: videos)
  end

  def new(conn, _params, user) do

    # We need to point user_id to the id of the user current stored in the connection at
    # conn.assigns.current_user. Since the action function will cause current_user to be
    # passed to the user variable, we can just use that. The build_assoc function form Ecto
    # will create the association.
    changeset =
      user
      |> build_assoc(:videos)
      |> Video.changeset()

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"video" => video_params}, user) do
    changeset =
      user
      |> build_assoc(:videos)
      |> Video.changeset(video_params)

    case Repo.insert(changeset) do
      {:ok, _video} ->
        conn
        |> put_flash(:info, "Video created successfully.")
        |> redirect(to: video_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, user) do
    video = Repo.get!(user_videos(user), id)
    render(conn, "show.html", video: video)
  end

  def edit(conn, %{"id" => id}, user) do
    video = Repo.get!(user_videos(user), id)
    changeset = Video.changeset(video)
    render(conn, "edit.html", video: video, changeset: changeset)
  end

  def update(conn, %{"id" => id, "video" => video_params}, user) do
    video = Repo.get!(user_videos(user), id)
    changeset = Video.changeset(video, video_params)

    case Repo.update(changeset) do
      {:ok, video} ->
        conn
        |> put_flash(:info, "Video updated successfully.")
        |> redirect(to: video_path(conn, :show, video))
      {:error, changeset} ->
        render(conn, "edit.html", video: video, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    video = Repo.get!(user_videos(user), id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(video)

    conn
    |> put_flash(:info, "Video deleted successfully.")
    |> redirect(to: video_path(conn, :index))
  end

  # Only returns videos associated with the particular user.
  defp user_videos(user) do
    assoc(user, :videos)
  end

  # Functional plug that builds a query, then passes that query to the repo in order
  # to retrive the categories. Using assign(conn, :categories, categories), this plug will
  # make those categories available as @categories.
  defp load_categories(conn, _) do
    query =
      Category
      |> Category.alphabetical
      |> Category.names_and_ids
    categories = Repo.all query
    assign(conn, :categories, categories)
  end
end

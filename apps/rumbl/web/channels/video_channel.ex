defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel
  alias Rumbl.AnnotationView

  def join("videos:" <> video_id, params, socket) do

    # Pulls the last_seen_id from the channel params. If nothing, id set to 0
    last_seen_id = params["last_seen_id"] || 0

    video_id = String.to_integer(video_id)

    # Fetches the video from the repo
    video = Repo.get!(Rumbl.Video, video_id)

    # Fetches all annotations for the video, using the index. Preloads user
    # associations. Only selects annotations created after the last_seen_id
    annotations = Repo.all(
      from a in assoc(video, :annotations),
        where: a.id > ^last_seen_id,
        order_by: [asc: a.at],
        limit: 200,
        preload: [:user]
    )

    # Composed a response by rendering an annotation.json view for every
    # annotation in our list using Phoenix.View.render_many. That function
    # essentially offloads the work to the work to the view layer.
    resp = %{annotations: Phoenix.View.render_many(annotations, AnnotationView,
                                                   "annotation.json")}

    {:ok, resp, assign(socket, :video_id, video_id)}
  end

  # Ensures every incoming event has the current_user, then calls our
  # handle_in/4 clause with the user as the 3rd argument.
  def handle_in(event, params, socket) do
    user = Repo.get(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  # Builds an annotation changeset for our user to persist the comment before
  # broadcasting it on the channel.
  def handle_in("new_annotation", params, user, socket) do
    changeset =
      user
      |> build_assoc(:annotations, video_id: socket.assigns.video_id)
      |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, ann} ->
        broadcast_annotation(socket, ann)
        # Asynchronous call. Using task means we don't care about the result
        # of the task. This will not block any particular messages arriving to
        # the channel.
        Task.start_link(fn -> compute_additional_info(ann, socket) end)
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp broadcast_annotation(socket, annotation) do
    annotation = Repo.preload(annotation, :user)
    rendered_ann = Phoenix.View.render(AnnotationView, "annotation.json", %{
      annotation: annotation
    })
    broadcast! socket, "new_annotation", rendered_ann
  end

  defp compute_additional_info(ann, socket) do
    # Only wants one result...the first, which should be the best based on the
    # sorting we do in InfoSys.
    for result <- InfoSys.compute(ann.body, limit: 1, timeout: 10_000) do
      attrs = %{url: result.url, body: result.text, at: ann.at}
      info_changeset =
        # Find username based on the backend name (set in info_sys/wolfram.ex)
        Repo.get_by!(Rumbl.User, username: result.backend)
        |> build_assoc(:annotations, video_id: ann.video_id)
        |> Rumbl.Annotation.changeset(attrs)

      case Repo.insert(info_changeset) do
        {:ok, info_ann} -> broadcast_annotation(socket, info_ann)
        {:error, _changeset} -> :ignore
      end
    end
  end
end

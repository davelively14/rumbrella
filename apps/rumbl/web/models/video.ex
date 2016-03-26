defmodule Rumbl.Video do
  use Rumbl.Web, :model

  # The primary key is still called :id, but it's of type Permalink now.
  # When any value is matched to the :id, it will go through Permalink's
  # casts, which will use Integer.parse to pull the first integer. As a result,
  # that will align with the underlying Ecto id, even though route calls will
  # pass id and slug.
  @primary_key {:id, Rumbl.Permalink, autogenerate: true}
  schema "videos" do
    field :url, :string
    field :title, :string
    field :description, :string
    field :slug, :string
    belongs_to :user, Rumbl.User
    belongs_to :category, Rumbl.Category
    has_many :annotations, Rumbl.Annotation

    timestamps
  end

  @required_fields ~w(url title description)
  @optional_fields ~w(category_id)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> slugify_title()

    # Because we established an association in the migration when creating the table, any
    # attempt to pick an invalid category resulting in an operation fail will create a constraint
    # error. This function allows us to catch the constraint error in the changeset, which
    # contains error information fit for human consumption.
    |> assoc_constraint(:category)
  end

  defp slugify_title(changeset) do
    if title = get_change(changeset, :title) do
      put_change(changeset, :slug, slugify(title))
    else
      changeset
    end
  end

  # Downcases the string and replaces nonword characers with a "-" character
  defp slugify(str) do
    str
    |> String.downcase
    |> String.replace(~r/[^\w-]+/, "-")
  end

  # Phoenix.Param is an Elixir protocol that, by default, extracts the id from
  # the struct. It is used to pass the id parameter by default when routing.
  # This function redefines the protocol for the Video data type, thus passing
  # the id-slug of every video as the path.
  defimpl Phoenix.Param, for: Rumbl.Video do
    def to_param(%{slug: slug, id: id}) do
      "#{id}-#{slug}"
    end
  end
end

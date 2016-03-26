defmodule Rumbl.User do
  use Rumbl.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    has_many :videos, Rumbl.Video
    has_many :annotations, Rumbl.Annotation

    timestamps
  end

  def changeset(model, params \\ :empty) do
    model
    # Using ~w(name username) is the same as typing ["name", "username"]
    # This 3rd parameter is a tuple for required fields
    # The 4th parameter is a tuple for optional fields
    # Returns an Ecto.Changeset, with all required and optional values assigned to
    # schema types
    #
    # Nothing is commited to the database until the Repo.insert(changeset) is called
    |> cast(params, ~w(name username), [])
    |> validate_length(:username, min: 1, max: 20)

    # Because we put 'create unique_index(:users, [:username])' in the migration when
    # creating the table, any attempt to create a duplicate entry will create a constraint
    # error. This function allows us to catch the constraint error in the changeset, which
    # contains error information fit for human consumption.
    |> unique_constraint(:username)
  end

  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, ~w(password), [])
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end
end

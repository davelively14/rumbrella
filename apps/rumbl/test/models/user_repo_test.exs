defmodule Rumbl.UserRepoTest do
  # We don't use the async: true option here because side-effects prevent us
  # from running these tests in isolation.
  use Rumbl.ModelCase
  alias Rumbl.User

  @valid_attrs %{name: "A User", username: "eva"}

  test "converts unique_constraint on username to error" do
    # Add user with a username of "eric" to the repo
    Rumbl.TestHelpers.insert_user(username: "eric")
    attrs = Map.put(@valid_attrs, :username, "eric")

    # Attempt to add another user with the same username as we added in the
    # Rumbl.TestHelpers.insert_user function above. Should throw an error.
    changeset = User.changeset(%User{}, attrs)

    assert {:error, changeset} = Repo.insert(changeset)
    assert {:username, "has already been taken"} in changeset.errors
  end
end

defmodule Rumbl.Auth do
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  # Added these two for authenticate_user function
  import Phoenix.Controller
  alias Rumbl.Router.Helpers

  # Extracts the repository, raising error if given key doesn't exist.
  # Rumbl.Auth will always require the :repo option
  #
  # Note: Keyword.fetch([a: 1, b: 2], :a) would return {:ok, 1}
  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  # Controversial change. We made our code more testable, but added complexity.
  def call(conn, repo) do
    # If a session :user_id exists, it will be assigned to user_id, otherwise nil
    user_id = get_session(conn, :user_id)

    # First condition to evaluate true is the only one that runs
    cond do
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      # If user_id is false, it won't go execute repo.get. Same as:
      #   if user_id, do: repo.get(Rumbl.User, user_id)
      user = user_id && repo.get(Rumbl.User, user_id) ->
        put_current_user(conn, user)

      # If no user is logged in, will assign nil
      true ->
        assign(conn, :current_user, nil)
    end

  end

  def login(conn, user) do
    conn
    |> put_current_user(user)
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)

    # Protects us from session fixation attacks. It tells Plug to send the session
    # cookie back to the client with a different identifier, in case an attacker knew
    # the previous one.
    |> configure_session(renew: true)
  end

  # Both assigns the user and the token to the connection for use in authorization
  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end

  def login_by_username_and_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Rumbl.User, username: username)

    # Match against different conditions to find first one that evaluates to true
    cond do

        # if user exists, then it will call Comeonin's checkpw function. If it returns
        # good, it will run the login function for that user and return the conn, then
        # return the conn
        user && checkpw(given_pass, user.password_hash) ->
          {:ok, login(conn, user)}

        # If user, then it means the password was all that failed from above.  This will
        # return the conn with an error :unauthorized.
        user ->
          {:error, :unauthorized, conn}

        # If all above fails, then it runs a dummy function to simulate password check
        # with variable timing. This hardens the authentication layer against timing
        # attacks.
        true ->
          dummy_checkpw()
          {:error, :not_found, conn}
    end
  end

  def logout(conn) do
    # Drops the entire session. Could have used delete_session(conn, :user_id) to keep
    # everything else besides the :user_id.
    configure_session(conn, drop: true)
  end


  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end
end

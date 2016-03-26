defmodule InfoSys.Wolfram do
  import SweetXml
  alias InfoSys.Result

  def start_link(query, query_ref, owner, limit) do
    # Calls fetch function upon start of link and passes all the params
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(query_str, query_ref, owner, _limit) do
    # Pipes the query_string as passed by to start_link
    query_str

    # Calls fetch_xml function below, should return a new string of xml
    |> fetch_xml()

    # Extracts the results from the xml from the string
    |> xpath(~x"/queryresult/pod[contains(@title, 'Result') or
                                 contains(@title, 'Definitions')]
                            /subpod/plaintext/text()")

    # Calls send_results and passes the resulting answer
    |> send_results(query_ref, owner)
  end

  # If no results, returns blank results
  defp send_results(nil, query_ref, owner) do
    send(owner, {:results, query_ref, []})
  end
  # Otherwise, it will return results to the owner formatted in Result
  defp send_results(answer, query_ref, owner) do
    results = [%Result{backend: "wolfram", score: 95, text: to_string(answer)}]
    send(owner, {:results, query_ref, results})
  end

  defp fetch_xml(query_str) do
    # :httpc ships with Erlang's standard library. Straight HTTP request.
    {:ok, {_, _, body}} = :httpc.request(
      String.to_char_list("http://api.wolframalpha.com/v2/query" <>
        "?appid=#{app_id()}" <>
        "&input=#{URI.encode(query_str)}&format=plaintext"))
    body
  end

  defp app_id, do: Application.get_env(:info_sys, :wolfram)[:app_id]
end

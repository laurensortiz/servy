defmodule Servy.Handler do

  @moduledoc """
    Handles HTTP requests.
  """

  alias Servy.Conv

  @pages_path Path.expand("../../pages", __DIR__)

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]

  @doc """
    Transformst the request into a response.
  """
  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> track
    |> format_response
  end

  def route(%Conv{ method: "GET", path: "/wildthings" } = conv) do
    %{ conv | resp_body: "Bears, Lions, Tigers", status: 200 }
  end

  def route(%Conv{ method: "GET", path: "/bears" } = conv) do
    %{ conv | resp_body: "Teddy, Paddington, Smokey", status: 200 }
  end

  def route(%Conv{ method: "GET", path: "/bears/" <> id } = conv) do
    %{ conv | resp_body: "Bear #{id}", status: 200 }
  end

  def route(%Conv{ method: "GET", path: "/about/" } = conv) do
    @pages_path
      |> Path.join("about.html")
      |> File.read
      |> handle_file(conv)
  end

  def handle_file({:ok, content}, conv) do
    %{ conv | status: 200, resp_body: content }
  end

  def handle_file({:error, :enoent}, conv) do
    %{ conv | status: 404, resp_body: "File not found" }
  end

  def handle_file({:error, reason}, conv) do
    %{ conv | status: 500, resp_body: "File error #{reason}" }
  end

  def route(%Conv{ method: "DELETE", path: "/bears/" <> id } = conv) do
    %{ conv | resp_body: "You can't delete bear # #{id}!", status: 403 }
  end

  def route(%Conv{ path: path } = conv) do
    %{ conv | resp_body: "No #{path} here", status: 404 }
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}
    Content-Type: text/html
    Content-Length: #{byte_size(conv.resp_body)}

    #{conv.resp_body}
    """
  end
end

request = """
GET /bears/4 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*
"""

request_delete = """
DELETE /besars/1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*
"""

request_exercise = """
GET /bears?id=1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*
"""

request_about = """
GET /about/ HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*
"""

# response = Servy.Handler.handle(request);
# response_delete = Servy.Handler.handle(request_delete);
# response_exercise = Servy.Handler.handle(request_exercise);
response_about = Servy.Handler.handle(request_about);

# IO.puts response
# IO.puts response_delete
# IO.puts response_exercise
IO.puts response_about

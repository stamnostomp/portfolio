defmodule Leaderboard.Mailer do
  @moduledoc """
  Delivers contact-form messages over SMTP submission.

  Works with any authenticated STARTTLS relay. For Proton (Business plan)
  generate an SMTP submission token and use:

      SMTP_HOST=smtp.protonmail.ch
      SMTP_PORT=587
      SMTP_USERNAME=you@yourdomain.com   # address the token was created for
      SMTP_PASSWORD=<smtp token>
      CONTACT_TO=you@yourdomain.com      # optional, defaults to SMTP_USERNAME

  Proton requires the From address to match the token's address, so the
  visitor's address goes in Reply-To.
  """

  require Logger

  @send_timeout 20_000

  def send_contact(name, email, message) do
    case config() do
      {:ok, cfg} -> deliver(cfg, name, email, message)
      :not_configured -> {:error, :not_configured}
    end
  end

  defp deliver(cfg, name, email, message) do
    mail = {cfg.from, [cfg.to], build_body(cfg, name, email, message)}

    task = Task.async(fn -> :gen_smtp_client.send_blocking(mail, smtp_options(cfg)) end)

    case Task.yield(task, @send_timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, receipt} when is_binary(receipt) ->
        :ok

      {:ok, {:error, type, detail}} ->
        Logger.error("contact mail rejected: #{inspect(type)} #{inspect(detail)}")
        {:error, :send_failed}

      {:ok, {:error, reason}} ->
        Logger.error("contact mail failed: #{inspect(reason)}")
        {:error, :send_failed}

      other ->
        Logger.error("contact mail timed out or crashed: #{inspect(other)}")
        {:error, :send_failed}
    end
  end

  defp build_body(cfg, name, email, message) do
    # Name and email are already validated single-line values, but strip CR/LF
    # again here so nothing typed into the form can inject extra headers.
    name = strip_newlines(name)
    email = strip_newlines(email)

    """
    Subject: [contact form] Message from #{ascii_only(name)}\r
    From: Contact Form <#{cfg.from}>\r
    To: #{cfg.to}\r
    Reply-To: #{email}\r
    MIME-Version: 1.0\r
    Content-Type: text/plain; charset=utf-8\r
    \r
    Name: #{name}
    Email: #{email}

    #{message}
    """
  end

  defp strip_newlines(value), do: String.replace(value, ~r/[\r\n]/, " ")

  # Headers must stay ASCII; anything else becomes '?' rather than pulling in
  # RFC 2047 encoding for a portfolio contact form.
  defp ascii_only(value) do
    for <<c <- value>>, into: "", do: if(c in 32..126, do: <<c>>, else: "?")
  end

  defp smtp_options(cfg) do
    [
      relay: String.to_charlist(cfg.host),
      port: cfg.port,
      username: String.to_charlist(cfg.username),
      password: String.to_charlist(cfg.password),
      auth: :always,
      tls: :always,
      tls_options: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        server_name_indication: String.to_charlist(cfg.host),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ],
        depth: 3
      ]
    ]
  end

  defp config do
    username = System.get_env("SMTP_USERNAME")
    password = System.get_env("SMTP_PASSWORD")

    if username in [nil, ""] or password in [nil, ""] do
      :not_configured
    else
      {:ok,
       %{
         host: System.get_env("SMTP_HOST", "smtp.protonmail.ch"),
         port: String.to_integer(System.get_env("SMTP_PORT", "587")),
         username: username,
         password: password,
         from: System.get_env("CONTACT_FROM", username),
         to: System.get_env("CONTACT_TO", username)
       }}
    end
  end
end

{:ok, _} = Application.ensure_all_started(:sentry)

ExUnit.start()

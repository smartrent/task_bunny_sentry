defmodule TaskBunnySentryTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias TaskBunny.JobError
  alias TaskBunnySentry.TestJob

  @job TestJob
  @payload %{"test" => true}

  setup do
    bypass = Bypass.open()

    event_id = to_string(:rand.uniform(1000))

    Bypass.expect(bypass, fn conn ->
      {:ok, _body, conn} = Plug.Conn.read_body(conn)
      Plug.Conn.resp(conn, 200, ~s<{"id": "#{event_id}"}>)
    end)

    Application.put_env(:sentry, :dsn, "http://public:secret@localhost:#{bypass.port}/1")
    Application.put_env(:sentry, :send_result, :sync)

    %{bypass: bypass, event_id: event_id}
  end

  describe "report_job_error/1" do
    test "handle an exception", %{event_id: event_id} do
      ex =
        try do
          raise "Hello"
        rescue
          e in RuntimeError -> e
        end

      error = JobError.handle_exception(@job, @payload, ex, [])

      assert {:ok, ^event_id} = TaskBunnySentry.report_job_error(error)
    end

    test "handle an exception with extra properties", %{event_id: event_id} do
      defmodule FooError do
        defexception([:message, :foo, :fizz])
      end

      ex =
        try do
          raise FooError, message: "Foo", foo: "bar", fizz: "buzz"
        rescue
          e in FooError -> e
        end

      error = JobError.handle_exception(@job, @payload, ex, [])
      assert {:ok, ^event_id} = TaskBunnySentry.report_job_error(error, extra: [:foo])
    end

    test "handle the exit signal", %{event_id: event_id} do
      reason =
        try do
          exit(:test)
        catch
          _, reason -> reason
        end

      error = JobError.handle_exit(@job, @payload, reason, [])
      assert {:ok, ^event_id} = TaskBunnySentry.report_job_error(error)
    end

    test "handle timeout error", %{event_id: event_id} do
      error = JobError.handle_timeout(@job, @payload)
      assert {:ok, ^event_id} = TaskBunnySentry.report_job_error(error)
    end

    test "handle the invalid return error", %{event_id: event_id} do
      error = JobError.handle_return_value(@job, @payload, {:error, :error_detail})
      assert {:ok, ^event_id} = TaskBunnySentry.report_job_error(error)
    end

    test "handle failure of upstream timeout", %{bypass: bypass} do
      Bypass.pass(bypass)
      Bypass.down(bypass)

      error = JobError.handle_return_value(@job, @payload, {:error, :error_detail})

      assert capture_log(fn ->
               assert :error = TaskBunnySentry.report_job_error(error)
             end) =~ "Elixir.TaskBunnySentry: Could not send error to upstream."
    end
  end
end

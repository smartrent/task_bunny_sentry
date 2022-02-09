defmodule TaskBunnySentry do
  @moduledoc """
  A TaskBunny failure backend that reports to Sentry.
  """
  use TaskBunny.FailureBackend
  require Logger
  alias TaskBunny.JobError

  @spec report_job_error(error :: JobError.t(), opts :: [extra: list(atom)]) ::
          Sentry.send_result()
  def report_job_error(error = %JobError{error_type: :exception}, opts = [extra: _]) do
    report_error(error.exception, error.stacktrace, error, opts)
  end

  @spec report_job_error(error :: JobError.t()) :: Sentry.send_result()
  def report_job_error(error = %JobError{error_type: :exception}) do
    report_error(error.exception, error.stacktrace, error)
  end

  def report_job_error(error = %JobError{error_type: :exit, job: job}) do
    %TaskBunnyError{message: "#{job_module(job)} - Unexpected exit signal"}
    |> report_error(error.stacktrace, error)
  end

  def report_job_error(error = %JobError{error_type: :return_value, job: job}) do
    %TaskBunnyError{message: "#{job_module(job)} - Unexpected return value"}
    |> report_error(original_stacktrace(Process.info(self(), :current_stacktrace)), error)
  end

  def report_job_error(error = %JobError{error_type: :timeout, job: job}) do
    %TaskBunnyError{message: "#{job_module(job)} - Timeout error"}
    |> report_error(original_stacktrace(Process.info(self(), :current_stacktrace)), error)
  end

  def report_job_error(error = %JobError{job: job}) do
    %TaskBunnyError{message: "#{job_module(job)} - Unknown error"}
    |> report_error(original_stacktrace(Process.info(self(), :current_stacktrace)), error)
  end

  defp job_module(job) do
    job
    |> Atom.to_string()
    |> String.replace("Elixir.", "")
  end

  ## PRIVATE FUNCTIONS

  defp original_stacktrace(stacktrace) do
    chunks = stacktrace |> elem(1) |> Enum.chunk_by(&(elem(&1, 0) == TaskBunnySentry))
    Enum.at(chunks, 1) ++ Enum.at(chunks, 2)
  end

  defp report_error(naked_exception, stacktrace, wrapped_error, opts \\ []) do
    extra =
      naked_exception
      |> Map.take(Keyword.get(opts, :extra, []))
      |> Map.merge(%{
        meta: inspect(wrapped_error.meta),
        job: wrapped_error.job,
        job_payload: wrapped_error.payload,
        pid: inspect(wrapped_error.pid),
        exit: wrapped_error.reason,
        return_value: inspect(wrapped_error.return_value)
      })

    with {:ok, _event_id} = result <-
           Sentry.capture_exception(naked_exception, stacktrace: stacktrace, extra: extra) do
      result
    else
      {:error, reason} ->
        Logger.error("#{__MODULE__}: Could not send error to upstream.
          JobError: #{inspect(naked_exception)} : #{inspect(extra)}
          Reason: #{inspect(reason)}")

        :error

      err ->
        Logger.error("#{__MODULE__}: unexpected error sending to upstream.
          JobError: #{inspect(naked_exception)} : #{inspect(extra)}
          Reason: #{inspect(err)}")

        :error
    end
  end
end

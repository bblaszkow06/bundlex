defmodule Bundlex.Platform do
  @type name_t :: atom

  @callback extra_otp_configure_options() :: [] | [String.t()]
  @callback required_env_vars() :: [] | [String.t()]
  @callback patches_to_apply() :: [] | [String.t()]
  @callback toolchain_module() :: module

  alias Bundlex.Output

  @doc """
  Converts platform passed as options into platform atom valid for further use
  and module that contains platform-specific callbacks.

  First argument are keyword list, as returned from `OptionParser.parse/2` or
  `OptionParse.parse!/2`.

  It expects that `platform` option was passed to options.

  In case of success returns platform name

  Otherwise raises Mix error.
  """
  @spec get_from_opts!(OptionParser.parsed()) :: name_t
  def get_from_opts!(opts) do
    cond do
      platform = opts[:platform] ->
        Bundlex.Output.info_substage("Selected target platform #{platform} via options.")
        String.to_atom(platform)

      true ->
        Bundlex.Output.info_substage(
          "Automatically detecting target platform to match current platform..."
        )

        get_current!()
    end
  end

  @doc """
  Detects current platform.

  In case of success returns platform name

  Otherwise raises Mix error.
  """
  @spec get_current! :: name_t
  def get_current! do
    case :os.type() do
      {:win32, _} ->
        {:ok, reg} = :win32reg.open([:read])
        :ok = :win32reg.change_key(reg, '\\hklm\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion')
        {:ok, build} = :win32reg.value(reg, 'BuildLabEx')

        platform_name =
          if build |> to_string |> String.contains?("amd64") do
            :windows64
          else
            :windows32
          end

        :ok = :win32reg.close(reg)

        platform_name

      {:unix, :linux} ->
        :linux

      {:unix, :darwin} ->
        :macosx

      other ->
        # TODO add detection for more platforms
        Output.raise(
          "Unable to detect current platform. Erlang returned #{inspect(other)} which I don't know how to handle."
        )
    end
  end

  def get_module!(:windows32), do: Bundlex.Platform.Windows32
  def get_module!(:windows64), do: Bundlex.Platform.Windows64
  def get_module!(:macosx), do: Bundlex.Platform.MacOSX
  def get_module!(:linux), do: Bundlex.Platform.Linux
  def get_module!(:android_armv7), do: Bundlex.Platform.AndroidARMv7
end

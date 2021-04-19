defmodule FarmbotCore.Firmware.UARTCoreSupport do
  defstruct path: "null", circuits_pid: nil

  @default_opts [
    active: true,
    speed: 115_200
  ]

  def connect(path) do
    {:ok, pid} = Circuits.UART.start_link()
    maybe_open_uart_device(pid, path)
  end

  def uart_send(uart_pid, text) do
    if is_pid(uart_pid) && Process.alive?(uart_pid) do
      :ok = Circuits.UART.write(uart_pid, text <> "\r\n")
    else
      raise "UART DIED!!"
    end
  end

  defp maybe_open_uart_device(pid, path) do
    if device_available?(path) do
      open_uart_device(pid, path)
    else
      {:error, :device_not_available}
    end
  end

  defp open_uart_device(pid, path) do
    :ok = Circuits.UART.open(pid, path, @default_opts)
    {:ok, pid}
  end

  defp device_available?(path) do
    Map.has_key?(Circuits.UART.enumerate(), path)
  end
end
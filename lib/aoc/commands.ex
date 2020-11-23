defmodule HelpCommand do
    def triggers?(message) do
        String.starts_with?(message, "!help")
    end
end

defmodule Wordex.Errors do
    @type value() :: nil | boolean() | String.t() | integer() | float()
    defexception message: "Wordex Error was found."

    @moduledoc """
    A module that contains functions to return errors to the terminal, always using status code 1 or 2. In addition, error_make() is the appropriate function to create errors

    @spec error_maker(message :: String.t(), status_code :: non_neg_integer()) :: no_return()
    defp error_maker(message, status_code) 

    Function that show a errors message before to raise a error.
    """


    @doc """
    Function that returns an error (in the shell) for an unknown option.
    """
    @spec invalid_option(option :: {String.t(), value()}) :: no_return()
    def invalid_option(option) do
        {name, _} = option
        error_maker("Invalid option: #{name}", 2)
    end

    @doc """
    Function that returns an error (in the shell) for missing arguments for a download request, in this case the dictionary's size
    """
    @spec missing_language() :: no_return()
    def missing_language() do
        error_maker("Missing the dictionary's language for download request.", 2)
    end

    @doc """
    Function that returns an error (in the shell) for missing arguments for a download request, in this case the dictionary's size
    """
    @spec missing_size() :: no_return()
    def missing_size() do
        error_maker("Missing the dictionary's size for download request.", 2)
    end

    @doc """
    Function that returns an error (in the shell) for invalid dictionary's language
    """
    @spec invalid_language() :: no_return()
    def invalid_language() do
        error_maker("Invalid dictionary's language.", 2)
    end

    @doc """
    Function that returns an error (in the shell) for invalid dictionary's size
    """
    @spec invalid_size() :: no_return()
    def invalid_size() do
        error_maker("Invalid dictionary's size.", 2)
    end

    @doc """
    Function that returns an error (in the shell) if no command or path is passed
    """
    @spec no_command() :: no_return()
    def no_command() do
        error_maker("No command was passed.", 2)
    end

    @doc """
    Function that returns an error (in the shell) if the path of file doesn't exist
    """
    @spec no_exist(file :: String.t()) :: no_return()
    def no_exist(file) do
        error_maker("The file \"#{file}\" does not exist", 1)
    end

    @doc """
    Function that returns an error (in the shell) if the path of folder doesn't exist
    """
    @spec no_folder(folder :: String.t()) :: no_return() 
    def no_folder(folder) do
        error_maker("The folder \"#{folder}\" does not exist", 1)
    end


    @spec error_maker(message :: String.t(), status_code :: non_neg_integer()) :: no_return()
    defp error_maker(message, status_code) do
        IO.puts(message <> "\nTry \"wordex -h\" for more information.")
        System.halt(status_code)
    end
end

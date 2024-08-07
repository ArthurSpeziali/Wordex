defmodule Wordex.Exec do
    @dialyzer {:nowarn_function, download_dict: 1}
    @dict_path "#{__DIR__}/../dictionaries"

    @moduledoc """
    Module to be used with the script, and create an executable.
    Uses the OptionParse module to manage the options, for more information, use the "--help" option.
    
    Main function is "main/1":
        @spec main(args :: [String.t()]) :: no_return()
        def main(args)
    """


    @doc """
    Function used by escript.
    Escript receives the "argv" from the shell, transforms it into a list of strings and passes it to the function.
    And finally, it uses the functions of the "Wordex" module.
    """
    @spec main(args :: [String.t()]) :: no_return()
    def main(args) do
        {opts, rest, unknow} = options(args)

        # Considering the unknown value as an error.
        if unknow != [] do
            List.first(unknow)
            |> Wordex.Errors.invalid_option()
        end

        if Keyword.has_key?(opts, :help) do
            IO.puts(help())
            # Exit the program after show message (Status code: 0).
            exit(:normal)
        end

        check_opts(opts)
        
        List.first(rest) |>
        case do
            "download" -> download_dict(opts)
            nil -> Wordex.Errors.no_command()
            _path -> nil
        end

    end


    @spec help() :: String.t()
    defp help() do
        """
        Wordex 1.0.0, made by Arthur Speziali. Project's Github: https://github.com/ArthurSpeziali/Wordex. See README.md (in project's folder) for more information.


        Usage: wordex --opts command {path/to/file}

        Commands:
            check                 Checks the file passed as an argument, looking at it word by word and correcting it if necessary.
                Affected by: All
                Arguments: path/to/file

            download              Dowload the english or portuguese dictionary to use off-line.
                Affected by: --language, --size
            

        Options:
            -h, --help             Show this help message.

            -l, --language         Set the language will be use, if not set, the program will try to guess the language of each word.
                It accepts: "en" (For English) or "pt" (For Portuguese)

            -a, --automatic        Set the mode "automatic", which replace each misspelled word for the most correct word, without asking.

            -s, --size             Set the dictionary's size.
                It accepts: "complex" (For big dictionary) or "light" (For small dictionary)

            -w, --write            Rewrite the new text (With new substitutions) into a new file.
                It accepts: path/to/file

            -c, --concatenate      Concatenate the new dictionary with the program's one.
                It accepts: path/to/file

            -o, --offline          Use the downloaded dictionaries. Need use "wordex download".

            -S, --spaces           Ignore spaces in a file when writing.
        """
    end


    @spec options(args :: [String.t()]) :: tuple()
    defp options(args) do
        OptionParser.parse(
            args,
            aliases: [h: :help, l: :language, i: :interactive, w: :write, c: :concatenate, s: :size, S: :spaces],
            strict: [help: :boolean, language: :string, interactive: :boolean, write: :string, concatenate: :string, size: :string, spaces: :boolean]
        )
    end

    
    @spec download_dict(opts :: list()) :: no_return()
    defp download_dict(opts) do
        # Checking if the dictionary file actually exists.
        if !File.exists?(@dict_path) do
            File.mkdir(@dict_path)
        end

        language = Keyword.get(opts, :language)
        size = Keyword.get(opts, :size)

        cond do
            !language -> Wordex.Errors.missing_language()
            !size -> Wordex.Errors.missing_size()
            true -> nil
        end


        # Using config Keyword to get the URl's dictionaries
        urls = Application.get_all_env(:wordex)

        command =
            # Matching size and language of dictionary and putting the value in "command".
            case {language, size} do
                {"pt", "light"} -> "curl -o '#{@dict_path}/portuguese-light.txt' '#{urls[:pt_light]}'"
                {"pt", "complex"} -> "curl -o '#{@dict_path}/portuguese-complex.txt' '#{urls[:pt_complex]}'"
                {"en", "light"} -> "curl -o #{@dict_path}/english-light.txt '#{urls[:en_light]}'"
                {"en", "complex"} -> "curl -o #{@dict_path}/english-complex.txt '#{urls[:en_complex]}'"
            end

        IO.puts("Downloading dictionary.")
        System.shell(command)
    end



    @spec check_opts(opts :: list()) :: no_return()
    defp check_opts(opts) do
        cond do
            # Checks if the option value is within a list, with the correct values.
            Keyword.get(opts, :language) not in [nil, "pt", "en"] -> Wordex.Errors.invalid_language()
            Keyword.get(opts, :size) not in [nil, "complex", "light"] -> Wordex.Errors.invalid_size()


            # Checks if the path of file or folder exists.
            Keyword.get(opts, :write) ->
                path = Keyword.get(opts, :write)
                       |> Path.dirname()

                if !File.exists?(path) do
                    Wordex.Errors.no_folder(path)
                end

            Keyword.get(opts, :dictionary) ->
                path = Keyword.get(opts, :dictionary)

                if !File.exists?(path) do
                    Wordex.Errors.no_exist(path)
                end


            true -> nil
        end
    end

end

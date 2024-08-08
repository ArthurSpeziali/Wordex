defmodule Wordex.Exec do
    @dialyzer {:nowarn_function, download_dict: 1, check_dict: 3}
    @dict_path "#{System.user_home}/.wordex"

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


            "check" -> 
                file_path = Enum.at(rest, 1)

                cond do
                    !file_path -> Wordex.Errors.no_path("check")
                    !File.exists?(file_path) -> Wordex.Errors.invalid_path("check")
                    true -> nil
                end

                result_path = Enum.at(rest, 2)
                if result_path do

                    result_folder = Path.dirname(result_path)
                    if !File.exists?(result_folder) do
                        Wordex.Errors.no_folder(result_folder)
                    end
                    
                    check_dict(opts, file_path, result_path)
                else
                    check_dict(opts, file_path, file_path)
                end


            nil -> Wordex.Errors.no_command()


            invalid_command -> Wordex.Errors.invalid_command(invalid_command)

        end

    end


    @spec help() :: String.t()
    defp help() do
        """
        Wordex 1.0.0, made by Arthur Speziali. Project's Github: https://github.com/ArthurSpeziali/Wordex. See README.md (in project's folder) for more information.


        Usage: wordex --opts command {path/to/file} {path/to/write}

        Commands:
            check                 Checks the file passed as an argument, looking at it word by word and correcting it if necessary.
                Affected by: All
                Arguments: path/to/file, path/to/write (Optional)

            download              Dowload the english or portuguese dictionary to use off-line.
                Affected by: --language, --size
            

        Options:
            -h, --help             Show this help message.

            -l, --language         Set the language will be use, if not set, the program will try to guess the language of each word.
                It accepts: "en" (For English) or "pt" (For Portuguese)

            -a, --automatic        Set the mode "automatic", which replace each misspelled word for the most correct word, without asking.

            -s, --size             Set the dictionary's size.
                It accepts: "complex" (For big dictionary) or "light" (For small dictionary)

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
            aliases: [h: :help, l: :language, a: :automatic, c: :concatenate, s: :size, S: :spaces, o: :offline],
            strict: [help: :boolean, language: :string, automatic: :boolean, concatenate: :string, size: :string, spaces: :boolean, offline: :boolean]
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
                {"pt", "light"} -> "curl -o '#{@dict_path}/pt-light.txt' '#{urls[:pt_light]}'"
                {"pt", "complex"} -> "curl -o '#{@dict_path}/pt-complex.txt' '#{urls[:pt_complex]}'"
                {"en", "light"} -> "curl -o #{@dict_path}/en-light.txt '#{urls[:en_light]}'"
                {"en", "complex"} -> "curl -o #{@dict_path}/en-complex.txt '#{urls[:en_complex]}'"
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
            Keyword.get(opts, :concatenate) ->
                path = Keyword.get(opts, :concatenate)

                if !File.exists?(path) do
                    Wordex.Errors.no_exist(path)
                end


            true -> nil
        end
    end


    @spec check_dict(opts :: tuple(), file_path :: Path.t(), result_path :: Path.t()) :: no_return()
    defp check_dict(opts, file_path, result_path) do
        language = Keyword.get(opts, :language)
        size = Keyword.get(opts, :size)

        # Match the dictionary size and language with the case. Default: English and Light.
        {language, size} = 
            case {language, size} do

                {nil, nil} -> {"en", "light"}
                {nil, size} -> {"en", size}
                {language, nil} -> {language, "light"}
                {language, size} -> {language, size}
            end


        dict = if Keyword.get(opts, :offline) do

            dict_file = "#{@dict_path}/#{language}-#{size}.txt"
            if !File.exists?(dict_file) do
                Wordex.Errors.dict_notfound("#{language}-#{size}.txt")
            end

            Wordex.offline_fetch(dict_file)

        else
            language_atom = String.to_atom(language)
            size_atom = String.to_atom(size)

            Wordex.online_fetch(language_atom, size_atom)
        end


        # Checks if the file exists, and concatenates it with String.concat with the previously chosen dictionary.
        dict = if Keyword.get(opts, :concatenate) do
            Wordex.offline_fetch(
                Keyword.get(opts, :concatenate)
            ) |> Stream.concat(dict)
        else
            dict
        end


        # Counts spaces when writing to the file, using the optional "false" argument.
        result = if Keyword.get(opts, :spaces) do
            Wordex.start(dict, file_path, false)
        else
            Wordex.start(dict, file_path)
        end


        if Keyword.get(opts, :automatic) do
            Wordex.force_change(result, result_path)
        else
            Wordex.ask_change(result, result_path)
        end

        :ok
    end

end

defmodule Wordex.Exec do
    @dialyzer {:nowarn_function, download_dict: 1}
    @dict_path "#{__DIR__}/../dictionaries"

    def main(args) do
        {opts, rest, unknow} = options(args)

        if unknow != [] do
            List.first(unknow)
            |> Wordex.Errors.invalid_option()
        end

        if Keyword.has_key?(opts, :help) do
            IO.puts(help())
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
            download              Dowload the english or portuguese dictionary to use off-line.
                Affected by: --language, --size


        Options:
            -h, --help             Show this help message.

            -l, --language         Set the language will be use, if not set, the program will try to guess the language of each word.
                It accepts: "en" (For English) or "pt" (For Portuguese)

            -a, --automatic        Set the mode "automatic", which replace each misspelled word for the most correct word, without asking.

            -i, --interactive      Set the mode "interactive", where it asks you which word will be replaced for the misspelled word (Or do nothing). This option already is default.

            -s, --size             Set the dictionary's size.
                It accepts: "complex" (For big dictionary) or "light" (For small dictionary)

            -w, --write            Rewrite the new text (With new substitutions) into a new file.
                It accepts: path/to/file

            -d, --dictionary       Concatenate the new dictionary with the program's one.
                It accepts: path/to/file

            -o, --offline          Use the downloaded dictionareis. Need use "wordex download"
        """
    end


    @spec options(args :: [String.t()]) :: tuple()
    defp options(args) do
        OptionParser.parse(
            args,
            aliases: [h: :help, l: :language, a: :automatic, i: :interactive, w: :write, d: :dictionary, s: :size],
            strict: [help: :boolean, language: :string, automatic: :boolean, interactive: :boolean, write: :string, dictionary: :string, size: :string]
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


        command =
            # Matching size and language of dictionary and putting the value in "command".
            case {language, size} do
                {"pt", "light"} -> "curl -o '#{@dict_path}/poruguese-light.txt' 'https://raw.githubusercontent.com/thoughtworks/dadoware/master/7776palavras.txt'"
                {"pt", "complex"} -> "curl -o '#{@dict_path}/poruguese-complex.txt' 'https://raw.githubusercontent.com/mmatje/br-wordlist/main/br-wordlist.txt'"
                {"en", "light"} -> "curl -o #{@dict_path}/english-light.txt 'https://raw.githubusercontent.com/jnoodle/English-Vocabulary-Word-List/master/Oxford%205000.txt'"
                {"en", "complex"} -> "curl -o #{@dict_path}/english-complex.txt 'https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa.txt'"
            end

        IO.puts("Downloading dictionary.")
        System.shell(command)
    end



    @spec check_opts(opts :: list()) :: no_return()
    def check_opts(opts) do

        cond do
            Keyword.get(opts, :language) not in [nil, "pt", "en"] -> Wordex.Errors.invalid_language()
            Keyword.get(opts, :size) not in [nil, "complex", "light"] -> Wordex.Errors.invalid_size()
            true -> nil
        end

    end

end

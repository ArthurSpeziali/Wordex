# Wordex
### Wordex 1.0.0, made by Arthur Speziali. Project's Github: https://github.com/ArthurSpeziali/Wordex.





## Dependencies:
	* erlang (OTP) => 24
	* elixir => 1.14
	* curl 

To access the functions, you need Elixir Erlang, if you only want to use the executable, only Erlang is needed. And Curl is used to download the dictionaries.






## Libraries and compilation
To download the project dependencies, inside the project folder, run the command `mix deps.get` to download the libraries, then `mix deps.compile` to compile the libraries.

`mix compile` Compiles the entire project, and the codes in "Wordex/lib/". To access interactive mode, use `iex -S mix`. The command to generate the executable using **escript** (Does not require Elixir, only Erlang) is the following command `mix escript.build`. To use the project's modules and functions in an external file, use the command `mix run file.exs`.






## Functions
To fix your file ("text.txt"), follow these steps:

1. Create a dictionary:
    ```elixir
    dict = Wordex.online_fetch(:en, :light)
    ```
	Languages and sizes:
	:en -> English
	:pt -> Portuguese

    :light -> 20Kb - 50Kb
    :complex -> 2Mb - 5Mb]

    

    To use a dictionary file, use:
    
    ```elixir
    dict = Wordex.offline_fetch("dict.txt")
    ```



2. Parse your file, with the dictionary, to find errors.

	```elixir
	parse = Wordex.start(dict, "arquivo.txt")
	```
	It may take a while depending on the size of your dictionary.




3. Finally, choose how to replace the misspellings with the correct words.
	```elixir
	Wordex.ask_change(parse, "new_file.txt")
	```
	To display a TUI, asking which of the suggestions will be replaced with the misspelled word.
	
	```elixir
	Wordex.force_change(parse, "new_file.txt")
	```
	For a more direct approach, where you take the first suggestion and automatically swap it for the wrong word.





## Executable
To use the executable, type the command `mix escript.build` then move to its folder in the PATH environment. On Windows, to move to the correct folder, the command is `move wordex C:\Windows\System32`, while on Linux it is `sudo mv wordex /usr/bin` and enter the sudo password.

To check the syntax and more, type `wordex -h`. An example here:
	`wordex -l en -s complex check "input.txt" "output.txt"`
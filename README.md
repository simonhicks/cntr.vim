# cntr.vim

`cntr.vim` is a data analysis tool for manipulating, analysing and visualising csv files.

## What is it?

`cntr.vim` is made up of two parts.

- A set of bash scripts for producing, manipulating and visualising streams of csv data. They are
  designed to be used in long unix pipe chains, with each command reading data from `STDIN`, applying a
transformation and then writing the results back to `STDOUT`. These scripts can be used as building blocks
for relatively complex transformations.

- A filetype and associated vim plugin designed to  make it easier to build, edit, debug and reuse
  these piped command chains to explore small-scale data a highly iterative manner. The plugin is
therefore optimised for rapid iteration, quick exploration and lightweight, ad-hoc analysis rather
than for building well engineered and repeatable data pipelines.

## TODO The commands

- copy (and update) from csv-utils
- add info about `AWK_INCLUDE_FILES`

## INPROGRESS Using the `.cntr` filetype plugin

Here's an example `.cntr` snippet

```
=repo-todos.csv
git grep '\(TODO\|FIXME\) ([^)]*)'
grep -o '\(TODO\|FIXME\) *([^)]*) *.*'
sed -e 's/,//g' -e 's/\(TODO\|FIXME\) *(\([^)]*\)) *:* *\(.*\)/\1,\2,\3/g'
add-headers type,user,comment

=todos-by-user.csv
cat %repo-todos.csv
count-by -g user
sort-by -c count -d desc

=todos-by-user.ascii
cat %todos-by-user.csv
head -n 6
histogram -l user -c count -d 140x30

=hacks-by-user.ascii
cat %repo-todos.csv
filter -c 'comment~/hack/'
count-by -g user
sort-by -c count -d desc
histogram -l user -c count -d 140x30
```

The snippet is divided into 4 blocks, with each block representing a pipe chain of commands.

- basic concepts tutorial using some dummy csv data
- slightly more advanced tutorial using data from ps and lsof
- include:
  - initializer blocks
  - named blocks
  - usage strings
  - linewise preview/full view
    - table vs. non-table
  - comments
  - starting from a command other than cat
  - charts
  - caching
  - anonymous pipes
  - csv export

## More docs are forthcoming

## Installation

`cntr.vim` is a regular vim plugin and can be installed using
[Vundle.vim](https://github.com/VundleVim/Vundle.vim),
[vim-pathogen](https://github.com/tpope/vim-pathogen), or any other Vim plugin installation process.

It also has some other dependencies, which should be installed before use.

## Dependencies

`cntr.vim` depends on the following things (from most obscure to least obscure)

- **`show#show()`:** a utility function for displaying output, provided by the
  [show.vim](https://github.com/simonhicks/show.vim) plugin. You should install it if you want to
use cntr.vim.
  
- **`gnuplot`:** a command line charting tool. `cntr.vim` was developed against version 4.6, but it
  doesn't use any fancy features, so it should work with earlier versions too.

- **`sha256()`:** a hashing function that is provided by the `+cryptv` feature compiled into vim. You
  almost certainly have this, but if you don't you'll probably have to recompile vim from source to
get it.

- **`zsh`**: an alternative shell (i.e. like bash, but different). N.B. You don't need to have zsh
  installed as your default shell... it just needs to be available.

- **`awk`:** a command line stream processing langauge. `cntr.vim` was developed against mawk 1.3.3.

- **`sed`:** another command line stream processing tool. `cntr.vim` was developed against version
  gnu sed 4.2.2.

Many of the \*nix commands used in `cntr.vim` differ in subtle ways between Mac and Linux...
Although it has been tested on a mac a little, `cntr.vim` was primarily developed on Linux and it's
possible that some Mac specific bugs have slipped through. If you've found something wrong and
you're using a Mac, it's probably that... **please let me know** and I promise I'll try to fix it as
soon as possible!

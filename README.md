# cntr.vim

`cntr.vim` is a vim plugin for producing, manipulating, analysing and visualising csv data.

## What is it?

`cntr.vim` is made up of two parts.

- A filetype and associated vim plugin designed to  make it easier to build, edit, debug and reuse
  long piped bash command chains a highly iterative and exploratory manner. The plugin is
therefore optimised for rapid iteration, quick exploration and lightweight, ad-hoc analysis rather
than for building well engineered and repeatable data pipelines.

- A set of bash scripts for producing, manipulating and visualising streams of csv data. They are
  designed to be used in long unix pipe chains, with each command reading data from `STDIN`,
applying a transformation and then writing the results back to `STDOUT`. These scripts can be used
in `cntr` files to as building blocks for relatively complex transformations.


## Using the `.cntr` filetype plugin

### Blocks

A `.cntr` analysis is composed of "blocks". Most blocks are "definition blocks" or "definitions". A
"definition" is a named series of simple bash commands, chained together to produce some output
(usually either csv or an ascii chart). Here's an example of a definition:

```{.cntr}
=repo-todos.csv
git grep '\(TODO\|FIXME\) ([^)]*)'
grep -o '\(TODO\|FIXME\) *([^)]*) *.*'
sed -e 's/,//g' -e 's/\(TODO\|FIXME\) *(\([^)]*\)) *:* *\(.*\)/\1,\2,\3/g'
add-headers type,user,comment
```

The first line of a definition block always starts with `=` and it gives the block its name. It ends
with the next empty line (or EOF) and the rest of the lines in the definition are a series of
commands, where STDOUT from each line is piped into STDIN for the next line. In this case the block
is named `repo-todos.csv`, and it uses the standard git, grep and sed commands, as well as the
add-headers command to produce a csv of TODO and FIXME comment data from a git repo.

### Using definition names

Within `cntr.vim` definition names are just like filenames, so the `.csv` extension means that
`cntr.vim` will treat the output as csv data. You can also use the `%` prefix to refer to the output
of a definition block as if it was a file. Here's another snippet that depends on the
`repo-todos.csv` block from above, and uses that to calculate the 10 hackiest devs on this repo and
plots a histogram displaying those results.

```{.cntr}
=hacks-by-user.csv
cat %repo-todos.csv
filter -c 'comment~/hack/'
count-by -g user
sort-by -c count -d desc

=hacks-by-user.ascii
cat %hacks-by-user.csv
head -n 10
histogram -l user -c count -d 140x30
```

When one definition block depends on another like that, `cntr.vim` will automatically keep track of
the dependency tree between blocks, so that when you try to run one it will automatically run all
the necessary upstream blocks in the correct order.

You can also create an anonymous definition block, by simply leaving the first line blank after the
`=`. Here's the same ascii chart block as an anonymous block.

```{.cntr}
=
cat %hacks-by-user.csv
head -n 10
histogram -l user -c count -d 140x30
```

### Executing a block

This is where things get interesting. You can execute a definition block by placing your cursor
anywhere within the block in normal mode, and hitting `c<CR>`. This will open a new window split
displaying the output of the block. If the block  produces csv data (like `repo-todos.csv` and
`hacks-by-user.csv`), the output will be formatted using table (so it's easier to read), but non-csv
blocks (like `hacks-by-user.ascii`) the output won't be formatted at all.

Sometimes, while debugging a definition it's useful to preview the output of a specific intermediate
step in the block. You can do that by putting your cursor on that line and hitting `cp` which will
print the first 10 lines of output of the block up to that point. You can also use `cP`, which does
the same thing, except without formatting.

That's actually pretty much all you need to know to for basic `cntr.vim` use, but there are a few
more details that can be handy to know.

### Getting help

Sometimes though it's not obvious how to use a particular command. Fortunately all the `cntr.vim` commands
have pretty good `--help` texts. You can see this quickly using `K`, which will take whatever word
is directly under your cursor, and run it in bash passing just the `--help` parameter. The resulting
help text is displayed at the bottom of the screen.

### Caching

Whenever a block is executed its output is cached so that it can be refered to multiple places in a
block (or in a series of blocks) without needing to be re-run each time it's used. That cache is
invalidated whenever you change the block itself, however the plugin only uses the `.cntr` file for
this, so *the cache will not be invalidated if something outside the `cntr` file changes*.

### Initializer blocks

Sometimes, it can be useful (or even necessary) to do setup things that don't fit neatly into this
paradigm, or that shouldn't be "cached", like cd'ing into a directory or setting an environment
variable. You can do this using "initializer" blocks. These look just like definition blocks, except
they do not begin with a name. Here's an example:

```{.cntr}
cd ~/src/hackety-hack
FOO=bar
```

Unlike definition blocks, initializer blocks are executed in sequence with no chaining of input and
output, they are never cached, and they can't be executed explicitly. They are always executed
before every other invocation, so you can assume that any state they create is always present when
your definitions run.

## The commands
### Test data

#### sales.csv

This is sales data for a fictional disney movie distributor with stores all around the world. The
first 10 rows look like this:

```
date     | location | film | format | amount
--------------------------------------------
20150908 | Tokyo    | 78   | mp4    | 16.99
20150909 | Tokyo    | 26   | mp4    | 15.99
20150901 | Berlin   | 99   | BluRay | 15.99
20150912 | London   | 93   | DVD    | 14.99
20150912 | Berlin   | 51   | HDDVD  | 14.99
20150903 | London   | 6    | VCR    | 15.99
20150918 | NYC      | 1    | VCR    | 17.99
20150930 | Tokyo    | 55   | VCR    | 17.99
20150913 | Berlin   | 78   | DVD    | 16.99
20150917 | Tokyo    | 33   | BluRay | 16.99
```

### titles.csv

This is a list of all the movies that the same distributor sells, along with some additional data.
The first 10 rows look like this:

```
id | title                          | date     | studio                           | price
-----------------------------------------------------------------------------------------
58 | The Jungle Book 2              | 20030214 | DisneyToon Studios               | 14.99
88 | Winnie the Pooh                | 20110715 | Walt Disney                      | 17.99
9  | Fun and Fancy Free             | 19470927 | Walt Disney                      | 17.99
93 | Frankenweenie                  | 20121105 | Tim Burton[st 3]                 | 14.99
83 | Toy Story 3                    | 20100618 | Pixar Animation Studios          | 18.99
3  | Fantasia                       | 19401113 | Walt Disney                      | 15.99
51 | Recess: School's Out           | 20010216 | Walt Disney Television Animation | 14.99
50 | The Emperor's New Groove       | 20001215 | Walt Disney                      | 18.99
34 | The Nightmare Before Christmas | 19931029 | Touchstone Pictures [st 2]       | 18.99
69 | Bambi II                       | 20060207 | DisneyToon Studios               | 17.99
```

### Examples

These examples are also available in `./example.cntr`

#### `table`

This is the most simple of all of the scripts. It lays things out in a neat table:

```
$ cat sales.csv | table
date      location  film  format  amount
20150908  Tokyo     78    mp4     16.99
20150909  Tokyo     26    mp4     15.99
20150901  Berlin    99    BluRay  15.99
20150912  London    93    DVD     14.99
20150912  Berlin    51    HDDVD   14.99
20150903  London    6     VCR     15.99
20150918  NYC       1     VCR     17.99
20150930  Tokyo     55    VCR     17.99
20150913  Berlin    78    DVD     16.99
20150917  Tokyo     33    BluRay  16.99
```

The remainder of these examples are all displayed using this script because it's easier to see
what's going on that way. If the `table` was removed from the end of any of these commands, then the
data would just look like a regular csv.

#### `columns`

This is used to limit output to specific columns, renaming them if necessary:

```
$ cat sales.csv | columns date,film=film_id,amount=price | table
date      film_id  price
20150908  78       16.99
20150909  26       15.99
20150901  99       15.99
20150912  93       14.99
20150912  51       14.99
20150903  6        15.99
20150918  1        17.99
20150930  55       17.99
20150913  78       16.99
20150917  33       16.99
```

#### `enrich`

This is where things get interesting. This script is used to enrich one csv using values from
another. For the example, lets add the extra info from titles.csv to each row in the sales data from
sales.csv. In SQL, this would be joining sales to titles where sales.film is equal to title.id

```
$ cat sales.csv | enrich -l titles.csv -k id -d film | table
date      location  format  amount  titles_id  titles_title                     titles_date titles_studio                     titles_price
20150908  Tokyo     mp4     16.99   78         Up                               20090529     Pixar Animation Studios           16.99
20150909  Tokyo     mp4     15.99   26         The Great Mouse Detective        19860702     Walt Disney                       15.99
20150901  Berlin    BluRay  15.99   99         The Wind Rises                   20140221     Studio Ghibli                     15.99
20150912  London    DVD     14.99   93         Frankenweenie                    20121105     Tim Burton[st 3]                  14.99
20150912  Berlin    HDDVD   14.99   51         Recess: School's Out             20010216     Walt Disney Television Animation  14.99
20150903  London    VCR     15.99   6          Saludos Amigos                   19420824     Walt Disney                       15.99
20150918  NYC       VCR     17.99   1          Snow White and the Seven Dwarfs  19371221     Walt Disney                       17.99
20150930  Tokyo     VCR     17.99   55         Lilo & Stitch                    20020621     Walt Disney                       17.99
20150913  Berlin    DVD     16.99   78         Up                               20090529     Pixar Animation Studios           16.99
20150917  Tokyo     BluRay  16.99   33         Aladdin                          19921125     Walt Disney                       16.99
...
```

That's a lot of data though, and now the headers aren't so great. Fortunately, `enrich` can also
selectively add only those columns you're interested in and can also rename them using a similar
syntax to `columns`. Lets enrich the sales data with just the movie title and the studio that
produced that movie.

```
$ cat sales.csv | enrich -l titles.csv -k id -d film -c title=movie_title,studio | table
date      location  format  amount  movie_title                      studio
20150908  Tokyo     mp4     16.99   Up                               Pixar Animation Studios
20150909  Tokyo     mp4     15.99   The Great Mouse Detective        Walt Disney
20150901  Berlin    BluRay  15.99   The Wind Rises                   Studio Ghibli
20150912  London    DVD     14.99   Frankenweenie                    Tim Burton[st 3]
20150912  Berlin    HDDVD   14.99   Recess: School's Out             Walt Disney Television Animation
20150903  London    VCR     15.99   Saludos Amigos                   Walt Disney
20150918  NYC       VCR     17.99   Snow White and the Seven Dwarfs  Walt Disney
20150930  Tokyo     VCR     17.99   Lilo & Stitch                    Walt Disney
20150913  Berlin    DVD     16.99   Up                               Pixar Animation Studios
20150917  Tokyo     BluRay  16.99   Aladdin                          Walt Disney
...
```

#### `count-by`

Now that you've got some joined up data, you can start doing some simple analysis. You can use
`count-by` to see which studio is selling the most movies.

```
$ cat test/sales.csv | enrich -l titles.csv -k id -d film -c title=movie_title,studio | count-by -g studio | table
studio                            count
                                  93
ImageMovers Digital[st 6]         208
Tim Burton[st 3]                  97
UTV Motion Pictures               119
DisneyToon Studios                1362
Yash Raj Films[st 5]              80
Touchstone Pictures [st 2]        92
Pixar Animation Studios           1371
Touchstone Pictures               217
Vanguard Animation                91
Skellington [st 3]                89
Studio Ghibli                     565
C.O.R.E.[st 4]                    106
Walt Disney Television Animation  311
Walt Disney                       5199
```

`count-by` supports grouping by a column (i.e. count the number of rows for each value of column X),
unique counts (i.e. count the number of unique values there are in column X), grouped unique counts
(i.e. count the number of unique values of column X there are in rows for each value of column Y)
and of course plain ol' counts (i.e. count the total number of rows)

#### `aggregate`

You also might want to look at the distribution of revenue between the different locations. You can
use `aggregate` to see the total sales of each location.

```
$ cat test/sales.csv | aggregate -g location -c amount -a sum | table
location  sum_of_amount
Tokyo     34840.6
Berlin    33544.4
London    33772.2
Paris     34341.9
NYC       34412.9
```

Aside from calculating sums, `aggregate` can also calculate min, max or mean values.

#### `sort-by`

You can use `sort-by` to numerically sort this data to see which location is the most profitable.

```
$ cat test/sales.csv | aggregate -g location -c amount -a sum | sort-by -s sum_of_amount -d desc | table
location  sum_of_amount
Tokyo     34840.6
NYC       34412.9
Paris     34341.9
London    33772.2
Berlin    33544.4
```

#### `filter`

`filter` is used to filter the rows based on some kind of condition. Lets say you're only
interested in the main Disney studios. You can use `filter` to filter results to only those rows
that include the word "Disney".

```
$ cat test/sales.csv | enrich -l titles.csv -k id -d film -c studio | count-by -g studio | filter -c 'studio~/.*Disney*./' | table
studio                            count
DisneyToon Studios                1362
Walt Disney Television Animation  311
Walt Disney                       5199
```

`filter` also supports other comparisons like ==, >=, >, <= and <. You can also remove the rows
which match the criteria by passing the `-n` flag.

```
$ cat test/sales.csv | enrich -l titles.csv -k id -d film -c studio | count-by -g studio | filter -n -c 'studio~/.*Disney*./' | table
studio                      count
                            93
ImageMovers Digital[st 6]   208
Tim Burton[st 3]            97
UTV Motion Pictures         119
Yash Raj Films[st 5]        80
Touchstone Pictures [st 2]  92
Pixar Animation Studios     1371
Touchstone Pictures         217
Vanguard Animation          91
Skellington [st 3]          89
Studio Ghibli               565
C.O.R.E.[st 4]              106
```

#### `derive`

`derive` is used to add a new column, based on the values of other columns. At this point, I'm far
too lazy to come up with realistic examples, but here's how you could use it to add a new column
containing the result of that row's id, plus that row's price.

```
$ head -n 5 test/titles.csv | derive -c id_plus_price -e 'id+price' | table
id  title               date      studio              price  id_plus_price
58  The Jungle Book 2   20030214  DisneyToon Studios  14.99  72.99
88  Winnie the Pooh     20110715  Walt Disney         17.99  105.99
9   Fun and Fancy Free  19470927  Walt Disney         17.99  26.99
93  Frankenweenie       20121105  Tim Burton[st 3]    14.99  107.99
```

This works by replacing the column header names in the expression with their awk column references,
and then directly substituting the resulting expression into an awk script. In other words the
expression parameter should support any valid awk expression, however since it's done using bash
substitution sometimes some pretty nasty bash escaping is needed to get it to actually work. Aside
from arithmetic operations (as the above example), the other common use case is string
concatenation. This is done as follows:

```
$ head -n 5 sales.csv | enrich -l titles.csv -k id -d film -c title=film | derive -c description -e '\"Someone bought \" film \" for £\" amount' | table
date      location  format  amount  film                       description
20150908  Tokyo     mp4     16.99   Up                         Someone bought Up for £16.99
20150909  Tokyo     mp4     15.99   The Great Mouse Detective  Someone bought The Great Mouse Detective for £15.99
20150901  Berlin    BluRay  15.99   The Wind Rises             Someone bought The Wind Rises for £15.99
20150912  London    DVD     14.99   Frankenweenie              Someone bought Frankenweenie for £14.99
```

#### `keep`

`keep` is used to provide set type operations. If you give it a lookup file, a column name from that
file and a column name from the data file it will emit the rows from the data file for which the
value in the data file column matches one of the values found in the lookup file column (in the
lookup file).

In other words, lets say you have a file called top-selling-films.csv containing the film id and
total\_sales for that film. If you want to filter the sales data to only those films, you can do
that as follows:

```
$ cat sales.csv | keep -l top-selling-films.csv -k film -d film | count
1326
```

You can also pass the -n flag to invert the selection (i.e. filter out the matching rows).

#### `bar-chart`

`bar-chart` is used to display simple bar charts. It will print 1 bar per row, using the value from
the column passed to -l for the label, and the value from the column passed to -c for the bar
length. By default it will use the entire width of your terminal, however you can override this with
the -w flag

```
$ cat sales.csv | aggregate -g film -a sum -c amount | head -n 10 | enrich -l titles.csv -k id -d film | columns titles_title=title,sum_of_amount=total_sales | bar-chart -c total_sales -l title -w 100
title                                  | total_sales
---------------------------------------+------------------------------------------------------------
The Many Adventures of Winnie the Pooh | *****************************************************
The Rescuers                           | ******************************************
The Fox and the Hound                  | ******************************************
The Black Cauldron                     | *********************************************
The Great Mouse Detective              | ************************************************
Who Framed Roger Rabbit                | ***************************************************
Oliver & Company                       | *******************************************************
The Little Mermaid                     | ************************************************

```

#### Working with other field separators and quoted csvs

All of these scripts can be configured to use a different field separator using the `-s` flag. You
can also use the `format` script to modify the field separator or to add/remove/change the character
used to quote field values in the middle of a pipeline. For example, in this (entirely contrived)
example, we do the following steps:

1. read the data from sales.csv using ',' as the field separator
2. convert the field separator to '|'
3. extract the 'location' and 'amount' columns using '|' as the field separator
4. convert the field separator back to ','
5. display the data in a table

```
$ cat test-data/sales.csv | format -s , -S \| | columns -s \| location\|amount | format -s \| -S , | table
```

Since you'll usually want to use the same field separator for each command in a chain, you can also
define the field separator by setting the `CSV_UTILS_SEPARATOR` environment variable. Using `-s`
will always take precedence though.

#### Adding awk extensions

Many of these commands use awk functions for transforming your data. If you want to add your own awk
functions to the execution environment, you can do so using the environment variable
`AWK_INCLUDE_FILES`. This is a `:` seperated list of paths that will be passed through to awk in all
the relevant commands.

## Warnings

- The vast majority of this is just awk, without anything particularly clever being done. None of
  these scripts handle escapes or quoting or anything like that yet.
- Some of these scripts assume that column headers only include "word characters" (i.e. a-z, A-Z,
  0-9 and \_).
- The character escaping can sometimes be a little counter intuitive.

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

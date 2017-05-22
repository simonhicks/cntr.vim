# cntr.vim

`cntr.vim` is a data analysis tool for manipulating, analysiing and visualising csv files.

## Docs are forthcoming

If you want to use this without docs, be my guest... but it's probably pretty cryptic! Good luck!

## Dependencies

`cntr.vim` depends on the following things (from most to least obscure)

- **`show#show()`:** a utility function for displaying output, provided by the
  [show.vim](https://github.com/simonhicks/show.vim) plugin. You should install it if you want to
use cntr.vim ...
  
- **`gnuplot`:** a command line charting tool. `cntr.vim` was developed against version 4.6, but it
  doesn't use any fancy features, so it should work with earlier versions.

- **`sha256()`:** a hashing function that is provided by the `+cryptv` feature compiled into vim. You
  almost certainly have this, but if you don't, you'll probably have to recompile vim from source to
get it.

- **`awk`:** a command line stream processing langauge. `cntr.vim` was developed against mawk 1.3.3.
  I have no idea if it'll work with older versions.

- **`sed`:** another command line stream processing tool. `cntr.vim` was developed against version
  4.2.2. I have no idea if it'll work with older versions.

Many of the \*nix commands used in `cntr.vim` differ in subtle ways between Mac and Linux...
Although it has been tested on a mac, `cntr.vim` was primarily developed on Linux and it's possible
that some Mac specific bugs have slipped through. If you've found something wrong and you're using a
Mac, it's probably that... **please let me know** and I promise I'll try to fix it as soon as
possible!

# checkForDups.pl

This is a perl script that will check for duplicate events over N files or via STDIN.

# Features

  . Processes N files in 1 pass.
  . Or Process STDIN.
  . Use a Regexp to include lines. 
  . Use a Regexp to exclude lines.
  . Use a Regexp to maskout patterns.
  . Use a Regexp to pickup and normalize JSON.
  . Reports...
    . File that contains dup.
    . Number of dups found in a given file.
    . Line Numbers where dups were found in a given file.


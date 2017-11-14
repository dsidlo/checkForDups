# checkForDups.pl

This is a perl script that will check for duplicate events over N files or via STDIN.

## Features

  * Processes N files in 1 pass.
  * Or Process STDIN.
  * Use a Regexp to include lines. 
  * Use a Regexp to exclude lines.
  * Use a Regexp to maskout patterns.
  * Use a Regexp to pickup and normalize JSON.
  * Reports...
    * File that contains dup.
    * Number of dups found in a given file.
    * Line Numbers where dups were found in a given file.

## checkForDups.pl
     Use this utility to check for duplicates within 1 or more files.
    The -files parameter can take a file glob (placed in single quotes),
    to match 1 or more files.

### Usage...

```
      checkForDups.pl  # Help
                       -[help|h]
                       # Regexp to include lines
                       -[incLines|il] '<RegExp>'
                       # Regexp to skip lines
                       -[skipLines|sl] '<RegExp>'
                       # Regexp Subst to mask substr
                       -[remask|rm] '[:;~]<RegExp>...'
                       # Mask Strings (Default: #MASKED#)
                       -[mask|m] '[:;~]<MaskString>...'
                       # Normalize JSON
                       -[nJson|nj] '<RegExp>'
                       # File Glob
                       -[file|files|f] '<FileGlob>'
                       # Report 1 or 2 lines
                       -[report|r]

      Example:
        ./checkForDups.pl -il '^\[' \
                          -f 'l2/fel_*.log' \
                          -rm '~\d+\.\d+\.\d+\.\d+~\d+\-\d+\-\d+T\d+\:\d+:\d+\.\d+Z~\"Sequence\":\d+~1515889680\-[^\"]+' \
                          -m '~~~"Sequence":"-seq-"~' \
                          -nj '^[^\{]+(\{.*\})$'

   (-help|h) Help
     Output this documentation.

   (-file|files|f '<FileGlob>') Match files (Required)
     The file option is required and should be enclosed in single quotes to
     ensure that the shell does not pre-interpret the file before perl
     gets it. Without the single quotes, the shell will add multiple files
     as the arguments to the parameter, and only the first file in the list
     will be seen and processed.

     Specifying dash '-' as the parameter will cause STDIN to be used instead
     of files. Thus, we can use this utility to detect duplicate piped into
     STDIN.

   (-incLines|il <RegExp>) Include Lines
     Use a regular express to inclue only those lines that match it.

   (-skipLies|sl <RegExp>) Exclude Lines
     Use a regular expression to exclude lines that match it.

   (-remask|rm <RegExp>) Mask Regular Expression
     Use this regular expression to Mask sub-strings within the line that match it.
     If the first char is ':' or ';' or '~', that indicates that there are multiple
     regular expressions that will be used to mask matching sub-strings.

     To define multiple regular expressions, the first character must be
     ':' or ';' or '~'.

     Example: -remask ":test:i:dgs"
              -mask ":---:^:zzz"

     -remask has been handed 3 regular expressions...
        :test
        :i
        :dgs

     -mask has been given 3 default mask overrides...
        :---
        :^
        :zzz

      If the input is: "This is a test! (dgs)"
      Output will look like: "Th^s ^s a ---:(zzz)"

     Note: regular expressions in -remask are executed globally on the input line.

   (-mask|m <RegExp>) Specify Masks
     By default that sub-string that matches a given -remask is masked with the
     default mask "#MASKED#".
     This option is used to change the default masking string.

     A string that contains one or more masks, that should be coordinated with
     the sequence of -remask regular expressions.

     So if you have 3 -remask expressions, you should have 3 -mask strings.

   (-nJson|nj <RegExp>) Normalize Captured JSON
     JSON objects can be output to logs such that elements in the JSON object
     are not consistently sorted. This option will capture the JSON in the
     text line, and normalize it, or sort its content, then output it to the
     text line, before it generates an md5sum. This will ensure that md5sums
     that are generated for similar JSON objects are the same, even if their
     elements had originally been output in different random orders.

     Example: -nj '^[^\{]+(\{.*\})$'

       - Input: [ALM] f_dst-fel {"GroupName":"dst","ServiceName":"fel","Component":"dst-fel","Host":"standard-1515889680-1lk28","Filename":"com.ancestry.boot.AncestryRestConfig","Method":"<init>","Thread":"main","Level":"INFO","Environment":"PPE","Process":1,"Sequence":1,"LogAgent":"java-2.1.0-SNAPSHOT-jdc-ri","LogVersion":"3.0","TimeStamp":"2017-11-07T00:05:20.430Z","Message":"Root package that JAXRS classes will be scanned for: [com.ancestry.dst]"}

     Given the input line, the regular expression will capture (group 1) and normalize a
     that JSON string.
     Group 1 must be specified in the parameters regular expression (at least
     1 set of parenthesis).

   (-report|r) Instead of reporting 1 line per file, report 2 lines.
     Instead of report 1 line for each file where a dup occurs, report
     2 lines, separating the file name from the dup count and line numbers,
     of the dups in the given file.

     Examples:
        (without -report)
     =[1]=> [ALM] f_dst-fel {"Component":"dst-fel", ... "Thread":"main","TimeStamp":"#MASKED#"}
     --> File: [l2/fel_standard-1515889680-ghgj0.log] Dups: [1] Lines: 86
     --> File: [l2/fel_standard-1515889680-40045.log] Dups: [1] Lines: 86
     --> File: [l2/fel_standard-1515889680-p7lfw.log] Dups: [1] Lines: 88
     --> File: [l2/fel_standard-1515889680-1lk28.log] Dups: [1] Lines: 87
     --> File: [l2/fel_standard-1515889680-zwlhl.log] Dups: [1] Lines: 86
     --> File: [l2/fel_standard-1515889680-vgww9.log] Dups: [1] Lines: 86
     ==> Total Dups: [6]

        (with -report)
     =[2]=> [ALM] f_dst-fel {"Component":"dst-fel", ... ,"Thread":"main","TimeStamp":"#MASKED#"}
     --> File: [l2/fel_standard-1515889680-vgww9.log]
     ~~> Dups: [1] Lines: 52
     --> File: [l2/fel_standard-1515889680-p7lfw.log]
     ~~> Dups: [1] Lines: 54
     --> File: [l2/fel_standard-1515889680-40045.log]
     ~~> Dups: [1] Lines: 52
     --> File: [l2/fel_standard-1515889680-zwlhl.log]
     ~~> Dups: [1] Lines: 52
     --> File: [l2/fel_standard-1515889680-1lk28.log]
     ~~> Dups: [1] Lines: 53
     --> File: [l2/fel_standard-1515889680-ghgj0.log]
     ~~> Dups: [1] Lines: 52
     ==> Total Dups: [6]
```

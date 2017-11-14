#!/opt/local/bin/perl
#!/usr/bin/perl

use Encode;
use JSON;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Getopt::Long;
use Try::Tiny;

use strict;

#
# Check for dup lines between a given set of file.
#

my $optHelp       = 0;
my $optIncLines   = "";
my $optSkipLines  = "";
my $optReMasks    = "";
my $optMasks      = "";
my $optNJson      = "";
my $optFileGlob   = "";
my $optReport     = 0;

my $retGetOpts = GetOptions ( # Help
                              "help|h"            => \$optHelp,
			      # Regexp to include lines
			      "incLines|il=s"     => \$optIncLines,
			      # Regexp to skip lines
			      "skipLines|sl=s"    => \$optSkipLines,
			      # Regexp Subst to mask substr
			      "remask|rm=s"       => \$optReMasks,
			      # Custom Masks (Sync with -remask)
			      "mask|m=s"          => \$optMasks,
			      # Regexp Normalize JSON
			      "nJson|nj=s"        => \$optNJson,
			      # File Glob
			      "file|files|f=s"    => \$optFileGlob,
			      # Report 1 or 2 lines
			      "report|r"          => \$optReport,
    );

=head1 checkForDups.pl

 Use this utility to check for duplicates within 1 or more files.
The -files parameter can take a file glob (placed in single quotes),
to match 1 or more files.

=head2 Usage...

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

=head3 (-help|h) Help

 Output this documentation.

=head3 (-file|files|f '<FileGlob>') Match files (Required)

 The file option is required and should be enclosed in single quotes to
 ensure that the shell does not pre-interpret the file before perl
 gets it. Without the single quotes, the shell will add multiple files
 as the arguments to the parameter, and only the first file in the list
 will be seen and processed.

 Specifying dash '-' as the parameter will cause STDIN to be used instead
 of files. Thus, we can use this utility to detect duplicate piped into
 STDIN.

=head3 (-incLines|il <RegExp>) Include Lines

 Use a regular express to inclue only those lines that match it.

=head3 (-skipLies|sl <RegExp>) Exclude Lines 

 Use a regular expression to exclude lines that match it.

=head3 (-remask|rm <RegExp>) Mask Regular Expression 

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

=head3 (-mask|m <RegExp>) Specify Masks

 By default that sub-string that matches a given -remask is masked with the
 default mask "#MASKED#".
 This option is used to change the default masking string.

 A string that contains one or more masks, that should be coordinated with
 the sequence of -remask regular expressions.

 So if you have 3 -remask expressions, you should have 3 -mask strings.

=head3 (-nJson|nj <RegExp>) Normalize Captured JSON

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

=head2 (-report|r) Instead of reporting 1 line per file, report 2 lines.

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

=cut

if ($optHelp) {

    print "\n".`perldoc $0`;
    exit 0;
}

my $filesLs = '';
my @files = ();
if ($optFileGlob eq '-') {
    $files[0] = '-';
} else {
    $filesLs = `ls $optFileGlob`;
    @files = split(' ', $filesLs);
}

# Parse Mask Regular Expressions
# Masks are applied (g)obally.
my @masksRe = ();
my $frstChr = substr($optReMasks, 0, 1);
if ($frstChr =~ /^(\:|\;|\~)/) {
    @masksRe = split(/${frstChr}/, $optReMasks);
    shift @masksRe;
} else {
    $masksRe[0] = $optReMasks if ($optReMasks ne '');
}
# Parse Masks
my @masks = ();
my $frstChr = substr($optMasks, 0, 1);
if ($frstChr =~ /^(\:|\;|\~)/) {
    @masks = split(/${frstChr}/, $optMasks);
    shift @masks;
} else {
    $masks[0] = $optMasks if ($optMasks ne '');
}

# Hash that contains md5sums of text lines.
# - {'c'} = Dup count for a given line of text.
my %md5s = ();

# Hash that contains Duped md5sums pointing to...
# - {'t'} = text line.
# - {'f'} -> {'<fileName>'} = file name.
# - {'f'} -> {'<fileName>'} -> {'l'} = (<lineNumbers>) array of matching lines.
my %md5s_dups = ();

my $skippedLines = 0;
my $totalLines = 0;

if ($#files < 0) {
    die "** ERROR: No matching lines!";
}

my $jsonObj = JSON->new->allow_nonref;
$jsonObj->canonical(1);

my $fileIndx = -1;

print "Scanning Files...\n";

foreach my $f (@files) {
    if ($f eq '-') {
	print "-> $f STDIN\n";
    } else {
	print "-> $f \n";
    }
    open( my $fh, "< $f" ) 
	|| die "Could not open file: $f!";
    $fileIndx += 1;
    my $lnCnt = 0;
    while (<$fh>) {
	$totalLines += 1;
	my $ln = $_;
	# print "--> $ln";
	$lnCnt += 1;
	if (($optSkipLines ne '') && ($ln =~ m/${optSkipLines}/)) {
	    $skippedLines += 1;
	    next;
	}
	if (($optIncLines ne '') && ($ln !~ m/${optIncLines}/)) {
	    $skippedLines += 1;
	    next;
	} else {
	    # Here's where we mask fields via regexp...
	    if ($#masksRe >= 0) {
		my $indx = 0;
		foreach my $re (@masksRe) {
		    my $repat = $re;
		    my $subst = "";
		    if ((exists $masks[$indx]) && ($masks[$indx] ne '')) {
			$subst = $masks[$indx];
		    } else {
			$subst = "\#MASKED\#";
		    }
		    # print "\$ln =~ s/${repat}/${subst}/g;\n";
		    $ln =~ s/${repat}/${subst}/g;
		    $indx += 1;
		}
	    }
	    # Here is where we Normaize JSON...
	    if ($optNJson ne '') {
		$ln =~ m/${optNJson}/;
		my $jtxt = $1;
		my ($jscl, $jrpl);
		my $jsonFailure = 0;
		if ($jtxt ne '') {
		    try {
			$jscl = $jsonObj->decode( $jtxt );
			$jrpl = $jsonObj->encode( $jscl );
		    } catch {
			$jsonFailure = 1;
		    }
		}
		if ($jsonFailure == 0) {
		    $jtxt =~ s/([\\\"\'\.\`\$\+\(\)\[\]\{\}\*\?])/\\\1/g;
		    # print "==> \$ln =~ s/${jtxt}/${jrpl}/;\n";
		    $ln =~ s/${jtxt}/${jrpl}/;
		}
 
	    }
	    # Get the md5sum of the line
	    my $dig = md5_hex(Encode::encode_utf8($ln));
	    # print "---> $dig\n";
	    # Initialize hash -> (pointer to) hash if it does not exist.
	    $md5s{$dig} = {} if (!exists $md5s{$dig});
	    # c is the dup count.
	    $md5s{$dig}->{'c'} += 1;
	    # Have we come across a dup?
	    if ($md5s{$dig}->{'c'} > 1) {
		# print "### 1 ###\n";
		# We found a dup...
		# Save off the test string into our dups array.
		# print "====> $ln";
		if (! exists $md5s_dups{$dig}) {
		    # print "### 2 ###\n";
		    # Store text value.
		    $md5s_dups{$dig} = {};
		    $md5s_dups{$dig}->{'t'} = $ln;
		    # Get file and lineCnt of first instance of text.
		    my ($fi, $fl) = split(':', $md5s{$dig}->{'f'});
		    # Get the file name from the file index.
		    my $fn = $files[$fi];
		    if (! exists $md5s_dups{$dig}->{'f'}->{$fn}->{'l'}) {
			# print "### 3 ###\n";
			# Create first instance of the fileName/lineCount array.
			$md5s_dups{$dig}->{'f'} = {} if (!exists $md5s_dups{$dig}->{'f'});

			# Store first instance...
			$md5s_dups{$dig}->{'f'}->{$fn} = {};
			$md5s_dups{$dig}->{'f'}->{$fn}->{'l'} = ();
			# print "push (\@{\$md5s_dups{$dig}->{'f'}->{$fn}->{'l'}}, $fl);\n";
			push (@{$md5s_dups{$dig}->{'f'}->{$fn}->{'l'}}, $fl);

			# Store first Dup...
			# Don't initialize arrays if they already exist.
			if (! exists $md5s_dups{$dig}->{'f'}->{$f}) {
			    $md5s_dups{$dig}->{'f'}->{$f} = {};
			    $md5s_dups{$dig}->{'f'}->{$f}->{'l'} = ();
			}
			# print "push (\@{\$md5s_dups{$dig}->{'f'}->{$f}->{'l'}}, $lnCnt);\n";
			push (@{$md5s_dups{$dig}->{'f'}->{$f}->{'l'}}, $lnCnt);
		    }
		} else {
		    # print "### 4 ###\n";
		    # Store additional Dups...
		    # Push more lines into an existing fileName/lineCount array.
		    # print "push (\@{\$md5s_dups{$dig}->{'f'}->{$f}->{'l'}}, $lnCnt);\n";
		    push (@{$md5s_dups{$dig}->{'f'}->{$f}->{'l'}}, $lnCnt);
		}
	    } else {
		# print "### 0 ###\n";
		# Store the file index (to @files).
		# If we find a a dup, we can know the first file
		# that had the text and the line number.
		$md5s{$dig}->{'f'} = "$fileIndx:$lnCnt";
	    }
	}
    }
}

print "\nDup Report...\n\n";
print "Total lines scanned: $totalLines\n";
print "      Lines skipped: $skippedLines\n";
my @dupMd5s = (keys %md5s_dups);
my $dupItems = $#dupMd5s + 1;
print "    Dup Items Found: $dupItems\n";

my $dupCnt = 0;
foreach my $md5 (keys %md5s_dups) {
    $dupCnt += 1;

    # For a given dup...
    # - Get matching files...
    my @fls = (keys (%{$md5s_dups{$md5}->{'f'}}));
    # print "---> [".join('\n',@fls)."]\n";
    # - Get the text...
    my $txt = $md5s_dups{$md5}->{'t'};
    print "\n =[$dupCnt]=> ".$txt;
    my $totDups = 0;
    foreach my $fn (@fls) {
	# print "my \@lines = \@{\$md5s_dups{$md5}->{'f'}->{$fn}->{'l'}}\n";
	my @lines = @{$md5s_dups{$md5}->{'f'}->{$fn}->{'l'}};
	my $lnCnt = $#lines + 1;
	$totDups += $lnCnt;
	if ($optReport == 0) {
	    print " --> File: \[$fn\] Dups: \[$lnCnt\] Lines: ".join(',',@lines)."\n";
	} else {
	    print " --> File: [$fn]\n";
	    print " ~~> Dups: \[$lnCnt\] Lines: ".join(',',@lines)."\n";
	}
    }
    print " ==> Total Dups: \[$totDups\]\n\n";
}


## -*- Perl -*-
#use ExtUtils::MakeMaker qw(WriteMakefile);
#WriteMakefile(
#	      NAME         => "Net::Pager",
#	      DISTNAME     => "Net-Pager",
#	      VERSION_FROM => "lib/Net/Pager.pm",
#           dist         => { COMPRESS => "gzip", SUFFIX => "gz" },
#	      );

#####################################################################
require 5.004;
use strict;

use lib "./lib/";
use Getopt::Long;
use ExtUtils::MakeMaker;

use vars qw($opt_config);
my %prereq;

my %opts = (NAME         => "Net::Pager",
	      DISTNAME     => "Net-Pager",
	      VERSION_FROM => "lib/Net/Pager.pm",
           dist         => { COMPRESS => "gzip", SUFFIX => "gz" },
	      );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'ABSTRACT'} = 'Send Numeric/AlphaNumeric Pages From Anywhere to Anyone';
    $opts{'AUTHOR'} = 'SimpleWire <www.simplewire.com>';
    $opts{'PREREQ_PM'} = \%prereq;
}

WriteMakefile(%opts);

print "Makefile Successful.\n";
print "\nNEWS!\n";
print "Net::Pager has a home page and development site. Try\n\n";
print "\thttp://www.simplewire.com/\n\n";

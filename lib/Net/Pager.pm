############################################################################
# Copyright (c) 2000 Rootlevel. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
#
# Net::Pager.pm, version 1.12
# Pager is a global numeric and alphanumeric paging interface via the
# Internet. We're bringing you the first and only way to interface any brand
# or type of pager through one consistent protocol without using the telephone
# network. Our purpose is to define a paging standard and make numerous tools
# available for developer's use so paging technology can be better utilized.

# The module interacts with SimleWire's Remote Procedure Calls. This new
# standard, and subsequently this Perl module, has a great deal of development
# energy behind it and will have full development support through an online
# support forum. Pager has built-in redundancy to create a fail-safe
# system.
#
# Rootlevel
# 743 Beaubien
# Suite 300
# Detroit, MI 48226
# 313.961.4407
#
# Started:  03/19/1999
# Released: 06/07/2000
# Coded By: Joe Lauer <joelauer@rootlevel.com>
# Contact:  John Lauer <jlauer@rootlevel.com>
############################################################################

# User documentation within and more is in POD format is at end of
# this file.  Search for =head

package Net::Pager;
$Net::Pager::VERSION = '1.12';
require 5.002;
use strict;

################ Global Variables for Pager.pm ########################
my $TIMEOUT          = 60;			# Timeout for how long it takes for Pager to give up and try the next Server
my @SERVICE_LIST     = ();			# The list of all services supported by Pager
my $GOT_SERVICE_LIST = 0;   		# 1 - on 0 - off
my $DEBUG            = 0;   		# 1 - on 0 - off
my $RETURN_START     = '<table>';   # Beginning of RPC return
my $RETURN_END       = '</table>';  # Ending of RPC return
my $SERVICE_REL_URL  = "/rpc/ver1/servicelist.html";
my $SENDPAGE_REL_URL = "/rpc/ver1/sendmsg.html?useragent=Perl/$Net::Pager::VERSION";
my %ERROR            = { CODE => "0", DESCRIPTION => "No error has been recorded yet." };
#my $t = Net::Telnet->new( Timeout => $TIMEOUT );

################ Variables for built-in redundancy #########################
my $DOMAIN           = "simplewire.com";
my @SERVERS          = ("www.$DOMAIN","www2.$DOMAIN","www3.$DOMAIN","www4.$DOMAIN","www5.$DOMAIN","www6.$DOMAIN","www7.$DOMAIN","www8.$DOMAIN","www9.$DOMAIN","www10.$DOMAIN");
my @SERVERS_PORTS    = (80,80,80,80,80,80,80,80,80,80);

########################### Public Functions ###############################

# Net::Pager::new
# DESCRIPTION:
# 	This function instantiates a new Pager object.
# PARAMETERS:
#   There are multiple ways to call this function.
#   $pager = Net::Pager->new();
#   $pager = Net::Pager->new($service,$pin,$from,$msg,$callback);
#	$pager = Net::Pager->new( service => "14",
#                      			   message => "This is a message from the fifth page!",
#                      			   pin     => "1234567890",
#                      			   from    => "John Smith",
#                      			   callback=> "1234567890",
#                     			   setvar  => 1 );
# NOTE:
# 	You do not have to pass in all the variables with the hash
#   approach.  You can just pass in the ones that you want and you
#   can pass them in, in any order that you want.
# RETURNS:
#   This returns a reference to a Pager object.  You can then store
#   any variables that you want in it, download the service list, etc.
sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    local $_;
    my %args;

    #declare variables that will be used locally to call send off page
    my($service,$pin,$from,$msg,$callback);

    #define what this object will contain
    my $self = {
    	SERVICE   => '',
    	PIN       => '',
    	FROM      => '',
        MSG       => '',
        CALLBACK  => '',
        ERRCODE   =>  0,         #the error code that corrosponds after a call
        ERRDSCR   => '',         #the description that corrosponds to ERRCODE
        SETVAR    =>  1,         #sets the object's variables when args passed into sendPage in no name form
        OBJECT    =>  1,
    };

    #see if any arguments are passed in, if so then set the variables
    if (@_ == 5) {  # variables that are passed in without names
       $service = shift;
       $pin = shift;
       $from = shift;
       $msg = shift;
       $callback = shift;

       #if SETVAR = true then we should set this object's values then
       if ($self->{SETVAR}) {
           $self->{SERVICE} = $service;
       	   $self->{PIN} = $pin;
       	   $self->{FROM} = $from;
       	   $self->{MSG} = $msg;
       	   $self->{CALLBACK} = $callback;
       }
    } elsif (@_) {  # named args given
	## Get the named args.
	(%args) = @_;

	## Parse the named args.
	foreach (keys %args) {
	    if (/^-?service$/i) {
		$self->{SERVICE} = $args{$_};
	    }
	    elsif (/^-?pin$/i) {
                $self->{PIN} = $args{$_};
	    }
	    elsif (/^-?from$/i) {
                $self->{FROM} = $args{$_};
	    }
	    elsif (/^-?message$/i) {
                $self->{MSG} = $args{$_};
	    }
	    elsif (/^-?callback$/i) {
                $self->{CALLBACK} = $args{$_};
	    }
	    elsif (/^-?setvar$/i) {
                $self->{SETVAR} = $args{$_};
	    }
            else {
                #There was an error, quit any procedures and return error
                print "\n" . '! Error in call to sendPage()' . "\n";
		print 'Usage: $obj->sendPage( service => $service,' . "\n";
                print '                       pin     => $pin,' . "\n";
                print '                       from    => $from,' . "\n";
                print '                       message => $message,' . "\n";
                print '                       callback=> $callback,' . "\n";
                print '                       setvar  => 0         );' . "\n";

            	return 0;
	    }
	}
    }

    bless($self, $class);
    return $self;
}

#This just for testing purposes
sub checkIfObjectPassed {
    if (ref($_[0])) {
        print "This was passed by an object\n";
    } else {
        print "This was not passed by an object\n";
    }
}

# sets or gets the variable.  This must be called by an object.  To get a
# the variable just call it with no parameters - e.g. setvar();
# To set then pass in the paramter of whatever you want - e.g. setvar(0);
sub setvar {
    if (ref($_[0])) { #this function was called by an object
        my $self = shift;
	if (@_) { $self->{SETVAR} = shift; }
	return    $self->{SETVAR};
    } else { #this function was not called by an object
        print "You must instanitate an Pager object to use Net::Pager::setvar()\n";
    }
}

# sets or gets the variable.  This must be called by an object.  To get a
# the variable just call it with no parameters - e.g. setvar();
# To set then pass in the paramter of whatever you want - e.g. setvar(0);
sub service {
    if (ref($_[0])) { #this function was called by an object
        my $self = shift;
    	if (@_) { $self->{SERVICE} = shift; }
    	return    $self->{SERVICE};
    } else { #this function was not called by an object
        print "You must instanitate an Pager object to use Net::Pager::service()\n";
    }
}

# sets or gets the variable.  This must be called by an object.  To get a
# the variable just call it with no parameters - e.g. setvar();
# To set then pass in the paramter of whatever you want - e.g. setvar(0);
sub pin {
    if (ref($_[0])) { #this function was called by an object
        my $self = shift;
    	if (@_) { $self->{PIN} = shift; }
    	return    $self->{PIN};
    } else { #this function was not called by an object
        print "You must instanitate an Pager object to use Net::Pager::pin()\n";
    }
}

# sets or gets the variable.  This must be called by an object.  To get a
# the variable just call it with no parameters - e.g. setvar();
# To set then pass in the paramter of whatever you want - e.g. setvar(0);
sub from {
    if (ref($_[0])) { #this function was called by an object
        my $self = shift;
    	if (@_) { $self->{FROM} = shift; }
    	return    $self->{FROM};
    } else { #this function was not called by an object
        print "You must instanitate an Pager object to use Net::Pager::from()\n";
    }
}

# sets or gets the variable.  This must be called by an object.  To get a
# the variable just call it with no parameters - e.g. setvar();
# To set then pass in the paramter of whatever you want - e.g. setvar(0);
sub message {
    if (ref($_[0])) { #this function was called by an object
        my $self = shift;
    	if (@_) { $self->{MSG} = shift; }
    	return    $self->{MSG};
    } else { #this function was not called by an object
        print "You must instanitate an Pager object to use Net::Pager::message()\n";
    }
}

# sets or gets the variable.  This must be called by an object.  To get a
# the variable just call it with no parameters - e.g. setvar();
# To set then pass in the paramter of whatever you want - e.g. setvar(0);
sub callback {
    if (ref($_[0])) { #this function was called by an object
        my $self = shift;
    	if (@_) { $self->{CALLBACK} = shift; }
    	return    $self->{CALLBACK};
    } else { #this function was not called by an object
        print "You must instanitate an Pager object to use Net::Pager::callback()\n";
    }
}

# Net::Pager::sendPage
# DESCRIPTION:
# 	This function sends off a page through Pager's network using port 80.
# PARAMETERS:
#   Function call w/o need to create an object
#		Net::Pager::sendPage();
#   Function call w/ object
#   	$pager->Net::Pager->new();
#		$pager->sendPage();
#   Once you have chosen whether object approach or function call w/o object you can pass
#   in variables in any of these ways.
#   sendPage($service,$pin,$from,$msg,$callback);
#	sendPage( service => "14",
#             message => "This is a message from the fifth page!",
#             pin     => "1234567890",
#             from    => "John Smith",
#             callback=> "1234567890",
#             setvar  => 1 );
# NOTE:
# 	You do not have to pass in all the variables with the hash
#   approach.  You can just pass in the ones that you want and you
#   can pass them in, in any order that you want.
# RETURNS:
#   This returns a true or false boolean indicating whether or not the page
#   was sucessfully sent or not.  If it is not successful then you can
#   check what error it was with the errorCode() and errorMessage()
#   functions.
sub sendPage {

    local $_;

    #declare variables that will be used locally to call send off page
    my( $service,
    	$pin,
		$from,
		$msg,
		$callback,
		$self,
		%args,
		$objectPassed,
		$index, );

    if (ref($_[0])) {
        $objectPassed = 1;   #this function was called by an object
    } else {
        $objectPassed = 0;   #this function was not called by an object
        #print "When not an object, this passed " . @_ . "\n";
    }

    #if an object then we need to get its reference
    if ($objectPassed) {
        $self = shift;
    }

    if (@_ == 5) {   # variables are passed in without corrosponding names in a list of 5
       $service = shift;
       $pin = shift;
       $from = shift;
       $msg = shift;
       $callback = shift;

       #if SETVAR = true and an object is passed then we should set this object's values then
       if ($objectPassed and $self->{SETVAR}) {
           $self->{SERVICE} = $service;
       	   $self->{PIN} = $pin;
       	   $self->{FROM} = $from;
       	   $self->{MSG} = $msg;
       	   $self->{CALLBACK} = $callback;
       }
    } elsif (@_ == 0 and $objectPassed) {    #no variables are passed in which means they must already be stored

       $service = $self->{SERVICE};
       $pin = $self->{PIN};
       $from = $self->{FROM};
       $msg = $self->{MSG};
       $callback = $self->{CALLBACK};

    } else {  # named arguments given in no particular order.
	## Get the named args.
	(%args) = @_;

	## Parse the named args.
	foreach (keys %args) {
	    if (/^-?service$/i) {
                if ( $objectPassed ) {
                    $service = $args{$_};
                } else {
                    $service = $args{$_};
                    if ($self->{SETVAR}) { $self->{SERVICE} = $service; }
                }
	    }
	    elsif (/^-?pin$/i) {
                if ( $objectPassed ) {
                    $pin = $args{$_};
                } else {
                    $pin = $args{$_};
                    if ($self->{SETVAR}) { $self->{PIN} = $pin; }
                }
            }
	    elsif (/^-?from$/i) {
                if ( $objectPassed ) {
                    $from = $args{$_};
                } else {
                    $from = $args{$_};
                    if ($self->{SETVAR}) { $self->{FROM} = $from; }
                }
	    }
	    elsif (/^-?message$/i) {
                if ( $objectPassed ) {
                    $msg = $args{$_};
                } else {
                    $msg = $args{$_};
                    if ($self->{SETVAR}) { $self->{MSG} = $msg; }
                }
	    }
	    elsif (/^-?callback$/i) {
                if ( $objectPassed ) {
                    $callback = $args{$_};
                } else {
                    $callback = $args{$_};
                    if ($self->{SETVAR}) { $self->{CALLBACK} = $callback; }
                }
	    }
	    else {
                #There was an error, quit any procedures and return error
                print "\n" . '! Error in call to sendPage()' . "\n";
				print 'Usage: $obj->sendPage( service => $service,' . "\n";
                print '                       pin     => $pin,' . "\n";
                print '                       from    => $from,' . "\n";
                print '                       message => $message,' . "\n";
                print '                       callback=> $callback );' . "\n";

            	return 0;
	    }
	}
    }

    #make sure that any arguments passed in are url compliant.
    $service = _UrlEncode($service);
    $pin = _UrlEncode($pin);
    $from = _UrlEncode($from);
    $msg = _UrlEncode($msg);
    $callback = _UrlEncode($callback);

    ###This calls the function to make sure that simplewire is working.
    my @lines = _DownloadHtml($SENDPAGE_REL_URL . "&servicepk=$service&pin=$pin&from=$from&message=$msg&callback=$callback");

    #process the lines that were returned
    _GetReturnForSendPage(@lines);

    #store error codes and description if this is an object
    if ( $objectPassed ) {
        $self->{ERRCODE} = $ERROR{CODE};
    	$self->{ERRDSCR} = $ERROR{DESCRIPTION};
    }

    if ($ERROR{CODE} == 0) {
        return 1;       #true
    } else {
        return 0;       #false
    }
}

#checks to see if there was an error in the last page sent.
sub isError {
    my $self = shift;

    if ($self->{ERRCODE} == 0) {
        return 0;       #true
    } else {
        return 1;       #false
    }
}

#returns the current errorMessage for this pager.
sub errorMessage {
    if (ref($_[0])) {     #this function was called by an object
        my $self = shift;
        return $self->{ERRDSCR};
    } else {
        return $ERROR{DESCRIPTION};   #this function was not called by an object
    }
}

#returns the current errorCode for this pager.
#Check www.Pager.com for a current list of error codes and associated
#values.
sub errorCode {
    my $self = shift;

    return $self->{ERRCODE};
}

# Net::Pager::getServiceList
# DESCRIPTION:
# 	This function retrieves the current service list for all the paging
#	services that Pager supports.
# PARAMETERS:
#   Function call w/o need to create an object
#		Net::Pager::getServiceList();
#   Function call w/ object
#   	$pager->Net::Pager->new();
#		$pager->getServiceList();
# NOTE:
#   We recommend the object approach because once you download the service
#   list for one object, we store it in a variable that persists and will
#   not download again.  If you want to force an update pass in the param
#   "refresh" so the call would be
#       $pager->getServiceList("refresh");
# RETURNS:
#   This returns an array of hashes that represent all the services that
#   Pager supports.  See the example code for exactly what the hash
#   contains and how to access an array of hashes.
sub getServiceList {
    my (@lines,
    	$objectPassed,
	 	$self,
	 	$refresh );

    #determine if this is an instantiated object calling this function
    if (ref($_[0])) {     #this function was called by an object
        $self = shift;
        $objectPassed = 1;
    }

    if (@_) { $refresh = shift; }

    if ($GOT_SERVICE_LIST and $refresh ne "refresh") {
    } else {
		@lines = _DownloadHtml($SERVICE_REL_URL);

		@SERVICE_LIST = _GetReturnForServiceList(@lines);

	    if ($#SERVICE_LIST < 0) {
	        #store error codes and description if this is an object
		    if ( $objectPassed ) {
		        $self->{ERRCODE} = 11;
		    	$self->{ERRDSCR} = "Sevice List Could Not Be Downloaded";
		    }
	    } else {
			#now set the global to already having retrieved the service list
			$GOT_SERVICE_LIST = 1;
	    }
    }

    return @SERVICE_LIST;

} #end getServiceList


#Pass into this function the service number
#Usage:   $index = serviceExists(2);
#Returns: The index in the service array that matches the service number
#         passed in.  If the service number does not exist then passes
#         back a -1
#Example: $index = serviceExists(2);
#         $services[$index]{SERVICE} = 2;
#
sub serviceExists {
    my ($objectPassed,
	 	$self,
	 	$id,
		$notFound,
		$index,
		$service );

    #determine if this is an instantiated object calling this function
    if (ref($_[0])) {     #this function was called by an object
        $self = shift;
        $objectPassed = 1;
    }

    if (@_) {             #Parameter passed in
		$id = shift;

        #check to see if the service list has been downloaded.

		if (!($GOT_SERVICE_LIST)) {
        	getServiceList();
        }

		#start loop to see if the service picked exists
        $notFound = 1;    #1 = true, 0 = false
		$index = 0;

        while ( ($notFound) and ($index <= $#SERVICE_LIST )) {
		    if ($SERVICE_LIST[$index]{SERVICE} eq $id) {
		        $notFound = 0;
		    } else {
		        $index++;
		    }
		}

        if ($notFound) {
            return -1;
        } else {
            return $index;
        }

	} else {
        return -1;
    }

}

######################### Private Functions ################################

#Combine array of lines into one string
#Usage:   $string = _CreateOneString(@array);
#Returns: A single string
sub _CreateOneString {
    my $line;
    my $txt;

    foreach $line (@_) {
    	$txt .= $line;
    }

    return $txt;
}

#Remove all newline characters in string
#Usage:   $string = _RemoveNewlines($string2);
#Returns: A sinlge string that has all newlines removed from it
sub _RemoveNewlines {
    my $txt = shift;
    $txt =~ s/\n//gs;
    return $txt;
}

#Remove all returned text except the text between the designated return tags
#Usage:   $string = _RemoveTextOutsideReturns($string2)
#Returns: A string that removes text up and including $RETURN_START tag and
#         all text including and after $RETURN_END tag.
sub _RemoveTextOutsideReturns {
    my $txt = shift;
    $txt =~ s/.*?$RETURN_START//;
    $txt =~ s/$RETURN_END.*?//;
    return $txt;
}

#Get Headings for Columns and Fill In Information Returned
#Usage:
#Returns:
sub _GetReturnForSendPage {

    my $txt = _CreateOneString(@_);
    $txt = _RemoveNewlines($txt);
    $txt = _RemoveTextOutsideReturns($txt);

    #clean out all the <tr>
    $txt =~ s/<tr>//gs;

    #split up the returns into arrays of lines
    my ($heading, $result) = split /<\/tr>/, $txt;

    #clean out all the <td> in the results
    $result =~ s/<td>//gs;
    ( $ERROR{CODE}, $ERROR{DESCRIPTION} ) = split /<\/td>/, $result;
}

#Get Headings for Columns and Fill In Information Returned
#Usage:
#Returns:
sub _GetReturnForServiceList {
    my ( $txt,
         $heading,
         @results,
         @r,
         @head,
         $row,
         $rec );

    $txt = _CreateOneString(@_);
    $txt = _RemoveNewlines($txt);
    $txt = _RemoveTextOutsideReturns($txt);

	if ($DEBUG) { print $txt . "\n"; }

    #clean out all the <tr>
    $txt =~ s/<tr>//gs;

    #split up the returns into arrays of lines
    ($heading, @results) = split /<\/tr>/, $txt;

    #clean out all the <td>
    $heading =~ s/<td>//gs;

    if ($DEBUG) { print $heading . "\n"; }

    @head = split /<\/td>/, $heading;

    my @S = ();

    # format: SERVICE=12, DESCRIPTION="Ameritech Whatever..."
    foreach $row (@results) {      #this takes each row and gets all the fields
         $row =~ s/<td>//gs;
         @r = split /<\/td>/, $row;

         $rec = {};
         $rec->{SERVICE} = $r[0];
         $rec->{DESCRIPTION} = $r[1];
         $rec->{TYPE} = $r[2];
         $rec->{MSGLEN} = $r[3];
         $rec->{FROMLEN} = $r[4];
         $rec->{PINLEN} = $r[5];
         $rec->{SUPPORTCALLBACK} = $r[6];
         push @S, $rec;
     }

     return @S;
}

#Encode any string to be web compliant
#Usage: $string1 = _UrlEncode($string2);
#Returns: $string1 will be encoded to be a valid url from $string2
sub _UrlEncode {

    my $string = shift;

    $string =~ s/([\x00-\x20"#%;<>?{}|\\\\^~`\[\]\x7F-\xFF])/
                 sprintf ('%%%x', ord ($1))/eg;

    return $string;
}

#Decode any string from being web compliant to ASCII text
#Usage: $string1 = _UrlDecode($string2);
#Returns: $string1 will be decoded to be a ASCII text from $string2
sub _UrlDecode {

    my $string = shift;

    $string =~ s/%([\da-fA-F]{2})/chr (hex ($1))/eg;

    return $string;
}

# This function encapsulates the built-in redundancy of Pager.pm
# It attempts to open up shit
sub _DownloadHtml {

	my $file = shift;
    my $connected = 0;
    my $return = 0;
    my @lines;
    my @tmp;
    my $txt;

	#begin loop open up connection to correct server
    my $index = -1;

	##### Begin loop to try and see whether or not <table> </table> tags are
    ##### present in the return.
    do {
	##### This will check for being able to connect to the server
	do {
		$@ = "";
		$index++;

        #telnet_open($SERVERS[$index],$SERVERS_PORTS[$index]) or die "Cannot open connection to $SERVERS[$index]";

        if ($DEBUG) { print "Attempting to connect to..." . $SERVERS[$index] . "\n"; }
		$connected = telnet_open($SERVERS[$index],$SERVERS_PORTS[$index]);
        if ($DEBUG) { print "The error message that a downed server gets in the eval is:" . $@ . "\n"; }

	} while ( !($connected) and ($index < $#SERVERS) );
    ##### End the check on whether the server allows us to connect

    if ($connected && $DEBUG) {
        print "Connected to " . $SERVERS[$index] . "\n";
    }

	my $call = "GET " . $file . " HTTP/1.0\n\n";
    $return = telnet_print($call);

    if ($DEBUG) {
        if ($return) {
            print "Print Was Successful\n";
        } else {
            print "Print Was Not Successful\n";
        }
    }

	#####################
    # This is a work around for buffering problems on different platforms
    #####################
    @lines = ();
    @tmp = ();
	my $counter = 0;

	do {
	    @tmp = getlines();
	    push @lines, @tmp;
	    $counter++;
    } until ($#tmp eq "-1" or $counter > 15);

    if ($DEBUG) {
        my $line;
		foreach $line (@lines) {
            print $line . "\n";
        }

        print "\nThere was a total of " . $counter . " times needed to wipe out the telnet buffer.\n";
    }

    # Break this array into one line and then get rid of returns.
    $txt = "";
    $txt = _CreateOneString(@lines);
    $txt = _RemoveNewlines($txt);

    #now check to see if the beginning and ending paramters are in the return
    #this will make sure we have a correct response and this server worked.

	} until ( ($index >= $#SERVERS) or ($txt =~ /$RETURN_START/ and $txt =~ /$RETURN_END/));

    return @lines;
}

################### Private Telnet Functions ###############################

## Module import.
use Exporter ();
use Socket qw(AF_INET SOCK_STREAM inet_aton sockaddr_in);
use Symbol qw(qualify);

## Base class.
use vars qw(@ISA);
@ISA = qw(Exporter);
if (eval 'require IO::Socket') {
    push @ISA, 'IO::Socket::INET';
}
else {
    require FileHandle;
    push @ISA, 'FileHandle';
}

## Create all Telnet Defaults.
my $Default_blocksize = 8192;
my $fh_open;
my $stream;
my $bin_mode     = 0;
my $blksize      = $Default_blocksize;
my $buf          = "";
my $cmd_prompt   = '/[\$%#>] $/';
my $cmd_rm_mode  = "auto";
my $dumplog      = '';
my $eofile       = 1;
my $errormode    = 'die';
my $errormsg     = "";
my $fdmask       = '';
my $host         = "localhost";
my $inputlog     = '';
my $last_line    = "";
my $maxbufsize   = 1024 * 1024;
my $num_wrote    = 0;
my $ofs          = "";
my $opened       = '';
my $opt_cback    = '',
my $opt_log      = '';
my %opts         = {};
my $ors          = "\n";
my $outputlog    = '';
my $port         = 80;
my $pushback_buf = "";
my $rs           = "\n";
my $telnet_mode  = 1;
my $timeout      = _parse_timeout($TIMEOUT);
my $timedout     = '';
my $unsent_opts  = "";

## Indicate that we'll accept an offer from remote side for it to echo
## and suppress go aheads.
_opt_accept(
	{ option    => TELOPT_ECHO(),
	  is_remote => 1,
	  is_enable => 1 },
	{ option    => TELOPT_SGA(),
	  is_remote => 1,
	  is_enable => 1 },
);

sub _opt_accept {
    my(@args) = @_;
    my(
       $arg,
       $option,
       $stream,
       );

    ## Init vars.

    foreach $arg (@args) {
		## Ensure data structure defined for this option.
		$option = $arg->{option};
		if (!defined $opts{$option}) {
		    _set_default_option($option);
		}

		## Save whether we'll accept or reject this option.
		if ($arg->{is_remote}) {
		    $opts{$option}{remote_enable_ok} = $arg->{is_enable};
		}
		else {
		    $opts{$option}{local_enable_ok} = $arg->{is_enable};
		}
    }

    1;
} # end sub _opt_accept

sub _set_default_option {
    my($option) = @_;

    $opts{$option} = {
	remote_enabled   => '',
	remote_state     => "no",
	remote_enable_ok => '',
	local_enabled    => '',
	local_state      => "no",
	local_enable_ok  => '',
    };
} # end sub _set_default_option


sub telnet_close {

    $eofile = 1;
    $opened = '';

	close SOCKET;

    return 1;
} # end sub close

sub telnet_open {
    my(
       $blksize2,
       $errno,
       $host,
       $ip_addr,
       $port,
       );
    local $_;

    ## Init vars.
    $timedout = '';
    $host = shift();
    $port = shift();

    ## Ensure we're already closed.
    telnet_close();

    ## Don't use a timeout if we can't use the alarm signal.
    unless (_have_alarm()) {
		$timeout = undef;
    }

    if (defined $timeout) {  # use a timeout
	## Ensure a valid timeout value for alarm.
	if ($timeout < 1) {
	    $timeout = 1;
	}
	$timeout = int($timeout + 1.5);

	## Connect to server, timing out if it takes too long.
	eval {
	    ## Turn on timer.
	    local $SIG{'__DIE__'} = 'DEFAULT';
	    local $SIG{ALRM} = sub { die "timed-out\n" };
	    alarm $timeout;

	    ## Lookup server's IP address.
	    $ip_addr = inet_aton $host
		or die "unknown remote host: $host\n";

	    ## Create a socket and attach the filehandle to it.
	    socket SOCKET, AF_INET, SOCK_STREAM, 0
		or die "problem creating socket: $!\n";

	    ## Open connection to server.
	    connect SOCKET, sockaddr_in($port, $ip_addr)
		or die "problem connecting to \"$host\", port $port: $!\n";
	};
	alarm 0;

	## Check for error.
	if ($@ =~ /^timed-out$/) {  # time out failure
	    $timedout = 1;
        telnet_close();
	    if (! $ip_addr) {
		#return $self->error("unknown remote host: $host: ",
		#		    "name lookup timed-out");
	    return 0;
		}
	    else {
		#return $self->error("problem connecting to \"$host\", ",
		#		    "port $port: connection timed-out");
	    return 0;
		}
	}
	elsif ($@) {  # hostname lookup or connect failure
        telnet_close();
	    chomp $@;
	    #return $self->error($@);
        return 0;
	}
    }
    else {  # don't use a timeout
	## Lookup server's IP address.
	$ip_addr = inet_aton $host
	    #or return $self->error("unknown remote host: $host");
        or return 0;

	## Create a socket and attach the filehandle to it.
	socket SOCKET, AF_INET, SOCK_STREAM, 0
	    #or return $self->error("problem creating socket: $!");
        or return 0;

	## Open connection to server.
	connect SOCKET, sockaddr_in($port, $ip_addr)
	    or do {
		$errno = "$!";
		telnet_close();
		#return $self->error("problem connecting to \"$host\", ",
		#		    "port $port: $errno");
	    return 0;
		};
    }

    $blksize2 = (stat SOCKET)[11];
    $blksize = $blksize2 || $Default_blocksize;
    $buf = "";
    $eofile = '';
    $errormsg = "";
    vec($fdmask ='', fileno(SOCKET), 1) = 1;
    $last_line = "";
    $num_wrote = 0;
    $opened = 1;
    $pushback_buf = "";
    $timedout = '';
    $unsent_opts = "";
    _reset_options(%opts);

    return 1;
} # end sub open

sub _reset_options {
    my(%opts2) = @_;
    my(
       $opt,
    );

    foreach $opt (keys %opts2) {
	$opts{$opt}{remote_enabled} = '';
	$opts{$opt}{remote_state} = "no";
	$opts{$opt}{local_enabled} = '';
	$opts{$opt}{local_state} = "no";
    }

    1;
} # end sub _reset_options

sub _flush_opts {
    my(
       $option_chars,
    );

    ## Get option and clear the output buf.
    $option_chars = $unsent_opts;
    $unsent_opts = '';

    ## Try to send options without waiting.
    {
	my $errormode = 'return';
	my $time_out = 0;
    my $ors = '';
	telnet_print($option_chars)
	    or do {
		## Save chars not printed for later.
		substr($option_chars, 0, print_length() ) = '';
		$unsent_opts .= $option_chars;
	    };
    }

    1;
} # end sub _flush_opts

sub print_length {
    $num_wrote;
} # end sub print_length

sub telnet_print {
    my(
       $data,
       $endtime,
       $fh,
       $len,
       $nfound,
       $nwrote,
       $offset,
       $ready,
       $stream,
       $timed_out
       );

    $timedout = '';
    $num_wrote = 0;
    return 0
	unless $opened;

    ## Try to send any waiting option negotiation.
    if (length $unsent_opts) {
		_flush_opts();
    }

    ## Add field and record separators.
    $data = join($ofs, @_) . $ors;

    ## Convert newlines to carriage-return and linefeed.
    $data =~ s(\n)(\015\012)g
	unless $bin_mode;

    $offset = 0;
    $len = length $data;
    $endtime = _endtime($timeout);
    while ($len) {
	## Set how long to wait for output ready.
	($timed_out, $timeout) = _timeout_interval($endtime);
	if ($timed_out) {
	    $timedout = 1;
	    #return $self->error("print timed-out");
        return 0;
	}

	## Wait for output ready.
	$nfound = select '', $ready=$fdmask, '', $timeout;
	if ($nfound > 0) {  # data can be written
	    if ($nwrote = syswrite SOCKET, $data, $len, $offset) {
		## If requested, display network traffic.
		($dumplog)
		    and _log_dump('>', $dumplog,
				   \$data, $offset, $nwrote);

		$num_wrote += $nwrote;
		$offset += $nwrote;
		$len -= $nwrote;
		next;
	    }
	    elsif (! defined $nwrote) {  # write failed
		next if $! =~ /^Interrupted/;

		$opened = '';
		#return $self->error("unexpected write error: $!");
        return 0;
		}
	    else {  # zero chars written
		$opened = '';
		#return $self->error("unexpected zero length write error: $!");
        return 0;
		}
	}
	elsif ($nfound < 0) {  # select failure
	    next if $! =~ /^Interrupted/;

	    ## Failure equates to eof.
	    $opened = '';
	    #return $self->error("unexpected write error: $!");
        return 0;
	}
	else {  # timed-out
	    $timedout = 1;
	    #return $self->error("print timed-out");
        return 0;
	}
    }

    return 1;
} # end sub print

sub _log_dump {
    my($direction, $fh, $data, $offset, $len) = @_;
    my(
       $addr,
       $hexvals,
       $line,
       );

    $addr = 0;
    $len = length($$data) - $offset
	unless defined $len;

    ## Print data in dump format.
    while ($len > 0) {
	## Convert up to the next 16 chars to hex, padding w/ spaces.
	if ($len >= 16) {
	    $line = substr $$data, $offset, 16;
	}
	else {
	    $line = substr $$data, $offset, $len;
	}
	$hexvals = unpack('H*', $line);
	$hexvals .= ' ' x (32 - length $hexvals);

	## Place in 16 columns, each containing two hex digits.
	$hexvals = sprintf("%s %s %s %s  " x 4,
			   unpack('a2' x 16, $hexvals));

	## For the ASCII column, change unprintable chars to a period.
	$line =~ s/[\000-\037,\177-\237]/./g;

	## Print the line in dump format.
	printf $fh "%s 0x%5.5lx: %s%s\n", $direction, $addr, $hexvals, $line;

	$addr += 16;
	$offset += 16;
	$len -= 16;
    }

    print $fh "\n";

    1;
} # end sub _log_dump

sub _endtime {
    my($interval) = @_;

    ## Compute wall time when timeout occurs.
    if (defined $interval) {
	if ($interval >= $^T) {  # it's already an absolute time
	    return $interval;
	}
	elsif ($interval > 0) {  # it's relative to the current time
	    return int(time + 1.5 + $interval);
	}
	else {  # it's a one time poll
	    return 0;
	}
    }
    else {  # there's no timeout
	return undef;
    }
} # end sub _endtime

sub _parse_timeout {
    $timeout = shift();

    ## Ensure valid timeout.
    if (defined $timeout) {
	## Test for non-numeric or negative values.
	eval {
	    local $^W = 1;
	    local $SIG{'__WARN__'} = sub { die "non-numeric\n" };
	    local $SIG{'__DIE__'} = 'DEFAULT';
	    $timeout *= 1;
	};
	if ($@) {  # timeout arg is non-numeric
	    $timeout = undef;
	}
	elsif ($timeout < 0) {
	    $timeout = undef;
	}
    }

    return $timeout;
} # end sub _parse_timeout

sub _timeout_interval {
    my($endtime) = @_;

    ## Return timed-out boolean and timeout interval.
    if (defined $endtime) {
	## Is it a one-time poll.
	return ('', 0) if $endtime == 0;

	## Calculate the timeout interval.
	$timeout = $endtime - time;

	## Did we already timeout.
	return (1, 0) unless $timeout > 0;

	return ('', $timeout);
    }
    else {  # there is no timeout
	return ('', undef);
    }
} # end sub _timeout_interval

sub getline {
    my(%args) = @_;
    my(
       $endtime,
       $len,
       $line,
       $offset,
       $pos
       );
    local $_;

    ## Init vars.
    $timedout = '';
    return if $eofile;

    ## Set wall time when we time out.
    $endtime = _endtime($timeout);

    ## Try to send any waiting option negotiation.
    if (length $unsent_opts) {
		_flush_opts();
    }

    ## Keep reading into buffer until end-of-line is read.
    $offset = 0;
    while (($pos = index($buf, $rs, $offset)) == -1) {
	$offset = length $buf;
	_fillbuf($endtime)
	    or do {
		return if $timedout;

		## We've reached end-of-file.
		telnet_close();
		if (length $buf) {
		    return $buf;
		}
		else {
		    return;
		}
	    };
    }

    ## Extract line from buffer.
    $len = $pos + length $rs;
    $line = substr($buf, 0, $len);
    substr($buf, 0, $len) = '';

    return $line;
} # end sub getline

sub _fillbuf {
    my($endtime) = @_;
    my(
       $fh,
       $firstpos,
       $lastpos,
       $len_w_sep,
       $len_wo_sep,
       $nextchar,
       $nfound,
       $nread,
       $offset,
       $pos,
       $pushback_len,
       $ready,
       $timed_out,
       );

    return unless $opened;

    while (1) {
	## Ensure we haven't exceeded maximum buffer size.
	#return $self->error("maximum input buffer length exceeded: ",
	#		$s->{maxbufsize}, " bytes")
    return 0
		unless length($buf) <= $maxbufsize;

	## Set how long to wait for input ready.
	($timed_out, $timeout) = _timeout_interval($endtime);
	if ($timed_out) {
	    $timedout = 1;
	    #return $self->error("read timed-out");
        return 0;
	}

	## Wait for input ready.
	$nfound = select $ready=$fdmask, '', '', $timeout;
	if ($nfound > 0) {  # data can be read
	    ## Append any partially read telnet char sequence.
	    $pushback_len = length $pushback_buf;
	    if ($pushback_len) {
		$buf .= $pushback_buf;
		$pushback_buf = '';
	    }

	    ## Do the read.
	    $offset = length $buf;
	    if ($nread = sysread SOCKET, $buf, $blksize, $offset) {
		## If requested, display network traffic.
		($dumplog)
		    and _log_dump('<', $dumplog, \$buf, $offset);

		## Process carriage-return sequences in the data stream.
		$pos = $offset - $pushback_len;
		while (($pos = index($buf, "\015", $pos)) > -1) {
		    $nextchar = substr($buf, $pos + 1, 1);
		    if ($nextchar eq "\0") {
			## Convert CR NULL to CR
			substr($buf, $pos + 1, 1) = ''
			    if $telnet_mode;
		    }
		    elsif ($nextchar eq "\012") {
			## Convert CR LF to newline when not in binary mode.
			substr($buf, $pos, 2) = "\n"
			    if ! $bin_mode;
		    }
		    elsif (! length($nextchar) and $telnet_mode) {
			## Save CR for possible CR NULL conversion.
			$pushback_buf .= "\015";
			chop $buf;
		    }

		    $pos++;
		}

		next if length $buf <= $offset;

		## Save last line in the buffer.
		if (($lastpos = rindex $buf, $rs) > -1) {
		    while (1) {
			## Find beginning of line.
			$firstpos = rindex $buf, $rs, $lastpos - 1;
			if ($firstpos == -1) {
			    $offset = 0;
			}
			else {
			    $offset = $firstpos + length $rs;
			}

			## Determine length of line with and without separator.
			$len_wo_sep = $lastpos - $offset;
			$len_w_sep = $len_wo_sep + length $rs;

			## Save line if it's not blank.
			if (substr($buf, $offset, $len_wo_sep)
			    !~ /^\s*$/)
			{
			    $last_line = substr($buf,
						     $offset,
						     $len_w_sep);
			    last;
			}

			last if $firstpos == -1;

			$lastpos = $firstpos;
		    }
		}

		return 1;
	    }
	    elsif (! defined $nread) {  # read failed
		next if $! =~ /^Interrupted/;

		$opened = '';
		#return $self->error("unexpected read error: $!");
	    return 0;
		}
	    else {  # read end-of-file
		$opened = '';
		return;
	    }
	}
	elsif ($nfound < 0) {  # select failure
	    next if $! =~ /^Interrupted/;

	    ## Failure equates to eof.
	    $opened = '';
	    #return $self->error("unexpected read error: $!");
        return 0;
	}
	else {  # timed-out
	    $timedout = 1;
	    #return $self->error("read timed-out");
        return 0;
	}
    }
} # end sub _fillbuf


sub getlines {
    my(
       $len,
       $line,
       $pos,
       @lines,
       );

    ## Fill buffer and get first line.
    $line = getline(@_)
	or return ();
    push @lines, $line;

    ## Extract subsequent lines from buffer.
    while (($pos = index($buf, $rs)) != -1) {
	$len = $pos + length $rs;
	push @lines, substr($buf, 0, $len);
	substr($buf, 0, $len) = '';
    }

    return @lines;
} # end sub getlines

sub _have_alarm {
    eval {
	local $SIG{'__DIE__'} = 'DEFAULT';
	local $SIG{ALRM} = sub { die };
	alarm 0;
    };

    ! $@;
} # end sub _have_alarm

######################## Exported Constants ##########################

sub TELOPT_BINARY ()	  {0}; # Binary Transmission
sub TELOPT_ECHO ()	      {1}; # Echo
sub TELOPT_RCP ()	      {2}; # Reconnection
sub TELOPT_SGA ()	      {3}; # Suppress Go Ahead

################### End Private Telnet Functions ###########################


1;
__END__;


######################## User Documentation ##########################


## To format the following user documentation into a more readable
## format, use one of these programs: pod2man; pod2html; pod2text.

=head1 NAME


Net::Pager - Send Numeric/AlphaNumeric Pages to any pager/phone around the world.

=head1 SYNOPSIS


Pager supports both plain function calls or an object to be instantiated.

C<use Net::Pager;>

see METHODS and EXAMPLES sections below for more explanation

=head1 DESCRIPTION


Net::Pager is a global numeric and alphanumeric paging interface via the
Internet. We're bringing you the first and only way to interface any brand
or type of pager through one consistent protocol without using the telephone
network. Our purpose is to define a paging standard and make numerous tools
available for developer's use so paging technology can be better utilized.

The module interacts with SimleWire's Remote Procedure Calls. This new
standard, and subsequently this Perl module, has a great deal of development
energy behind it and will have full development support through an online
support forum. Pager has built-in redundancy to create a fail-safe
system.

For futher support or questions, you should visit Pager's website at
I<www.simplewire.com> where you can visit our developer support forum, faq, or
download the most recent documentation.  SimpleWire's site has more example
code and perl client tools.

=head2 What To Know Before Using


=over 2

=item *


Net::Pager attempts to bypass most firewall problems by only interacting
with port 80 of any of SimpleWire's servers.

=item *


If you are unfamiliar with what a service list means or what services
that SimpleWire currently supports then a visit to our website will give you
a good idea.  I<www.simplewire.com> can provide you with that information.

=back

=head2 Important variables


=over 2

=item B<service>


This stands for the type of paging service.  You can figure out what service
you need by either exploring the return from B<getServiceList()> or by
viewing the services on www.simplewire.com.

=item B<pin>


This stands for the pager's 7 or 10 digit phone number.

=item B<from>


This is simply the full name of the person who is sending the page.  This
value is prepended to any pages so that alphanumeric pages start out with
"FR:$from" and then a "| " seperates this value from the text message.

=item B<message>


This is the text message that you want to send to the pager.  Remember that
all pagers have limits on how long messages can be.  You want to check the
service list's $getServiceListReturn[$array_index_of_service]{MSGLEN} to
determine the maximum message length.

=item B<callback>


This variable is the number that you want to be called back at.  For numeric
pagers this is used as the message displayed on the pager instead of the
message variable for alphanumeric pagers.  NOTE: Alphanumeric pagers do not
use this variable.  If you want the callback number to show up then you must
append this number to the message field.

=item B<setvar>


This variable determines whether or not stored variables like pin or callback
are changed when you call the sendPage() function.  For example, if you store
the service, pin, callback, message, and from in seperate function calls
to pin($pin) or service($service) and then get ready to call sendPage()
and setvar is false then you can pass in all in new variables to sendPage()
like sendPage( service => '32' ) and sendPage will now temporarily use a
service id of 32 instead of $service and not change what you previously
stored in the call to service($service).

=back

=head1 METHODS


=over 4

=item B<new()> - create a new Net::Pager object


There are multiple ways to call this function.

You can call it with no parameters

	$pager = Net::Pager->new();

Or you can call it with a list of 5 parameters that must be in this order

    $pager = Net::Pager->new($service,
                                  $pin,
                                  $from,
                                  $message,
                                  $callback);

Or you can call it with a hash and pass however many parameters that you
want and pass them in whatever order you want.  This is probably the best
way to call Net::Pager::sendPage()

    $pager = Net::Pager->new(service => "14",
                                  message => "Message",
                                  pin     => "1234567890",
                                  from    => "John Smith",
                                  callback=> "1234567890",
                                  setvar  => 1 );

This returns a reference to a Pager object.  You can then store
any variables that you want in it, download the service list, etc.

=item B<sendPage()> - sends a numeric or alphanumeric page


Using sendPage() without instantiating an object:

	$return = Net::Pager::sendPage($service,$pin,$from,$msg,$callback);

Using sendPage() with an instantiated object:

    #you must always create a new object
    $pager->Net::Pager->new();

    #based on what you did before you call sendPage() you can use
    #any of these calls
    $return = $pager->sendPage();

   	$return = $pager->sendPage($service,$pin,$from,$message,$callback);

    $return = $pager->sendPage(service => "14",
                     message => "Message",
                     pin     => "1234567890",
                     from    => "John Smith",
                     callback=> "1234567890",
                     setvar  => 1 );

You do not have to pass in all the variables with the hash
approach.  You can just pass in the ones that you want and you
can pass them in, in any order that you want.

sendPage() returns a true or false boolean indicating whether or not the page
was sucessfully sent or not.  If it is not successful then you can
check what error it was with the errorCode() and errorMessage()
functions.

=item B<getServiceList()> - gets service list


Retrieves service list for all the paging services that SimpleWire supports.

Using getServiceList() without instantiating an object:

	@services = Net::Pager::getServiceList();

Using getServiceList() with an instantiated object:

    $pager->Net::Pager->new();
    @services = $pager->getServiceList();

We recommend the object approach because once you download the service
list for one object, we store it in a variable that persists and will
not download again.  If you want to force an update pass in the param
"refresh" so the call would be

    @services = $pager->getServiceList("refresh");

This returns an array of hashes that represent all the services that
SimpleWire supports.  Here is some example code and more is in the
EXAMPLES section to show exactly how to access the service list.

    @services = $pager->getServiceList();

    #the @serv array contains a hash with these keys and the index
    #of zero always will contain these values.
	$services[0]{SERVICE} = "The Service ID"
    $services[0]{DESCRIPTION} = "Describes Service"
    $services[0]{TYPE} = "N or A"
    $services[0]{MSGLEN} = "Max Length of message"
    $services[0]{FROMLEN} = "Max length of from"
    $services[0]{PINLEN} = "Max Length of pin"

You'll see how to use the service list array more in the EXAMPLES section

=item B<serviceExists($service)>


returns the index in the service list array where
$service = $services[$index]{SERVICE}

if $service does not exist then a -1 is passed back.

=item B<service()> - the service number


    #get service
    $service = $pager->service();

    #set service
    $pager->service($service);

With no argument this method returns the service number in the object.
With an argument it sets the service number to $service and returns the
previous value.

=item B<pin()> - the pager's phone number


    #get pin
    $pin = $pager->pin();

    #set pin
    $pager->pin($pin);

With no argument this method returns the pin in the object.
With an argument it sets the pin to $pin and returns the
previous value.

=item B<from()> - who is sending the page


    #get from
    $from = $pager->from();

    #set from
    $pager->from($from);

With no argument this method returns the from in the object.
With an argument it sets the from to $from and returns the
previous value.

=item B<message()> - the alphanumeric pager's text message


    #get message
    $message = $pager->message();

    #set message
    $pager->message($message);

With no argument this method returns the message in the object.
With an argument it sets the message to $message and returns the
previous value. Remember that their are limits to the length of messages.
See the explanation in the DESCRIPTION section for how to determine
the maximum length for each paging service.

If you want a callback number to show up then you must append this value
to the message.  Callback only works for numeric pagers.

=item B<callback()> - the callback number for numeric pagers


    #get callback
    $callback = $pager->callback();

    #set callback
    $pager->callback($callback);

This is the numeric callback number where someone should call in response
to a page.

=item B<errorCode()> - the last error code


    #get service
    $errCode = $pager->errorCode();

With no argument this method returns the last error code from attempting to
send a page.  For a current list of what the codes mean, please visit
www.simplewire.com

=item B<errorMessage()> - the last error message


    #get service
    $errCode = $pager->errorMessage();

With no argument this method returns the last error message from attempting to
send a page.  Basically this is a description of what the errorCode()
function returns.

=back

=head1 EXAMPLES


Send off a normal page once you know the paging service number and check to
see if it went through correctly.

    use Net::Pager;

	$service = "12";
    $pin = "01234567890";
    $from = "Joe Lauer";
    $msg = "Merry Christmas!";
    $callback = "01234567890";

    $pager = Net::Pager->new;

    #now send the page off
    $pager->sendPage($service, $pin, $from, $msg, $callback);

    if ( $pager->isError() ) {
        print "There was an error sending your page!\n";
        print "Message: " .$pager->errorMessage . "\n";
        print "   Code: " . $pager->errorCode . "\n";
    } else {
        print "Your message was succesfully sent!!\n";
    }

This example instantiates an object and calls sendPage() with 5 parameters

    use Net::Pager;

    $service = "12";
    $pin = "1234567890";
    $from = "joe";
	$msg = "Hello World From Net::Pager!!!";
    $callback = "2022381349";

    $pager = Net::Pager->new;

    $retBool = $pager->sendPage($service, $pin, $from, $msg, $callback);

This next example sets and stores all the service, pin, etc. within a Pager
object and then calls the sendPage() function with no parameters.

    use Net::Pager;

    $pager = Net::Pager->new;

	$pager->service("13");
    $pager->pin("1234567890");
    $pager->from("Joe");
    $pager->message("Hello World From Net::Pager!!!");
    $pager->callback("1234567890");

	$retBool = $pager->sendPage();

This next way sets all the variables when it creates the object and then
calls sendPage() with no parameters.

    use Net::Pager;

	$pager = Net::Pager->new(service => "1",
                             message => "Message",
                             pin     => "1234567890",
                             from    => "Joe Lauer",
                             callback=> "1234567890",
                             setvar  => 1 );

    $retBool = $pager->sendPage();

This next few lines of code show how to use the getServiceList() without
instantiating an object.

    use Net::Pager;

    #get service list
    @services = Net::Pager::getServiceList();

    #accessing the results examples
	print $services[0]{DESCRIPTION} . "\n";
    print $services[0]{SERVICE} . "\n";
    print $services[1]{DESCRIPTION} . "\n";
    print $services[1]{SERVICE} . "\n";
    print $services[1]{TYPE} . "\n";
    print $services[1]{FROMLEN} . "\n";
    print $services[1]{PINLEN} . "\n";

This next few lines of code show how to use the getServiceList() with
instantiating an object.

    use Net::Pager;

    #get service list
	$pager = new Net::Pager;
    @services = $pager->getServiceList();

    #accessing the results examples
    print $services[0]{DESCRIPTION} . "\n";
    print $services[0]{SERVICE} . "\n";
    print $services[1]{DESCRIPTION} . "\n";
    print $services[1]{SERVICE} . "\n";
    print $services[1]{TYPE} . "\n";
    print $services[1]{FROMLEN} . "\n";
    print $services[1]{PINLEN} . "\n";

Now we want to refresh the service list in the same $pager object.

    use Net::Pager;

	@services = $pager->getServiceList("refresh");

I want to check and see if a service number exists or I want to get the
position of the service in the array passed back by getServiceList()

    use Net::Pager;

    $index = $pager->serviceExists("22");

    #accessing the results examples
    print $services[$index]{DESCRIPTION} . "\n";
    print $services[$index]{SERVICE} . "\n";
    print $services[$index]{TYPE} . "\n";
    print $services[$index]{FROMLEN} . "\n";
    print $services[$index]{PINLEN} . "\n";
    print $services[$index]{MSGLEN} . "\n";

These are all the examples for now.  If you still don't know how to do what
you want then please submit your code request at SimpleWire's site.  Just go
to www.simplewire.com and then follow the links to the Developers section
and go to the Support Forum.  This forum is monitored by the creator's of
this module and can answer your question very quickly.

=head1 AUTHOR


Joe Lauer E<lt>joelauer@rootlevel.comE<gt>

=head1 COPYRIGHT


Copyright (c) 2000 Rootlevel. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

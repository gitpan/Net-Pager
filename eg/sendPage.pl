#!/usr/local/bin/perl

############################################################################
# Examples For Net::Pager, version 0.90

#Copyright (c) 2000 Rootlevel. All rights reserved. This program is free
#software; you can redistribute it and/or modify it under the same terms
#as Perl itself.


# If you need the module/updates/dependencies/more help please go to
# www.simplewire.com
############################################################################

#First declare package
use Net::Pager;

#Now we can do some examples.

##################
# NOTE: None of these examples truly sends a page and all but one will
# generate a message that says the page was not successful.
##################

#Send off a normal page once you know the paging service number
#and check to see if it went through correctly.

print "\n\nTesting the first page...\n\n";

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

#This example instantiates an object and calls sendPage() with 5
#parameters


print "\n\nTesting the second page...\n\n";
        
		$service = "12";
        $pin = "1234567890";
        $from = "joe";
            $msg = "Hello World From Net::Pager!!!";
        $callback = "2022381349";

        $pager = Net::Pager->new;

        $retBool = $pager->sendPage($service, $pin, $from, $msg, $callback);

        if ( $pager->isError() ) {
            print "There was an error sending your page!\n";
            print "Message: " .$pager->errorMessage . "\n";
            print "   Code: " . $pager->errorCode . "\n";
        } else {
            print "Your message was succesfully sent!!\n";
        }

#This next example sets and stores all the service, pin, etc.
#within a Pager object and then calls the sendPage() function
#with no parameters.

print "\n\nTesting the third page...\n\n";

		$pager = Net::Pager->new;

        $pager->service("13");
        $pager->pin("1234567890");
        $pager->from("Joe");
        $pager->message("Hello World From Net::Pager!!!");
        $pager->callback("1234567890");

        $retBool = $pager->sendPage();

        if ( $pager->isError() ) {
            print "There was an error sending your page!\n";
            print "Message: " .$pager->errorMessage . "\n";
            print "   Code: " . $pager->errorCode . "\n";
        } else {
            print "Your message was succesfully sent!!\n";
        }

#This next way sets all the variables when it creates the object
#and then calls sendPage() with no parameters.

print "\n\nTesting the fourth page...\n\n";

		$pager = Net::Pager->new(service => "19",
                                 message => "Message",
                                 pin     => "1234567890",
                                 from    => "Joe Lauer",
                                 callback=> "1234567890");

        $retBool = $pager->sendPage();

        if ( $pager->isError() ) {
            print "There was an error sending your page!\n";
            print "Message: " .$pager->errorMessage . "\n";
            print "   Code: " . $pager->errorCode . "\n";
        } else {
            print "Your message was succesfully sent!!\n";
        }


#Some examples showing what you can access and print out after a sendPage()
#NOTE: You must instanitate an object to do this.

print "Just printing out everything we can print out...\n\n";

print "Err Message: " . $pager->errorMessage . "\n";
print "   Err Code: " . $pager->errorCode . "\n";
print "    Service: " . $pager->service . "\n";
print "        Pin: " . $pager->pin . "\n";
print "       From: " . $pager->from . "\n";
print "    Message: " . $pager->message . "\n";
print "   Callback: " . $pager->callback . "\n";
print "    Message: " . Net::Pager::errorMessage . "\n";

#Don't do these!!!  These wont' work. You have to instantiate an object
#if you want to access these.

#print "    Code: " . Net::Pager::errorCode . "\n";
#print " Service: " . Net::Pager::service . "\n";
#print "     Pin: " . Net::Pager::pin . "\n";
#print "    From: " . Net::Pager::from . "\n";
#print " Message: " . Net::Pager::message . "\n";
#print "Callback: " . Net::Pager::callback . "\n";

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

#I want to check and see if a service number exists or I want to
#get the position of the service in the array passed back by
#getServiceList()

        $pager = Net::Pager->new();
        
		$test = "20";
		@services = $pager->getServiceList();
		$index = $pager->serviceExists($test);

        print "\nThe results of trying to see if the service exists...\n\n";

		if ($index ne "-1") {
	        #accessing the results examples
	        print "Description: " . $services[$index]{DESCRIPTION} . "\n";
	        print "Service: " . $services[$index]{SERVICE} . "\n";
	        print "Type: " . $services[$index]{TYPE} . "\n";
	        print "From: " . $services[$index]{FROMLEN} . "\n";
	        print "Pin Length: " . $services[$index]{PINLEN} . "\n";
	        print "Msg Length: " . $services[$index]{MSGLEN} . "\n";
        } else {
            print "Service '$test' does not exist.\n\n";
        }

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

#This next few lines of code show how to use the getServiceList()
#without instantiating an object.

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

#This next few lines of code show how to use the getServiceList()
#with instantiating an object.

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

#Now we want to refresh the service list in the same $pager
#object.

        @services = $pager->getServiceList("refresh");

#Print out all the services available

        foreach $index (0..$#services) {
            print $services[$index]{SERVICE} . ":" . $services[$index]{DESCRIPTION} . "\n";
        }
#!/usr/bin/perl -w
#
#
#
use Infoblox;
use Getopt::Std;
use Net::Netrc;
use XML::Dumper;
use strict;

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options;
getopts("r: ", \%options);
my $bloxmaster = 'ibl01nyc2us.us.wspgroup.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

my $zone = $options{r};

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my @hostrecords = $session->search(
	object=>"Infoblox::DNS::Host",
	ipv4addr=>$options{r},
	);

while (scalar(@hostrecords) gt 0)
	{
	local $\ = "\n";
	my $hostrecord = pop(@hostrecords);
	next if ($hostrecord->configure_for_dns() eq 'false');
	print "Testing " . $hostrecord->name;
	my $arrayipv4 = $hostrecord->ipv4addrs();
	foreach my $ip (@$arrayipv4)
		{
		my @arrayptr = $session->get(object=>"Infoblox::DNS::Record::PTR",
			ipv4addr=>$ip,
			);
		foreach my $ptr (@arrayptr)
			{
			my $result = $session->remove($ptr);
			if ($result) {print "Deleted " . $ptr->ptrdname} else {print "Could not delete " . $ptr->ptrdname}
			}
		}
	}


sub HELP_MESSAGE
        {
        print "\n$0 [OPTIONS]|--help|--version
        
        OPTIONS:
        --help (this message)
	-r Desired range\n";
        exit 0;
        }   


#!/usr/bin/perl -w
#
use Infoblox;
use Net::Netrc;
#use XML::Dumper;
use strict;

$\ = "\n";
my $reftoany = ["any"];  # That's right. Just a ref to the array with the array scalar. Just so I don't keep defining it.
my $reftonull = [];  # That's right. Just a ref to the array to nothing. Just so I don't keep defining it.
my $bloxmaster = 'ryentp2.rye.avon.com';
my $creds = Net::Netrc->lookup($bloxmaster);
my $session = Infoblox::Session->new("master"=> $bloxmaster, "username"=>$creds->login, "password"=>$creds->password);

unless ($session) {
               die("Construct session failed: ",
                       Infoblox::status_code() . ":" . Infoblox::status_detail());
                }

my @zones = $session->search(object=>'Infoblox::DNS::Zone',
		name => "^[0-9].*24\$",
		);

foreach (@zones)
	{
	next if ($_->name eq '127.0.0.0/24');   # Gotta skip loopback

	unless ($_->allow_gss_tsig_zone_updates() eq 'true')
		{
		print $_->name . " needs to have TSIG enabled.";
		$_->allow_gss_tsig_zone_updates('true');
		my $result = $session->modify($_);
		if ($result) {print "Succesfully changed " . $_->name;}
			else {warn $session->status_detail()}
		}
	if (@{$_->allow_update()})
		{
		print $_->name . " needs changing.";
		$_->allow_update($reftonull);
		my $result = $session->modify($_);
		if ($result) {print "Succesfully changed " . $_->name;}
			else {warn $session->status_detail()}
		}
	}


if (grep(/dns/, $session->restart_status())) # Restart stuff if needed
	{
	print "Have to restart DNS services.";
	my $result = $session->restart();
	if ($result) {print "Succesfully restarted members."} else { print "Problem restarting."}
	}

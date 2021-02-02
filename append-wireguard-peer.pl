#!/usr/bin/perl

use strict; use warnings;


my ($svr_conf, $svr_wan_if, $new_peer_IP, $new_peer_comment) = @ARGV;

if (not defined $svr_conf or not defined $svr_wan_if) {
	die "Arguments: my_svr.conf svr_WAN_interface [new_peer_IP] [new_peer_comment]";
}

# Get the server WAN IP address
`ip -o -4 addr list $svr_wan_if` =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
my $svr_WAN_IP = $1;

# Open and parse the server conf file
open SVR_CONF_HANDLE, $svr_conf or die $!;
my $svr_conf_str = do {local $/; <SVR_CONF_HANDLE>};
close SVR_CONF_HANDLE;

$svr_conf_str =~ /PrivateKey\s=\s(\S+)/;
my $svr_private_key = $1;

$svr_conf_str =~ /ListenPort\s=\s(\d+)/;
my $listen_port = $1;


# Get the first part of the name of the conf file
$svr_conf =~ /^(\w+)\.conf$/;
my $svr_conf_name = $1;

# Derive the server public key
my $svr_public_key = `echo "$svr_private_key" | wg pubkey`;


if (defined $new_peer_IP) {

	# Generate a private key for the peer
	my $peer_private_key = `wg genkey`;
	# Generate a public key for the peer
	my $peer_public_key = `echo "$peer_private_key" | wg pubkey`;
	
	# Output a new peer configuration file
	print
		"[Interface]\n" .
		"PrivateKey = ${peer_private_key}" .
		"Address = ${new_peer_IP}/32\n" .
		"\n" .
		"[Peer]\n" .
		"PublicKey = ${svr_public_key}" .
		"Endpoint = ${svr_WAN_IP}:${listen_port}\n" .
		"AllowedIPs = 0.0.0.0/0\n" .
		"DNS = 84.200.70.40\n";
	
	`cp ${svr_conf} ${svr_conf}.bak` and die "Unable to create backup of ${svr_conf}!\n".$!;
	# Append to the server conf file
	open SVR_APPEND_CONF_HANDLE, '>>', $svr_conf or die "Unable to append to ${svr_conf}!\n".$!;
	print SVR_APPEND_CONF_HANDLE
		"\n" .
		"[Peer]\n" .
		(defined $new_peer_comment ? "# ${new_peer_comment}\n" : "") .
		"PublicKey = ${peer_public_key}" .
		"AllowedIPs = ${new_peer_IP}/32\n";
	close SVR_APPEND_CONF_HANDLE;
	
} else {

	print
		"Server WAN IP: ".$svr_WAN_IP."\n".
		"Server PublicKey: ".$svr_public_key.
		"Server ListenPort: ".$listen_port."\n";
		
	my @address_list = ($svr_conf_str =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/g);
	
	print "IP List:\n";
	foreach my $ip (@address_list) {
		print $ip."\n";
	}
	
}


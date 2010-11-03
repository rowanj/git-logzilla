#!/usr/bin/env perl
# Copyright (C) 2007, Steve Frécinaux <code@istique.net>
# License: GPL v2 or later

use strict;
use warnings;
use Getopt::Long qw(:config posix_default gnu_getopt);
use Term::ReadKey qw/ReadMode ReadLine/;

# Use WWW::Mechanize if available and display a gentle message otherwise.
BEGIN {
	eval { require WWW::Mechanize; import WWW::Mechanize };
	die <<ERROR if $@;
The module WWW::Mechanize is required by git-send-bugzilla but is currently
not available. You can install it using cpan WWW::Mechanize.
ERROR
}

my $mech = WWW::Mechanize->new(agent => "git-logzilla/0.1");
my $url = '';

sub authenticate {
	my $username = shift;
	my $password = shift;

	unless ($username) {
		print "Bugzilla login: ";
		chop ($username = ReadLine(0));
	}

	unless ($password) {
		print "Bugzilla password: ";
		ReadMode 'noecho';
		chop ($password = ReadLine(0));
		ReadMode 'restore';
		print "\n";
	}

#	print STDERR "Logging in as $username...\n";
	$mech->get("$url/index.cgi?GoAheadAndLogIn=1");
	die "Can't fetch login form: ", $mech->res->status_line
		unless $mech->success;

	$mech->set_fields(Bugzilla_login => $username,
			  Bugzilla_password => $password);
	$mech->submit;
	die "Login submission failed: ", $mech->res->status_line
		unless $mech->success;
	die "Invalid login or password\n" if $mech->title =~ /Invalid/i;
}

sub add_comment {
	my $bugid = shift;
	my $comment = shift;

	$mech->get("$url/show_bug.cgi?id=$bugid");
	die "Can't get bug modification form: ", $mech->res->status_line
		unless $mech->success;

	my $form = $mech->form_name('changeform');

	$form->value('comment', $comment);

	$mech->submit;
	die "Comment failed: ", $mech->res->status_line
		unless $mech->success;
}

sub read_repo_config {
	my $key = shift;
	my $type = shift || 'str';
	my $default = shift || '';

	my $arg = 'git config';
	$arg .= " --$type" unless $type eq 'str';

	chop (my $val = `$arg --get bugzilla.$key`);
	
	return $default if $?;
	return $val eq 'true' if ($type eq 'bool');
	return $val;
}

sub usage {
	my $exitcode = shift || 0;
	my $fd = $exitcode ? \*STDERR : \*STDOUT;
	print $fd "Usage: git-logzilla [options] <bugid> <comment>\n";
	exit $exitcode;
}

$url = read_repo_config 'url', 'str', 'http://bugzilla.gnome.org';
my $username = read_repo_config 'username';
my $password = read_repo_config 'password';
my $start_number = read_repo_config 'startnumber', 'int', 1;
my $help = 0;

# Parse options
GetOptions("url|b=s" => \$url,
           "username|u=s" => \$username,
	   "password|p=s" => \$password,
	   "start-number" => \$start_number,
	   "help|h|?" => \$help);

exec 'man', 1, 'git-logzilla' if $help;

my $bugid = shift @ARGV
    or print STDERR "No bug id specified!\n" and usage 1;

my $comment = shift @ARGV
    or print STDERR "No comment specified!\n" and usage 1;

#print STDERR "Preparing to comment \"$comment\" on bug $bugid...";

authenticate $username, $password;

print STDERR "Adding comment to bug $bugid... ";

add_comment $bugid, $comment;

print STDERR "done.\n"

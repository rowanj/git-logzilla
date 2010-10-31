#!/usr/bin/env perl
# Based on code by: Devendra Gera, 2008
# Copyright (C) 2010, Rowan James <rowanj@burninator.net>
# License: GPL v2 or later
use strict;

my $input = <>;
chomp $input;

my ($oldrev, $newrev, $refname) = split /\s+/, $input;
#print "oldrev=$oldrev\n";
#print "newvev=$newrev\n";
#print "refname=$refname\n";

my $commit_msg = `git whatchanged $oldrev..$newrev`;
#print "base commit_msg=$commit_msg\n";

# author
my ($author) = ( $commit_msg =~ /^Author:\s+(.*)$/m );

# files
my @filelist = grep ( /^:/, split( /\n/, $commit_msg ) );

# prepare comment
$commit_msg =~ s/^.*?Date://s;# eat everything till the Date: heder
$commit_msg =~ s/^.*?\n//m;# eat the date line completely
$commit_msg =~ s/^:.*?$//mg;# eat the file list from the msg.
chomp $commit_msg;

my $bug_regex = 'bug\s*(?:#|)\s*(?P<bug>\d+)';
my ($bug_number) = ( $commit_msg =~ /$bug_regex/ );

my $comment = "----------------------------------------
$author changed bug $bug_number in $refname
\t($newrev)
----------------------------------------";
$comment .= "$commit_msg";
$comment .= "----------------------------------------
Changed:\n";
$comment .= join("", @filelist) . "\n----------------------------------------\n";


print "$comment";

#!/usr/bin/env perl
# Based on code by: Devendra Gera, 2008
# Copyright (C) 2010, Rowan James <rowanj@burninator.net>
# License: GPL v2 or later
use strict;

use List::MoreUtils qw(uniq);

my $input = <>;
chomp $input;

my ($oldrev, $newrev, $refname) = split /\s+/, $input;

sub add_comment {
    my $bug_number = shift;
    my $comment = shift;

    git-bugz-comment $bug_number "$comment";
}

# Define a function to add git notes to each bug it modifies
sub process_commit {
    my $commit_id = shift;

    print "Proccessing message for commit $commit_id\n";

    my $commit_msg = `git whatchanged -n 1 $oldrev..$newrev`;
#print "base commit_msg=$commit_msg\n";

# author
    my ($author) = ( $commit_msg =~ /^Author:\s+(.*)$/m );

# files
    my @filelist = grep ( /^:/, split( /\n/, $commit_msg ) );

# prepare comment
    $commit_msg =~ s/^.*?Date://s;# eat everything till the Date: header
    $commit_msg =~ s/^.*?\n//m;# eat the date line completely
    $commit_msg =~ s/^:.*?$//mg;# eat the file list from the msg.
    chomp $commit_msg;

    my $bug_regex = 'bug\s*(?:#|)\s*(?P<bug>\d+)';
    my (@bug_numbers) = uniq(sort( $commit_msg =~ /$bug_regex/gi ));

    my $comment = "----------------------------------------
$author committed $refname
\t($newrev)
Tagged with:\n";
    foreach my $bug_number(@bug_numbers) {
	$comment .= "\tbug $bug_number\n";
    }
    $comment .= "----------------------------------------";
    $comment .= "$commit_msg";
    $comment .= "----------------------------------------
Paths changed:\n";
    $comment .= join("", @filelist) . "\n----------------------------------------\n";

    foreach my $bug_number(@bug_numbers) {
	add_comment($bug_number, $comment);
    }
}

# Get a list of all commits being added
my $commit_list = `git log --pretty=oneline $oldrev..$newrev`;
my @commits = reverse(split("\n", $commit_list));

foreach my $commit(@commits) {
    process_commit($commit);
}

exit 0;
# 

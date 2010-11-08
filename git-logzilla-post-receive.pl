#!/usr/bin/env perl
# Based on code by: Devendra Gera, 2008
# Copyright (C) 2010, Rowan James <rowanj@burninator.net>
# License: GPL v2 or later
use strict;

use List::MoreUtils qw(uniq);

sub add_comment {
    my $bug_number = shift;
    my $comment = shift;

#    print STDERR "Hook: adding comment \"$comment\" to bug $bug_number\n";
    open(COMMENT_PIPE, "|-") || exec 'git-bugz-comment', "$bug_number";
    print COMMENT_PIPE "$comment";
    close(COMMENT_PIPE);
}

# Define a function to add git notes to each bug it modifies
sub process_commit {
    my $commit_info = shift;
    my $commit_refname = shift;

    my $commit_id = ((split(/\s+/,$commit_info))[0]);

#    print "Proccessing message for commit $commit_id\n";

    my $commit_msg = `git whatchanged -n 1 $commit_id`;
#print "base commit_msg=$commit_msg\n";

# author
    my ($author) = ( $commit_msg =~ /^Author:\s+(.*)$/m );

# files
    my @filelist = grep ( /^:/, split( /\n/, $commit_msg ) );

# prepare comment
    $commit_msg =~ s/^.*?Date://s;# eat everything till the Date: header
    $commit_msg =~ s/^.*?\n//m;# eat the date line completely
    $commit_msg =~ s/^:.*?$//mg;# eat the file list from the msg.
    $commit_msg =~ s/^\s+|\s+$//g ;# strip leading and trailing whitespace

    my $bug_regex = 'bug\s*(?:#|)\s*(?P<bug>\d+)';
    my (@bug_numbers) = uniq(sort( $commit_msg =~ /$bug_regex/gi ));

    my $bug_list;
    foreach my $bug_number(@bug_numbers) {
	$bug_list .= "\tbug $bug_number\n";
    }
    chomp $bug_list;

    my $change_list;
    foreach my $file(@filelist) {
	$change_list .= "\t$file\n";
    }
    chomp $change_list;

    my $comment = <<END;
$author committed $commit_refname
\t($commit_id)

$commit_msg

--
Changed:
$change_list
--
Tagged with:
$bug_list
END

    foreach my $bug_number(@bug_numbers) {
	add_comment($bug_number, $comment);
    }
}

# for each ref that's being updated
# we get the previous HEAD, the new HEAD, and the name of the ref
# read lines from STDIN until the pipe is closed (EOF)
my $line;
while (defined($line = <STDIN>)) {
    chomp $line;
    my ($oldrev, $newrev, $refname) = split /\s+/, $line;

    my $commit_list = `git log --pretty=oneline $oldrev..$newrev`;
    my @commits = reverse(split("\n", $commit_list));

    foreach my $commit(@commits) {
	if ($refname == "refs/heads/master") {
	    process_commit($commit, $refname);
	} else {
	    print "Ignoring update on $refname";
	}
    }
}
exit;


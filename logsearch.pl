#!/usr/bin/env perl -w
#
# Adds a /search <query> command to irssi which will search the channel/pm
# logs for the given query and print the results in the window

use strict;
use vars qw($VERSION %IRSSI $DEBUG $LogDir $NumLines $NumContext);

use Irssi;

#######################################
###     GLOBALS                     ###
#######################################
$VERSION = '0.0.1';
%IRSSI = (
        authors         =>      'Masen Furer',
        contact         =>      'mf@0x26.net, masen on irc.freenode.net',
        name            =>      'logsearch',
        description     =>      'irssi in-client log search',
        license         =>      'BSD',
        url             =>      'http://github.com/masenf/irssi-logsearch'
);

# correlates the reverse index of the last item returned in search
# of a given query or channel, allows for resuming search with /searchmore
my %last_search = { };
my %last_search_query = { };


sub create_settings {
    Irssi::settings_add_bool($IRSSI{'name'}, 'ls_debug', 0);
    Irssi::settings_add_str($IRSSI{'name'}, 'ls_logdir', '~/irclogs');
    Irssi::settings_add_int($IRSSI{'name'}, 'ls_numlines', 11);
    Irssi::settings_add_int($IRSSI{'name'}, 'ls_numcontext', 1);
}

sub load_settings {
    # delayed global variables are loaded after irssi has been
    # initializaed
    $DEBUG      = Irssi::settings_get_bool('ls_debug');
    $LogDir     = Irssi::settings_get_str('ls_logdir');
    $NumLines   = Irssi::settings_get_int('ls_numlines');
    $NumContext = Irssi::settings_get_int('ls_numcontext');
}

sub debug {
    if ($DEBUG) {
        Irssi:print("DEBUG: ". $_[0]);
    }
}

sub expand_home {
    my $path = @_[0];
    $path =~ s{
        ^ ~     # find a leading tilde
        (       # save this in $1
        [^/]    # a non-slash character
        *       # repeated 0 or more times (0 means me)
        )
    }{
        $1
        ? (getpwnam($1))[7]
        : ( $ENV{HOME} || $ENV{LOGDIR} )
    }ex;
    return $path;
}
sub print_results {
    my ($witem, $target, $cmd) = @_;
    my @lines = `$cmd`;
    my $startindex = scalar(@lines) - $last_search{$target};
    my $endindex = $startindex - $NumLines;
    if ($endindex < 0) {
        $endindex = 0;
    }
    if ($startindex <= 0) {
        return;
    }
    my $strip = expand_home($LogDir) . "/";
    debug("Printing results from $startindex to $endindex");
    for (my $i=$endindex; $i<$startindex; $i++) {
        chomp($lines[$i]);
        $lines[$i] =~ s/$strip//;
        if ($lines[$i]) {
            $witem->printformat(MSGLEVEL_CRAP,
                                'format_result',
                                $lines[$i]);
        }
    }
    $last_search{$target} += ($startindex - $endindex);
    debug("Set last_search on $target to " . $last_search{$target});
}

#######################################
###     IRSSI COMMANDS              ###
#######################################
# this starts a new search
sub cmd_ls_logsearch {
    my ($data, $server, $witem) = @_;
    my $target = $server->{tag};

    if ($witem) {
        $target = $witem->{name};
    }
    $last_search{$target} = 0;
    $last_search_query{$target} = $data;
    cmd_ls_logsearch_more($data, $server, $witem)
}

# this continues a previous search
sub cmd_ls_logsearch_more {
    my ($data, $server, $witem) = @_;
    my $target = $server->{tag};
    my $logpath = $LogDir . "/" . $target;
    my $cmd = "";
    my $flags = "";

    if ($witem) {
        $target = $witem->{name};
        $logpath = $logpath . "/" . $target . ".log";
    } else {
        # recursively search all logs for the server
        $witem = Irssi::active_win();
        $flags = "-r";
    }

    $logpath = expand_home($logpath);

    my $query = $last_search_query{$target};
    $cmd = "grep $flags -C $NumContext '$query' $logpath";

    debug("cmd_ls_logsearch_more query=" . $query . " target=" . $target . " cmd=" . $cmd);

    # check to make sure things are sort of valid before continuing
    if (! -e $logpath) {
        $witem->printformat(MSGLEVEL_CRAP,
                            'format_result',
                            "log file not found: $logpath");
        return;
    }
    if (!$query)
    {
        $witem->printformat(MSGLEVEL_CRAP,
                            'format_result',
                            "no previous search query for $target");
        return;
    }
    print_results($witem, $target, $cmd);
}

#######################################
###     INITIALIZATION              ###
#######################################
Irssi::command_bind('search', 'cmd_ls_logsearch');
Irssi::command_bind('searchmore', 'cmd_ls_logsearch_more');
Irssi::theme_register([
  'format_result', '%y$0%n'
]);
create_settings();
load_settings();

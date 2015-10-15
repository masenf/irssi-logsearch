# irssi-logsearch
Search your irc logs from within your irc client

## setup

* enable irc logging by server/channel/nick in irssi

      ```/SET AUTOLOG ON```

* copy the script to ```~/.irssi/scripts```

* load the script

      ```/LOAD logsearch.pl```

## usage

The script adds 2 new commands and 4 new settings

Search the log for the current window

    /SEARCH <query>

Continue the search

    /SEARCHMORE
  
### settings

Log directory (default: ~/irclogs)

    /SET ls_logdir

Results per search (default: 11)

    /SET ls_numlines
  
Context lines to show (default: 1)

    /SET ls_numcontext
    
Enable debugging output (default: OFF)

    /SET ls_debug ON

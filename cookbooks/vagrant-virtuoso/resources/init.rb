#!/bin/sh
#
# Example init.d script with LSB support.
#
# Please read this init.d carefully and modify the sections to
# adjust it to the program you want to run.
#
# Copyright (c) 2007 Javier Fernandez-Sanguino <jfs@debian.org>
#
# This is free software; you may redistribute it and/or modify
# it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2,
# or (at your option) any later version.
#
# This is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License with
# the Debian operating system, in /usr/share/common-licenses/GPL;  if
# not, write to the Free Software Foundation, Inc., 59 Temple Place,
# Suite 330, Boston, MA 02111-1307 USA
#
### BEGIN INIT INFO
# Provides:          virtuoso-opensource-7
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $remote_fs
# Should-Start:      $named
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Virtuoso OpenSource Edition
# Description:       This file should be used to start/stop the virtuoso-t
#                    daemon for the default installed database.
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

DAEMON=/usr/local/bin/virtuoso-t
NAME=virtuoso-opensource-7
SHORTNAME=virtuoso
DESC="Virtuoso OpenSource Edition 7"
DBPATH=/usr/local/var/lib/virtuoso-opensource-7/db
LOGDIR=/usr/local/var/log/virtuoso-opensource-7 # Log directory to use

PIDFILE=/var/run/$NAME.pid

test -x $DAEMON || exit 0

. /lib/lsb/init-functions

# Default options, these can be overriden by the information
# at /etc/default/$NAME
DAEMON_OPTS="+configfile /usr/local/var/lib/virtuoso-opensource-7/db/virtuoso.ini"          # Additional options given to the server

STARTTIME=1             # Time to wait for the server to start, in seconds
                        # If this value is set each time the server is
                        # started (on start or restart) the script will
                        # stall to try to determine if it is running
                        # If it is not set and the server takes time
                        # to setup a pid file the log message might
                        # be a false positive (says it did not start
                        # when it actually did)

LOGFILE=$LOGDIR/$NAME.log  # Server logfile
# DAEMONUSER=$NAME   # Users to run the daemons as. If this value
                        # is set start-stop-daemon will chuid the server

# Include defaults if available
if [ -f /etc/default/$NAME ] ; then
    . /etc/default/$NAME
fi

# Use this if you want the user to explicitly set 'RUN' in
# /etc/default/
if [ "x$RUN" != "xyes" -a "x$2" != "xignoredefault" ] ; then
    log_failure_msg "$NAME disabled, /etc/default/$NAME."
    exit 0
fi

# Check that the user exists (if we set a user)
# Does the user exist?
if [ -n "$DAEMONUSER" ] ; then
    if getent passwd | grep -q "^$DAEMONUSER:"; then
        # Obtain the uid and gid
        DAEMONUID=`getent passwd |grep "^$DAEMONUSER:" | awk -F : '{print $3}'`
        DAEMONGID=`getent passwd |grep "^$DAEMONUSER:" | awk -F : '{print $4}'`
    else
        log_failure_msg "The user $DAEMONUSER, required to run $NAME does not exist."
        exit 1
    fi
fi

running_pid() {
# Check if a given process pid's cmdline matches a given name
    pid=$1
    name=$2
    [ -z "$pid" ] && return 1
    [ ! -d /proc/$pid ] &&  return 1
    cmd=`cat /proc/$pid/cmdline | tr "\000" "\n"|head -n 1 |cut -d : -f 1`
    # Is this the expected server
    [ "$cmd" != "$name" ] &&  return 1
    return 0
}

running() {
# Check if the process is running looking at /proc
# (works for all users)

    # No pidfile, probably no daemon present
    [ ! -f "$PIDFILE" ] && return 1
    pid=`cat $PIDFILE`
    running_pid $pid $DAEMON || return 1
    return 0
}

start_server() {
# Start the process using the wrapper
        if [ -z "$DAEMONUSER" ] ; then
            start-stop-daemon --start --quiet \
                        --user `id -un` \
                        --chdir $DBPATH --exec $DAEMON \
                        -- $DAEMON_OPTS || return $?
        else
# if we are using a daemonuser then change the user id
            start-stop-daemon --start --quiet \
                        --user $DAEMONUSER --chuid $DAEMONUSER \
                        --chdir $DBPATH --exec $DAEMON \
                        -- $DAEMON_OPTS || return $?
        fi
        # Write the pid file using the process id from virtuoso.lck
        sleep 1
        sed 's/VIRT_PID=//' $DBPATH/$SHORTNAME.lck > $PIDFILE
        return 0
}

stop_server() {
# http://docs.openlinksw.com/virtuoso/signalsandexitcodes.html says TERM should be used by rc.d scripts, so we do
# Stop the process using the wrapper
        if [ -z "$DAEMONUSER" ] ; then
            start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE \
                        --user `id -un` \
                        --exec $DAEMON || return $?
        else
# if we are using a daemonuser then look for process that match
            start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE \
                        --user $DAEMONUSER \
                        --exec $DAEMON || return $?
        fi

        rm -f $PIDFILE
        return 0
}


case "$1" in
  start)
        log_daemon_msg "Starting $DESC " "$NAME"
        # Check if it's running first
        if running ;  then
            log_progress_msg "apparently already running"
            log_end_msg 0
            exit 0
        fi
        if start_server ; then
            # NOTE: Some servers might die some time after they start,
            # this code will detect this issue if STARTTIME is set
            # to a reasonable value
            [ -n "$STARTTIME" ] && sleep $STARTTIME # Wait some time
            if  running ;  then
                # It's ok, the server started and is running
                log_end_msg 0
            else
                # It is not running after we did start
                log_end_msg 1
            fi
        else
            # Either we could not start it
            log_end_msg 1
        fi
        ;;
  stop)
        log_daemon_msg "Stopping $DESC" "$NAME"
        if running ; then
            # Only stop the server if we see it running
            stop_server
            log_end_msg $?
        else
            # If it's not running don't do anything
            log_progress_msg "apparently not running"
            log_end_msg 0
            exit 0
        fi
        ;;
  restart|force-reload)
        log_daemon_msg "Restarting $DESC" "$NAME"
        stop_server
        case "$?" in
        0|1)
            start_server
            case "$?" in
                0) [ -n "$STARTTIME" ] && sleep $STARTTIME # Wait some time
                    running # check if it still runs
                    log_end_msg $?
                    ;;
                1) log_end_msg 1 ;; # Old process is still running
                *) log_end_msg 1 ;; # Failed to start
            esac
            ;;
        *)
            # Failed to stop
            log_end_msg 1
            ;;
        esac
        ;;
  status)
        log_daemon_msg "Checking status of $DESC" "$NAME"
        if running ;  then
            log_progress_msg "running"
            log_end_msg 0
        else
            log_progress_msg "apparently not running"
            log_end_msg 1
            exit 1
        fi
        ;;
  *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload|status}" >&2
        exit 1
        ;;
esac

exit 0


Filtering Log Files
===================

It is not really possible to write comprehensive rules about how to deal with the influx of data that may appear in a logfile.

(this is why machine learning is good for huge numbers of logs)

The goal of manually examining a log is to find clues to bad system behavior.

The methods used to achieve that will vary according to the data encountered, and what you are looking for.

This point cannot be overemphasized:  You must know how to leverage OS commands used to manipulate data so you can filter out the chaff.

When looking at log files (of any type) keep these things in mind

- what am I looking for?
  - an error message?
  - something that appears anomalous? 
  - missing info?  
    - something you would expect to see, but it is not there
- which logs should I look at?
  - database logs?
  - application logs?
  - system logs?

Following are examples of each.  

In these examples I am not really looking for anything in particular, but just showing different techniques for finding information.

Some of these examples may not work on servers other than Linux.

They can be modified without too much trouble.  For instance, the '--time-style=long-iso' argument for 'ls'

Just check the man page as needed.

Windows?  Sorry, I don't know how to do that, and so seldom have need (almost never), I haven't put any effort in to it.

# Locating files

To look at log files, you must first locate them.

## Oracle Alert Logs

tfactl can be used to find ASM and database alert logs.

use tfactl if available

```text

[root@ora192rac01 ~]# tfactl ls  alert
   
 
Output from host : ora192rac01
------------------------------
/u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log
/u01/app/19.0.0/grid_base/diag/asm/+asm/+ASM1/trace/alert_+ASM1.log
 
 
Output from host : ora192rac02
------------------------------
/u01/app/19.0.0/grid_base/diag/asm/+asm/+ASM2/trace/alert_+ASM2.log
/u01/app/oracle/diag/rdbms/cdb/cdb2/trace/alert_cdb2.log
```

Another method is to use sqlplus:

```sql
select d.value || '/alert_' || i.instance_name || '.log' alert_log
from v$diag_info d
, v$instance i
where d.name = 'Diag Trace'
/
 
ALERT_LOG
------------------------------------------------------------
/u01/app/oracle/diag/rdbms/cdb/cdb2/trace/alert_cdb2.log
```

If working on RAC, you may want to see the CRS log.

```text
TFA does not tell us where the CRS alert log is, but we can find the location.

   [root@ora192rac01 AHF-20.2.0]# tfactl print directories | grep -B1 -A3 '\[CRS\]'| grep -3 trace
   | Collection policy : Exclusions     |                                                  |            |          |
   +------------------------------------+--------------------------------------------------+------------+----------+
   | /u01/app/19.0.0/grid_base/crsdata/ | [CRS]                                            | public     | root     |
   | ora192rac01/trace                  |                                                  |            |          |
   | Collection policy : Exclusions     |                                                  |            |          |
   +------------------------------------+--------------------------------------------------+------------+----------+
   --
   --
   | Collection policy : No Exclusions  |                                                  |            |          |
   +------------------------------------+--------------------------------------------------+------------+----------+
   | /u01/app/19.0.0/grid_base/diag/crs | [CRS]                                            | public     | root     |
   | /ora192rac01/crs/trace             |                                                  |            |          |
   | Collection policy : Exclusions     |                                                  |            |          |
   +------------------------------------+--------------------------------------------------+------------+----------+

   [root@ora192rac01 AHF-20.2.0]# ls -l /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/alert.log
   -rw-rw---- 1 grid oinstall 669187 Jul 22 17:56 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/alert.log
```

If ORACLE_BASE is set:

```text
   [root@ora192rac01 AHF-20.2.0]# ls -l $ORACLE_BASE/diag/crs/$(hostname -s)/crs/trace/alert.log
   -rw-rw---- 1 grid oinstall 669187 Jul 22 17:56 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/alert.log
```

## Locating Recently Updated Files

Sometimes you may want to see the most recently updated files.

Here are some methods for that.  Probably there are other ways to accomplish this, but these are what I use.

### search current directory only

```text
ls -ltar | tail -20
```

### search directory and all subdirectories

The following command will find all files of type f (files, not directories, not links, etc) and pipe them to ls -ltar, sort by date, and show the most recent 20
  
`find . -type f -print0  | xargs -0 ls -ltar --time-style=long-iso |  sort -k6,7 | tail -20`
  
find args

```text
  -type f  find files
  -print0  use null as a field separator.  this is due to the possibility of spaces in the filename
```

xargs args

```text
  -0 fields terminated by null
```

ls args

```text
  -l long
  -t sort by modification time - probably not necessary here, though it does simplify the job somewhat for sort
    - tested it - using -t saves a lot of work
  -a all
  -r reverse the order, in this case, reverse time order
  --time-style=long-iso   so sort will work
```

sort args

```text
  -k6,7 sort on date and time
``` 

Create an alias:

`alias recent-files='find . -type f -print0  | xargs -0 ls -ltar --time-style=long-iso |  sort -k6,7 | tail -50'`
  
Or, create a function and load it.  I've never used this as a function, but it is a good idea for repeated use.

The following assumes Bash, and it may work in Ksh.

```shell
recent-files () {

   declare searchDir=$1; shift
      
   [[ -z $searchDir ]] && {
      echo "usage: recent-files dir2search <tail count>"
      return 1
   }

   declare tailCount=$1
   if [[ -z $tailCount ]]; then
      tailCount=50
   fi
   
   find "$searchDir" -type f -print0  | xargs -0 ls -ltar --time-style=long-iso |  sort -k6,7 | tail -$tailCount
   
}
```

This function can be pasted at the command line, or included in a file of functions.

```text

[root@ora192rac01 ~]# date; recent-files $ORACLE_BASE 10
Mon Jul 27 17:12:28 PDT 2020
-rw-rw---- 1 root   oinstall  2989211 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/ohasd_orarootagent_root.trm
-rw-rw---- 1 root   oinstall  3208549 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/crsd_orarootagent_root.trm
-rw-rw---- 1 root   oinstall  3324085 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/octssd.trm
-rw-rw---- 1 root   oinstall  3899401 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/ologgerd.trm
-rw-rw---- 1 root   oinstall  4001120 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/ohasd_cssdmonitor_root.trc
-rw-rw---- 1 root   oinstall  4922231 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/ohasd_cssdagent_root.trm
-rw-rw---- 1 root oinstall  5849760 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/ohasd.trc
-rw-rw---- 1 root   oinstall   752354 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/ohasd_cssdmonitor_root.trm
-rw-rw---- 1 root   oinstall   966086 2020-07-27 17:12 /u01/app/19.0.0/grid_base/diag/crs/ora192rac01/crs/trace/ohasd.trm
-rwx------ 1 root   root       7474457 2020-07-27 17:12 /u01/app/19.0.0/grid_base/oracle.ahf/data/ora192rac01/tfa/database/BERKELEY_JE_DB/00000032.jdb
```

# Examining Log Files

Let's look at a system log

This is /var/log/messages-20200705 from a test RAC system

```text
[root@ora192rac01 log]# wc messages-20200705
  21672  324555 3418073 messages-20200705
```

This log was chosen for no other reason that it is unchanging, and available.

21k lines is a lot of stuff to look at

Let's see the most recent events:

Fortunately (for explanation purposes) or unfortunately (for real life) a 'tail' of this log is gibberish

```text

[root@ora192rac01 log]# tail messages-20200705
 
Jul  5 03:13:05 ora192rac01 journal: orachk @cee: {"orachkExecTimestamp":"2020-07-05 03:13:05 PDT", "orachkID":"2FE891F7E8F6F03AE0530D98EB0A1F67", "
...
undo_tablespace='UNDOTBS2'\ncdb1.undo_tablespace='UNDOTBS1' " ,"orachkColumnValues":[  {"Name":"NodeName","value":"ora192rac01"},  {"Name":"InstanceName","value":"cdb1"}  ]  }
```

So lets remove orachk, as it is not likely we care about orachk messages in the log

OK, that is readable.  But boring.

```text
[root@ora192rac01 log]# grep -v 'ora192rac01 journal: orachk' messages-20200705| tail
Jul  5 03:12:55 ora192rac01 systemd: Started Session c5600 of user oracle.
Jul  5 03:12:56 ora192rac01 systemd: Removed slice User Slice of oracle.
Jul  5 03:12:57 ora192rac01 su: (to oracle) root on none
Jul  5 03:12:57 ora192rac01 systemd: Created slice User Slice of oracle.
Jul  5 03:12:57 ora192rac01 systemd: Started Session c5601 of user oracle.
Jul  5 03:12:58 ora192rac01 systemd: Removed slice User Slice of oracle.
Jul  5 03:13:01 ora192rac01 su: (to oracle) root on none
Jul  5 03:13:01 ora192rac01 systemd: Created slice User Slice of oracle.
Jul  5 03:13:01 ora192rac01 systemd: Started Session c5602 of user oracle.
Jul  5 03:13:02 ora192rac01 systemd: Removed slice User Slice of oracle.
```

Time to filter out more stuff.

At this time it seems a good idea to script this, as the command line will get unwieldy otherwise

Two files were created:

```text
[root@ora192rac01 pythian]# ls -l
total 8
lrwxrwxrwx 1 root root 13 Jul 24 09:18 lf.sh -> log-filter.sh
-rw-r--r-- 1 root root 28 Jul 24 09:19 log-filter.rules
-rw-r--r-- 1 root root 22 Jul 24 09:18 log-filter.sh
```

log-filter.sh is the driver
log-filter.rules are grep rules, used to filter out chaff we don't want to see

A quick look shows more things we don't care about:

Current contents of log-filter.rules

```text
ora192rac01 journal: orachk
ora192rac01 su:
ora192rac01 systemd: Started Session
ora192rac01 systemd: Removed slice User Slice
```

The contents are becoming more manageable:

```text
[root@ora192rac01 pythian]# ./lf.sh|wc
  6285   64524  448354
```

I found more output I don't care about.

Current contents of log-filter.rules:

```text
ora192rac01 journal: orachk
ora192rac01 su:
ora192rac01 systemd: Started Session
ora192rac01 systemd: Removed slice User Slice
ora192rac01 systemd-logind:
ora192rac01 systemd: Created slice User
```

Here is what is left after removing all the chaff, or at least, what we are considering chaff for this test:

```text
[root@ora192rac01 pythian]# ./lf.sh
Jun 28 08:07:45 ora192rac01 systemd: Starting Cleanup of Temporary Directories...
Jun 28 08:07:45 ora192rac01 systemd: Started Cleanup of Temporary Directories.
Jun 29 00:00:00 ora192rac01 systemd: Starting update of the root trust anchor for DNSSEC validation in unbound...
Jun 29 00:00:00 ora192rac01 systemd: Started update of the root trust anchor for DNSSEC validation in unbound.
Jun 29 08:07:45 ora192rac01 systemd: Starting Cleanup of Temporary Directories...
Jun 29 08:07:45 ora192rac01 systemd: Started Cleanup of Temporary Directories.
Jun 29 18:34:16 ora192rac01 auditd[1245]: Audit daemon rotating log files
Jun 30 00:00:00 ora192rac01 systemd: Starting update of the root trust anchor for DNSSEC validation in unbound...
Jun 30 00:00:00 ora192rac01 systemd: Started update of the root trust anchor for DNSSEC validation in unbound.
Jun 30 08:07:46 ora192rac01 systemd: Starting Cleanup of Temporary Directories...
Jun 30 08:07:46 ora192rac01 systemd: Started Cleanup of Temporary Directories.
Jun 30 19:28:15 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]
Jul  1 00:00:00 ora192rac01 systemd: Starting update of the root trust anchor for DNSSEC validation in unbound...
Jul  1 00:00:00 ora192rac01 systemd: Started update of the root trust anchor for DNSSEC validation in unbound.
Jul  1 08:07:46 ora192rac01 systemd: Starting Cleanup of Temporary Directories...
Jul  1 08:07:46 ora192rac01 systemd: Started Cleanup of Temporary Directories.
Jul  2 00:00:00 ora192rac01 systemd: Starting update of the root trust anchor for DNSSEC validation in unbound...
Jul  2 00:00:00 ora192rac01 systemd: Started update of the root trust anchor for DNSSEC validation in unbound.
Jul  2 08:07:47 ora192rac01 systemd: Starting Cleanup of Temporary Directories...
Jul  2 08:07:47 ora192rac01 systemd: Started Cleanup of Temporary Directories.
Jul  2 16:45:16 ora192rac01 auditd[1245]: Audit daemon rotating log files
Jul  3 00:00:00 ora192rac01 systemd: Starting update of the root trust anchor for DNSSEC validation in unbound...
Jul  3 00:00:00 ora192rac01 systemd: Started update of the root trust anchor for DNSSEC validation in unbound.
Jul  3 08:07:47 ora192rac01 systemd: Starting Cleanup of Temporary Directories...
Jul  3 08:07:47 ora192rac01 systemd: Started Cleanup of Temporary Directories.
Jul  4 00:00:00 ora192rac01 systemd: Starting update of the root trust anchor for DNSSEC validation in unbound...
Jul  4 00:00:00 ora192rac01 systemd: Started update of the root trust anchor for DNSSEC validation in unbound.
Jul  4 08:07:48 ora192rac01 systemd: Starting Cleanup of Temporary Directories...
Jul  4 08:07:48 ora192rac01 systemd: Started Cleanup of Temporary Directories.
Jul  5 00:00:00 ora192rac01 systemd: Starting update of the root trust anchor for DNSSEC validation in unbound...
Jul  5 00:00:00 ora192rac01 systemd: Started update of the root trust anchor for DNSSEC validation in unbound.
```

Warning:  Be careful to not include any blank lines in the rules file.

There is really nothing of interest in this log.

We can easily examine all of the log files.

But first, some more rules are added to the file log-filter.rules:

```text
ora192rac01 journal: orachk
ora192rac01 su:
ora192rac01 systemd: Started Session
ora192rac01 systemd: Removed slice User Slice
ora192rac01 systemd-logind:
ora192rac01 systemd: Created slice User
ora192rac01 systemd: Starting Cleanup
ora192rac01 systemd: Started Cleanup
ora192rac01 systemd: Starting update
ora192rac01 systemd: Started update
auditd\[.+\]: Audit daemon rotating log files
```

Now a simple script 'scan-all-logfiles.sh', used to look at all the /var/log/messages files

```shell

#!/usr/bin/env bash

for logfile in /var/log/messages*
do
   echo
   echo "################  $logfile #######################"
   echo
   ./log-filter.sh log-filter.rules $logfile
done
```

Example Output:

```text

[root@ora192rac01 pythian]# ./scan-all-logfiles.sh

################  /var/log/messages #######################

Jul 26 03:57:23 ora192rac01 kernel: CIFS VFS: Server stillnas has not responded in 120 seconds. Reconnecting...
Jul 26 03:57:24 ora192rac01 kernel: CIFS VFS: Free previous auth_key.response = ffff9cf4b6b670c0
Jul 27 06:48:28 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]
...
Jul 27 13:12:40 ora192rac01 dbus[1294]: [system] Activating service name='org.freedesktop.problems' (using servicehelper)
Jul 27 13:12:40 ora192rac01 dbus[1294]: [system] Successfully activated service 'org.freedesktop.problems'

################  /var/log/messages-20200705 #######################

Jun 30 19:28:15 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]

################  /var/log/messages-20200712 #######################

Jul  5 03:14:01 ora192rac01 rsyslogd: [origin software="rsyslogd" swVersion="8.24.0-38.el7" x-pid="1787" x-info="http://www.rsyslog.com"] rsyslogd was HUPed
Jul  6 08:43:45 ora192rac01 dbus[1294]: [system] Activating service name='org.freedesktop.problems' (using servicehelper)
Jul  6 08:43:45 ora192rac01 dbus[1294]: [system] Successfully activated service 'org.freedesktop.problems'
Jul  6 13:01:01 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]

################  /var/log/messages-20200719 #######################

Jul 12 03:34:01 ora192rac01 rsyslogd: [origin software="rsyslogd" swVersion="8.24.0-38.el7" x-pid="1787" x-info="http://www.rsyslog.com"] rsyslogd was HUPed
Jul 12 06:58:53 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]
Jul 13 09:54:56 ora192rac01 dbus[1294]: [system] Activating service name='org.freedesktop.problems' (using servicehelper)
Jul 13 09:54:56 ora192rac01 dbus[1294]: [system] Successfully activated service 'org.freedesktop.problems'
...
Jul 13 13:24:56 ora192rac01 kernel: FS-Cache: Netfs 'cifs' registered for caching
Jul 13 13:24:56 ora192rac01 kernel: Key type cifs.spnego registered
Jul 13 13:24:56 ora192rac01 kernel: Key type cifs.idmap registered
Jul 13 13:24:56 ora192rac01 kernel: No dialect specified on mount. Default has changed to a more secure dialect, SMB2.1 or later (e.g. SMB3), from CIFS (SMB1). To use the less secure SMB1 dialect to access old servers which do not support SMB3 (or SMB2.1) specify vers=1.0 on mount.
Jul 13 13:24:56 ora192rac01 kernel: CIFS VFS: ioctl error in smb2_get_dfs_refer rc=-2
Jul 13 13:24:59 ora192rac01 kernel: No dialect specified on mount. Default has changed to a more secure dialect, SMB2.1 or later (e.g. SMB3), from CIFS (SMB1). To use the less secure SMB1 dialect to access old servers which do not support SMB3 (or SMB2.1) specify vers=1.0 on mount.
Jul 13 13:24:59 ora192rac01 kernel: CIFS VFS: ioctl error in smb2_get_dfs_refer rc=-2
Jul 13 13:27:22 ora192rac01 yum[18402]: Installed: bison-3.0.4-2.el7.x86_64
Jul 13 13:28:13 ora192rac01 yum[19914]: Installed: flex-2.5.37-6.el7.x86_64
Jul 13 13:33:40 ora192rac01 dbus[1294]: [system] Activating service name='org.freedesktop.problems' (using servicehelper)
Jul 13 13:33:40 ora192rac01 dbus[1294]: [system] Successfully activated service 'org.freedesktop.problems'
Jul 14 11:37:10 ora192rac01 kernel: CIFS VFS: Server stillnas has not responded in 120 seconds. Reconnecting...
...
Jul 17 12:44:43 ora192rac01 dbus[1294]: [system] Successfully activated service 'org.freedesktop.problems'
Jul 17 12:45:16 ora192rac01 journal: Oracle Clusterware: 2020-07-17 12:45:16.196#012[(3608)]CRS-8504:Oracle Clusterware OCTSSD process with operating system process ID 3608 is exiting
Jul 17 12:45:48 ora192rac01 journal: Oracle Clusterware: 2020-07-17 12:45:48.486#012[(18733)]CRS-8500:Oracle Clusterware OSYSMOND process is starting with operating system process ID 18733
Jul 17 12:46:36 ora192rac01 journal: Oracle Clusterware: 2020-07-17 12:46:36.091#012[(19457)]CRS-8500:Oracle Clusterware OCTSSD process is starting with operating system process ID 19457
Jul 17 16:50:01 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]

################  /var/log/messages-20200726 #######################

Jul 19 12:48:24 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]
Jul 21 12:47:54 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]
Jul 21 22:47:07 ora192rac01 kernel: CIFS VFS: Server stillnas has not responded in 120 seconds. Reconnecting...
...
Jul 25 08:59:00 ora192rac01 rsyslogd: imjournal: journal reloaded... [v8.24.0-38.el7 try http://www.rsyslog.com/e/0 ]
Jul 25 15:21:41 ora192rac01 kernel: CIFS VFS: Server stillnas has not responded in 120 seconds. Reconnecting...
Jul 25 15:21:41 ora192rac01 kernel: CIFS VFS: Free previous auth_key.response = ffff9cf3f55cb9c0
Jul 26 03:07:01 ora192rac01 rsyslogd: [origin software="rsyslogd" swVersion="8.24.0-38.el7" x-pid="1787" x-info="http://www.rsyslog.com"] rsyslogd was HUPed
```

The `/var/log/messages` files contain 10k lines.

There are now approximately 100 lines to consider.

What about other log files?

Let's use the same technique to examine an Oracle alert log.

Currently the bash script looks like this:

```shell
#!/usr/bin/env bash
   
declare -r msgFile=/var/log/messages-20200705
   
declare -r rulesFile=/root/pythian/log-filter.rules
   
grep -v -f $rulesFile $msgFile
```

Now it is modified to accept a filename:

```shell
#!/usr/bin/env bash
 
declare -r msgFile=$1
 
[[ -z $msgFile ]] && { echo $0 \<filename\>; exit 1; }
[[ -r $msgFile ]] || { echo cannot read $msgFile; exit 2; }
 
declare -r rulesFile=/root/pythian/log-filter.rules
 
grep -v -f $rulesFile $msgFile
```

But, we probably want different rules for an alert log than for a system log.

```shell
#!/usr/bin/env bash

declare -r rulesFile=$1
declare -r msgFile=$2
   
[[ -z $rulesFile ]] && { echo $0 \<filename\>; exit 1; }
[[ -r $rulesfile ]] || { echo cannot read $rulesfile; exit 2; }
 
[[ -z $msgFile ]] && { echo $0 \<filename\>; exit 3; }
[[ -r $msgFile ]] || { echo cannot read $msgFile; exit 4; }
   
grep -v -f $rulesFile $msgFile
```

Currently the ora-alert.rules files is empty and will have no effect:

```text
[root@ora192rac01 pythian]# ls -l ora-alert.rules
-rw-r--r-- 1 root root 0 Jul 24 10:34 ora-alert.rules
```

Hmm, must be a problem in the script:

```text
[root@ora192rac01 pythian]# ./lf.sh ora-alert.rules /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log
cannot read
[root@ora192rac01 pythian]# echo $?
2
```

Notice the exit code was 2? Look for `exit 2` in the script.

A variable name was spelled incorrectly.

One way to deal with typos like that is via 'set -u'

```shell
#!/usr/bin/env bash

set +u

declare -r rulesFile=$1
declare -r msgFile=$2

# throw an error if an undefined variable is referenced
set -u
...
```

Now run the script again:

```text
[root@ora192rac01 pythian]# ./lf.sh ora-alert.rules /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log
./lf.sh: line 9: rulesfile: unbound variable
```

Line 9 has reference a variable that has not previously been assigned.

Now, again, with typos fixed:

```shell
#!/usr/bin/env bash

set +u

declare -r rulesFile=$1
declare -r msgFile=$2

# throw an error if an undefined variable is referenced
set -u


[[ -z $rulesFile ]] && { echo $0 \<filename\>; exit 1; }
[[ -r $rulesFile ]] || { echo cannot read $rulesFile; exit 2; }

[[ -z $msgFile ]] && { echo $0 \<filename\>; exit 3; }
[[ -r $msgFile ]] || { echo cannot read $msgFile; exit 4; }
 
grep -v -f $rulesFile $msgFile
```

We can see that all lines are making it through the filter script, as the rules file is empty.

```text
[root@ora192rac01 pythian]# ./lf.sh ora-alert.rules /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log | wc
  48295  287908 3002622
[root@ora192rac01 pythian]# wc /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log
  48295  287908 3002622 /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log
```

There are many different kinds of messages in an oracle alert log.

We are not really sure what we are looking for, so initially I am trying to filter out stuff I don't care about.

Here's one quick way to see the frequency of different messages.

Bash has a built in substr expansion:

example:

```text
[root@ora192rac01 pythian]# x='this is a test'
[root@ora192rac01 pythian]# echo ${x:0:8}
this is
```

Let's use that to collate the leading part of each line.

Note: the quotes around the "${line}" variable are required, as oracle logs have lines of '**********'

We start with 20 characters:

```shell
while read line
do
  echo "${line:0:20}"
done  < /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log | sort | uniq -c | sort -n
```


This results in 10k or so lines, a little too much.

The end of the output:

```text
    290 Closing Resource Man
    290 PDB1(3):Clearing Res
    290 PDB1(3):Closing Reso
    290 PDB2(4):Clearing Res
    290 PDB2(4):Closing Reso
    290 PDB3(5):Clearing Res
    290 PDB3(5):Closing Reso
    290 PDB4(6):Clearing Res
    290 PDB4(6):Closing Reso
    311 ORA-00028: your sess
    392 ORA-06512: at "SYS.P
    437 PGA memory used by t
    439 Setting Resource Man
    454 Starting background
    455 PDB4(6):Setting Reso
    456 PDB2(4):Setting Reso
    456 PDB3(5):Setting Reso
    463 PDB1(3):Setting Reso
    468 ********************
    490 TABLE SYS.WRP$_REPOR
    660 Incident details in:
    734 PDB1(3):Resize opera
    812 Thread 1 advanced to
    888 Current log# 1 seq#
    892 Current log# 2 seq#
   1969 ORA-06512: at "SYS.D
   2494 Errors in file /u01/
   2788 ORA-04036: PGA memor
```

There are many ORA-6512 and ORA-04036 errors.

These will be investigated later; for now we will filter them out.

This output is redirected to a rules file, leaving the lines we want to exclude:

```shell
[root@ora192rac01 pythian]# 
while read line;
do
   echo "${line:0:30}"
done  < /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log | sort | uniq -c | sort -n |  awk '{for(i=2;i<=NF;i++) printf $i" "; print ""}' | tail -100 > ora-alert.rules
```

The awk command is used to skip the count that appears at the beginning of each line.

It soon becomes clear this approach does not work well with Oracle RDBMS alert logs, simply because there are too many different things recorded in this file.

So, rather than try to exclude strings from the output, I will search for lines of the log that are of interest.

The problem with that approach is that we don't always know just what we are looking for.

A start has been made on a set of inclusive rules for Oracle Alert logs; more on that later.

As sometimes we want to use an inclusive search, and other times an exclusive search, provision is made to reserve the first 2 lines of the rules files for configuration

Here is an exclusive file, `log-filter.rules`.

When this file is used, all lines NOT matching the rules will be displayed.

```text
#INCLUDE/EXCLUDE:CONTEXT_LINES_BEFORE:CONTEXT_LINES_AFTER:CASE_SENSITIVE Y/N:GREP_COLOR [Y]es/[A]uto/[N]ever
INCLUDE:2:3:N:Y
ora192rac01 journal: orachk
ora192rac01 su:
ora192rac01 systemd: Started Session
ora192rac01 systemd: Removed slice User Slice
ora192rac01 systemd-logind:
ora192rac01 systemd: Created slice User
ora192rac01 systemd: Starting Cleanup
ora192rac01 systemd: Started Cleanup
ora192rac01 systemd: Starting update
ora192rac01 systemd: Started update
auditd\[.+\]: Audit daemon rotating log files
```


And an inclusive rules file, `ora-alert.rules`.

When this file is used, all lines that DO match the rules will be displayed

```text
#INCLUDE/EXCLUDE:CONTEXT_LINES_BEFORE:CONTEXT_LINES_AFTER:CASE_SENSITIVE Y/N:GREP_COLOR [Y]es/[A]uto/[N]ever
INCLUDE:2:3:N:Y
Errors in file
ORA-[[:digit:]]{1,}
Starting ORACLE instance
shutdown
WARNING:
ERROR
Set master node info
alter system
alter database
deadlock
```

Additionally, when inclusive rules are used, the portion of the line that matched the rule will be highlighted.

The output from this may well be enough to spot issues, without the need to scroll through all 48,614 lines of the alert log.

This particular alert log has a _lot_ of errors in it, and so the output is still 22k lines.

Even so, that is better than 48k lines.

Another benefit, as that the most recent lines of interest may be seen via `tail -N`.

Here it is with `tail -20`

```text
[root@ora192rac01 pythian]# ./lf.sh ora-alert.rules /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/alert_cdb1.log  |  tail -20
ORA-06512: at "SYS.DBMS_SPACE", line 2791
2020-07-18T06:05:16.515828-07:00
PDB3(5):TABLE SYS.WRI$_OPTSTAT_HISTHEAD_HISTORY: ADDED INTERVAL PARTITION SYS_P4901 (44029) VALUES LESS THAN (TO_DATE(' 2020-07-19 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN'))
PDB3(5):TABLE SYS.WRI$_OPTSTAT_HISTGRM_HISTORY: ADDED INTERVAL PARTITION SYS_P4904 (44029) VALUES LESS THAN (TO_DATE(' 2020-07-19 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN'))
--
ARC2 (PID:31564): Archived Log entry 1486 added for T-1.S-822 ID 0x7f666770 LAD:1
2020-07-19T14:10:26.115206-07:00
PDB4(6):ORA-00060: deadlock resolved; details in file /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/cdb1_j003_22639.trc
2020-07-19T14:10:26.971112-07:00
PDB4(6):Errors in file /u01/app/oracle/diag/rdbms/cdb/cdb1/trace/cdb1_j003_22639.trc:
ORA-12012: error on auto execute of job "SYS"."ORA$AT_SA_SPC_SY_4262"
ORA-00060: deadlock detected while waiting for resource
ORA-06512: at "SYS.DBMS_SPACE", line 2785
ORA-06512: at "SYS.DBMS_HEAT_MAP_INTERNAL", line 716
ORA-06512: at "SYS.DBMS_HEAT_MAP_INTERNAL", line 1171
ORA-06512: at "SYS.DBMS_HEAT_MAP", line 228
ORA-06512: at "SYS.DBMS_SPACE", line 2791
2020-07-19T18:10:53.122363-07:00
Thread 1 advanced to log sequence 824 (LGWR switch)
  Current log# 2 seq# 824 mem# 0: +DATA/CDB/ONLINELOG/group_2.261.1020800783
```

## grep colors

The grep utility can display different parts of a match using highlighting.

The `log-filter.sh` script is using the `mt` syntax to highlight the matched portion of a line. (this does not work for `grep -v`)

You can learn more about colors in grep by searching for `GREP_COLORS` in `man grep`.

Currently the colors are hard-coded into the script, but that may change by the time you read this.

Following is an example of the highlighting.

![log-filter.sh ... | tail -20](log-filter-tail.png)

The available 8 bit colors can be seen by running `grep-colors.sh`.

![grep-colors.sh](grep-colors-8.png)

The 'mt' lines are the full values to assign to `GREP_COLORS` to set the colors.

The 256 colors may also be seen.  As the script shows the foreground and background colors together, there is quite a bit of output.

It is best piped through `more` or `less -r`

`./grep-colors.sh 256 | more`

![grep-colors.sh](grep-colors-256.png)

## always-exclude.rules

The alert log is now filtered with the rules in this file before processing with `ora-alert.rules`.

This currently removes `ALTER SYSTEM ARCHIVE LOG` and `ORA-06512`.

The ORA-06512 error is not useful in this context, as it is an ancillary error message

## crs-alert.rules

There are currently no rules in this file

## log-filter.rules

This is an EXCLUDE rules file, that is, the regular expresssions in this file will prevent  seeing these lines from the log file.

Currently there is just one rule in this file

## ora-alert.rules.

This is an INCLUDE rules file. This means that the only lines output from a log file must be matched by a regex in this file.

The `Show Matched Only` flag is set to `Y`, which will cause grep to use the `-o` flag.  Only the matching portions of lines will appear.

This allows for a bucket histogram of items found:

```text

$  ./log-filter.sh ora-alert.rules logs/server004/alert_dbp004-recent.log  | sort | uniq -c | sort -n
      1 ERROR
      1 Errors in file
      1 ORA-02395
      1 Starting ORACLE instance
      1 Warning:
      4 ORA-00000
      4 shutdown
      5 ORA-48180
      8 ALTER DATABASE
     10 Error
     47 --
     70 alter database
     91 ORA-2396
    528 ORA-3136
    528 TNS-12535
    528 WARNING:
   1061 error
   6671 Checkpoint not complete
```



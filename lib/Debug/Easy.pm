#############################################################################
#################         Easy Debugging Module        ######################
################# Copyright 2013 - 2017 Richard Kelsch ######################
#################          All Rights Reserved         ######################
#############################################################################
####### Licensing information available near the end of this file. ##########
#############################################################################

package Debug::Easy;

use strict;
use constant {
    TRUE  => 1,
    FALSE => 0
};

use DateTime;
use Term::ANSIColor;
use Log::Fast;
use Time::HiRes qw(time);
use File::Basename;

# "Data::Dumper::Simple" gives better output for debugging, but at a startup cost.
# It falls back to the default "Data::Dumper" if the "Simple" variant isn't available.
use Best qw(Data::Dumper::Simple Data::Dumper);

use Config;
use threads;

BEGIN {
    require Exporter;

    # set the version for version checking
    our $VERSION = '1.19';

    # Inherit from Exporter to export functions and variables
    our @ISA = qw(Exporter);

    # Functions and variables which are exported by default
    our @EXPORT = qw();

    # Functions and variables which can be optionally exported
    our @EXPORT_OK = qw(@Levels);
} ## end BEGIN

$Data::Dumper::Sortkeys = TRUE;
$Data::Dumper::Purity   = TRUE;

# This can be optionally exported for whatever
our @Levels = qw( ERR WARN NOTICE INFO VERBOSE DEBUG DEBUGMAX );

# For quick level checks to speed up execution
our %LevelLogic;
for (my $count = 0 ; $count < scalar(@Levels) ; $count++) {
    $LevelLogic{$Levels[$count]} = $count;
}

my %ANSILevel   = ();                     # Global debug level colorized messages hash.  It will be filled in later.
my $LOG         = Log::Fast->global();    # Let's snag the Log::Fast object.
my $MASTERSTART = time;                   # Script start timestamp.
my ($SCRIPTNAME, $SCRIPTPATH, $suffix) = fileparse($0);
my $PARENT      = $$;                     # Get the parent process ID
my $TIMEZONE    = DateTime::TimeZone->new(name => 'local');

=head1 NAME

Debug::Easy - A Handy Debugging Module With Colorized Output and Formatting

=head1 SYNOPSIS

 use Debug::Easy;

 my $debug = Debug::Easy->new( 'LogLevel' => 'DEBUG', 'Color' => 1 );

'LogLevel' is the maximum level to report, and ignore the rest.  The method names correspond to their loglevels, when outputting a specific message.  This identifies to the module what type of message it is.

The following is a list, in order of level, of the logging methods:

 ERR       = Error
 WARN      = Warning
 NOTICE    = Notice
 INFO      = Information
 VERBOSE   = Special version of INFO that does not output any
             Logging headings.  Very useful for verbose modes in your
             scripts.
 DEBUG     = Level 1 Debugging messages
 DEBUGMAX  = Level 2 Debugging messages (typically more terse)

The parameter is either a string or a reference to an array of strings to output as multiple lines.

Each string can contain newlines, which will also be split into a separate line and formatted accordingly.

 $debug->ERR(        ['Error message']);
 $debug->ERROR(      ['Error message']);
 $debug->WARN(       ['Warning message']);
 $debug->WARNING(    ['Warning message']);
 $debug->NOTICE(     ['Notice message']);
 $debug->INFO(       ['Information and VERBOSE mode message']);
 $debug->INFORMATION(['Information and VERBOSE mode message']);
 $debug->DEBUG(      ['Level 1 Debug message']);
 $debug->DEBUGMAX(   ['Level 2 (terse) Debug message']);

 my @messages = (
    'First Message',
    'Second Message',
    "Third Message First Line\nThird Message Second Line",
    \%hash_reference
 );

 $debug->INFO(\@messages);

=head1 DESCRIPTION

This module makes it easy to add debugging features to your code, Without having to re-invent the wheel.  It uses STDERR and ANSI color formatted text output, as well as indented and multiline text formatting, to make things easy to read.  NOTE:  It is generally defaulted to output in a format for viewing on wide terminals!

Benchmarking is automatic, to make it easy to spot bottlenecks in code.  It automatically stamps from where it was called, and makes debug coding so much easier, without having to include the location of the debugging location in your debug message.  This is all taken care of for you.

It also allows multiple output levels from errors only, to warnings, to notices, to verbose information, to full on debug output.  All of this fully controllable by the coder.

It is essentially a smart wrapper on top of Log::Fast to enhance it. ** See AUTHOR COMMENTS near the end of this document.

Generally all you need are the defaults and you are ready to go.

=head1 B<EXPORTABLE VARIABLES>

=head2 B<@Levels>

 A simple list of all the acceptable debug levels to pass as "LogLevel" in the {new} method.  Not normally needed for coding, more for reference.  Only exported if requested.

=cut

END {    # We spit out one last message before we die, the total execute time.
    my $bench = colored(['bright_cyan'], sprintf('%06s', sprintf('%.02f', (time - $MASTERSTART))));
    my $name = $SCRIPTNAME;
    $name .= ' [child]' if ($PARENT ne $$);
    $LOG->DEBUG(' %s%s %s', $bench, $ANSILevel{'DEBUG'}, colored(['black on_white'], "---- $name complete ----")) if (defined($ANSILevel{'DEBUG'}) && defined($LOG));
} ## end END

=head1 B<METHODS>

=head2 B<new>

* The parameter names are case insensitive as of Version 0.04.

=over 4

=item B<LogLevel> [level]

This adjusts the global log level of the Debug object.  It requires a string.

=back

=over 8

B<ERR> (default)

 This level shows only error messages and all other messages are not shown.

B<WARN>

 This level shows error and warning messages.  All other messages are not shown.

B<NOTICE>

 This level shows error, warning, and notice messages.  All other messages are not shown.

B<INFO>

 This level shows error, warning, notice, and information messages.  Only debug level messages are not shown.

B<VERBOSE>

 This level can be used as a way to do "Verbose" output for your scripts.  It ouputs INFO level messages without logging headers and on STDOUT instead of STDERR.

B<DEBUG>

 This level shows error, warning, notice, information, and level 1 debugging messages.  Level 2 Debug messages are not shown.

B<DEBUGMAX>

 This level shows all messages up to level 2 debugging messages.

 NOTE:  It has been asked "Why have two debugging levels?"  Well, I have had many times where I would like to see what a script is doing without it showing what I consider garbage overhead it may generate.  This is simply because the part of the code you are debugging you may not need such a high level of detail.  I use 'DEBUGMAX' to show me absolutely everything.  Such as Data::Dumper output.  Besides, anyone asking that question obviously hasn't dealt with complex data conversion scripts.

=back

=over 4

=item B<Color> [boolean] (Not case sensitive)

B<0>, B<Off>, or B<False> (Off)

  This turns off colored output.  Everything is plain text only.

B<1>, B<On>, or B<True> (On - Default)

  This turns on colored output.  This makes it easier to spot all of the different types of messages throughout a sea of debug output.  You can read the output with Less, and see color, by using it's switch "-r".

=back

=over 4

=item B<Prefix> [pattern]

This is global

A string that is parsed into the output prefix.

DEFAULT:  '%Date% %Time% %Benchmark% %Loglevel%[%Subroutine%][%Lastline%] '

 %Date%       = Date (Uses format of "DateStamp" below)
 %Time%       = Time (Uses format of "TimeStamp" below)
 %Benchmark%  = Benchmark - The time it took between the last benchmark display
                of this loglevel.  If in an INFO level message, it benchmarks
                the time until the next INFO level message.  The same rule is
                true for all loglevels.
 %Loglevel%   = Log Level
 %Lines%      = Line Numbers of all nested calls
 %Module%     = Module and subroutine of call (can be a lot of stuff!)
 %Subroutine% = Just the last subroutine
 %Lastline%   = Just the last line number
 %PID%        = Process ID
 %date%       = Just Date (typically used internally only, use %Date%)
 %time%       = Just time (typically used internally only, use %Time%)
 %Filename%   = Script Filename (parsed $0)
 %Fork%       = Running in parent or child?
     P = Parent
     C = Child
 %Thread%     = Running in Parent or Thread
     P   = Parent
     T## = Thread # = Thread ID

=item B<[loglevel]-Prefix> [pattern]

You can define a prefix for a specific log level.

 ERR-Prefix
 WARN-Prefix
 NOTICE-Prefix
 INFO-Prefix
 DEBUG-Prefix
 DEBUGMAX-Prefix

If one of these are not defined, then the global value is used.

=item B<TimeStamp> [pattern]

(See Log::Fast for specifics on these)

I suggest you just use Prefix above, but here it is anyway.

Make this an empty string to turn it off, otherwise:

=back

=over 8

B<%T>

 Formats the timestamp as HH:MM:SS.  This is the default for the timestamp.

B<%S>

 Formats the timestamp as seconds.milliseconds.  Normally not needed, as the benchmark is more helpful.

B<%T %S>

 Combines both of the above.  Normally this is just too much, but here if you really want it.

=back

=over 4

=item B<DateStamp> [pattern]

I suggest you just use Prefix above, but here it is anyway.

(See Log::Fast for specifics on these)

Make this an empty string to turn it off, otherwise:

=back

=over 8

B<%D>

 Formats the datestamp as YYYY-MM-DD.  It is the default, and the only option.

=back

=over 4

=item B<Type>

 Output type. Possible values are: 'fh' (output to any already open filehandle) and 'unix' (output to syslog using UNIX socket).

=back

=over 8

B<fh>

 When set to 'fh', you have to also set {FileHandle} to any open filehandle (like "\*STDERR", which is the default).

B<unix>

 When set to 'unix', you have to also set {FileHandle} to a path pointing to an existing unix socket (typically it's '/dev/log').

=back

=over 4

=item B<FileHandle>

 File handle to write log messages if {Type} set to 'fh' (which is the default).

 Syslog's UNIX socket path to write log messages if {Type} set to 'unix'.

=item B<ANSILevel>

 Contains a hash reference describing the various colored debug level labels

 The default definition (using Term::ANSIColor) is as follows:

=back

=over 8

  'ANSILevel' => {
     'ERR'      => colored(['white on_red'],        '[ ERROR ]'),
     'WARN'     => colored(['black on_yellow'],     '[WARNING]'),
     'NOTICE'   => colored(['yellow'],              '[NOTICE ]'),
     'INFO'     => colored(['black on_white'],      '[ INFO  ]'),
     'DEBUG'    => colored(['bold green'],          '[ DEBUG ]'),
     'DEBUGMAX' => colored(['bold black on_green'], '[DEBUGMX]'),
  }


=back

=cut

sub new {
    # This module uses the Log::Fast library heavily.  Many of the
    # Log::Fast variables and features can work here.  See the perldocs
    # for Log::Fast for specifics.
    my $class = shift;
    my ($filename, $dir, $suffix) = fileparse($0);
    my $self = {
        'LogLevel'           => 'ERR',                                   # Default is errors only
        'Type'               => 'fh',                                    # Default is a filehandle
        'Path'               => '/var/log',                              # Default path should type be unix
        'FileHandle'         => \*STDERR,                                # Default filehandle is STDERR
        'MasterStart'        => $MASTERSTART,                            # Pull in the script start timestamp
        'ANY_LastStamp'      => time,                                    # Initialize main benchmark
        'ERR_LastStamp'      => time,                                    # Initialize the ERR benchmark
        'WARN_LastStamp'     => time,                                    # Initialize the WARN benchmark
        'INFO_LastStamp'     => time,                                    # Initialize the INFO benchmark
        'NOTICE_LastStamp'   => time,                                    # Initialize the NOTICE benchmark
        'DEBUG_LastStamp'    => time,                                    # Initialize the DEBUG benchmark
        'DEBUGMAX_LastStamp' => time,                                    # Initialize the DEBUGMAX benchmark
        'LOG'                => $LOG,                                    # Pull in the global Log::Fast object.
        'Color'              => TRUE,                                    # Default to colorized output
        'DateStamp'          => colored(['yellow'], '%date%'),
        'TimeStamp'          => colored(['yellow'], '%time%'),
        'Padding'            => -20,                                     # Default padding is 20 spaces
        'Lines-Padding'      => -2,
        'Subroutine-Padding' => 0,
        'Line-Padding'       => 0,
        'Prefix'             => '%Date% %Time% %Benchmark% %Loglevel%[%Subroutine%][%Lastline%] ',
        'DEBUGMAX-Prefix'    => '%Date% %Time% %Benchmark% %Loglevel%[%Module%][%Lines%] ',
        'Filename'           => '[' . colored(['magenta'], $filename) . ']',
        'ANSILevel'          => {
            'ERR'      => colored(['white on_red'],        '[ ERROR ]'),
            'WARN'     => colored(['black on_yellow'],     '[WARNING]'),
            'NOTICE'   => colored(['yellow'],              '[NOTICE ]'),
            'INFO'     => colored(['black on_white'],      '[ INFO  ]'),
            'DEBUG'    => colored(['bold green'],          '[ DEBUG ]'),
            'DEBUGMAX' => colored(['bold black on_green'], '[DEBUGMX]'),
        },
        @_
    };
    # This pretty much makes all hash keys uppercase
    my @Keys = (keys %{$self});
    foreach my $Key (@Keys) {
        my $upper = uc($Key);
        if ($Key ne $upper) {
            $self->{$upper} = $self->{$Key};

            # This fixes a documentation error for past versions
            if ($upper eq 'LOGLEVEL') {
                $self->{$upper} = 'ERR' if ($self->{$upper} =~ /^ERROR$/i);
                $self->{$upper} = uc($self->{$upper});    # Make loglevels case insensitive
            }
            delete($self->{$Key});
        } elsif ($Key eq 'LOGLEVEL') {    # Make loglevels case insensitive
            $self->{$upper} = uc($self->{$upper});
        }
    } ## end foreach my $Key (@Keys)

    # This instructs the ANSIColor library to turn off coloring,
    # if the Color attribute is set to zero.
    $ENV{'ANSI_COLORS_DISABLED'} = TRUE if ($self->{'COLOR'} =~ /0|FALSE|OFF|NO/i);

    # If COLOR is FALSE, then clear color data from ANSILEVEL, as these were
    # defined before color was turned off.
    $self->{'ANSILEVEL'} = {
        'ERR'      => '[ ERROR ]',
        'WARN'     => '[WARNING]',
        'NOTICE'   => '[NOTICE ]',
        'INFO'     => '[ INFO  ]',
        'DEBUG'    => '[ DEBUG ]',
        'DEBUGMAX' => '[DEBUGMX]',
    } if ($self->{'COLOR'} =~ /0|FALSE|OFF|NO/i);
    %ANSILevel = %{$self->{'ANSILEVEL'}};

    foreach my $lvl (@Levels) {
        $self->{"$lvl-PREFIX"} = $self->{'PREFIX'} unless (exists($self->{"$lvl-PREFIX"}) && defined($self->{"$lvl-PREFIX"}));
    }

    # The Global loglevel is set here.
    if ($self->{'LOGLEVEL'} eq 'VERBOSE') {
        $self->{'LOG'}->level('INFO');
    } elsif ($self->{'LOGLEVEL'} eq 'DEBUGMAX') {
        $self->{'LOG'}->level('DEBUG');
    } else {
        $self->{'LOG'}->level($self->{'LOGLEVEL'});
    }

    $self->{'LOG'}->config(    # Configure Log::Fast
        {
            'type'   => $self->{'TYPE'},
            'path'   => $self->{'PATH'},
            'prefix' => '',
            'fh'     => $self->{'FILEHANDLE'}
        }
    );

    # Signal the script has started (and logger initialized)
    my $name = $SCRIPTNAME;
    $name .= ' [child]' if ($PARENT ne $$);
    $self->{'LOG'}->DEBUG('   %.02f%s %s', 0, $self->{'ANSILEVEL'}->{'DEBUG'}, colored(['black on_white'], "----- $name begin -----") . " (To View in 'less', use it's '-r' switch)" );
    bless($self, $class);
    return ($self);
} ## end sub new

=head2 debug

NOTE:  This is a legacy method for backwards compatibility.  Please use the direct methods instead.

The parameters must be passed in the order given

=over 4

=item B<LEVEL>

 The log level with which this message is to be triggered

=item B<MESSAGE(S)>

 A string or a reference to a list of strings to output line by line.

=back

=cut

sub debug {
    my $self  = shift;
    my $level = uc(shift);
    my $msgs  = shift;

    if ($level !~ /ERR.*|WARN.*|NOTICE|INFO.*|DEBUG/i) {    # Compatibility with older versions.
        $level = uc($msgs);                                 # It tosses the legacy __LINE__ argument
        $msgs  = shift;
    }
    $level =~ s/(OR|ING|RMATION)$//; # Strip off the excess

    # A much quicker bypass when the log level is below what is needed
    return if ($LevelLogic{$self->{'LOGLEVEL'}} < $LevelLogic{$level});

    my @messages;
    if (ref($msgs) eq 'SCALAR' || ref($msgs) eq '') {
        push(@messages, $msgs);
    } elsif (ref($msgs) eq 'ARRAY') {
        @messages = @{$msgs};
    } else {
        push(@messages,Dumper($msgs));
    } ## end else [ if (ref($msgs) eq 'SCALAR'...)]
    my ($sname, $cline, $nested, $subroutine, $thisBench, $thisBench2, $sline, $short) = ('', '', '', '', '', '', '', '');

    # Figure out the proper caller tree and line number ladder
    # But only if it's part of the prefix, else don't waste time.
    if ($self->{'PREFIX'} =~ /\%(Subroutine|Module|Lines|Lastline)\%/) {    # %P = Subroutine, %l = Line number(s)
        my $package = '';
        my $count   = 1;
        my $nest    = 0;
        while (my @array = caller($count)) {
            if ($array[3] !~ /Debug::Easy/) {
                $package = $array[0];
                my $subroutine = $array[3];
                $subroutine =~ s/^$package\:\://;
                $sname =~ s/$subroutine//;
                if ($sname eq '') {
                    $sname = ($subroutine ne '') ? $subroutine : $package;
                    $cline = $array[2];
                } else {
                    $sname = $subroutine . '::' . $sname;
                    $cline = $array[2] . '/' . $cline;
                }
                if ($count == 2) {
                    $short = $array[3];
                    $sline = $array[2];
                }
                $nest++;
            } ## end if ($array[3] !~ /Debug::Easy/)
            $count++;
        } ## end while (my @array = caller...)
        if ($package ne '') {
            $sname = $package . '::' . $sname;
            $nested = ' ' x $nest if ($nest);
        } else {
            my @array = caller(1);
            $cline = $array[2];
            if (!defined($cline) || $cline eq '') {
                @array = caller(0);
                $cline = $array[2];
            }
            $sname = 'main';
            $sline = $cline;
            $short = $sname;
        } ## end else [ if ($package ne '') ]
        $subroutine = $sname;
        $self->{'PADDING'}            = 0 - length($subroutine) if (length($subroutine) > abs($self->{'PADDING'}));
        $self->{'LINES-PADDING'}      = 0 - length($cline)      if (length($cline) > abs($self->{'LINES-PADDING'}));
        $self->{'SUBROUTINE-PADDING'} = 0 - length($short)      if (length($short) > abs($self->{'SUBROUTINE-PADDING'}));
        $self->{'LINE-PADDING'}       = 0 - length($sline)      if (length($sline) > abs($self->{'LINE-PADDING'}));
        $cline = sprintf('%' . $self->{'LINES-PADDING'} . 's', $cline);
        $subroutine = colored(['bold cyan'], sprintf('%' . $self->{'PADDING'} . 's', $subroutine));
        $sline = sprintf('%' . $self->{'LINE-PADDING'} . 's', $sline);
        $short = colored(['bold cyan'], sprintf('%' . $self->{'SUBROUTINE-PADDING'} . 's', $short));
    } ## end if ($self->{'PREFIX'} ...)

    # Figure out the benchmarks, but only if it is in the prefix
    if ($self->{'PREFIX'} =~ /\%Benchmark\%/) {
        # For multiline output, only output the bench data on the first line.  Use padded spaces for the rest.
        #        $thisBench  = sprintf('%7s', sprintf(' %.02f', time - $self->{$level . '_LASTSTAMP'}));
        $thisBench = sprintf('%7s', sprintf(' %.02f', time - $self->{'ANY_LASTSTAMP'}));
        $thisBench2 = ' ' x length($thisBench);
    } ## end if ($self->{'PREFIX'} ...)
    my $first = TRUE;    # Set the first line flag.
    foreach my $msg (@messages) {    # Loop through each line of output and format accordingly.
        if (ref($msg) ne '') {
            $msg = Dumper($msg);
        } ## end if (ref($msg) ne '')
        if ($msg =~ /\n/s) {         # If the line contains newlines, then it too must be split into multiple lines.
            my @message = split(/\n/, $msg);
            foreach my $line (@message) {    # Loop through the split lines and format accordingly.
                $self->_send_to_logger($level, $nested, $line, $first, $thisBench, $thisBench2, $subroutine, $cline, $sline, $short);
                $first = FALSE;              # Clear the first line flag.
            }
        } else {    # This line does not contain newlines.  Treat it as a single line.
            $self->_send_to_logger($level, $nested, $msg, $first, $thisBench, $thisBench2, $subroutine, $cline, $sline, $short);
        }
        $first = FALSE;    # Clear the first line flag.
    } ## end foreach my $msg (@messages)
    $self->{'ANY_LASTSTAMP'} = time;
    $self->{$level . '_LASTSTAMP'} = time;
} ## end sub debug

sub _send_to_logger {      # This actually simplifies the previous method ... seriously
    my $self       = shift;
    my $level      = shift;
    my $padding    = shift;
    my $msg        = shift;
    my $first      = shift;
    my $thisBench  = shift;
    my $thisBench2 = shift;
    my $subroutine = shift;
    my $cline      = shift;
    my $sline      = shift;
    my $shortsub   = shift;

    my $dt       = DateTime->now('time_zone' => $TIMEZONE);
    my $Date     = $dt->ymd();
    my $Time     = $dt->hms();
    my $prefix   = $self->{$level . '-PREFIX'} . '';    # A copy not a pointer
    my $forked   = ($PARENT ne $$) ? 'C' : 'P';
    my $threaded = 'PT-';
    if (exists($Config{'useithreads'}) && $Config{'useithreads'}) { # Do eval so non-threaded perl's don't whine
        eval(q(
            my $tid   = threads->tid();
            $threaded = ($tid > 0) ? sprintf('T%02d',$tid) : 'PT-';
        ));
    }

    $prefix =~ s/\%PID\%/$$/g;
    $prefix =~ s/\%Loglevel\%/$ANSILevel{$level}/g;
    $prefix =~ s/\%Lines\%/$cline/g;
    $prefix =~ s/\%Lastline\%/$sline/g;
    $prefix =~ s/\%Subroutine\%/$shortsub/g;
    $prefix =~ s/\%Date\%/$self->{'DATESTAMP'}/g;
    $prefix =~ s/\%Time\%/$self->{'TIMESTAMP'}/g;
    $prefix =~ s/\%date\%/$Date/g;
    $prefix =~ s/\%time\%/$Time/g;
    $prefix =~ s/\%Filename\%/$self->{'FILENAME'}/g;
    $prefix =~ s/\%Fork\%/$forked/g;
    $prefix =~ s/\%Thread\%/$threaded/g;
    $prefix =~ s/\%Module\%/$subroutine/g;

    if ($first) {
        $prefix =~ s/\%Benchmark\%/$thisBench/g;
    } else {
        $prefix =~ s/\%Benchmark\%/$thisBench2/g;
    }

    if ($level eq 'INFO' && $self->{'LOGLEVEL'} eq 'VERBOSE') {    # Trap verbose flag and temporarily drop the prefix.
        $self->{'LOG'}->INFO($msg);
    } elsif ($level eq 'DEBUGMAX') {                               # Special version of DEBUG.  Outputs as DEBUG in Log::Fast
        if ($self->{'LOGLEVEL'} eq 'DEBUGMAX') {
            $self->{'LOG'}->DEBUG($prefix . $padding . $msg);
        }
    } else {
        $self->{'LOG'}->$level($prefix . $padding . $msg);
    }
} ## end sub _send_to_logger

=head2 b<ERR> or B<ERROR>

Sends ERROR level debugging output to the log.  Errors are always shown.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub ERR {
    my $self = shift;
    $self->debug('ERR', @_);
}

sub ERROR {
    my $self = shift;
    $self->debug('ERR', @_);
}

=head2 B<WARN> or B<WARNING>

If the log level is WARN or above, then these warnings are logged.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub WARN {
    my $self = shift;
    $self->debug('WARN', @_);
}

sub WARNING {
    my $self = shift;
    $self->debug('WARN', @_);
}

=head2 B<NOTICE> or B<ATTENTION>

If the loglevel is NOTICE or above, then these notices are logged.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub NOTICE {
    my $self = shift;
    $self->debug('NOTICE', @_);
}

sub ATTENTION {
    my $self = shift;
    $self->debug('NOTICE'. @_);
}

=head2 B<INFO> or B<INFORMATION>

If the loglevel is INFO (or VERBOSE) or above, then these information messages are displayed.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub INFO {
    my $self = shift;
    $self->debug('INFO', @_);
}

sub INFORMATION {
    my $self = shift;
    $self->debug('INFO', @_);
}

=head2 B<DEBUG>

If the Loglevel is DEBUG or above, then basic debugging messages are logged.  DEBUG is intended for basic program flow messages for easy tracing.  Best not to place variable contents in these messages.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub DEBUG {
    my $self = shift;
    $self->debug('DEBUG', @_);
}

=head2 B<DEBUGMAX>

If the loglevel is DEBUGMAX, then all messages are shown, and terse debugging messages as well.  Typically DEBUGMAX is used for variable dumps and detailed data output for heavy tracing.  This is a very "noisy" log level.

=over 4

=item B<MESSAGE>

Either a single string or a reference to a list of strings

=back
=cut

sub DEBUGMAX {
    my $self = shift;
    $self->debug('DEBUGMAX', @_);
}

1;

=head1 B<CAVEATS>

Since it is possible to duplicate the object in a fork or thread, the output formatting may be mismatched between forks and threads due to the automatic padding adjustment of the subroutine name field.

Ways around this are to separately create a Debug::Easy object in each fork or thread, and have them log to separate files.

The "less" pager is the best for viewing log files generated by this module.  It's switch "-r" allows you to see them in all their colorful glory.

=head1 B<INSTALLATION>

To install this module, run the following commands:

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

OR you can use the old ExtUtils::MakeMaker method:

 perl Makefile.PL
 make
 make test
 make install

=head1 AUTHOR

Richard Kelsch <rich@rk-internet.com>

Copyright 2013-2016 Richard Kelsch, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 B<VERSION>

Version 1.17    (November 10, 2016)

=head1 B<BUGS>

Please report any bugs or feature requests to C<bug-easydebug at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=EasyDebug>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 B<SUPPORT>

You can find documentation for this module with the perldoc command.

C<perldoc Debug::Easy>


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Debug-Easy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Debug-Easy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Debug-Easy>

Not exactly a reliable and fair means of rating modules.  Modules are updated and improved over time, and what may have been a poor or mediocre review at version 0,04, may not remotely apply to current or later versions.  It applies ratings in an arbitrary manner with no ability for the author to add their own rebuttals or comments to the review, especially should the review be malicious or inapplicable.

More importantly, issues brought up in a mediocre review may have been addressed and improved in later versions, or completely changed to allieviate that issue.

So, check the reviews AND the version number when that review was written.

=item * Search CPAN

L<http://search.cpan.org/dist/Debug-Easy/>

=back

=head1 B<ACKNOWLEDGEMENTS>

The author of Log::Fast.  A very fine module, without which, this module would be much larger.

=head1 B<AUTHOR COMMENTS>

Earlier versions of this module (pre version 1.0), were difficult to code with, and not "Easy" as the name implied.  Version 1.x+ has addressed the issues brought forward by some users (and reviewers), and has made the module truely easy to use.

Version 2.0 promises to be even simpler, with fewer prerequisites on installation.  Specifically the requirement for "Log::Fast" will be removed, and this module will exclusively handle logging, as I believe it should.

I coded this module because it filled a gap when I was working for a major chip manufacturing company.  It gave the necessary output the other coders asked for, and fulfilled a need.  It has grown far beyond those days, and I use it every day in my coding work.

If you have any features you wish added, or functionality improved or changed, then I welcome them, and will very likely incorporate them sooner than you think.

=head1 B<LICENSE AND COPYRIGHT>

Copyright 2013 Richard Kelsch.

This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

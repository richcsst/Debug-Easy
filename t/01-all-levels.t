#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Term::ANSIColor;
use Test::More tests => 115;    # 115

BEGIN {
    use_ok('Debug::Easy') || print "Bail out! Can't load Debug::Easy!\n";
}

diag("\n\r" . colored(['yellow'], "\e[4m                                                                  "));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{888888888888                         88                          }) . colored(['yellow'], '◣'));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{     88                        ,d    ""                          }) . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{     88                        88                                }) . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{     88  ,adPPYba, ,adPPYba, MM88MMM 88 8b,dPPYba,   ,adPPYb,d8  }) . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{     88 a8P_____88 I8[    ""   88    88 88P'   `"8a a8"    `Y88  }) . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{     88 8PP"""""""  `"Y8ba,    88    88 88       88 8b       88  }) . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{     88 "8b,   ,aa aa    ]8I   88,   88 88       88 "8a,   ,d88  }) . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{     88  `"Ybbd8"' `"YbbdP"'   "Y888 88 88       88  `"YbbdP"Y8  }) . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '▏') . colored(['cyan on_black'], q{                                                     aa,    ,88  }) . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '▏') . ' Debug::Easy' . colored(['cyan on_black'], q{                                          "Y8bbdP"   }) . colored(['yellow'], '█'));
# diag("\r" . colored(['yellow'], '▏                                                                 ') . colored(['yellow'], '█'));
diag("\r" . colored(['yellow'], '◥' . '█' x 66));
diag("\r  \r");

my @LogLevel  = qw( ERR WARN NOTICE INFO DEBUG DEBUGMAX );
my @CodeLevel = ('[ ERROR ]', '[WARNING]', '[NOTICE ]', '[ INFO  ]', '[ DEBUG ]', '[-DEBUG-]');

# Legacy "debug" method is used for testing only.  It is not recommended you use "debug" in your code.

skip 'Perl version < 5.10 skipping tests', 114 if ($] < 5.010000);

my $stderr;

open(OUTPUT, '>', \$stderr);
foreach my $LEVEL (0 .. 5) {
    my $debug = Debug::Easy->new('LogLevel' => $LogLevel[$LEVEL], 'Color' => 1, 'FileHandle' => \*OUTPUT);
    isa_ok($debug, 'Debug::Easy');

    foreach my $count (0 .. 5) {
        diag("\r" . colored(['white'], 'LogLevel = ') . colored(['bright_white'], sprintf('%-8s', $LogLevel[$LEVEL])) . colored(['green'], ' | ') . colored(['white'], 'Message Level = ') . colored(['bright_white'], $LogLevel[$count]));
        $stderr = '';
        if ($count <= $LEVEL) {
            $debug->debug($LogLevel[$count], $LogLevel[$count] . ' Single Line Message Test');
            like($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Single Line Scalar Message Test');
            $stderr = '';
            $debug->debug($LogLevel[$count], $LogLevel[$count] . "Multi-Line Scalar\nMessage Test");
            like($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Multi-Line Scalar Message Test');
            $stderr = '';
            $debug->debug($LogLevel[$count], [$LogLevel[$count] . ' Multi-Line', 'Array', 'Message Test']);
            like($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Multi-Line Array Message Test');
        } else {
            $debug->debug($LogLevel[$count], $LogLevel[$count] . ' Single Line Message Test');
            unlike($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Single Line Scalar Message Test');
            $stderr = '';
            $debug->debug($LogLevel[$count], $LogLevel[$count] . "Multi-Line Scalar\nMessage Test");
            unlike($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Multi-Line Scalar Message Test');
            $stderr = '';
            $debug->debug($LogLevel[$count], [$LogLevel[$count] . ' Multi-Line', 'Array', 'Message Test']);
            unlike($stderr, qr/$CodeLevel[$count]/, $LogLevel[$count] . ' Multi-Line Array Message Test');
        } ## end else [ if ($count <= $LEVEL) ]
    } ## end foreach my $count (0 .. 5)
} ## end foreach my $LEVEL (0 .. 5)


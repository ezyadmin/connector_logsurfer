#!/usr/bin/perl

use Getopt::Std;
use Data::Dumper;
getopts("f:p:c:");
my $FILE = $opt_f if defined $opt_f;
my $postrotate = $opt_p if defined $opt_p;
my $create = $opt_c if defined $opt_c;
my $options = {
  'postrotate' => $postrotate,
  'create' => $create
};

if (!$FILE) {
  print "Please usage -f <logrotate_file> \n";
  print " -c '<mode> <user> <group>' \n";
} elsif (-e "/etc/logrotate.conf") {
  readConf('/etc/logrotate.conf', $options);
} else {
  print "Find not found /etc/logrotate.conf\n";
}

sub readConf {
  my $file = shift;
  my $options = shift;
  my $lines = '';
  open(my $fd, '<', $file) or die "$file: $!";
  my $isOnOpen = 0;
  my $code = '';
  while (<$fd>) {
    if ($isOnOpen eq 1) {
      if ($_ =~ /\}/gi) {
        $isOnOpen = 0;
        $code .= $_;
        $lines .= complieCode($code, $options);
      } else {
        $code .= $_;
      }
    } elsif ($_ =~/^#/gi) {
      $lines .= $_;
    } elsif ($_ =~ /^include\s+(.*)/g) {
      $lines .= $_;
      readInclude($1, $options);
    } elsif ($_ =~ /^$FILE .*\{/g) {
      $isOnOpen = 1;
      $code .= $_;
    } elsif ($_ =~ /.* $FILE .*\{/g) {
      $isOnOpen = 1;
      $code .= $_;
    } else {
      $lines .= $_;
    }
  }
  close($fd);
  open(my $fw, '>', $file) or die "$file: $!";
  print $fw $lines;
  close($fw);
}

sub readInclude {
  my $includeDir = shift;
  my $options = shift;
  my @globData = glob($includeDir . '/*');
  foreach my $loadFile (@globData) {
    readConf($loadFile, $options);
  }
}

sub complieCode {
  my $code = shift;
  my $options = shift;
  my @lines = split("\n", $code);
  my $newCode = '';
  my $isOnOpenPostrotate = 0;
  my @postrotateOptions = ();
  my $lastPostrotateLine = '';
  my $isUpdatePostrotate = 0;
  my $isUpdateCreate = 0;
  if ($options->{'postrotate'}) {
    @postrotateOptions = split(';', $options->{'postrotate'});
  }
  my $fline = '';
  foreach my $line (@lines) {
    if ($fline eq '' && $line =~ /^\s+\W/) {
      $fline = $line;
    }
    if ($options->{'postrotate'} && $line =~/^\s+postrotate$/gi) {
      $isOnOpenPostrotate = 1;
      $newCode .= $line . "\n";
    } elsif ($options->{'postrotate'} && $isOnOpenPostrotate eq 1 && $line =~/^\s+endscript$/i) {
      foreach my $opt (@postrotateOptions) {
        my $bufer = $lastPostrotateLine;
        $bufer =~ s/(\s+).*$/$1$opt/;
        $newCode .= $bufer . "\n";
      }
      $newCode .= $line . "\n";
      $isUpdatePostrotate = 1;
      $isOnOpenPostrotate = 0;
    } elsif ($isOnOpenPostrotate eq 1) {
      my $found = 0;
      my $buffer = $line;
      chomp($buffer);
      $buffer =~ s/^\s+|\s+$//g;
      foreach my $opt (@postrotateOptions) {

        if ($buffer eq $opt) {
          $found = 1;
        }
      }

      if ($found eq 0) {
        $newCode .= $line . "\n";
        $lastPostrotateLine = $line;
      }
    } elsif ($options->{'create'} && $line =~/^\s+create\s+/i) {
      $line =~ s/create.*/create $options->{'create'}/gi;
      $newCode .= $line . "\n";
      $isUpdateCreate = 1
    } elsif ($line =~ /\}/gi) {
      if ($options->{'create'} && $isUpdateCreate eq 0) {
        if ($fline eq '') {
          $fline = '    ';
        }
         my $bufer = '';
        my $text = 'create ' . $options->{'create'};
        $bufer = $fline;
        $bufer =~ s/(\s+).*/$1$text/;
        $newCode .= $bufer . "\n";
      }
      if ($options->{'postrotate'} && $isUpdatePostrotate eq 0) {
        if ($fline eq '') {
          $fline = '    ';
        }
        my $bufer = '';
        my $text = '';
        $bufer = $fline;
        $text = 'postrotate';
        $bufer =~ s/(\s+).*/$1$text/;
        $newCode .= $bufer . "\n";
        foreach my $opt (@postrotateOptions) {
          my $bufer = $fline;
          $bufer =~ s/(\s+).*$/$1    $opt/;
          $newCode .= $bufer . "\n";
        }
        $bufer = $fline;
        $text = 'endscript';
        $bufer =~ s/(\s+).*/$1$text/;
        $newCode .= $bufer . "\n";
        $newCode .= $line . "\n";
      } else {
        $newCode .= $line . "\n";
      }
    } else {
      $newCode .= $line . "\n";
    }
  }
  return $newCode
}

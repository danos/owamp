#!/usr/local/bin/perl -w

##
##      $Id$
##

# Read the file with binary time stamp records and print out one-way delays.
# Author: Anatoly Karp, Internet2 2002.

# usage: owdrive1.pl [datafile]

use strict;

print "opening $ARGV[0]\n";
open(FILE, "<$ARGV[0]") or die "Could not open file $ARGV[0]: $!";

# Read header.
my $magic;
read FILE, $magic, 4 or die "Failed to read the magic number: $!";
my $version;
read FILE, $version, 4 or die "Failed to read the versionr: $!";
my $hdr_size;
read FILE, $hdr_size, 4 or die "Failed to read the header size: $!";
$hdr_size = unpack "N", $hdr_size;
seek(FILE, $hdr_size, 0) or die "Could not seek: $!";

# Read records.
my $buf;
while (read FILE, $buf, 20) {
  my ($seq_no, $send_sec, $send_a, $send_b, $send_c,
      $recv_sec, $recv_a, $recv_b, $recv_c)
    = unpack "NNnCCNnCC", $buf;

  if (!(frac($recv_a, $recv_b)) && !$recv_sec) {
    print "seq_no = $seq_no     *LOST*\n";
    next;
  }

  my $delay = (rec2sec($recv_sec, $recv_a, $recv_b)
	       - rec2sec($send_sec, $send_a, $send_b)) * 1000;

  my $line = 
    sprintf "seq_no = %u     delay = %.3f ms    (%s, precision %.3f ms))\n",
    $seq_no, $delay, sync_set($send_c) && sync_set($recv_c) ?
      "sync" : "unsync", (byte2prec($send_c) + byte2prec($recv_c))*1000;
  print $line;
}

sub frac {
  my ($a, $b) = @_;
  my $val = pack "CnC", 0, $a, $b;
  return unpack "N", $val;
}

sub rec2sec {
  my ($sec, $a, $b) = @_;
  return $sec + frac($a, $b)/(1 << 24);
}

sub sync_set {
  return ($_[0] & 0x80)? 1 : 0;
}

sub byte2prec {
  my $bits = $_[0] & 0x3F;
  return 1.0/(2**($bits - 32));
}

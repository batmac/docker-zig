#! /usr/bin/env perl

use strict;
use warnings;
use JSON::PP;
use HTTP::Tiny;
use Data::Dumper;

my $response = HTTP::Tiny->new->get('https://ziglang.org/download/index.json');
#print Dumper($response);
die "Failed!\n" unless $response->{success};

my $manifest = decode_json($response->{content});

my $tagname ="master";

my $tag = $manifest->{$tagname};
my $version = $tag->{version};
my $date = $tag->{date};

print "version:$version date:$date\n";

my %arch = (
     "linux/amd64" => "x86_64-linux",
     "linux/arm64" => "aarch64-linux",
            );
my $arch = $ARGV[0];
if (defined($arch{$arch})) {
    $arch = $arch{$arch};
}
my $data = $tag->{"$arch"};
print Dumper($tag->{"$arch"});
my $tarball = (split'/', $data->{tarball})[-1];
$tarball =~ "^(.*).tar.xz";
my $dir = $1;
system "wget -N $data->{tarball} && tar xJf $tarball && rm -rf tag || true  && mv $dir tag";
exit $? >> 8;

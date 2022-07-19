#! /usr/bin/env perl

use strict;
use warnings;
use JSON::PP;
use HTTP::Tiny;
use Data::Dumper;
use YAML qw(Dump);

my $response = HTTP::Tiny->new->get('https://ziglang.org/download/index.json');
#print Dumper($response);
die "Failed!\n" unless $response->{success};

my $manifest = decode_json($response->{content});

my $tagname ="master";

my $tag = $manifest->{$tagname};
my $version = $tag->{version};
my $date = $tag->{date};

print "version:$version date:$date\n";

my $msg = "version:$version date:$date\n\n".Dump($tag);
my $data = $tag->{src};
print Dumper($tag->{src});
my $tarball = (split'/', $data->{tarball})[-1];
$tarball =~ "^(.*).tar.xz";
my $dir = $1;
system "wget -N $data->{tarball} && tar xJf $tarball && rm -rf src && mv $dir src && git add src && git commit -m '$msg' && git tag '$version' 2>&1";
exit $? >> 8;

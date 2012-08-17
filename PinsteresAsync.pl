#!/usr/bin/env perl
use strict;
use warnings;
use lib qw(/home/toshi/perl/lib);
use feature qw( say );
use Benchmark qw (timethese cmpthese);
use LWP::Simple;
use Web::Scraper;
use YAML;
use Pindata;

use Coro;
use Coro::AnyEvent;
use Coro::Handle;
use Coro::LWP;

my $url = 'http://pinterest.com/toshi0104/pins/?filter=likes';

my $pinlist = Pindata->new();
$pinlist->url($url);
my $res = $pinlist->get;
my @pinlist = @{$res->{permalink}};


STDOUT->autoflush(1);
my $result = timethese(10, {
		Blocking => 'get_by_blocking',
		NonBlocking => 'get_by_nonblocking',
});
cmpthese($result);
STDOUT->autoflush(0);

sub get_by_blocking {
#	use Pindata;
	say "@ BLOCKING @";
	my @content;
	foreach my $permalink (@pinlist) {
#		say "retriving $permalink";
		my $pindata = Pindata->new($permalink);
		my $res = $pindata->get;
		push (@content, $res);
#		say "complete $permalink";
	}
	return @content;
}

sub get_by_nonblocking {
#	use Pindata;
	say "@ NON BLOCKING @";
	my @cvs;
	my @content;
	foreach my $permalink (@pinlist) {
		my $cv = AnyEvent->condvar;
		push (@cvs, $cv);
		async {
#			say "retrieving $permalink";
			my $pindata = Pindata->new($permalink);
			my $res = $pindata->get;
			push (@content, $res);
#			say "complete $permalink";
			$cv->send;
		};
	}
	foreach my $cv (@cvs) {
		$cv->recv;
	}
	return @content;
}





use strict;
use warnings;

use Test::More tests => 6;

use HTTP::Response;
use JSON::XS;
use Test::LWP::UserAgent;

BEGIN { use_ok( 'Sentry::Raven' ); }

my $ua = Test::LWP::UserAgent->new();
$ua->map_response(qr//, HTTP::Response->new('200'));

local $ENV{SENTRY_DSN} = 'http://key:secret@somewhere.com:9000/foo/123';
my $raven = Sentry::Raven->new(ua_obj => $ua);

my $event_id = $raven->capture_message('HELO');
my $request = $ua->last_http_request_sent();


is(
    $ua->last_http_request_sent()->method(),
    'POST',
);

is(
    $event_id,
    JSON::XS->new()->decode($request->content())->{event_id},
);

like(
    $request->header('x-sentry-auth'),
    qr{^Sentry sentry_client=raven-perl/[\d.]+, sentry_key=key, sentry_secret=secret, sentry_timestamp=\d+, sentry_version=\d+$},
);

is($ua->last_useragent()->timeout(), 5);

$raven = Sentry::Raven->new(ua_obj => $ua, timeout => 10);
$raven->capture_message('HELO');

is($ua->last_useragent()->timeout(), 10);

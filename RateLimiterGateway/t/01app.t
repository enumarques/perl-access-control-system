#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'RateLimiterGateway';

ok( request('/')->code == 401, 'Bad request from unauthenticated request' );




done_testing();

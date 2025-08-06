#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'RateLimiterGateway';

# ok( request('/')->is_success, 'Request should succeed' );

# Given
# An incoming request
# When
# The request has no authentication information
# Then
# The system responds with a 400 code
ok( request('')->code() == 400, 'Request is missing authentication information' );



done_testing();

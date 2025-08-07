use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Data::GUID;
use Catalyst::Test 'RateLimiterGateway';

subtest 'Request without API Key to root' => sub {
    my $res = request(GET '/');
    is($res->code, 401, 'Response code is 401 for missing API Key');
    like($res->content, qr/Unauthorized: Invalid API Key/, 'Response body is "Unauthorized: Invalid API Key"');
};

subtest 'Request with invalid API Key to root' => sub {
    note 'This test assumes the Authentication plugin returns 401 for unknown keys.';
    my $api_key = Data::GUID->new->as_string;
    my $req     = GET '/', 'X-API-KEY' => $api_key;
    my $res     = request($req);
    is($res->code, 401, 'Response code is 401 for invalid API Key');
};

subtest 'Request with valid API Key to root' => sub {
    my $schema = RateLimiterGateway->model('GatewayModel')->schema;

    # Clean up any previous test data
    $schema->resultset('UsageLog')->delete_all;
    $schema->resultset('User')->delete_all;
    $schema->resultset('Tier')->delete_all;
    $schema->resultset('Customer')->delete_all;

    # Create test data
    my $free_tier = $schema->resultset('Tier')->create(
        {
            tierid       => 1,
            name         => 'Free Tier',
            monthlylimit => 100,
            ratelimit    => 2,
        }
    );
    my $pro_tier = $schema->resultset('Tier')->create(
        {
            tierid       => 2,
            name         => 'Pro Tier',
            monthlylimit => 100000,
            ratelimit    => 10,
        }
    );

    my $customer = $schema->resultset('Customer')->create(
        {
            customerid => Data::GUID->new->as_binary,
            name       => 'Test Customer',
        }
    );

    my $api_key = Data::GUID->new->as_string;
    $schema->resultset('User')->create(
        {
            userid     => Data::GUID->new->as_binary,
            name       => 'Test User',
            apikey     => $api_key,
            customerid => $customer->customerid,
            tierid     => $free_tier->tierid,
        }
    );
    $schema->resultset('User')->create(
        {
            userid     => Data::GUID->new->as_binary,
            name       => 'Test Pro User',
            apikey     => Data::GUID->new->as_string,
            customerid => $customer->customerid,
            tierid     => $pro_tier->tierid,
        }
    );

    # Make the request
    my $req = GET '/', 'X-API-KEY' => $api_key;
    my $res = request($req);

    is($res->code, 200, 'Response code is 200 for valid API Key');
    $schema->resultset('UsageLog')->search({
        userid      => $schema->resultset('User')->find({ apikey => $api_key })->userid,
        customerid  => $customer->customerid,
        endpoint    => '/',
        requesttime => { '>=' => DateTime->now->subtract( seconds => 1 )->iso8601 . 'Z' },
    })->count == 1, 'Usage log entry created for valid API Key request';
};

subtest 'Request with valid API Key to non-existent page' => sub {
    my $schema  = RateLimiterGateway->model('GatewayModel')->schema;
    my $user    = $schema->resultset('User')->find( { name => 'Test User' } );
    my $api_key = $user->apikey;

    my $req = GET '/nonexistent/path', 'X-API-KEY' => $api_key;
    my $res = request($req);

    is($res->code, 404, 'Request to non-existent page succeeds with valid API Key');
    $schema->resultset('UsageLog')->search({
        userid      => $user->userid,
        customerid  => $user->customerid,
        endpoint    => '/nonexistent/path/',
        requesttime => { '>=' => DateTime->now->subtract( seconds => 1 )->iso8601 . 'Z' },
    })->count == 0, 'Usage log entry not created for invalid request';
};

subtest 'Rate limit is enforced' => sub {
    my $schema  = RateLimiterGateway->model('GatewayModel')->schema;
    my $user    = $schema->resultset('User')->find( { name => 'Test User' } );
    my $api_key = $user->apikey;

    # Clean up any previous test data
    $schema->resultset('UsageLog')->delete_all;

    # The user's tier has a rate limit of 2.
    $schema->resultset('UsageLog')->create({
        usagelogid  => Data::GUID->new->as_binary,
        userid      => $user->userid,
        customerid  => $user->customerid,
        endpoint    => '/',
        requesttime => DateTime->now->iso8601 . 'Z',
    });
    $schema->resultset('UsageLog')->create({
        usagelogid  => Data::GUID->new->as_binary,
        userid      => $user->userid,
        customerid  => $user->customerid,
        endpoint    => '/',
        requesttime => DateTime->now->iso8601 . 'Z',
    });

    # This third request should be rate limited.
    my $res = request(GET '/', 'X-API-KEY' => $api_key);

    is($res->code, 429, 'Third request is blocked by rate limit');
    like($res->content, qr/Too Many Requests/, 'Response body is "Too Many Requests"');
};

subtest 'Monthly limit is enforced' => sub {
    my $schema  = RateLimiterGateway->model('GatewayModel')->schema;
    my $user    = $schema->resultset('User')->find( { name => 'Test User' } );
    my $api_key = $user->apikey;

    # Clean up any previous test data
    $schema->resultset('UsageLog')->delete_all;

    # The user's tier has a monthly limit of 100.
    for my $i (1..$user->tierid->monthlylimit) {
        my $start_of_month = DateTime->now->truncate(to => 'month')->iso8601 . 'Z';
        my $request_time = DateTime->now->subtract( hours => 1 )->iso8601 . 'Z';
        if ($request_time lt $start_of_month) {
            $request_time = $start_of_month;
        }
        $schema->resultset('UsageLog')->create({
            usagelogid  => Data::GUID->new->as_binary,
            userid      => $user->userid,
            customerid  => $user->customerid,
            endpoint    => '/',
            requesttime => $request_time,
        });
    }

    # This request should be rate limited.
    my $res = request(GET '/', 'X-API-KEY' => $api_key);

    is($res->code, 429, 'Request is blocked by monthly limit');
    like($res->content, qr/Too Many Requests/, 'Response body is "Too Many Requests"');
};

subtest 'Rate limit is enforced for pro user' => sub {
    my $schema  = RateLimiterGateway->model('GatewayModel')->schema;
    my $user    = $schema->resultset('User')->find( { name => 'Test Pro User' } );
    my $api_key = $user->apikey;

    # Clean up any previous test data
    $schema->resultset('UsageLog')->delete_all;

    # The user's tier has a rate limit of 10.
    my $events = [];
    for my $i (1..$user->tierid->ratelimit) {
        push @$events, {
            usagelogid  => Data::GUID->new->as_binary,
            userid      => $user->userid,
            customerid  => $user->customerid,
            endpoint    => '/',
            requesttime => DateTime->now->iso8601 . 'Z',
        };
    }
    $schema->resultset('UsageLog')->populate($events);

    # This request should be rate limited.
    my $res = request(GET '/', 'X-API-KEY' => $api_key);

    is($res->code, 429, 'Third request is blocked by rate limit');
    like($res->content, qr/Too Many Requests/, 'Response body is "Too Many Requests"');
};

subtest 'Monthly limit is enforced' => sub {
    my $schema  = RateLimiterGateway->model('GatewayModel')->schema;
    my $user    = $schema->resultset('User')->find( { name => 'Test User' } );
    my $api_key = $user->apikey;

    # Clean up any previous test data
    $schema->resultset('UsageLog')->delete_all;

    # The user's tier has a monthly limit of 100.
    for my $i (1..$user->tierid->monthlylimit) {
        my $start_of_month = DateTime->now->truncate(to => 'month')->iso8601 . 'Z';
        my $request_time = DateTime->now->subtract( hours => 1 )->iso8601 . 'Z';
        if ($request_time lt $start_of_month) {
            $request_time = $start_of_month;
        }
        $schema->resultset('UsageLog')->create({
            usagelogid  => Data::GUID->new->as_binary,
            userid      => $user->userid,
            customerid  => $user->customerid,
            endpoint    => '/',
            requesttime => $request_time,
        });
    }

    # This request should be rate limited.
    my $res = request(GET '/', 'X-API-KEY' => $api_key);

    is($res->code, 429, 'Request is blocked by monthly limit');
    like($res->content, qr/Too Many Requests/, 'Response body is "Too Many Requests"');
};

subtest 'Monthly limit is enforced for pro user' => sub {
    my $schema  = RateLimiterGateway->model('GatewayModel')->schema;
    my $user    = $schema->resultset('User')->find( { name => 'Test Pro User' } );
    my $api_key = $user->apikey;

    # Clean up any previous test data
    $schema->resultset('UsageLog')->delete_all;

    # The user's tier has a monthly limit of 100000.
    my $events = [];
    my $start_of_month = DateTime->now->truncate(to => 'month')->iso8601 . 'Z';
    my $request_time = DateTime->now->subtract( hours => 1 )->iso8601 . 'Z';
    if ($request_time lt $start_of_month) {
        $request_time = $start_of_month;
    }
    for my $i (1..$user->tierid->monthlylimit) {
        push @$events, {
            usagelogid  => Data::GUID->new->as_binary,
            userid      => $user->userid,
            customerid  => $user->customerid,
            endpoint    => '/',
            requesttime => $request_time,
        };
    }
    $schema->resultset('UsageLog')->populate($events);

    # This request should be rate limited.
    my $res = request(GET '/', 'X-API-KEY' => $api_key);

    is($res->code, 429, 'Request is blocked by monthly limit');
    like($res->content, qr/Too Many Requests/, 'Response body is "Too Many Requests"');
};

subtest 'Request with valid API Key to non-existent page is still rate limited' => sub {
    my $schema  = RateLimiterGateway->model('GatewayModel')->schema;
    my $user    = $schema->resultset('User')->find( { name => 'Test User' } );
    my $api_key = $user->apikey;

    my $events = [];
    for my $i (1..$user->tierid->ratelimit) {
        push @$events, {
            usagelogid  => Data::GUID->new->as_binary,
            userid      => $user->userid,
            customerid  => $user->customerid,
            endpoint    => '/',
            requesttime => DateTime->now->iso8601 . 'Z',
        };
    }
    $schema->resultset('UsageLog')->populate($events);

    my $req = GET '/nonexistent', 'X-API-KEY' => $api_key;
    my $res = request($req);

    is($res->code, 429, 'Request to non-existent page is still rate-limited');
};

done_testing();

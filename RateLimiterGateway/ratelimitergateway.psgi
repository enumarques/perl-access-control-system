use strict;
use warnings;

use RateLimiterGateway;

my $app = RateLimiterGateway->apply_default_middlewares(RateLimiterGateway->psgi_app);
$app;


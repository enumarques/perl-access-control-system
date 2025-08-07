package RateLimiterGateway::Controller::Root;
use Moose;
use namespace::autoclean;
use DateTime;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

RateLimiterGateway::Controller::Root - Root Controller for RateLimiterGateway

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub begin :Private {
    my ( $self, $c ) = @_;

    if ( ! $c->authenticate({}, 'apikey')) {
        $c->log->debug("Authentication failed for API Key")
            if $c->debug;
        $c->res->status(401);
        $c->res->body('Unauthorized: Invalid API Key');
        $c->detach; # Stop processing the request
    }

    # --- Rate Limiting Logic ---
    my $user = $c->user; # This is now a valid DBIx::Class::Row object.
    my $tier = $c->user->tierid;

    my $rate_limit = $tier->ratelimit;

    # Check requests in the last second - should be moved to a model class
    my $one_second_ago = DateTime->now->subtract( seconds => 1 )->iso8601 . 'Z';
    my $recent_requests = $c->model('GatewayModel::UsageLog')->count({
        userid => $user->userid,
        requesttime => { '>=' => $one_second_ago },
    });
    if ($recent_requests >= $rate_limit) {
        $c->response->status(429);
        $c->response->body('Too Many Requests: Rate limit exceeded');
        $c->detach;
    }

    # Check requests in the current month - should be moved to a model class
    my $monthly_limit = $tier->monthlylimit;
    my $start_of_month = DateTime->now->truncate(to => 'month')->iso8601 . 'Z';
    my $requests_this_month = $c->model('GatewayModel::UsageLog')->count({
        userid => $user->userid,
        requesttime => { '>=' => $start_of_month },
    });

    if ($requests_this_month >= $monthly_limit) {
        $c->response->status(429);
        $c->response->body('Too Many Requests: Monthly limit exceeded');
        $c->detach;
    }
 
}

sub index :Path('/') :Args(0) {
    my ( $self, $c ) = @_;

    $c->log->info("Index action called");
    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;

    $c->log->info("Default action called for non-existent page");
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end {
    my ( $self, $c ) = @_;
    if ($c->user_exists) {
        $c->model('GatewayModel::UsageLog')->create({
            usagelogid  => Data::GUID->new->as_binary,
            userid      => $c->user ? $c->user->userid : undef,
            customerid  => $c->user ? $c->user->customerid : undef,
            endpoint    => $c->request->uri->path,
            requesttime => DateTime->now->iso8601 . 'Z',
        });
    }
}

=head1 AUTHOR

Eduardo Marques

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

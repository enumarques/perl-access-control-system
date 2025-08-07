package RateLimiterGateway;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple

    Authentication
    Authorization::Roles
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in ratelimitergateway.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'RateLimiterGateway',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    encoding => 'UTF-8', # Setup request decoding and response encoding

    'Plugin::Authentication' => {
        default_realm => 'apikey',
        realms => {
            apikey => {
                # This tells the plugin how to get credentials from the request.
                credential => {
                    class => "APIKey",
                    header_name => 'X-API-KEY',
                },
                # This tells the plugin how to validate the credentials.
                store => {
                    class      => 'DBIx::Class',
                    user_model => 'GatewayModel::User', # The Catalyst Model name
                    user_class => 'User', # The name of the ResultSet
                    id_field   => 'apikey', # The column to check the key against
                },
                # This handles what to do if authentication fails.
                on_failure => sub {
                    my $c = shift;
                    $c->response->status(401);
                    $c->response->body('Unauthorized: Invalid API Key');
                    $c->detach;
                },
            },
        },
    },
);

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

RateLimiterGateway - Catalyst based application

=head1 SYNOPSIS

    script/ratelimitergateway_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<RateLimiterGateway::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Eduardo Marques

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

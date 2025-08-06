package RateLimiterGateway::Controller::Root;
use Moose;
use namespace::autoclean;

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

sub auth :Chained('/') :PathPart('') {
    my ( $self, $c ) = @_;
    
    $c->log->debug("dont thinkg this is going to print\n");
    # Check api key header, return 401 if not found
    if (!$c->request->header('api-key')) {
        $c->response->status(400);
        $c->response->body('Bad Request');
        return;
    }
}

sub index :Chained('auth') :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Chained('auth') {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Eduardo Marques

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

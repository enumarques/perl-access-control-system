package Catalyst::Authentication::Credential::APIKey;
use Moose;
use namespace::autoclean;

with 'MooseX::Emulate::Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(_config realm));

=head1 NAME

Catalyst::Authentication::Credential::APIKey - Get API Key from HTTP Header.

=cut

sub new {
    my ($class, $config, $app, $realm) = @_;
    my $self = { _config => $config };
    bless $self, $class;
    $self->realm($realm);
    $self->_config->{'header_name'} ||= 'X-API-KEY';
    return $self;
}

sub authenticate {
    my ( $self, $c, $realm, $credentials ) = @_;

    my $api_key = $c->request->header($self->_config->{'header_name'} || 'X-API-KEY');
    return unless $api_key;

    my $user = $realm->find_user({ apikey => $api_key }, $c);

    if (ref($user)) {
        return $user;
    }
    else {
        $c->log->debug("API Key '$api_key' not found in realm '$realm->{name}'")
            if $c->debug;
        return;
    }
}

__PACKAGE__;
__END__

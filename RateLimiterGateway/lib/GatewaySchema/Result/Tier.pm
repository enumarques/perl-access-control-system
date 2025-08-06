use utf8;
package GatewaySchema::Result::Tier;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GatewaySchema::Result::Tier

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<Tier>

=cut

__PACKAGE__->table("Tier");

=head1 ACCESSORS

=head2 tierid

  data_type: 'int'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 monthlylimit

  data_type: 'int'
  is_nullable: 1

=head2 ratelimit

  data_type: 'int'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tierid",
  { data_type => "int", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 30 },
  "monthlylimit",
  { data_type => "int", is_nullable => 1 },
  "ratelimit",
  { data_type => "int", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tierid>

=back

=cut

__PACKAGE__->set_primary_key("tierid");

=head1 RELATIONS

=head2 users

Type: has_many

Related object: L<GatewaySchema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "GatewaySchema::Result::User",
  { "foreign.tierid" => "self.tierid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-08-06 05:45:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XtHDP67vkP5p4oaRQBUmeQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

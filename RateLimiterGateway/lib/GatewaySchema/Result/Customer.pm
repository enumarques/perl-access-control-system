use utf8;
package GatewaySchema::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GatewaySchema::Result::Customer

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

=head1 TABLE: C<Customer>

=cut

__PACKAGE__->table("Customer");

=head1 ACCESSORS

=head2 customerid

  data_type: 'blob'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "customerid",
  { data_type => "blob", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</customerid>

=back

=cut

__PACKAGE__->set_primary_key("customerid");

=head1 RELATIONS

=head2 usage_logs

Type: has_many

Related object: L<GatewaySchema::Result::UsageLog>

=cut

__PACKAGE__->has_many(
  "usage_logs",
  "GatewaySchema::Result::UsageLog",
  { "foreign.customerid" => "self.customerid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-08-06 05:45:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u2GCRuwWurqddFvICMVHJQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

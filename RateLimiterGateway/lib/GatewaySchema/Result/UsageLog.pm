use utf8;
package GatewaySchema::Result::UsageLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GatewaySchema::Result::UsageLog

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

=head1 TABLE: C<UsageLog>

=cut

__PACKAGE__->table("UsageLog");

=head1 ACCESSORS

=head2 usagelogid

  data_type: 'blob'
  is_nullable: 0

=head2 userid

  data_type: 'blob'
  is_foreign_key: 1
  is_nullable: 1

=head2 customerid

  data_type: 'blob'
  is_foreign_key: 1
  is_nullable: 1

=head2 endpoint

  data_type: 'varchar'
  is_nullable: 1
  size: 2048

=head2 requesttime

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "usagelogid",
  { data_type => "blob", is_nullable => 0 },
  "userid",
  { data_type => "blob", is_foreign_key => 1, is_nullable => 1 },
  "customerid",
  { data_type => "blob", is_foreign_key => 1, is_nullable => 1 },
  "endpoint",
  { data_type => "varchar", is_nullable => 1, size => 2048 },
  "requesttime",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</usagelogid>

=back

=cut

__PACKAGE__->set_primary_key("usagelogid");

=head1 RELATIONS

=head2 customerid

Type: belongs_to

Related object: L<GatewaySchema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customerid",
  "GatewaySchema::Result::Customer",
  { customerid => "customerid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 userid

Type: belongs_to

Related object: L<GatewaySchema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "userid",
  "GatewaySchema::Result::User",
  { userid => "userid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07053 @ 2025-08-06 05:45:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:p/sILdr93lp3NTdJ65TUpA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;

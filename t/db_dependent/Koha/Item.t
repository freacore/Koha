#!/usr/bin/perl

# Copyright 2019 Koha Development team
#
# This file is part of Koha
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;
use utf8;

use Test::More tests => 14;
use Test::Exception;

use C4::Biblio qw( GetMarcSubfieldStructure );
use C4::Circulation qw( AddIssue AddReturn );

use Koha::Caches;
use Koha::Items;
use Koha::Database;
use Koha::DateUtils qw( dt_from_string );
use Koha::Old::Items;

use List::MoreUtils qw(all);

use t::lib::TestBuilder;
use t::lib::Mocks;

my $schema  = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new;

subtest 'tracked_links relationship' => sub {
    plan tests => 3;

    my $biblio = $builder->build_sample_biblio();
    my $item   = $builder->build_sample_item({
        biblionumber => $biblio->biblionumber,
    });
    my $tracked_links = $item->tracked_links;
    is( ref($tracked_links), 'Koha::TrackedLinks', 'tracked_links returns a Koha::TrackedLinks object set' );
    is($item->tracked_links->count, 0, "Empty Koha::TrackedLinks set returned if no tracked_links");
    my $link1 = $builder->build({ source => 'Linktracker', value => { itemnumber => $item->itemnumber }});
    my $link2 = $builder->build({ source => 'Linktracker', value => { itemnumber => $item->itemnumber }});

    is($item->tracked_links()->count,2,"Two tracked links found");
};

subtest 'hidden_in_opac() tests' => sub {

    plan tests => 4;

    $schema->storage->txn_begin;

    my $item  = $builder->build_sample_item({ itemlost => 2 });
    my $rules = {};

    # disable hidelostitems as it interteres with OpachiddenItems for the calculation
    t::lib::Mocks::mock_preference( 'hidelostitems', 0 );

    ok( !$item->hidden_in_opac, 'No rules passed, shouldn\'t hide' );
    ok( !$item->hidden_in_opac({ rules => $rules }), 'Empty rules passed, shouldn\'t hide' );

    # enable hidelostitems to verify correct behaviour
    t::lib::Mocks::mock_preference( 'hidelostitems', 1 );
    ok( $item->hidden_in_opac, 'Even with no rules, item should hide because of hidelostitems syspref' );

    # disable hidelostitems
    t::lib::Mocks::mock_preference( 'hidelostitems', 0 );
    my $withdrawn = $item->withdrawn + 1; # make sure this attribute doesn't match

    $rules = { withdrawn => [$withdrawn], itype => [ $item->itype ] };

    ok( $item->hidden_in_opac({ rules => $rules }), 'Rule matching itype passed, should hide' );



    $schema->storage->txn_rollback;
};

subtest 'has_pending_hold() tests' => sub {

    plan tests => 2;

    $schema->storage->txn_begin;

    my $dbh = C4::Context->dbh;
    my $item  = $builder->build_sample_item({ itemlost => 0 });
    my $itemnumber = $item->itemnumber;

    $dbh->do("INSERT INTO tmp_holdsqueue (surname,borrowernumber,itemnumber) VALUES ('Clamp',42,$itemnumber)");
    ok( $item->has_pending_hold, "Yes, we have a pending hold");
    $dbh->do("DELETE FROM tmp_holdsqueue WHERE itemnumber=$itemnumber");
    ok( !$item->has_pending_hold, "We don't have a pending hold if nothing in the tmp_holdsqueue");

    $schema->storage->txn_rollback;
};

subtest "as_marc_field() tests" => sub {

    my $mss = C4::Biblio::GetMarcSubfieldStructure( '' );
    my ( $itemtag, $itemtagsubfield) = C4::Biblio::GetMarcFromKohaField( "items.itemnumber" );

    my @schema_columns = $schema->resultset('Item')->result_source->columns;
    my @mapped_columns = grep { exists $mss->{'items.'.$_} } @schema_columns;

    plan tests => 2 * (scalar @mapped_columns + 1) + 3;

    $schema->storage->txn_begin;

    my $item = $builder->build_sample_item;
    # Make sure it has at least one undefined attribute
    $item->set({ replacementprice => undef })->store->discard_changes;

    # Tests with the mss parameter
    my $marc_field = $item->as_marc_field({ mss => $mss });

    is(
        $marc_field->tag,
        $itemtag,
        'Generated field set the right tag number'
    );

    foreach my $column ( @mapped_columns ) {
        my $tagsubfield = $mss->{ 'items.' . $column }[0]->{tagsubfield};
        is( $marc_field->subfield($tagsubfield),
            $item->$column, "Value is mapped correctly for column $column" );
    }

    # Tests without the mss parameter
    $marc_field = $item->as_marc_field();

    is(
        $marc_field->tag,
        $itemtag,
        'Generated field set the right tag number'
    );

    foreach my $column (@mapped_columns) {
        my $tagsubfield = $mss->{ 'items.' . $column }[0]->{tagsubfield};
        is( $marc_field->subfield($tagsubfield),
            $item->$column, "Value is mapped correctly for column $column" );
    }

    my $unmapped_subfield = Koha::MarcSubfieldStructure->new(
        {
            frameworkcode => '',
            tagfield      => $itemtag,
            tagsubfield   => 'X',
        }
    )->store;

    my @unlinked_subfields;
    push @unlinked_subfields, X => 'Something weird';
    $item->more_subfields_xml( C4::Items::_get_unlinked_subfields_xml( \@unlinked_subfields ) )->store;

    Koha::Caches->get_instance->clear_from_cache( "MarcStructure-1-" );
    Koha::MarcSubfieldStructures->search(
        { frameworkcode => '', tagfield => $itemtag } )
      ->update( { display_order => \['FLOOR( 1 + RAND( ) * 10 )'] } );

    $marc_field = $item->as_marc_field;

    my $tagslib = C4::Biblio::GetMarcStructure(1, '');
    my @subfields = $marc_field->subfields;
    my $result = all { defined $_->[1] } @subfields;
    ok( $result, 'There are no undef subfields' );
    my @ordered_subfields = sort {
            $tagslib->{$itemtag}->{ $a->[0] }->{display_order}
        <=> $tagslib->{$itemtag}->{ $b->[0] }->{display_order}
    } @subfields;
    is_deeply(\@subfields, \@ordered_subfields);

    is( scalar $marc_field->subfield('X'), 'Something weird', 'more_subfield_xml is considered' );

    $schema->storage->txn_rollback;
    Koha::Caches->get_instance->clear_from_cache( "MarcStructure-1-" );
};

subtest 'pickup_locations' => sub {
    plan tests => 66;

    $schema->storage->txn_begin;

    my $dbh = C4::Context->dbh;

    my $root1 = $builder->build_object( { class => 'Koha::Library::Groups', value => { ft_local_hold_group => 1, branchcode => undef } } );
    my $root2 = $builder->build_object( { class => 'Koha::Library::Groups', value => { ft_local_hold_group => 1, branchcode => undef } } );
    my $library1 = $builder->build_object( { class => 'Koha::Libraries', value => { pickup_location => 1, } } );
    my $library2 = $builder->build_object( { class => 'Koha::Libraries', value => { pickup_location => 1, } } );
    my $library3 = $builder->build_object( { class => 'Koha::Libraries', value => { pickup_location => 0, } } );
    my $library4 = $builder->build_object( { class => 'Koha::Libraries', value => { pickup_location => 1, } } );
    my $group1_1 = $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root1->id, branchcode => $library1->branchcode } } );
    my $group1_2 = $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root1->id, branchcode => $library2->branchcode } } );

    my $group2_1 = $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root2->id, branchcode => $library3->branchcode } } );
    my $group2_2 = $builder->build_object( { class => 'Koha::Library::Groups', value => { parent_id => $root2->id, branchcode => $library4->branchcode } } );

    our @branchcodes = (
        $library1->branchcode, $library2->branchcode,
        $library3->branchcode, $library4->branchcode
    );

    my $item1 = $builder->build_sample_item(
        {
            homebranch    => $library1->branchcode,
            holdingbranch => $library2->branchcode,
            copynumber    => 1,
            ccode         => 'Gollum'
        }
    )->store;

    my $item3 = $builder->build_sample_item(
        {
            homebranch    => $library3->branchcode,
            holdingbranch => $library4->branchcode,
            copynumber    => 3,
            itype         => $item1->itype,
        }
    )->store;

    Koha::CirculationRules->set_rules(
        {
            categorycode => undef,
            itemtype     => $item1->itype,
            branchcode   => undef,
            rules        => {
                reservesallowed => 25,
            }
        }
    );


    my $patron1 = $builder->build_object( { class => 'Koha::Patrons', value => { branchcode => $library1->branchcode, firstname => '1' } } );
    my $patron4 = $builder->build_object( { class => 'Koha::Patrons', value => { branchcode => $library4->branchcode, firstname => '4' } } );

    my $results = {
        "1-1-from_home_library-any"               => 3,
        "1-1-from_home_library-holdgroup"         => 2,
        "1-1-from_home_library-patrongroup"       => 2,
        "1-1-from_home_library-homebranch"        => 1,
        "1-1-from_home_library-holdingbranch"     => 1,
        "1-1-from_any_library-any"                => 3,
        "1-1-from_any_library-holdgroup"          => 2,
        "1-1-from_any_library-patrongroup"        => 2,
        "1-1-from_any_library-homebranch"         => 1,
        "1-1-from_any_library-holdingbranch"      => 1,
        "1-1-from_local_hold_group-any"           => 3,
        "1-1-from_local_hold_group-holdgroup"     => 2,
        "1-1-from_local_hold_group-patrongroup"   => 2,
        "1-1-from_local_hold_group-homebranch"    => 1,
        "1-1-from_local_hold_group-holdingbranch" => 1,
        "1-4-from_home_library-any"               => 0,
        "1-4-from_home_library-holdgroup"         => 0,
        "1-4-from_home_library-patrongroup"       => 0,
        "1-4-from_home_library-homebranch"        => 0,
        "1-4-from_home_library-holdingbranch"     => 0,
        "1-4-from_any_library-any"                => 3,
        "1-4-from_any_library-holdgroup"          => 2,
        "1-4-from_any_library-patrongroup"        => 1,
        "1-4-from_any_library-homebranch"         => 1,
        "1-4-from_any_library-holdingbranch"      => 1,
        "1-4-from_local_hold_group-any"           => 0,
        "1-4-from_local_hold_group-holdgroup"     => 0,
        "1-4-from_local_hold_group-patrongroup"   => 0,
        "1-4-from_local_hold_group-homebranch"    => 0,
        "1-4-from_local_hold_group-holdingbranch" => 0,
        "3-1-from_home_library-any"               => 0,
        "3-1-from_home_library-holdgroup"         => 0,
        "3-1-from_home_library-patrongroup"       => 0,
        "3-1-from_home_library-homebranch"        => 0,
        "3-1-from_home_library-holdingbranch"     => 0,
        "3-1-from_any_library-any"                => 3,
        "3-1-from_any_library-holdgroup"          => 1,
        "3-1-from_any_library-patrongroup"        => 2,
        "3-1-from_any_library-homebranch"         => 0,
        "3-1-from_any_library-holdingbranch"      => 1,
        "3-1-from_local_hold_group-any"           => 0,
        "3-1-from_local_hold_group-holdgroup"     => 0,
        "3-1-from_local_hold_group-patrongroup"   => 0,
        "3-1-from_local_hold_group-homebranch"    => 0,
        "3-1-from_local_hold_group-holdingbranch" => 0,
        "3-4-from_home_library-any"               => 0,
        "3-4-from_home_library-holdgroup"         => 0,
        "3-4-from_home_library-patrongroup"       => 0,
        "3-4-from_home_library-homebranch"        => 0,
        "3-4-from_home_library-holdingbranch"     => 0,
        "3-4-from_any_library-any"                => 3,
        "3-4-from_any_library-holdgroup"          => 1,
        "3-4-from_any_library-patrongroup"        => 1,
        "3-4-from_any_library-homebranch"         => 0,
        "3-4-from_any_library-holdingbranch"      => 1,
        "3-4-from_local_hold_group-any"           => 3,
        "3-4-from_local_hold_group-holdgroup"     => 1,
        "3-4-from_local_hold_group-patrongroup"   => 1,
        "3-4-from_local_hold_group-homebranch"    => 0,
        "3-4-from_local_hold_group-holdingbranch" => 1
    };

    sub _doTest {
        my ( $item, $patron, $ha, $hfp, $results ) = @_;

        Koha::CirculationRules->set_rules(
            {
                branchcode => undef,
                itemtype   => undef,
                rules => {
                    holdallowed => $ha,
                    hold_fulfillment_policy => $hfp,
                    returnbranch => 'any'
                }
            }
        );
        my $ha_value =
          $ha eq 'from_local_hold_group' ? 'holdgroup'
          : (
            $ha eq 'from_any_library' ? 'any'
            : 'homebranch'
          );

        my @pl = map {
            my $pickup_location = $_;
            grep { $pickup_location->branchcode eq $_ } @branchcodes
        } $item->pickup_locations( { patron => $patron } )->as_list;

        ok(
            scalar(@pl) eq $results->{
                    $item->copynumber . '-'
                  . $patron->firstname . '-'
                  . $ha . '-'
                  . $hfp
            },
            'item'
              . $item->copynumber
              . ', patron'
              . $patron->firstname
              . ', holdallowed: '
              . $ha_value
              . ', hold_fulfillment_policy: '
              . $hfp
              . ' should return '
              . $results->{
                    $item->copynumber . '-'
                  . $patron->firstname . '-'
                  . $ha . '-'
                  . $hfp
              }
              . ' and returns '
              . scalar(@pl)
        );

    }


    foreach my $item ($item1, $item3) {
        foreach my $patron ($patron1, $patron4) {
            #holdallowed 1: homebranch, 2: any, 3: holdgroup
            foreach my $ha ('from_home_library', 'from_any_library', 'from_local_hold_group') {
                foreach my $hfp ('any', 'holdgroup', 'patrongroup', 'homebranch', 'holdingbranch') {
                    _doTest($item, $patron, $ha, $hfp, $results);
                }
            }
        }
    }

    # Now test that branchtransferlimits will further filter the pickup locations

    my $item_no_ccode = $builder->build_sample_item(
        {
            homebranch    => $library1->branchcode,
            holdingbranch => $library2->branchcode,
            itype         => $item1->itype,
        }
    )->store;

    t::lib::Mocks::mock_preference('UseBranchTransferLimits', 1);
    t::lib::Mocks::mock_preference('BranchTransferLimitsType', 'itemtype');
    Koha::CirculationRules->set_rules(
        {
            branchcode => undef,
            itemtype   => $item1->itype,
            rules      => {
                holdallowed             => 'from_home_library',
                hold_fulfillment_policy => 1,
                returnbranch            => 'any'
            }
        }
    );
    $builder->build_object(
        {
            class => 'Koha::Item::Transfer::Limits',
            value => {
                toBranch   => $library1->branchcode,
                fromBranch => $library2->branchcode,
                itemtype   => $item1->itype,
                ccode      => undef,
            }
        }
    );

    my @pickup_locations = map {
        my $pickup_location = $_;
        grep { $pickup_location->branchcode eq $_ } @branchcodes
    } $item1->pickup_locations( { patron => $patron1 } )->as_list;

    is( scalar @pickup_locations, 3 - 1, "With a transfer limits we get back the libraries that are pickup locations minus 1 limited library");

    $builder->build_object(
        {
            class => 'Koha::Item::Transfer::Limits',
            value => {
                toBranch   => $library4->branchcode,
                fromBranch => $library2->branchcode,
                itemtype   => $item1->itype,
                ccode      => undef,
            }
        }
    );

    @pickup_locations = map {
        my $pickup_location = $_;
        grep { $pickup_location->branchcode eq $_ } @branchcodes
    } $item1->pickup_locations( { patron => $patron1 } )->as_list;

    is( scalar @pickup_locations, 3 - 2, "With 2 transfer limits we get back the libraries that are pickup locations minus 2 limited libraries");

    t::lib::Mocks::mock_preference('BranchTransferLimitsType', 'ccode');
    @pickup_locations = map {
        my $pickup_location = $_;
        grep { $pickup_location->branchcode eq $_ } @branchcodes
    } $item1->pickup_locations( { patron => $patron1 } )->as_list;
    is( scalar @pickup_locations, 3, "With no transfer limits of type ccode we get back the libraries that are pickup locations");

    @pickup_locations = map {
        my $pickup_location = $_;
        grep { $pickup_location->branchcode eq $_ } @branchcodes
    } $item_no_ccode->pickup_locations( { patron => $patron1 } )->as_list;
    is( scalar @pickup_locations, 3, "With no transfer limits of type ccode and an item with no ccode we get back the libraries that are pickup locations");

    $builder->build_object(
        {
            class => 'Koha::Item::Transfer::Limits',
            value => {
                toBranch   => $library2->branchcode,
                fromBranch => $library2->branchcode,
                itemtype   => undef,
                ccode      => $item1->ccode,
            }
        }
    );

    @pickup_locations = map {
        my $pickup_location = $_;
        grep { $pickup_location->branchcode eq $_ } @branchcodes
    } $item1->pickup_locations( { patron => $patron1 } )->as_list;
    is( scalar @pickup_locations, 3 - 1, "With a transfer limits we get back the libraries that are pickup locations minus 1 limited library");

    $builder->build_object(
        {
            class => 'Koha::Item::Transfer::Limits',
            value => {
                toBranch   => $library4->branchcode,
                fromBranch => $library2->branchcode,
                itemtype   => undef,
                ccode      => $item1->ccode,
            }
        }
    );

    @pickup_locations = map {
        my $pickup_location = $_;
        grep { $pickup_location->branchcode eq $_ } @branchcodes
    } $item1->pickup_locations( { patron => $patron1 } )->as_list;
    is( scalar @pickup_locations, 3 - 2, "With 2 transfer limits we get back the libraries that are pickup locations minus 2 limited libraries");

    t::lib::Mocks::mock_preference('UseBranchTransferLimits', 0);

    $schema->storage->txn_rollback;
};

subtest 'request_transfer' => sub {
    plan tests => 13;
    $schema->storage->txn_begin;

    my $library1 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $library2 = $builder->build_object( { class => 'Koha::Libraries' } );
    my $item     = $builder->build_sample_item(
        {
            homebranch    => $library1->branchcode,
            holdingbranch => $library2->branchcode,
        }
    );

    # Mandatory fields tests
    throws_ok { $item->request_transfer( { to => $library1 } ) }
    'Koha::Exceptions::MissingParameter',
      'Exception thrown if `reason` parameter is missing';

    throws_ok { $item->request_transfer( { reason => 'Manual' } ) }
    'Koha::Exceptions::MissingParameter',
      'Exception thrown if `to` parameter is missing';

    # Successful request
    my $transfer = $item->request_transfer({ to => $library1, reason => 'Manual' });
    is( ref($transfer), 'Koha::Item::Transfer',
        'Koha::Item->request_transfer should return a Koha::Item::Transfer object'
    );
    my $original_transfer = $transfer->get_from_storage;

    # Transfer already in progress
    throws_ok { $item->request_transfer( { to => $library2, reason => 'Manual' } ) }
    'Koha::Exceptions::Item::Transfer::InQueue',
      'Exception thrown if transfer is already in progress';

    my $exception = $@;
    is( ref( $exception->transfer ),
        'Koha::Item::Transfer',
        'The exception contains the found Koha::Item::Transfer' );

    # Queue transfer
    my $queued_transfer = $item->request_transfer(
        { to => $library2, reason => 'Manual', enqueue => 1 } );
    is( ref($queued_transfer), 'Koha::Item::Transfer',
        'Koha::Item->request_transfer allowed when enqueue is set' );
    my $transfers = $item->get_transfers;
    is($transfers->count, 2, "There are now 2 live transfers in the queue");
    $transfer = $transfer->get_from_storage;
    is_deeply($transfer->unblessed, $original_transfer->unblessed, "Original transfer unchanged");
    $queued_transfer->datearrived(dt_from_string)->store();

    # Replace transfer
    my $replaced_transfer = $item->request_transfer(
        { to => $library2, reason => 'Manual', replace => 1 } );
    is( ref($replaced_transfer), 'Koha::Item::Transfer',
        'Koha::Item->request_transfer allowed when replace is set' );
    $original_transfer->discard_changes;
    ok($original_transfer->datecancelled, "Original transfer cancelled");
    $transfers = $item->get_transfers;
    is($transfers->count, 1, "There is only 1 live transfer in the queue");
    $replaced_transfer->datearrived(dt_from_string)->store();

    # BranchTransferLimits
    t::lib::Mocks::mock_preference('UseBranchTransferLimits', 1);
    t::lib::Mocks::mock_preference('BranchTransferLimitsType', 'itemtype');
    my $limit = Koha::Item::Transfer::Limit->new({
        fromBranch => $library2->branchcode,
        toBranch => $library1->branchcode,
        itemtype => $item->effective_itemtype,
    })->store;

    throws_ok { $item->request_transfer( { to => $library1, reason => 'Manual' } ) }
    'Koha::Exceptions::Item::Transfer::Limit',
      'Exception thrown if transfer is prevented by limits';

    my $forced_transfer = $item->request_transfer( { to => $library1, reason => 'Manual', ignore_limits => 1 } );
    is( ref($forced_transfer), 'Koha::Item::Transfer',
        'Koha::Item->request_transfer allowed when ignore_limits is set'
    );

    $schema->storage->txn_rollback;
};

subtest 'deletion' => sub {
    plan tests => 13;

    $schema->storage->txn_begin;

    my $biblio = $builder->build_sample_biblio();

    my $item = $builder->build_sample_item(
        {
            biblionumber => $biblio->biblionumber,
        }
    );

    is( ref( $item->move_to_deleted ), 'Koha::Schema::Result::Deleteditem', 'Koha::Item->move_to_deleted should return the Deleted item' )
      ;    # FIXME This should be Koha::Deleted::Item
    is( Koha::Old::Items->search({itemnumber => $item->itemnumber})->count, 1, '->move_to_deleted must have moved the item to deleteditem' );
    $item = $builder->build_sample_item(
        {
            biblionumber => $biblio->biblionumber,
        }
    );
    $item->delete;
    is( Koha::Old::Items->search({itemnumber => $item->itemnumber})->count, 0, '->move_to_deleted must not have moved the item to deleteditem' );


    my $library   = $builder->build_object({ class => 'Koha::Libraries' });
    my $library_2 = $builder->build_object({ class => 'Koha::Libraries' });
    t::lib::Mocks::mock_userenv({ branchcode => $library->branchcode });

    my $patron = $builder->build_object({class => 'Koha::Patrons'});
    $item = $builder->build_sample_item({ library => $library->branchcode });

    # book_on_loan
    C4::Circulation::AddIssue( $patron->unblessed, $item->barcode );

    is(
        @{$item->safe_to_delete->messages}[0]->message,
        'book_on_loan',
        'Koha::Item->safe_to_delete reports item on loan',
    );

    is(
        @{$item->safe_to_delete->messages}[0]->message,
        'book_on_loan',
        'item that is on loan cannot be deleted',
    );

    ok(
        ! $item->safe_to_delete,
        'Koha::Item->safe_to_delete shows item NOT safe to delete'
    );

    AddReturn( $item->barcode, $library->branchcode );

    # book_reserved is tested in t/db_dependent/Reserves.t

    # not_same_branch
    t::lib::Mocks::mock_preference('IndependentBranches', 1);
    my $item_2 = $builder->build_sample_item({ library => $library_2->branchcode });

    is(
        @{$item_2->safe_to_delete->messages}[0]->message,
        'not_same_branch',
        'Koha::Item->safe_to_delete reports IndependentBranches restriction',
    );

    is(
        @{$item_2->safe_to_delete->messages}[0]->message,
        'not_same_branch',
        'IndependentBranches prevents deletion at another branch',
    );

    # linked_analytics

    { # codeblock to limit scope of $module->mock

        my $module = Test::MockModule->new('C4::Items');
        $module->mock( GetAnalyticsCount => sub { return 1 } );

        $item->discard_changes;
        is(
            @{$item->safe_to_delete->messages}[0]->message,
            'linked_analytics',
            'Koha::Item->safe_to_delete reports linked analytics',
        );

        is(
            @{$item->safe_to_delete->messages}[0]->message,
            'linked_analytics',
            'Linked analytics prevents deletion of item',
        );

    }

    { # last_item_for_hold
        C4::Reserves::AddReserve({ branchcode => $patron->branchcode, borrowernumber => $patron->borrowernumber, biblionumber => $item->biblionumber });
        is(
            @{$item->safe_to_delete->messages}[0]->message,
            'last_item_for_hold',
            'Item cannot be deleted if a biblio-level is placed on the biblio and there is only 1 item attached to the biblio'
        );
        # With another item attached to the biblio, the item can be deleted
        $builder->build_sample_item({ biblionumber => $item->biblionumber });
    }

    ok(
        $item->safe_to_delete,
        'Koha::Item->safe_to_delete shows item safe to delete'
    );

    $item->safe_delete,

    my $test_item = Koha::Items->find( $item->itemnumber );

    is( $test_item, undef,
        "Koha::Item->safe_delete should delete item if safe_to_delete returns true"
    );

    $schema->storage->txn_rollback;
};

subtest 'renewal_branchcode' => sub {
    plan tests => 13;

    $schema->storage->txn_begin;

    my $item = $builder->build_sample_item();
    my $branch = $builder->build_object({ class => 'Koha::Libraries' });
    my $checkout = $builder->build_object({
        class => 'Koha::Checkouts',
        value => {
            itemnumber => $item->itemnumber,
        }
    });


    C4::Context->interface( 'intranet' );
    t::lib::Mocks::mock_userenv({ branchcode => $branch->branchcode });

    is( $item->renewal_branchcode, $branch->branchcode, "If interface not opac, we get the branch from context");
    is( $item->renewal_branchcode({ branch => "PANDA"}), $branch->branchcode, "If interface not opac, we get the branch from context even if we pass one in");
    C4::Context->set_userenv(51, 'userid4tests', undef, 'firstname', 'surname', undef, undef, 0, undef, undef, undef ); #mock userenv doesn't let us set null branch
    is( $item->renewal_branchcode({ branch => "PANDA"}), "PANDA", "If interface not opac, we get the branch we pass one in if context not set");

    C4::Context->interface( 'opac' );

    t::lib::Mocks::mock_preference('OpacRenewalBranch', undef);
    is( $item->renewal_branchcode, 'OPACRenew', "If interface opac and OpacRenewalBranch undef, we get OPACRenew");
    is( $item->renewal_branchcode({branch=>'COW'}), 'OPACRenew', "If interface opac and OpacRenewalBranch undef, we get OPACRenew even if branch passed");

    t::lib::Mocks::mock_preference('OpacRenewalBranch', 'none');
    is( $item->renewal_branchcode, '', "If interface opac and OpacRenewalBranch is none, we get blank string");
    is( $item->renewal_branchcode({branch=>'COW'}), '', "If interface opac and OpacRenewalBranch is none, we get blank string even if branch passed");

    t::lib::Mocks::mock_preference('OpacRenewalBranch', 'checkoutbranch');
    is( $item->renewal_branchcode, $checkout->branchcode, "If interface opac and OpacRenewalBranch set to checkoutbranch, we get branch of checkout");
    is( $item->renewal_branchcode({branch=>'MONKEY'}), $checkout->branchcode, "If interface opac and OpacRenewalBranch set to checkoutbranch, we get branch of checkout even if branch passed");

    t::lib::Mocks::mock_preference('OpacRenewalBranch','patronhomebranch');
    is( $item->renewal_branchcode, $checkout->patron->branchcode, "If interface opac and OpacRenewalBranch set to patronbranch, we get branch of patron");
    is( $item->renewal_branchcode({branch=>'TURKEY'}), $checkout->patron->branchcode, "If interface opac and OpacRenewalBranch set to patronbranch, we get branch of patron even if branch passed");

    t::lib::Mocks::mock_preference('OpacRenewalBranch','itemhomebranch');
    is( $item->renewal_branchcode, $item->homebranch, "If interface opac and OpacRenewalBranch set to itemhomebranch, we get homebranch of item");
    is( $item->renewal_branchcode({branch=>'MANATEE'}), $item->homebranch, "If interface opac and OpacRenewalBranch set to itemhomebranch, we get homebranch of item even if branch passed");

    $schema->storage->txn_rollback;
};

subtest 'Tests for itemtype' => sub {
    plan tests => 2;
    $schema->storage->txn_begin;

    my $biblio = $builder->build_sample_biblio;
    my $itemtype = $builder->build_object({ class => 'Koha::ItemTypes' });
    my $item = $builder->build_sample_item({ biblionumber => $biblio->biblionumber, itype => $itemtype->itemtype });

    t::lib::Mocks::mock_preference('item-level_itypes', 1);
    is( $item->itemtype->itemtype, $item->itype, 'Pref enabled' );
    t::lib::Mocks::mock_preference('item-level_itypes', 0);
    is( $item->itemtype->itemtype, $biblio->biblioitem->itemtype, 'Pref disabled' );

    $schema->storage->txn_rollback;
};

subtest 'get_transfers' => sub {
    plan tests => 16;
    $schema->storage->txn_begin;

    my $item = $builder->build_sample_item();

    my $transfers = $item->get_transfers();
    is(ref($transfers), 'Koha::Item::Transfers', 'Koha::Item->get_transfer should return a Koha::Item::Transfers object' );
    is($transfers->count, 0, 'When no transfers exist, the Koha::Item:Transfers object should be empty');

    my $library_to = $builder->build_object( { class => 'Koha::Libraries' } );

    my $transfer_1 = $builder->build_object(
        {
            class => 'Koha::Item::Transfers',
            value => {
                itemnumber    => $item->itemnumber,
                frombranch    => $item->holdingbranch,
                tobranch      => $library_to->branchcode,
                reason        => 'Manual',
                datesent      => undef,
                datearrived   => undef,
                datecancelled => undef,
                daterequested => \'NOW()'
            }
        }
    );

    $transfers = $item->get_transfers();
    is($transfers->count, 1, 'When one transfer has been requested, the Koha::Item:Transfers object should contain one result');

    my $transfer_2 = $builder->build_object(
        {
            class => 'Koha::Item::Transfers',
            value => {
                itemnumber    => $item->itemnumber,
                frombranch    => $item->holdingbranch,
                tobranch      => $library_to->branchcode,
                reason        => 'Manual',
                datesent      => undef,
                datearrived   => undef,
                datecancelled => undef,
                daterequested => \'NOW()'
            }
        }
    );

    my $transfer_3 = $builder->build_object(
        {
            class => 'Koha::Item::Transfers',
            value => {
                itemnumber    => $item->itemnumber,
                frombranch    => $item->holdingbranch,
                tobranch      => $library_to->branchcode,
                reason        => 'Manual',
                datesent      => undef,
                datearrived   => undef,
                datecancelled => undef,
                daterequested => \'NOW()'
            }
        }
    );

    $transfers = $item->get_transfers();
    is($transfers->count, 3, 'When there are multiple open transfer requests, the Koha::Item::Transfers object contains them all');
    my $result_1 = $transfers->next;
    my $result_2 = $transfers->next;
    my $result_3 = $transfers->next;
    is( $result_1->branchtransfer_id, $transfer_1->branchtransfer_id, 'Koha::Item->get_transfers returns the oldest transfer request first');
    is( $result_2->branchtransfer_id, $transfer_2->branchtransfer_id, 'Koha::Item->get_transfers returns the newer transfer request second');
    is( $result_3->branchtransfer_id, $transfer_3->branchtransfer_id, 'Koha::Item->get_transfers returns the newest transfer request last');

    $transfer_2->datesent(\'NOW()')->store;
    $transfers = $item->get_transfers();
    is($transfers->count, 3, 'When one transfer is set to in_transit, the Koha::Item::Transfers object still contains them all');
    $result_1 = $transfers->next;
    $result_2 = $transfers->next;
    $result_3 = $transfers->next;
    is( $result_1->branchtransfer_id, $transfer_2->branchtransfer_id, 'Koha::Item->get_transfers returns the active transfer request first');
    is( $result_2->branchtransfer_id, $transfer_1->branchtransfer_id, 'Koha::Item->get_transfers returns the other transfers oldest to newest');
    is( $result_3->branchtransfer_id, $transfer_3->branchtransfer_id, 'Koha::Item->get_transfers returns the other transfers oldest to newest');

    $transfer_2->datearrived(\'NOW()')->store;
    $transfers = $item->get_transfers();
    is($transfers->count, 2, 'Once a transfer is received, it no longer appears in the list from ->get_transfers()');
    $result_1 = $transfers->next;
    $result_2 = $transfers->next;
    is( $result_1->branchtransfer_id, $transfer_1->branchtransfer_id, 'Koha::Item->get_transfers returns the other transfers oldest to newest');
    is( $result_2->branchtransfer_id, $transfer_3->branchtransfer_id, 'Koha::Item->get_transfers returns the other transfers oldest to newest');

    $transfer_1->datecancelled(\'NOW()')->store;
    $transfers = $item->get_transfers();
    is($transfers->count, 1, 'Once a transfer is cancelled, it no longer appears in the list from ->get_transfers()');
    $result_1 = $transfers->next;
    is( $result_1->branchtransfer_id, $transfer_3->branchtransfer_id, 'Koha::Item->get_transfers returns the only transfer that remains');

    $schema->storage->txn_rollback;
};

subtest 'Tests for relationship between item and item_orders via aqorders_item' => sub {
    plan tests => 3;

    $schema->storage->txn_begin;

    my $biblio = $builder->build_sample_biblio();
    my $item = $builder->build_sample_item({ biblionumber => $biblio->biblionumber });

    my $orders = $item->orders;
    is ($orders->count, 0, 'No order on this item yet');

    my $order_note = 'Order for ' . $item->itemnumber;

    my $aq_order1 = $builder->build_object({
        class => 'Koha::Acquisition::Orders',
        value  => {
            biblionumber => $biblio->biblionumber,
            order_internalnote => $order_note,
        },
    });
    my $aq_order2 = $builder->build_object({
        class => 'Koha::Acquisition::Orders',
        value  => {
            biblionumber => $biblio->biblionumber,
        },
    });
    my $aq_order_item1 = $builder->build({
        source => 'AqordersItem',
        value  => {
            ordernumber => $aq_order1->ordernumber,
            itemnumber => $item->itemnumber,
        },
    });

    $orders = $item->orders;
    is ($orders->count, 1, 'One order found by item with the relationship');
    is ($orders->next->order_internalnote, $order_note, 'Correct order found by item with the relationship');
};

subtest 'move_to_biblio() tests' => sub {
    plan tests => 16;

    $schema->storage->txn_begin;

    my $dbh = C4::Context->dbh;

    my $source_biblio = $builder->build_sample_biblio();
    my $target_biblio = $builder->build_sample_biblio();

    my $source_biblionumber = $source_biblio->biblionumber;
    my $target_biblionumber = $target_biblio->biblionumber;

    my $item1 = $builder->build_sample_item({ biblionumber => $source_biblionumber });
    my $item2 = $builder->build_sample_item({ biblionumber => $source_biblionumber });
    my $item3 = $builder->build_sample_item({ biblionumber => $source_biblionumber });

    my $itemnumber1 = $item1->itemnumber;
    my $itemnumber2 = $item2->itemnumber;

    my $library = $builder->build_object({ class => 'Koha::Libraries' });

    my $patron = $builder->build_object({
        class => 'Koha::Patrons',
        value => { branchcode => $library->branchcode }
    });
    my $borrowernumber = $patron->borrowernumber;

    my $aq_budget = $builder->build({
        source => 'Aqbudget',
        value  => {
            budget_notes => 'test',
        },
    });

    my $aq_order1 = $builder->build_object({
        class => 'Koha::Acquisition::Orders',
        value  => {
            biblionumber => $source_biblionumber,
            budget_id => $aq_budget->{budget_id},
        },
    });
    my $aq_order_item1 = $builder->build({
        source => 'AqordersItem',
        value  => {
            ordernumber => $aq_order1->ordernumber,
            itemnumber => $itemnumber1,
        },
    });
    my $aq_order2 = $builder->build_object({
        class => 'Koha::Acquisition::Orders',
        value  => {
            biblionumber => $source_biblionumber,
            budget_id => $aq_budget->{budget_id},
        },
    });
    my $aq_order_item2 = $builder->build({
        source => 'AqordersItem',
        value  => {
            ordernumber => $aq_order2->ordernumber,
            itemnumber => $itemnumber2,
        },
    });

    my $bib_level_hold = $builder->build_object({
        class => 'Koha::Holds',
        value  => {
            biblionumber => $source_biblionumber,
            itemnumber => undef,
        },
    });
    my $item_level_hold1 = $builder->build_object({
        class => 'Koha::Holds',
        value  => {
            biblionumber => $source_biblionumber,
            itemnumber => $itemnumber1,
        },
    });
    my $item_level_hold2 = $builder->build_object({
        class => 'Koha::Holds',
        value  => {
            biblionumber => $source_biblionumber,
            itemnumber => $itemnumber2,
        }
    });

    my $tmp_holdsqueue1 = $builder->build({
        source => 'TmpHoldsqueue',
        value  => {
            borrowernumber => $borrowernumber,
            biblionumber   => $source_biblionumber,
            itemnumber     => $itemnumber1,
        }
    });
    my $tmp_holdsqueue2 = $builder->build({
        source => 'TmpHoldsqueue',
        value  => {
            borrowernumber => $borrowernumber,
            biblionumber   => $source_biblionumber,
            itemnumber     => $itemnumber2,
        }
    });
    my $hold_fill_target1 = $builder->build({
        source => 'HoldFillTarget',
        value  => {
            borrowernumber     => $borrowernumber,
            biblionumber       => $source_biblionumber,
            itemnumber         => $itemnumber1,
        }
    });
    my $hold_fill_target2 = $builder->build({
        source => 'HoldFillTarget',
        value  => {
            borrowernumber     => $borrowernumber,
            biblionumber       => $source_biblionumber,
            itemnumber         => $itemnumber2,
        }
    });
    my $linktracker1 = $builder->build({
        source => 'Linktracker',
        value  => {
            borrowernumber     => $borrowernumber,
            biblionumber       => $source_biblionumber,
            itemnumber         => $itemnumber1,
        }
    });
    my $linktracker2 = $builder->build({
        source => 'Linktracker',
        value  => {
            borrowernumber     => $borrowernumber,
            biblionumber       => $source_biblionumber,
            itemnumber         => $itemnumber2,
        }
    });

    my $to_biblionumber_after_move = $item1->move_to_biblio($target_biblio);
    is($to_biblionumber_after_move, $target_biblionumber, 'move_to_biblio returns the target biblionumber if success');

    $to_biblionumber_after_move = $item1->move_to_biblio($target_biblio);
    is($to_biblionumber_after_move, undef, 'move_to_biblio returns undef if the move has failed. If called twice, the item is not attached to the first biblio anymore');

    my $get_item1 = Koha::Items->find( $item1->itemnumber );
    is($get_item1->biblionumber, $target_biblionumber, 'item1 is moved');
    my $get_item2 = Koha::Items->find( $item2->itemnumber );
    is($get_item2->biblionumber, $source_biblionumber, 'item2 is not moved');
    my $get_item3 = Koha::Items->find( $item3->itemnumber );
    is($get_item3->biblionumber, $source_biblionumber, 'item3 is not moved');

    $aq_order1->discard_changes;
    $aq_order2->discard_changes;
    is($aq_order1->biblionumber, $target_biblionumber, 'move_to_biblio moves aq_orders for item 1');
    is($aq_order2->biblionumber, $source_biblionumber, 'move_to_biblio does not move aq_orders for item 2');

    $bib_level_hold->discard_changes;
    $item_level_hold1->discard_changes;
    $item_level_hold2->discard_changes;
    is($bib_level_hold->biblionumber,   $source_biblionumber, 'move_to_biblio does not move the biblio-level hold');
    is($item_level_hold1->biblionumber, $target_biblionumber, 'move_to_biblio moves the item-level hold placed on item 1');
    is($item_level_hold2->biblionumber, $source_biblionumber, 'move_to_biblio does not move the item-level hold placed on item 2');

    my $get_tmp_holdsqueue1 = $schema->resultset('TmpHoldsqueue')->search({ itemnumber => $tmp_holdsqueue1->{itemnumber} })->single;
    my $get_tmp_holdsqueue2 = $schema->resultset('TmpHoldsqueue')->search({ itemnumber => $tmp_holdsqueue2->{itemnumber} })->single;
    is($get_tmp_holdsqueue1->biblionumber->biblionumber, $target_biblionumber, 'move_to_biblio moves tmp_holdsqueue for item 1');
    is($get_tmp_holdsqueue2->biblionumber->biblionumber, $source_biblionumber, 'move_to_biblio does not move tmp_holdsqueue for item 2');

    my $get_hold_fill_target1 = $schema->resultset('HoldFillTarget')->search({ itemnumber => $hold_fill_target1->{itemnumber} })->single;
    my $get_hold_fill_target2 = $schema->resultset('HoldFillTarget')->search({ itemnumber => $hold_fill_target2->{itemnumber} })->single;
    # Why does ->biblionumber return a Biblio object???
    is($get_hold_fill_target1->biblionumber->biblionumber, $target_biblionumber, 'move_to_biblio moves hold_fill_targets for item 1');
    is($get_hold_fill_target2->biblionumber->biblionumber, $source_biblionumber, 'move_to_biblio does not move hold_fill_targets for item 2');

    my $get_linktracker1 = $schema->resultset('Linktracker')->search({ itemnumber => $linktracker1->{itemnumber} })->single;
    my $get_linktracker2 = $schema->resultset('Linktracker')->search({ itemnumber => $linktracker2->{itemnumber} })->single;
    is($get_linktracker1->biblionumber->biblionumber, $target_biblionumber, 'move_to_biblio moves linktracker for item 1');
    is($get_linktracker2->biblionumber->biblionumber, $source_biblionumber, 'move_to_biblio does not move linktracker for item 2');

    $schema->storage->txn_rollback;
};

subtest 'columns_to_str' => sub {
    plan tests => 4;

    $schema->storage->txn_begin;

    my ( $itemtag, $itemsubfield ) = C4::Biblio::GetMarcFromKohaField( "items.itemnumber" );

    my $cache = Koha::Caches->get_instance();
    $cache->clear_from_cache("MarcStructure-0-");
    $cache->clear_from_cache("MarcStructure-1-");
    $cache->clear_from_cache("default_value_for_mod_marc-");
    $cache->clear_from_cache("MarcSubfieldStructure-");

    # Creating subfields 'é', 'è' that are not linked with a kohafield
    Koha::MarcSubfieldStructures->search(
        {
            frameworkcode => '',
            tagfield => $itemtag,
            tagsubfield => ['é', 'è'],
        }
    )->delete;    # In case it exist already

    # é is not linked with a AV
    # è is linked with AV branches
    Koha::MarcSubfieldStructure->new(
        {
            frameworkcode => '',
            tagfield      => $itemtag,
            tagsubfield   => 'é',
            kohafield     => undef,
            repeatable    => 1,
            defaultvalue  => 'ééé',
            tab           => 10,
        }
    )->store;
    Koha::MarcSubfieldStructure->new(
        {
            frameworkcode    => '',
            tagfield         => $itemtag,
            tagsubfield      => 'è',
            kohafield        => undef,
            repeatable       => 1,
            defaultvalue     => 'èèè',
            tab              => 10,
            authorised_value => 'branches',
        }
    )->store;

    my $biblio = $builder->build_sample_biblio({ frameworkcode => '' });
    my $item = $builder->build_sample_item({ biblionumber => $biblio->biblionumber });
    my $lost_av = $builder->build_object({ class => 'Koha::AuthorisedValues', value => { category => 'LOST', authorised_value => '42' }});
    my $dateaccessioned = '2020-12-15';
    my $library = Koha::Libraries->search->next;
    my $branchcode = $library->branchcode;

    my $some_marc_xml = qq{<?xml version="1.0" encoding="UTF-8"?>
<collection
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
  xmlns="http://www.loc.gov/MARC21/slim">

<record>
  <leader>         a              </leader>
  <datafield tag="999" ind1=" " ind2=" ">
    <subfield code="é">value é</subfield>
    <subfield code="è">$branchcode</subfield>
  </datafield>
</record>

</collection>};

    $item->update(
        {
            itemlost           => $lost_av->authorised_value,
            dateaccessioned    => $dateaccessioned,
            more_subfields_xml => $some_marc_xml,
        }
    );

    $item = $item->get_from_storage;

    my $s = $item->columns_to_str;
    is( $s->{itemlost}, $lost_av->lib, 'Attributes linked with AV replaced with description' );
    is( $s->{dateaccessioned}, '2020-12-15', 'Date attributes iso formatted');
    is( $s->{'é'}, 'value é', 'subfield ok with more than a-Z');
    is( $s->{'è'}, $library->branchname );

    $cache->clear_from_cache("MarcStructure-0-");
    $cache->clear_from_cache("MarcStructure-1-");
    $cache->clear_from_cache("default_value_for_mod_marc-");
    $cache->clear_from_cache("MarcSubfieldStructure-");

    $schema->storage->txn_rollback;

};

subtest 'store() tests' => sub {

    plan tests => 1;

    subtest '_set_found_trigger() tests' => sub {

        plan tests => 6;

        $schema->storage->txn_begin;

        my $patron = $builder->build_object({ class => 'Koha::Patrons' });
        my $item   = $builder->build_sample_item({ itemlost => 1, itemlost_on => dt_from_string() });

        # Add a lost item debit
        my $debit = $patron->account->add_debit(
            {
                amount    => 10,
                type      => 'LOST',
                item_id   => $item->id,
                interface => 'intranet',
            }
        );

        my $lostreturn_policy = 'charge';

        my $mocked_circ_rules = Test::MockModule->new('Koha::CirculationRules');
        $mocked_circ_rules->mock( 'get_lostreturn_policy', sub { return $lostreturn_policy; } );

        # simulate it was found
        $item->set( { itemlost => 0 } )->store;

        my $messages = $item->object_messages;

        my $message_1 = $messages->[0];

        is( $message_1->type,    'info',          'type is correct' );
        is( $message_1->message, 'lost_refunded', 'message is correct' );

        # Find the refund credit
        my $credit = $debit->credits->next;

        is_deeply(
            $message_1->payload,
            { credit_id => $credit->id },
            'type is correct'
        );

        my $message_2 = $messages->[1];

        is( $message_2->type,    'info',        'type is correct' );
        is( $message_2->message, 'lost_charge', 'message is correct' );
        is( $message_2->payload, undef,         'no payload' );

        $schema->storage->txn_rollback;
    };
};

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

use Test::More tests => 5;

use t::lib::TestBuilder;
use t::lib::Mocks;

use Koha::Database;

my $schema  = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new;

subtest 'effective_reset_password() tests' => sub {

    plan tests => 2;

    subtest 'specific overrides global' => sub {

        plan tests => 4;

        $schema->storage->txn_begin;

        my $category = $builder->build_object({
            class => 'Koha::Patron::Categories',
            value => {
                reset_password => 1
            }
        });

        t::lib::Mocks::mock_preference( 'OpacResetPassword', 0 );
        ok( $category->effective_reset_password, 'OpacResetPassword unset, but category has the flag set to 1' );

        t::lib::Mocks::mock_preference( 'OpacResetPassword', 1 );
        ok( $category->effective_reset_password, 'OpacResetPassword set and category has the flag set to 1' );

        # disable
        $category->reset_password( 0 )->store->discard_changes;

        t::lib::Mocks::mock_preference( 'OpacResetPassword', 0 );
        ok( !$category->effective_reset_password, 'OpacResetPassword unset, but category has the flag set to 0' );

        t::lib::Mocks::mock_preference( 'OpacResetPassword', 1 );
        ok( !$category->effective_reset_password, 'OpacResetPassword set and category has the flag set to 0' );

        $schema->storage->txn_rollback;
    };

    subtest 'no specific rule, global applies' => sub {

        plan tests => 2;

        $schema->storage->txn_begin;

        my $category = $builder->build_object({
            class => 'Koha::Patron::Categories',
            value => {
                reset_password => undef
            }
        });

        t::lib::Mocks::mock_preference( 'OpacResetPassword', 0 );
        ok( !$category->effective_reset_password, 'OpacResetPassword set to 0 used' );

        t::lib::Mocks::mock_preference( 'OpacResetPassword', 1 );
        ok( $category->effective_reset_password, 'OpacResetPassword set to 1 used' );

        $schema->storage->txn_rollback;
    };
};

subtest 'effective_change_password() tests' => sub {

    plan tests => 2;

    subtest 'specific overrides global' => sub {

        plan tests => 4;

        $schema->storage->txn_begin;

        my $category = $builder->build_object({
            class => 'Koha::Patron::Categories',
            value => {
                change_password => 1
            }
        });

        t::lib::Mocks::mock_preference( 'OpacPasswordChange', 0 );
        ok( $category->effective_change_password, 'OpacPasswordChange unset, but category has the flag set to 1' );

        t::lib::Mocks::mock_preference( 'OpacPasswordChange', 1 );
        ok( $category->effective_change_password, 'OpacPasswordChange set and category has the flag set to 1' );

        # disable
        $category->change_password( 0 )->store->discard_changes;

        t::lib::Mocks::mock_preference( 'OpacPasswordChange', 0 );
        ok( !$category->effective_change_password, 'OpacPasswordChange unset, but category has the flag set to 0' );

        t::lib::Mocks::mock_preference( 'OpacPasswordChange', 1 );
        ok( !$category->effective_change_password, 'OpacPasswordChange set and category has the flag set to 0' );

        $schema->storage->txn_rollback;
    };

    subtest 'no specific rule, global applies' => sub {

        plan tests => 2;

        $schema->storage->txn_begin;

        my $category = $builder->build_object({
            class => 'Koha::Patron::Categories',
            value => {
                change_password => undef
            }
        });

        t::lib::Mocks::mock_preference( 'OpacPasswordChange', 0 );
        ok( !$category->effective_change_password, 'OpacPasswordChange set to 0 used' );

        t::lib::Mocks::mock_preference( 'OpacPasswordChange', 1 );
        ok( $category->effective_change_password, 'OpacPasswordChange set to 1 used' );

        $schema->storage->txn_rollback;
    };
};

subtest 'override_hidden_items() tests' => sub {

    plan tests => 4;

    $schema->storage->txn_begin;

    my $category_1 = $builder->build_object({ class => 'Koha::Patron::Categories' });
    my $category_2 = $builder->build_object({ class => 'Koha::Patron::Categories' });

    t::lib::Mocks::mock_preference( 'OpacHiddenItemsExceptions', $category_1->categorycode . '|' . $category_2->categorycode . '|RANDOM' );

    ok( $category_1->override_hidden_items, 'Category configured to override' );
    ok( $category_2->override_hidden_items, 'Category configured to override' );

    t::lib::Mocks::mock_preference( 'OpacHiddenItemsExceptions', 'RANDOM|' . $category_2->categorycode );

    ok( !$category_1->override_hidden_items, 'Category not configured to override' );
    ok( $category_2->override_hidden_items, 'Category configured to override' );

    $schema->storage->txn_rollback;
};

subtest 'effective_min_password_length' => sub {
  plan tests => 2;

  $schema->storage->txn_begin;

  t::lib::Mocks::mock_preference('minPasswordLength', 3);

  my $category = $builder->build_object({class => 'Koha::Patron::Categories', value => {min_password_length => undef}});

  is($category->effective_min_password_length, 3, 'Patron should have minimum password length from preference');

  $category->min_password_length(10)->store;

  is($category->effective_min_password_length, 10, 'Patron should have minimum password length from category');

  $schema->storage->txn_rollback;
};

subtest 'effective_require_strong_password' => sub {
  plan tests => 2;

  $schema->storage->txn_begin;

  t::lib::Mocks::mock_preference('RequireStrongPassword', 0);

  my $category = $builder->build_object({class => 'Koha::Patron::Categories', value => {require_strong_password => undef}});

  is($category->effective_require_strong_password, 0, 'Patron should be required strong password from preference');

  $category->require_strong_password(1)->store;

  is($category->effective_require_strong_password, 1, 'Patron should be required strong password from category');

  $schema->storage->txn_rollback;
};

#!/usr/bin/perl

# This file is part of Koha.
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

use CGI qw ( -utf8 );

use C4::Koha;
use C4::Biblio qw(
    GetFrameworkCode
    GetMarcBiblio
    GetMarcSeries
    GetMarcSubjects
    GetMarcUrls
);
use C4::Items qw( GetHiddenItemnumbers GetItemsInfo );
use C4::Circulation qw( GetTransfers );
use C4::Auth qw( get_template_and_user );
use C4::Output qw( output_html_with_http_headers );
use Koha::RecordProcessor;
use Koha::CsvProfiles;
use Koha::AuthorisedValues;
use Koha::Biblios;

my $query = CGI->new;

my ( $template, $borrowernumber, $cookie ) = get_template_and_user (
    {
        template_name   => "opac-basket.tt",
        query           => $query,
        type            => "opac",
        authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
    }
);

my $bib_list     = $query->param('bib_list');
my $verbose      = $query->param('verbose');

if ($verbose)      { $template->param( verbose      => 1 ); }

my @bibs = split( /\//, $bib_list );
my @results;

my $num = 1;
my $marcflavour = C4::Context->preference('marcflavour');
if (C4::Context->preference('TagsEnabled')) {
	$template->param(TagsEnabled => 1);
	foreach (qw(TagsShowOnList TagsInputOnList)) {
		C4::Context->preference($_) and $template->param($_ => 1);
	}
}

my $borcat = q{};
if ( C4::Context->preference('OpacHiddenItemsExceptions') ) {
    # we need to fetch the borrower info here, so we can pass the category
    my $patron = Koha::Patrons->find($borrowernumber);
    $borcat = $patron ? $patron->categorycode : $borcat;
}

my $record_processor = Koha::RecordProcessor->new({ filters => 'ViewPolicy' });
my $rules = C4::Context->yaml_preference('OpacHiddenItems');

foreach my $biblionumber ( @bibs ) {
    $template->param( biblionumber => $biblionumber );

    my $biblio           = Koha::Biblios->find( $biblionumber ) or next;
    my $dat              = $biblio->unblessed;

    # No filtering on the item records needed for the record itself
    # since the only reason item information is grabbed is because of branchcodes.
    my $record = &GetMarcBiblio({ biblionumber => $biblionumber });
    my $framework = &GetFrameworkCode( $biblionumber );
    $record_processor->options({
        interface => 'opac',
        frameworkcode => $framework
    });
    $record_processor->process($record);
    next unless $record;
    my $marcnotesarray   = $biblio->get_marc_notes({ marcflavour => $marcflavour, opac => 1 });
    my $marcauthorsarray = $biblio->get_marc_authors;
    my $marcsubjctsarray = GetMarcSubjects( $record, $marcflavour );
    my $marcseriesarray  = GetMarcSeries  ($record,$marcflavour);
    my $marcurlsarray    = GetMarcUrls    ($record,$marcflavour);

    # grab all the items...
    my @all_items        = &GetItemsInfo( $biblionumber );

    # determine which ones should be hidden / visible
    my @hidden_items     = GetHiddenItemnumbers({ items => \@all_items, borcat => $borcat });

    # If every item is hidden, then the biblio should be hidden too.
    next
      if $biblio->hidden_in_opac({ rules => $rules });

    # copy the visible ones into the items array.
    my @items;
    foreach my $item (@all_items) {

            # next if item is hidden
            next  if  grep  { $item->{itemnumber} eq $_  } @hidden_items ;

            my $reserve_status = C4::Reserves::GetReserveStatus($item->{itemnumber});
            if( $reserve_status eq "Waiting"){ $item->{'waiting'} = 1; }
            if( $reserve_status eq "Reserved"){ $item->{'onhold'} = 1; }
            push @items, $item;
    }

    my $hasauthors = 0;
    if($dat->{'author'} || @$marcauthorsarray) {
      $hasauthors = 1;
    }
    my $collections =
      { map { $_->{authorised_value} => $_->{opac_description} } Koha::AuthorisedValues->get_descriptions_by_koha_field( { frameworkcode => $dat->{frameworkcode}, kohafield => 'items.ccode' } ) };
    my $shelflocations =
      { map { $_->{authorised_value} => $_->{opac_description} } Koha::AuthorisedValues->get_descriptions_by_koha_field( { frameworkcode => $dat->{frameworkcode}, kohafield => 'items.location' } ) };

	# COinS format FIXME: for books Only
        my $fmt = substr $record->leader(), 6,2;
        my $fmts;
        $fmts->{'am'} = 'book';
        $dat->{ocoins_format} = $fmts->{$fmt};

    if ( $num % 2 == 1 ) {
        $dat->{'even'} = 1;
    }

    for my $itm (@items) {
        if ($itm->{'location'}){
            $itm->{'location_opac'} = $shelflocations->{$itm->{'location'} };
        }
        my ( $transfertwhen, $transfertfrom, $transfertto ) = GetTransfers($itm->{itemnumber});
        if ( defined( $transfertwhen ) && $transfertwhen ne '' ) {
             $itm->{transfertwhen} = $transfertwhen;
             $itm->{transfertfrom} = $transfertfrom;
             $itm->{transfertto}   = $transfertto;
        }
    }
    $num++;
    $dat->{biblionumber} = $biblionumber;
    $dat->{ITEM_RESULTS}   = \@items;
    $dat->{MARCNOTES}      = $marcnotesarray;
    $dat->{MARCSUBJCTS}    = $marcsubjctsarray;
    $dat->{MARCAUTHORS}    = $marcauthorsarray;
    $dat->{MARCSERIES}  = $marcseriesarray;
    $dat->{MARCURLS}    = $marcurlsarray;
    $dat->{HASAUTHORS}  = $hasauthors;

    if ( C4::Context->preference("BiblioDefaultView") eq "normal" ) {
        $dat->{dest} = "opac-detail.pl";
    }
    elsif ( C4::Context->preference("BiblioDefaultView") eq "marc" ) {
        $dat->{dest} = "opac-MARCdetail.pl";
    }
    else {
        $dat->{dest} = "opac-ISBDdetail.pl";
    }
    push( @results, $dat );
}

my $resultsarray = \@results;

# my $itemsarray=\@items;

$template->param(
    csv_profiles => Koha::CsvProfiles->search(
        { type => 'marc', used_for => 'export_records', staff_only => 0 } ),
    bib_list => $bib_list,
    BIBLIO_RESULTS => $resultsarray,
);

output_html_with_http_headers $query, $cookie, $template->output, undef, { force_no_caching => 1 };

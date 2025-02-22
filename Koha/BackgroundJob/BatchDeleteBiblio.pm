package Koha::BackgroundJob::BatchDeleteBiblio;

use Modern::Perl;
use JSON qw( encode_json decode_json );

use Koha::BackgroundJobs;
use Koha::DateUtils qw( dt_from_string );
use C4::Biblio;

use base 'Koha::BackgroundJob';

=head1 NAME

Koha::BackgroundJob::BatchDeleteBiblio - Batch delete bibliographic records

This is a subclass of Koha::BackgroundJob.

=head1 API

=head2 Class methods

=head3 job_type

Define the job type of this job: batch_biblio_record_deletion

=cut

sub job_type {
    return 'batch_biblio_record_deletion';
}

=head3 process

Process the job.

=cut

sub process {
    my ( $self, $args ) = @_;

    my $job_type = $args->{job_type};

    my $job = Koha::BackgroundJobs->find( $args->{job_id} );

    if ( !exists $args->{job_id} || !$job || $job->status eq 'cancelled' ) {
        return;
    }

    # FIXME If the job has already been started, but started again (worker has been restart for instance)
    # Then we will start from scratch and so double delete the same records

    my $job_progress = 0;
    $job->started_on(dt_from_string)
        ->progress($job_progress)
        ->status('started')
        ->store;

    my $mmtid = $args->{mmtid};
    my @record_ids = @{ $args->{record_ids} };

    my $report = {
        total_records => scalar @record_ids,
        total_success => 0,
    };
    my @messages;
    my $schema = Koha::Database->new->schema;
    RECORD_IDS: for my $record_id ( sort { $a <=> $b } @record_ids ) {

        last if $job->get_from_storage->status eq 'cancelled';

        next unless $record_id;

        $schema->storage->txn_begin;

        my $biblionumber = $record_id;
        # First, checking if issues exist.
        # If yes, nothing to do
        my $biblio = Koha::Biblios->find( $biblionumber );

        # TODO Replace with $biblio->get_issues->count
        if ( C4::Biblio::CountItemsIssued( $biblionumber ) ) {
            push @messages, {
                type => 'warning',
                code => 'item_issued',
                biblionumber => $biblionumber,
            };
            $schema->storage->txn_rollback;
            $job->progress( ++$job_progress )->store;
            next;
        }

        # Cancel reserves
        my $holds = $biblio->holds;
        while ( my $hold = $holds->next ) {
            eval{
                $hold->cancel;
            };
            if ( $@ ) {
                push @messages, {
                    type => 'error',
                    code => 'reserve_not_cancelled',
                    biblionumber => $biblionumber,
                    reserve_id => $hold->reserve_id,
                    error => "$@",
                };
                $schema->storage->txn_rollback;
                $job->progress( ++$job_progress )->store;
                next RECORD_IDS;
            }
        }

        # Delete items
        my $items = Koha::Items->search({ biblionumber => $biblionumber });
        while ( my $item = $items->next ) {
            my $deleted = $item->safe_delete;
            if( $deleted ) {
                push @messages, {
                    type => 'error',
                    code => 'item_not_deleted',
                    biblionumber => $biblionumber,
                    itemnumber => $item->itemnumber,
                    error => @{$deleted->messages}[0]->message,
                };
                $schema->storage->txn_rollback;
                $job->progress( ++$job_progress )->store;
                next RECORD_IDS;
            }
        }

        # Finally, delete the biblio
        my $error = eval {
            C4::Biblio::DelBiblio( $biblionumber );
        };
        if ( $error or $@ ) {
            push @messages, {
                type => 'error',
                code => 'biblio_not_deleted',
                biblionumber => $biblionumber,
                error => ($@ ? $@ : $error),
            };
            $schema->storage->txn_rollback;
            $job->progress( ++$job_progress )->store;
            next;
        }

        push @messages, {
            type => 'success',
            code => 'biblio_deleted',
            biblionumber => $biblionumber,
        };
        $report->{total_success}++;
        $schema->storage->txn_commit;
        $job->progress( ++$job_progress )->store;
    }

    my $job_data = decode_json $job->data;
    $job_data->{messages} = \@messages;
    $job_data->{report} = $report;

    $job->ended_on(dt_from_string)
        ->data(encode_json $job_data);
    $job->status('finished') if $job->status ne 'cancelled';
    $job->store;
}

=head3 enqueue

Enqueue the new job

=cut

sub enqueue {
    my ( $self, $args) = @_;

    # TODO Raise exception instead
    return unless exists $args->{record_ids};

    my @record_ids = @{ $args->{record_ids} };

    $self->SUPER::enqueue({
        job_size => scalar @record_ids,
        job_args => {record_ids => \@record_ids,}
    });
}

1;

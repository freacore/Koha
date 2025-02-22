[% BLOCK report %]
    [% SET report = job.report %]
    [% IF report %]
        [% IF report.total_records == report.total_success %]
            <div class="dialog message">
                All records have been deleted successfully!
            </div>
        [% ELSIF report.total_success == 0 %]
            <div class="dialog message">
                No record has been deleted. An error occurred.
            </div>
        [% ELSE %]
            <div class="dialog message">
                [% report.total_success | html %] / [% report.total_records | html %] records have been deleted successfully but some errors occurred.
            </div>
        [% END %]
    [% END %]
[% END %]

[% BLOCK detail %]
    [% FOR m IN job.messages %]
        <div class="dialog message">
            [% IF m.type == 'success' %]
                <i class="fa fa-check success"></i>
            [% ELSIF m.type == 'warning' %]
                <i class="fa fa-warning warn"></i>
            [% ELSIF m.type == 'error' %]
                <i class="fa fa-exclamation error"></i>
            [% END %]
            [% IF m.code == 'authority_not_exists' %]
                The authority id [% m.authid | html %] does not exist in the database.
            [% ELSIF m.code == 'authority_not_deleted' %]
                Authority record [% m.authid | html %] was not deleted. An error occurred.
            [% ELSIF m.code == 'authority_deleted' %]
                Authority [% m.authid | html %] has been deleted successfully.
            [% END %]
        </div>
    [% END %]
[% END %]

[% BLOCK js %]
[% END %]

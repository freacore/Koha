[% USE Koha %]
[% SET hold_cancellation = AuthorisedValues.GetAuthValueDropbox('HOLD_CANCELLATION') %]
[% USE AuthorisedValues %]
<table class="holds_table">
    <tr>
        <th><input type="checkbox" class="select_hold_all"/></th>
        [% IF ( CAN_user_reserveforothers_modify_holds_priority ) %]
            <th>Priority</th>
            <th>&nbsp;</th>
        [% ELSE %]
            <th>Delete?</th>
        [% END %]
        <th>Patron</th>
        <th>Notes</th>
        <th>Date</th>
        <th>Expiration</th>
        <th>Pickup library</th>
        <th>Details</th>
        [% IF ( CAN_user_reserveforothers_modify_holds_priority ) %]
            <th><img src="[% interface | html %]/[% theme | html %]/img/go-bottom.png" alt="Toggle set to lowest priority" /></th>
        [% END %]
        <th>&nbsp;</th>
        <th>&nbsp;</th>
    </tr>
    [%- SET first_priority = 0 -%]
    [%- SET found_holds = 0 -%]
    [%- SET last_priority  = holds.last.priority -%]

    [% BLOCK priority_dropdown %]
        [%- SET loop_priority = 1 -%]
        [%- WHILE loop_priority <= last_priority -%]
            [%- IF this_priority == loop_priority -%]
                <option value="[% loop_priority | html %]" selected="selected">[% loop_priority | html %]</option>
            [%- ELSE -%]
                <option value="[% loop_priority | html %]">[% loop_priority | html %]</option>
            [%- END -%]
            [%- loop_priority = loop_priority + 1- %]
        [%- END -%]
    [% END %]

    [% FOREACH hold IN holds %]
    [%- IF !hold.found && first_priority == 0 -%]
        [%- first_priority = hold.priority -%]
        [%- found_holds = loop.index() -%]
    [%- END -%]
    [%- IF Koha.Preference('HoldsSplitQueueNumbering') == 'actual' -%]
        [%- this_priority = hold.priority -%]
    [%- ELSE -%]
        [%- this_priority = loop.count() - found_holds -%]
    [%- END -%]
        <tr>
            <th><input type="checkbox" class="select_hold" data-id="[% hold.reserve_id | html %]"/></th>
            <td>
                <input type="hidden" name="reserve_id" value="[% hold.reserve_id | html %]" />
                <input type="hidden" name="borrowernumber" value="[% hold.borrowernumber | html %]" />
                <input type="hidden" name="biblionumber" value="[% hold.biblionumber | html %]" />
                [% IF Koha.Preference('HoldsSplitQueue') == "nothing" && !hold.found %]
                    <select name="rank-request" class="rank-request" data-hold-id="[% hold.reserve_id | html %]">
                    [% IF ( CAN_user_reserveforothers_modify_holds_priority ) %]
                        [% PROCESS priority_dropdown %]
                    [% ELSE %]
                        <option value="[% hold.priority | html %]" selected="selected">[% this_priority | html %]</option>
                    [% END %]
                        <option value="del">del</option>
                    </select>
                [% ELSE %]
                    <input type="hidden" name="rank-request" class="rank-request" value="[% hold.priority | html %]" data-hold-id="[% hold.reserve_id | html %]">
                    <select name="rank-request" class="rank-request" disabled="disabled" data-hold-id="[% hold.reserve_id | html %]">
                    [% IF ( hold.found ) %]
                        [% IF ( hold.intransit ) %]
                            <option value="T" selected="selected">In transit</option>
                        [% ELSIF (hold.inprocessing) %]
                            <option value="P" selected="selected">In processing</option>
                        [% ELSE %]
                            <option value="W" selected="selected">Waiting</option>
                        [% END %]
                    [% ELSE %]
                        <option value="[% hold.priority | html %]" selected="selected">[% this_priority | html %]</option>
                    [% END %]
                    </select>
                [% END %]
            </td>
            [%- IF ( CAN_user_reserveforothers_modify_holds_priority ) -%]
            [%- UNLESS hold.found -%]
                    [%- SET prev_priority  = loop.prev.priority -%]
                    [%- SET next_priority  = loop.next.priority -%]
                    <td style="white-space:nowrap;">
                        <a title="Move hold up" href="request.pl?action=move&amp;where=up&amp;first_priority=[% first_priority | html %]&amp;last_priority=[% last_priority | html %]&amp;prev_priority=[% prev_priority | html %]&amp;next_priority=[% next_priority | html %]&amp;borrowernumber=[% hold.borrowernumber | html %]&amp;biblionumber=[% hold.biblionumber | html %]&amp;reserve_id=[% hold.reserve_id | html %]&amp;date=[% hold.date | html %]">
                            <img src="[% interface | html %]/[% theme | html %]/img/go-up.png" alt="Go up" />
                        </a>
                        <a title="Move hold to top" href="request.pl?action=move&amp;where=top&amp;first_priority=[% first_priority | html %]&amp;last_priority=[% last_priority | html %]&amp;prev_priority=[% prev_priority | html %]&amp;next_priority=[% next_priority | html %]&amp;borrowernumber=[% hold.borrowernumber | html %]&amp;biblionumber=[% hold.biblionumber | html %]&amp;reserve_id=[% hold.reserve_id | html %]&amp;date=[% hold.date | html %]">
                            <img src="[% interface | html %]/[% theme | html %]/img/go-top.png" alt="Go top" />
                        </a>
                        <a title="Move hold to bottom" href="request.pl?action=move&amp;where=bottom&amp;first_priority=[% first_priority | html %]&amp;last_priority=[% last_priority | html %]&amp;prev_priority=[% prev_priority | html %]&amp;next_priority=[% next_priority | html %]&amp;borrowernumber=[% hold.borrowernumber | html %]&amp;biblionumber=[% hold.biblionumber | html %]&amp;reserve_id=[% hold.reserve_id | html %]&amp;date=[% hold.date | html %]">
                            <img src="[% interface | html %]/[% theme | html %]/img/go-bottom.png" alt="Go bottom" />
                        </a>
                        <a title="Move hold down" href="request.pl?action=move&amp;where=down&amp;first_priority=[% first_priority | html %]&amp;last_priority=[% last_priority | html %]&amp;prev_priority=[% prev_priority | html %]&amp;next_priority=[% next_priority | html %]&amp;borrowernumber=[% hold.borrowernumber | html %]&amp;biblionumber=[% hold.biblionumber | html %]&amp;reserve_id=[% hold.reserve_id | html %]&amp;date=[% hold.date | html %]">
                            <img src="[% interface | html %]/[% theme | html %]/img/go-down.png" alt="Go down" />
                        </a>
                    </td>
        [%- ELSE -%]
            <td></td>
        [%- END -%]
            [%- END -%]
            <td>
                [% INCLUDE 'patron-title.inc' patron=hold.patron hide_patron_infos_if_needed=1 %]
            </td>
            <td>[% hold.notes | html | html_line_break %]</td>
            <td>
                [% IF Koha.Preference('AllowHoldDateInFuture') %]
                    <input type="text" class="flatpickr" value="[% hold.date | $KohaDates %]" required="required" size="10" name="reservedate" />
                [% ELSE %]
                    [% hold.date | $KohaDates %]
                [% END %]
            </td>
            <td>
                <input type="text" class="flatpickr" data-flatpickr-futuredate="true" value="[% hold.expirationdate | $KohaDates %]" size="10" name="expirationdate" />
            </td>
            <td>
                [%- IF ( hold.found ) -%]
                    [%- IF ( hold.atdestination ) -%]
                            Item waiting at <strong> [% hold.wbrname | html %]</strong>[% IF hold.desk_name %], [% hold.desk_name | html %],[% END %] <input type="hidden" name="pickup" value="[% hold.wbrcode | html %]" /> since [% hold.waiting_date | $KohaDates %]
                    [%- ELSIF (hold.intransit) -%]
                        Item being transferred to <strong> [% hold.wbrname | html %]</strong> <input type="hidden" name="pickup" value="[% hold.wbrcode | html %]" />
                    [%- ELSIF (hold.inprocessing) -%]
                        Item being processed at <strong> [% hold.wbrname | html %]</strong> <input type="hidden" name="pickup" value="[% hold.wbrcode | html %]" />
                    [%- END -%]
                [%- ELSE -%]
                    [%- IF Koha.Preference('IndependentBranches') && Branches.all().size == 1 -%]
                        [% Branches.GetName(hold.branchcode) | html %] <input type="hidden" name="pickup" value="[% hold.branchcode | html %]" />
                    [%- ELSE -%]
                        <select class="pickup_location_dropdown"
                                data-selected="[% hold.branchcode | html %]"
                                data-hold-id="[% hold.reserve_id | html %]"
                                data-pickup-location-source="hold"
                                name="pickup">
                            <option selected="selected" value="[% hold.branchcode | html %]">[% Branches.GetName(hold.branchcode) | html %]</option>
                            <option value="" disabled="disabled" class="loading">Loading...</option>
                        </select>
                        <img class="loading_[% hold.reserve_id | html %]" src="[% interface | html %]/[% theme | html %]/img/spinner-small.gif" alt="" style="display:none;"/>
                    [%- END -%]
                [%- END -%]
            </td>
            <td>
                [%- IF ( hold.found ) -%]
                    <a href="/cgi-bin/koha/catalogue/moredetail.pl?biblionumber=[% hold.biblionumber | uri %]&amp;itemnumber=[% hold.itemnumber | uri %]#item[% hold.itemnumber | uri %]">
                        [%- IF ( hold.barcodenumber ) -%]
                            [%- hold.barcodenumber | html -%]
                            <input type="hidden" name="itemnumber" value="[% hold.itemnumber | html %]" />
                        [%- ELSE -%]
                            No barcode
                        [%- END -%]
                    </a>
                [%- ELSE -%]
                    [%- IF ( hold.item_level_hold ) -%]
                        <em>
                            Only item
                            <a href="/cgi-bin/koha/catalogue/moredetail.pl?biblionumber=[% hold.biblionumber | uri %]&amp;itemnumber=[% hold.itemnumber | uri %]#item[% hold.itemnumber | uri %]">
                                [%- IF ( hold.barcodenumber ) -%]
                                    [%- hold.barcodenumber | html -%]
                                    <input type="hidden" name="itemnumber" value="[% hold.itemnumber | html %]" />
                                [%- ELSE -%]
                                    No barcode
                                [%- END -%]
                            </a>
                        </em>
                    [%- ELSE -%]
                        [%- IF hold.itemtype -%]
                            <em>Next available [% ItemTypes.GetDescription( hold.itemtype ) | html %] item</em>
                        [%- ELSE -%]
                            <em>Next available</em>
                        [%- END -%]

                        <input type="hidden" name="itemnumber" value="" />
                    [%- END -%]
                [%- END -%]
                [%- IF hold.non_priority -%]
                    <br><i>Non priority hold</i>
                [%- END -%]
            </td>
            [%- IF ( CAN_user_reserveforothers_modify_holds_priority ) -%]
            [%- UNLESS hold.found -%]
                    <td>
                        <a title="Toggle lowest priority" href="request.pl?action=setLowestPriority&amp;borrowernumber=[% hold.borrowernumber | html %]&amp;biblionumber=[% hold.biblionumber | html %]&amp;reserve_id=[% hold.reserve_id | html %]&amp;date=[% hold.date | html %]">
                            [%- IF ( hold.lowestPriority ) -%]
                                <img src="[% interface | html %]/[% theme | html %]/img/go-bottom.png" alt="Unset lowest priority" />
                            [%- ELSE -%]
                                <img src="[% interface | html %]/[% theme | html %]/img/go-down.png" alt="Set to lowest priority" />
                            [%- END -%]
                        </a>
                    </td>
        [%- ELSE -%]
            <td></td>
        [%- END -%]
            [%- END -%]
            <td>
                <a class="btn btn-default btn-xs cancel-hold" data-borrowernumber="[% hold.borrowernumber | html %]" data-biblionumber="[% hold.biblionumber | html %]" data-id="[% hold.reserve_id | html %]" href="request.pl?action=cancel&amp;borrowernumber=[% hold.borrowernumber | html %]&amp;biblionumber=[% hold.biblionumber | html %]&amp;reserve_id=[% hold.reserve_id | html %]&amp;date=[% hold.date | html %]">
                    <i class="fa fa-trash" aria-hidden="true"></i> Cancel
                </a>
            </td>
            <td>
                [% IF Koha.Preference('SuspendHoldsIntranet') %]
                    [% UNLESS ( hold.found ) %]
                        <button class="btn btn-default btn-xs toggle-suspend" data-reserve-id="[% hold.reserve_id | html %]" data-biblionumber="[% hold.biblionumber | html %]">
                            [% IF ( hold.suspend ) %]
                                <i class="fa fa-play" aria-hidden="true"></i> Unsuspend
                            [% ELSE %]
                                <i class="fa fa-pause" aria-hidden="true"></i> Suspend
                            [% END %]
                        </button>

                        [% IF Koha.Preference('AutoResumeSuspendedHolds') %]
                            <label for="suspend_until_[% hold.reserve_id | html %]">[% IF ( hold.suspend ) %] on [% ELSE %] until [% END %]</label>
                            <input type="text" name="suspend_until_[% hold.reserve_id | html %]" id="suspend_until_[% hold.reserve_id | html %]" size="10" value="[% hold.suspend_until | $KohaDates %]" class="flatpickr" data-flatpickr-futuredate="true" />
                        [%- ELSE -%]
                            <input type="hidden" name="suspend_until_[% hold.reserve_id | html %]" id="suspend_until_[% hold.reserve_id | html %]" value=""/>
                        [%- END -%]
                    [%- END -%]
                [%- END # IF SuspendHoldsIntranet -%]
                [%- IF ( hold.found ) -%]
                    <input type="button" id="revert_hold_[% hold.reserve_id | html %]" value="[% IF hold.intransit %]Revert transit status[% ELSE %]Revert waiting status[% END %]" onclick="window.location.href='request.pl?action=move&amp;where=down&amp;first_priority=[% first_priority | uri %]&amp;last_priority=[% last_priority | uri %]&amp;prev_priority=0&amp;next_priority=1&amp;borrowernumber=[% hold.borrowernumber | uri %]&amp;biblionumber=[% hold.biblionumber | uri %]&amp;itemnumber=[% hold.itemnumber | uri %]&amp;reserve_id=[% hold.reserve_id | uri %]&amp;date=[% hold.date | uri %]'">
                [%- END -%]
            </td>
        </tr>
    [% END %]
</table>

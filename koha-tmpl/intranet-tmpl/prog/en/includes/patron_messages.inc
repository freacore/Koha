[% SET ClaimReturnedWarningThreshold = Koha.Preference('ClaimReturnedWarningThreshold') %]
[% SET return_claims = patron.return_claims %]

[% IF ( has_modifications || warndeparture || returnbeforeexpiry || expired || patron.gonenoaddress || patron.lost || userdebarred || odues || ( return_claims.count > ClaimReturnedWarningThreshold ) || age_limitations || charges || charges_guarantors_guarantees || charges_guarantees || credits ) %]
    <h3>Attention</h3>
    <ul>
        [% IF ( has_modifications ) %]
            <li class="has_modifications">
                <span class="circ-hlt">Pending modifications:</span>
                [% IF CAN_user_borrowers_edit_borrowers && ( !Koha.Preference('IndependentBranchesPatronModifications') || borrower.branch == branch ) %]
                    <a href="/cgi-bin/koha/members/members-update.pl?active=[% patron.borrowernumber | uri %]">Review pending modifications</a>
                [% ELSE %]
                    Patron has pending modifications
                [% END %]
            </li>
        [% END %]

        [% IF ( warndeparture ) %]
            <li class="warndeparture">
                <span class="circ-hlt">Expiration:</span> Patron's card will expire soon.
                Patron's card expires on [% expiry | $KohaDates %] <a href="/cgi-bin/koha/members/setstatus.pl?borrowernumber=[% patron.borrowernumber | uri %]&amp;destination=circ&amp;reregistration=y">Renew</a> or <a href="/cgi-bin/koha/members/memberentry.pl?op=modify&amp;destination=circ&amp;borrowernumber=[% patron.borrowernumber | html %]">Edit details</a>

            </li>
        [% END %]

        [% IF ( returnbeforeexpiry ) %]
            <li class="returnbeforeexpiry">
                <span class="circ-hlt">Set due date to expiry:</span> You have the ReturnBeforeExpiry system preference enabled this means if the expiry date is before the date due, the date due will be set to the expiry date
            </li>
        [% END %]

        [% IF ( expired ) %]
            <li class="expired">
                <span class="circ-hlt">Expiration:</span> Patron's card has expired.
                [% IF ( expiry ) %]
                    Patron's card expired on [% expiry | $KohaDates %]
                [% END %]
                <a href="/cgi-bin/koha/members/setstatus.pl?borrowernumber=[% patron.borrowernumber | uri %]&amp;destination=circ&amp;reregistration=y">Renew</a> or <a href="/cgi-bin/koha/members/memberentry.pl?op=modify&amp;destination=circ&amp;borrowernumber=[% patron.borrowernumber | html %]">Edit details</a>
            </li>
        [% END %]

        [% IF ( patron.gonenoaddress ) %]
            <li class="gonenoaddress blocker">
                <span class="circ-hlt">Address:</span> Patron's address in doubt
            </li>
        [% END %]

        [% IF ( patron.lost ) %]
            <li class="lost blocker">
                <span class="circ-hlt">Lost: </span> Patron's card is lost
            </li>
        [% END %]

        [% IF ( userdebarred ) %]
            <li class="userdebarred blocker">
                <span class="circ-hlt"> Restricted:</span> Patron's account is restricted

                [% IF ( userdebarreddate ) %]
                    until [% userdebarreddate | $KohaDates %]
                [% END %]

                [% IF ( debarredcomment ) %]
                    with the explanation: <br/>
                    <em>
                        [% IF debarredcomment.search('OVERDUES_PROCESS') %]
                            Restriction added by overdues process [% debarredcomment.remove('OVERDUES_PROCESS ') | $raw | html_line_break %]
                        [% ELSE %]
                            [% debarredcomment | $raw | html_line_break %]
                        [% END %]
                    </em><br/>
                [% END %]
                <a class="btn btn-xs btn-default" href="#reldebarments" onclick="$('#debarments-tab-link').click()"><i class="fa fa-ban"></i> View restrictions</a>

                [% IF (noissues && CAN_user_circulate_force_checkout) %]
                    <span class="override_debarment">
                        <a href="/cgi-bin/koha/circ/circulation.pl?forceallow=1&amp;borrowernumber=[% patron.borrowernumber | uri %]" class="btn btn-xs btn-default">Override restriction temporarily</a>
                    </span>
                [% END %]
            </li> <!-- /.blocker -->
        [% END # /IF userdebarred %]

        [% IF ( odues ) %]
            <li class="odues blocker">
                <span class="circ-hlt">Overdues:</span>  Patron has ITEMS OVERDUE <a href="#checkouts">See highlighted items below</a>
            </li>
        [% END %]

        [% IF return_claims.count > ClaimReturnedWarningThreshold %]
            <li class="return_claims blocker">
                <span class="circ-hlt return-claims">Return claims:</span> Patron has [% return_claims.count | html %] RETURN CLAIMS
            </li>
        [% END %]

        [% IF age_limitations %]
            [% INCLUDE 'category-out-of-age-limit.inc' %]
        [% END %]

        [% IF ( charges ) %]
            [% INCLUDE 'blocked-fines.inc' fines = chargesamount %]
        [% END %]

        [% IF ( charges_guarantors_guarantees ) %]
            <li class="charges_guarantors_guarantees">
                <span class="circ-hlt">Charges:</span> Patron's guarantors and their other guarantees collectively owe [% charges_guarantors_guarantees | $Price %].
                [% IF noissues %]
                    <span class="circ-hlt">Checkouts are BLOCKED because fine balance is OVER THE LIMIT.</span>
                [% END %]
            </li>
        [% END %]

        [% IF ( charges_guarantees ) %]
            <li class="charges_guarantees">
                <span class="circ-hlt">Charges:</span> Patron's guarantees collectively owe [% chargesamount_guarantees | $Price %].
                    [% IF noissues %]
                        <span class="circ-hlt">Checkouts are BLOCKED because fine balance is OVER THE LIMIT.</span>
                    [% END %]
            </li>
        [% END %]

        [% IF ( credits ) %]
            <li class="credits">
                <span class="circ-hlt">Credits:</span> Patron has a credit[% IF ( creditsamount ) %] of <span class="credit"><strong>[% creditsamount | $Price %]</strong></span>[% END %]
            </li>
        [% END %]

    </ul>

[% END # /F ( has_modifications || warndeparture... %]


[% IF WaitingHolds.count %]
    <div id="holdswaiting" class="circmessage">
        [% SET waiting_here = 0 %]
        [% SET waiting_elsewhere = 0 %]
        [% FOREACH w IN WaitingHolds %]
            [% IF ( w.branch.branchcode == Branches.GetLoggedInBranchcode()  ) %]
                [% waiting_here = waiting_here + 1 %]
            [% ELSE %]
                [% waiting_elsewhere = waiting_elsewhere + 1 %]
            [% END %]
        [% END %]

        [% IF ( waiting_here > 0 ) %]
            <h4>Holds waiting here ([% waiting_here | html %])</h4>
            <ul>
                [% FOREACH w IN WaitingHolds %]
                    [% IF ( w.branch.branchcode == Branches.GetLoggedInBranchcode()  ) %]
                        <li>
                            <a href="/cgi-bin/koha/reserve/request.pl?biblionumber=[% w.biblio.biblionumber | uri %]">[% w.biblio.title | html %]</a>
                            ([% ItemTypes.GetDescription( w.item.effective_itemtype ) | html %]),
                            [% IF ( w.biblio.author ) %] by [% w.biblio.author | html %] [% END %]
                            [% IF ( w.item.itemcallnumber ) %] [[% w.item.itemcallnumber | html %]] [% END %]
                            Hold placed on [% w.reservedate | $KohaDates %].
                            <br />
                            <strong class="waitinghere">
                                [% SET expires_on = w.expirationdate %]
                                Waiting here [% IF expires_on %] until [% expires_on | $KohaDates %] [% END %]
                            </strong>
                        </li>
                    [% END %]
                [% END %]
            </ul>
        [% END %]

        [% IF ( waiting_elsewhere > 0 ) %]
            <h4>Holds waiting at other libraries ([% waiting_elsewhere | html %])</h4>
            <ul>
                [% FOREACH w IN WaitingHolds %]
                    [% IF ( w.branch.branchcode != Branches.GetLoggedInBranchcode()  ) %]
                        <li>
                            <a href="/cgi-bin/koha/reserve/request.pl?biblionumber=[% w.biblio.biblionumber | uri %]">[% w.biblio.title | html %]</a>
                            ([% ItemTypes.GetDescription( w.item.effective_itemtype ) | html %]),
                            [% IF ( w.biblio.author ) %] by [% w.biblio.author | html %] [% END %]
                            [% IF ( w.item.itemcallnumber ) %] [[% w.item.itemcallnumber | html %]] [% END %]
                            Hold placed on [% w.reservedate | $KohaDates %].
                            <br />
                            <strong>
                                [% SET expires_on = w.expirationdate %]
                                Waiting at [% w.branch.branchname | html %] [% IF expires_on %] until [% expires_on | $KohaDates %] [% END %]
                            </strong>
                        </li>
                    [% END %]
                [% END %]
            </ul>
        [% END %]
    </div>
[% END # /IF WaitingHolds.count %]

[% IF ( patron.borrowernotes ) %]
    <div id="circnotes" class="circmessage">
        <h4>Notes</h4>
        <ul>
            <li>
                <span class="circ-hlt">
                    [% patron.borrowernotes | $raw | html_line_break %]
                </span>
            </li>
        </ul>
    </div> <!-- /#circnotes -->
[% END # /IF patron.borrowernotes %]

[% IF ( patron_messages ) %]
    <div id="messages" class="circmessage">
        <h4>Messages</h4>
        <ul>
            [% FOREACH patron_message IN patron_messages %]
                <li>
                    [% IF(patron_message.message_type == "L") %]
                        <span class="circ-hlt">
                    [% ELSE %]
                        <span>
                    [% END %]
                        [% patron_message.message_date | $KohaDates %]
                        [% Branches.GetName( patron_message.branchcode ) | html %]
                        [% IF patron_message.manager_id %]
                            ( <a href="/cgi-bin/koha/members/moremember.pl?borrowernumber=[% patron_message.manager_id | uri %]">[% patron_message.get_column('manager_firstname') | html %] [% patron_message.get_column('manager_surname') | html %]</a> )
                        [% END %]
                        <em>"[% patron_message.message | html %]"</em>
                    </span>
                    [% IF patron_message.branchcode == Branches.GetLoggedInBranchcode OR Koha.Preference('AllowAllMessageDeletion') %]
                        <a class="btn btn-link" href="/cgi-bin/koha/circ/del_message.pl?message_id=[% patron_message.message_id | html %]&amp;borrowernumber=[% patron_message.borrowernumber | html %]&amp;from=moremember" onclick='return confirm(_("Are you sure you want to delete this message? This cannot be undone."));'><i class="fa fa-trash"></i> Delete</a>
                    [% END %]
                </li>
            [% END %]
        </ul>
        <a id="addnewmessageLabel" href="#add_message_form" class="btn btn-link" data-toggle="modal"><i class="fa fa-plus"></i> Add a new message</a>
    </div> <!-- /#messages -->
[% END # /IF patron_messages %]

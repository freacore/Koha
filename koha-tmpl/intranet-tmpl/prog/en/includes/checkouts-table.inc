[% USE Koha %]
<div id="checkouts">
    [% IF ( issuecount ) %]
        <div id="issues-table-loading-message">
            <p>
                <a id="issues-table-load-now-button" href="#" class="btn btn-default"><i class="fa fa-book"></i> Show checkouts</a>
            </p>
        </div>
        <form name="issues" action="/cgi-bin/koha/tools/export.pl" method="post">
            <table id="issues-table" style="width: 100% !Important;">
                <thead>
                    <tr>
                        <th scope="col">&nbsp;</th>
                        <th scope="col">&nbsp;</th>
                        <th scope="col">Due date</th>
                        <th scope="col">Due date</th>
                        <th scope="col">Title</th>
                        <th scope="col">Record-level item type</th>
                        <th scope="col">Item type</th>
                        <th scope="col">Collection</th>
                        <th scope="col">Location</th>
                        <th scope="col">Home library</th>
                        <th scope="col">&nbsp;</th>
                        <th scope="col">Checked out on</th>
                        <th scope="col">Checked out from</th>
                        <th scope="col">Call number</th>
                        <th scope="col">Copy number</th>
                        <th scope="col">Charge</th>
                        <th scope="col">Fine</th>
                        <th scope="col">Price</th>
                        <th scope="col">Renew <p class="column-tool"><a href="#" id="CheckAllRenewals">select all</a> | <a href="#" id="UncheckAllRenewals">none</a></p></th>
                        <th scope="col">Check in <p class="column-tool"><a href="#" id="CheckAllCheckins">select all</a> | <a href="#" id="UncheckAllCheckins">none</a></p></th>
                        <th scope="col">Return claims</th>
                        <th scope="col">Export <p class="column-tool"><a href="#" id="CheckAllExports">select all</a> | <a href="#" id="UncheckAllExports">none</a></p></th>
                    </tr>
                </thead>
                [% INCLUDE 'checkouts-table-footer.inc' %]
            </table>

            <label for="issues-table-load-immediately">Always show checkouts immediately</label>
            <input id="issues-table-load-immediately" type="checkbox" />

            <div id="issues-table-actions">
                <fieldset class="action">
                    [% IF ( CAN_user_circulate_override_renewals ) %]
                        [% IF Koha.Preference( 'AllowRenewalLimitOverride' ) || Koha.Preference( 'AllowRenewalOnHoldOverride' ) %]
                            <label for="override_limit">Override renewal restrictions:</label>
                            <input type="checkbox" name="override_limit" id="override_limit" value="1" />
                        [% END %]
                    [% END %]
                    [% IF ( CAN_user_circulate_circulate_remaining_permissions ) %]
                        [% IF Koha.Preference( 'UnseenRenewals' ) %]
                            <label id="renew_as_unseen_label" for="override_limit">Renew as &quot;unseen&quot; if appropriate:</label>
                            <input type="checkbox" name="renew_as_unseen" id="renew_as_unseen_checkbox" value="1" />
                        [% END %]
                        <button class="btn btn-default" id="RenewCheckinChecked"><i class="fa fa-check"></i> Renew or check in selected items</button>
                        <button class="btn btn-default" id="RenewAll"><i class="fa fa-book"></i> Renew all</button>
                    [% END %]
                </fieldset>

                [% IF Koha.Preference('ExportCircHistory') %]
                    <fieldset>
                        <label for="issues-table-output-format"><strong>Export checkouts using format:</strong></label>
                        <select name="issues-table-output-format" id="issues-table-output-format">
                            <option value="iso2709_995">MARC with items</option>
                            <option value="iso2709">MARC without items</option>
                            [% IF csv_profiles.count %]
                                <option value="csv">CSV</option>
                            [% END %]
                        </select>

                        [% IF csv_profiles.count %]
                            <select name="csv_profile_id">
                                [% FOREACH csv_profile IN csv_profiles %]
                                    <option value="[% csv_profile.export_format_id | html %]">[% csv_profile.profile | html %]</option>
                                [% END %]
                            </select>
                        [% END %]
                       <label for="export_remove_fields">Don't export fields:</label> <input type="text" id="export_remove_fields" name="export_remove_fields" value="[% Koha.Preference('ExportRemoveFields') | html %]" title="Use for MARC exports" />
                        <input type="hidden" name="op" value="export" />
                        <input type="hidden" id="output_format" name="output_format" value="iso2709" />
                        <input type="hidden" id="dont_export_item" name="dont_export_item" value="0" />
                        <input type="hidden" id="record_type" name="record_type" value="bibs" />
                        <button class="btn btn-default btn-sm" id="export_submit"><i class="fa fa-download"></i> Export</button>
                    </fieldset>
                [% END %]
            </div>
        </form>
    [% ELSE %]
        <p>Patron has nothing checked out.</p>
    [% END %]
</div>

<!-- Claims Returned Modal -->
<div class="modal fade" id="claims-returned-modal" tabindex="-1" role="dialog" aria-labelledby="claims-returned-modal-label">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h4 class="modal-title" id="claims-returned-modal-label">Claim returned</h4>
      </div>
      <div class="modal-body">

          <div class="form-group">
            <label for="claims-returned-notes" class="control-label">Notes</label>
            <div>
              <textarea id="claims-returned-notes" class="form-control" rows="3"></textarea>
            </div>
          </div>

          [% IF Koha.Preference('ClaimReturnedChargeFee') == 'ask' %]
            <div class="form-group">
              <div class="checkbox">
                <label for="claims-returned-charge-lost-fee">
                  <input id="claims-returned-charge-lost-fee" type="checkbox" value="1">
                  Charge lost fee
                </label>
              </div>
            </div>
          [% END %]

          <input type="hidden" id="claims-returned-itemnumber" />
      </div>
      <div class="modal-footer">
        <button id="claims-returned-modal-btn-submit" type="button" class="btn btn-primary"><i class="fa fa-exclamation-circle"></i> Make claim</button>
        <button class="btn btn-default deny cancel" href="#" data-dismiss="modal" aria-hidden="true"><i class="fa fa-times"></i> Cancel</button>
      </div>
    </div>
  </div>
</div>

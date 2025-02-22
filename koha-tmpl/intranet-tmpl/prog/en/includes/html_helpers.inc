[% BLOCK options_for_libraries %]
    [% FOREACH l IN libraries %]
        [% IF l.selected %]
            <option value="[% prefix | html %][% l.branchcode | html %]" selected="selected">[% l.branchname | html %]</option>
        [% ELSE %]
            <option value="[% prefix | html %][% l.branchcode | html %]">[% l.branchname | html %]</option>
        [% END%]
    [% END %]
[% END %]

[% BLOCK options_for_desks %]
    <option id="nodesk" value="">---</option>
    [% FOREACH d IN desks %]
        [% IF d.branchcode == branch %]
          [% IF selected == d.desk_id %]
            <option class="[% d.branchcode | html %]" value="[% d.desk_id | html %]" selected="selected">[% d.desk_name | html %]</option>
          [% ELSE %]
            <option class="[% d.branchcode | html %]" value="[% d.desk_id | html %]" >[% d.desk_name | html %]</option>
          [% END %]
        [% ELSE %]
            <option class="[% d.branchcode | html %]" value="[% d.desk_id | html %]" disabled hidden>[% d.desk_name | html %]</option>
        [% END %]
    [% END %]
[% END %]

[% BLOCK options_for_registers %]
    [% FOREACH r IN registers %]
        [% IF r.branch == Branches.GetLoggedInBranchcode %]
            [% IF r.selected %]
                <option class="[%- r.branch | html -%][%- IF r.branch_default -%] default[%- END -%]" value="[% r.id | html %]" selected="selected">[% r.name | html %]</option>
            [% ELSE %]
                <option class="[%- r.branch | html -%][%- IF r.branch_default -%] default[%- END -%]" value="[% r.id | html %]">[% r.name | html %]</option>
            [% END%]
        [% ELSE %]
            <option class="[%- r.branch | html -%][%- IF r.branch_default -%] default[%- END -%]" value="[% r.id | html %]" disabled style="display: none">[% r.name | html %]</option>
        [% END %]
    [% END %]
[% END %]

[% BLOCK options_for_authorised_value_categories %]
    [% FOREACH avc IN authorised_value_categories %]
        [% IF avc.selected %]
            <option value="[% avc.category | html %]" selected="selected">[% avc.category | html %]</option>
        [% ELSE %]
            <option value="[% avc.category | html %]">[% avc.category | html %]</option>
        [% END %]
    [% END %]
[% END %]

[% BLOCK options_for_authorised_values %]
    [% FOREACH av IN authorised_values %]
        [% IF av.authorised_value == selected_av %]
            <option value="[% av.authorised_value | html %]" selected="selected">[% av.lib | html %]</option>
        [% ELSE %]
            <option value="[% av.authorised_value | html %]">[% av.lib | html %]</option>
        [% END %]
    [% END %]
[% END %]

[% BLOCK options_for_item_types %]
    [% FOREACH itemtype IN itemtypes %]
        [% IF itemtype.itemtype == selected_itemtype %]
            <option value="[% itemtype.itemtype | html %]" selected="selected">
        [% ELSE %]
            <option value="[% itemtype.itemtype | html %]">
        [% END %]
            [% itemtype.translated_description | html %]
        </option>
    [% END %]
[% END %]

[% BLOCK subfields_for_item %]
    <ol>
        [% FOREACH subfield IN subfields %]
            [% IF subfield.kohafield == 'items.more_subfields_xml' %]
                [% SET kohafield = 'items.more_subfields_xml_' _ subfield.subfield %]
            [% ELSE %]
                [% SET kohafield = subfield.kohafield %]
            [% END %]

            <li>
                <div class="subfield_line" style="[% subfield.visibility | html %]" id="subfield[% subfield.tag | html %][% subfield.subfield | html %][% subfield.random | html %]">
                    [% IF ( subfield.mandatory ) %]
                        <label class="required">[% subfield.subfield | html %] - [% subfield.marc_lib | $raw %]</label>
                    [% ELSE %]
                       <label>[% subfield.subfield | html %] - [% subfield.marc_lib | $raw %]</label>
                    [% END %]

                    [% SET mv = subfield.marc_value %]
                    [% IF ( mv.type == 'hidden' ) %]
                        <input type="hidden" id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" maxlength="[%- mv.maxlength | html -%]" value="[%- mv.value | html -%]">
                    [% ELSIF ( mv.type == 'select' ) %]
                        [% IF ( mv.readonly || subfield.IS_RETURN_CLAIM ) %]
                            <select name="[% kohafield | html %]" id="[%- mv.id | html -%]" class="input_marceditor" readonly="readonly" disabled="disabled" data-width="50%">
                        [% ELSE %]
                            <select name="[% kohafield | html %]" id="[%- mv.id | html -%]" class="input_marceditor select2" data-category="[% mv.category | html %]" data-width="50%">
                        [% END %]

                        [% FOREACH aval IN mv.values %]
                            [% IF aval == mv.default %]
                                <option value="[%- aval | html -%]" selected="selected">[%- mv.labels.$aval | html -%]</option>
                            [% ELSE %]
                                [% IF subfield.IS_LOST_AV && Koha.Preference("ClaimReturnedLostValue") && aval == Koha.Preference("ClaimReturnedLostValue") %]
                                    <option disabled="disabled" value="[%- aval | html -%]" title="Return claims must be processed from the patron details page">[%- mv.labels.$aval | html -%]</option>
                                [%  ELSE %]
                                    <option value="[%- aval | html -%]">[%- mv.labels.$aval | html -%]</option>
                                [% END %]
                            [% END %]
                        [% END %]
                        </select>
                    [% ELSIF ( mv.type == 'text_auth' ) %]
                        [% IF mv.readonly %]
                            <input type="text" id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" maxlength="[%- mv.maxlength | html -%]" value="[%- mv.value | html -%]" readonly="readonly" />
                        [% ELSE %]
                            <input type="text" id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" maxlength="[%- mv.maxlength | html -%]" value="[%- mv.value | html -%]" />
                            [% SET dopop = "Dopop('/cgi-bin/koha/authorities/auth_finder.pl?authtypecode=\"${mv.authtypecode}\"&index=${mv.id}','${mv.id}')" %]
                            <a href="#" class="buttonDot"  onclick="[%- dopop | html -%]; return false;" title="Tag editor">...</a>
                        [% END %]
                    [% ELSIF ( mv.type == 'text_plugin' ) %]
                        [% IF mv.readonly %]
                            <input type="text" id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" maxlength="[%- mv.maxlength | html -%]" value="[%- mv.value | html -%]" readonly="readonly" />
                        [% ELSE %]
                            <input type="text" id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" maxlength="[%- mv.maxlength | html -%]" value="[%- mv.value | html -%]" />
                            [% IF ( mv.nopopup ) %]
                                <a href="#" id="buttonDot_[%- mv.id | html -%]" class="[%- mv.class | html -%]" title="No popup">...</a>
                            [% ELSE  %]
                                <a href="#" id="buttonDot_[%- mv.id | html -%]" class="[%- mv.class | html -%]" title="Tag editor">...</a>
                            [% END %]
                            [% UNLESS no_plugin %][%# FIXME - from batchMod-edit, jQuery is included at the end of the template and cataloguing plugins are not working in this situation %]
                                [%- mv.javascript | $raw -%]
                            [% END %]
                        [% END %]
                    [% ELSIF ( mv.type == 'text' ) %]
                        [% IF mv.readonly %]
                            <input type="text" id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" maxlength="[%- mv.maxlength | html -%]" value="[%- mv.value | html -%]" readonly="readonly" />
                        [% ELSE %]
                            <input type="text" id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" maxlength="[%- mv.maxlength | html -%]" value="[%- mv.value | html -%]" />
                        [% END %]
                    [% ELSIF ( mv.type == 'textarea' ) %]
                        [% IF mv.readonly %]
                            <textarea id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" rows="5" cols="64" readonly="readonly" >[% mv.value | html %]</textarea>
                        [% ELSE %]
                            <textarea id="[%- mv.id | html -%]" name="[% kohafield | html %]" class="input_marceditor" rows="5" cols="64" >[% mv.value | html %]</textarea>
                        [% END %]
                    [% END %]

                    [% IF subfield.kohafield == 'items.more_subfields_xml' %]
                        <input type="hidden" name="items.more_subfields_xml" value="[% subfield.subfield | html %]" />
                    [% END %]
                    <input type="hidden" name="tag"       value="[% subfield.tag | html %]" />
                    <input type="hidden" name="kohafield" value="[% subfield.kohafield | html %]" /> [%# We should not need that but all item forms are not rewritten yet %]
                    <input type="hidden" name="subfield"  value="[% subfield.subfield | html %]" />
                    <input type="hidden" name="mandatory" value="[% subfield.mandatory | html %]" />
                    <input type="hidden" name="important" value="[% subfield.important | html %]" />

                    [% IF add_regex %]
                        <span name="regex_fields" style="display: none;">
                            s/<input type="text" name="[% kohafield | html %]_regex_search" class="regex_search" placeholder="regex pattern" />/
                            <input type="text" name="[% kohafield | html %]_regex_replace" class="regex_replace" placeholder="regex replacement" />/
                            <input type="text" name="[% kohafield | html %]_regex_modifiers" class="regex_modifiers" placeholder="ig" size="3" />
                        </span>
                    [% END %]

                    [% IF add_delete_checkbox %]
                        [% UNLESS ( subfield.mandatory ) %]
                            <input type="checkbox" id="row[% subfield.tag | html %][% subfield.subfield | html %][% subfield.random | html %]" title="Check to delete subfield [% subfield.subfield | html %]" name="disable_input" value="[% kohafield | html %]" />
                        [% ELSE %]
                            <span class="required">Required</span>
                        [% END %]
                    [% ELSE %]
                        [% IF ( subfield.mandatory ) %] <span class="required">Required</span>
                        [% ELSIF ( subfield.important ) %] <span class="important">Important</span>
                        [% END %]
                    [% END %]

                    [% IF add_regex %]
                        [% IF (mv.type == 'text' || mv.type == 'text2' || mv.type == 'textarea' ) %]
                            <a href="#" name="[% kohafield | html %]_field_regex" class="field_regex" id="[% subfield.id | html %]" >RegEx</a>
                        [% END %]
                    [% END %]

                    [% IF ( subfield.repeatable ) %]
                        <a href="#" class="buttonPlus" onclick="CloneItemSubfield(this.parentNode.parentNode); return false;">
                            <img src="[% interface | html %]/[% theme | html %]/img/clone-subfield.png" alt="Clone" title="Clone this subfield" />
                        </a>
                    [% END %]

                    <span class="hint" id="hint[% subfield.tag | html %][% subfield.subfield | html %][% subfield.random | html %]"></span>

                </div>
            </li>
        [% END %]
    </ol>
[% END %]

[% BLOCK items_table_batchmod %]

    [% IF display_columns_selection %][%# Needs js/pages/batchMod.js %]
        [% IF checkboxes_edit OR checkboxes_delete %]
            <div id="toolbar">
                <a id="selectallbutton" href="#"><i class="fa fa-check"></i> Select all</a> | <a id="clearallbutton" href="#"><i class="fa fa-remove"></i> Clear all</a> | <a id="clearonloanbutton" href="#">Clear on loan</a>
            </div>
        [% END %]

        <div id="cataloguing_additem_itemlist">

            <p id="selections">
                <strong>Show/hide columns:</strong>
                <span class="selected">
                    <input type="checkbox" checked="checked" id="showall" />
                    <label for="showall">Show all columns</label>
                </span>
                <span>
                    <input type="checkbox" id="hideall" />
                    <label for="hideall">Hide all columns</label>
                </span>

                [% FOREACH header IN item_header_loop %]
                    <span class="selected">
                        <input id="checkheader[% loop.count | html %]" type="checkbox" checked="checked" />
                        <label for="checkheader[% loop.count | html %]">[% header.header_value | html %]</label>
                    </span>
                [% END %]
            </p> <!-- /#selections -->
        </div>
    [% END %]
    [% SET date_fields = [ 'dateaccessioned', 'onloan', 'datelastseen', 'datelastborrowed', 'replacementpricedate' ] %]
    <table id="itemst">
        <thead>
            <tr>
                [% IF checkboxes_edit OR checkboxes_delete %]
                    <th></th>
                [% END %]
                <th class="anti-the">Title</th>
                <th class="holds_count" title="Item holds / Total holds">Holds</th>
                [% FOREACH item_header IN headers %]
                    [% IF item_header.column_name %]
                        <th data-colname="[% item_header.column_name | html %]">
                    [% ELSE %]
                        <th>
                    [% END %]
                        [% item_header.header_value | html %]
                    </th>
                [% END %]
            </tr>
        </thead>
        <tbody>
            [% FOREACH item IN items %]
                [% SET can_be_edited = ! ( Koha.Preference('IndependentBranches') && ! logged_in_user && item.homebranch != Branches.GetLoggedInBranchcode() ) %]

                <tr>
                    [% IF checkboxes_edit %]
                        [% UNLESS can_be_edited%]
                            <td class="error">Cannot edit</td>
                        [% ELSE %]
                            <td>
                                <input type="checkbox" name="itemnumber" value="[% item.itemnumber | html %]" id="row[% item.itemnumber | html %]" checked="checked" data-is-onloan="[% item.is_checked_out | html %]" />
                            </td>
                        [% END %]
                    [% ELSIF checkboxes_delete %]
                        [% UNLESS can_be_edited %]
                            <td class="error">Cannot delete</td>
                        [% ELSE %]
                            [% IF item.safe_to_delete %]
                                <td><input type="checkbox" name="itemnumber" value="[% item.itemnumber | html %]" id="row[% item.itemnumber | html %]" checked="checked" /></td>
                            [% ELSE %]
                                [% SET messages = item.safe_to_delete.messages %]
                                [% FOR m IN messages %]
                                    [% SWITCH m.message %]
                                    [% CASE "book_on_loan" %][% SET cannot_delete_reason = t("Item is checked out") %]
                                    [% CASE "not_same_branch" %][% SET cannot_delete_reason = t("Item does not belong to your library") %]
                                    [% CASE "book_reserved" %][% SET cannot_delete_reason = t("Item has a waiting hold") %]
                                    [% CASE "linked_analytics" %][% SET cannot_delete_reason = t("Item has linked analytics") %]
                                    [% CASE "last_item_for_hold" %][% SET cannot_delete_reason = t("Last item for bibliographic record with biblio-level hold on it") %]
                                    [% CASE %][% SET cannot_delete_reason = t("Unknown reason") _ '(' _ m.message _ ')' %]
                                    [% END %]
                                [% END %]

                                <td><input type="checkbox" name="itemnumber" value="[% item.itemnumber | html %]" id="row[% item.itemnumber | html %]" disabled="disabled" title="[% cannot_delete_reason | html %]"/></td>
                            [% END %]

                        [% END %]
                    [% END %]
                    <td>
                        <label for="row[% item.itemnumber | html %]">
                            <a href="/cgi-bin/koha/catalogue/detail.pl?biblionumber=[% item.biblionumber | uri %]">
                                [% item.biblio.title | html %]
                            </a>
                            [% IF ( item.biblio.author ) %], by [% item.biblio.author | html %][% END %]
                        </label>
                    </td>
                    <td class="holds_count">
                        [% IF item.holds %]
                            [% IF item.item_holds %]
                                <a href="/cgi-bin/koha/reserve/request.pl?biblionumber=[% item.biblionumber | uri %]" title="Holds on this item: [% item.item_holds | html %] / Total holds on this record: [% item.holds | html -%]" >
                            [% ELSE %]
                                <a href="/cgi-bin/koha/reserve/request.pl?biblionumber=[% item.biblionumber | uri %]" title="No holds on this item / Total holds on this record: [% item.holds | html -%]" >
                            [% END %]
                        [% ELSE %]
                            [% IF item.holds %]
                                <a href="/cgi-bin/koha/reserve/request.pl?biblionumber=[% item.biblionumber | uri %]" title="Holds on this record: [% item.holds | html -%]" >
                            [% ELSE %]
                                <a href="/cgi-bin/koha/reserve/request.pl?biblionumber=[% item.biblionumber | uri %]" title="No holds on this record" >
                            [% END %]
                        [% END # /IF item.holds %]
                        [% IF item.holds %]
                            [% item.item_holds | html %]/[% item.holds | html %]
                        [% ELSE %]
                            [% item.holds | html %]
                        [% END %]
                        </a>
                    </td>
                    [% FOREACH header IN headers %]
                        [% SET attribute = header.attribute %]
                        [% IF header.attribute AND date_fields.grep('^' _ attribute _ '$').size %]
                            <td data-order="[% item.$attribute | html %]">[% item.$attribute | $KohaDates %]</td>
                        [% ELSE %]
                            <td>[% item.$attribute | html %]</td>
                        [% END %]
                    [% END %]

                </tr>
            [% END # /FOREACH items %]
        </tbody>
    </table> <!-- /#itemst -->

[% END %]

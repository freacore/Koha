[% USE KohaDates %]
<table id="table_borrowers" class="selections-table">
    <thead>
        <tr>
            <th>Name</th>
            <th>Card number</th>
            <th>Date of birth</th>
            <th>Category</th>
            <th>Library</th>
            <th>Address</th>
            <th>Primary phone</th>
        </tr>
    </thead>
    <tbody>
        [% FOREACH borrower IN borrowers %]
            [% IF destination == "circ" %]
                <tr class="clickable" data-url="/cgi-bin/koha/circ/circulation.pl?borrowernumber=[% borrower.borrowernumber | html %]">
                    <td><a href="/cgi-bin/koha/circ/circulation.pl?borrowernumber=[% borrower.borrowernumber | uri %]">[% borrower.surname | html %], [% borrower.firstname | html %]</a></td>
            [% ELSIF destination == "holds" %]
                [% IF multi_hold %]
                    [% SET data_url = "/cgi-bin/koha/reserve/request.pl?borrowernumber=" _ borrower.borrowernumber _ "&amp;multi_hold=1&amp;biblionumbers=" _ biblionumbers %]
                [% ELSE %]
                    [% SET data_url = "/cgi-bin/koha/reserve/request.pl?borrowernumber=" _ borrower.borrowernumber _ "&amp;biblionumber=" _ biblionumber %]
                [% END %]
                <tr class="clickable" data-url="[% data_url | url %]">
                    <td><a href="[% data_url | url %]">[% borrower.surname | html %], [% borrower.firstname | html %]</a></td>
            [% END %]
                <td>[% borrower.cardnumber | html %]</td>
                <td data-order="[% borrower.dateofbirth | html %]">[% INCLUDE 'patron-age.inc' patron = borrower %]</td>
                <td>[% Categories.GetName( borrower.categorycode ) | html %]</td>
                <td>
                    [% IF ( Branches.GetLoggedInBranchcode == borrower.branchcode && !singleBranchMode ) %]
                        <span class="currentlibrary">[% Branches.GetName( borrower.branchcode ) | html %]</span>
                    [% ELSE %]
                        [% Branches.GetName( borrower.branchcode ) | html %]
                    [% END %]
                </td>
                <td>[% borrower.address | html %]</td>
                <td>[% borrower.phone | html %]</td>
            </tr>
        [% END %]
    </tbody>
</table>

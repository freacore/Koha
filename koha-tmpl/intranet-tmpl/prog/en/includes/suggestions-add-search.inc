[% USE Koha %]
<div class="gradient">
<h1 id="logo"><a href="/cgi-bin/koha/mainpage.pl">[% LibraryName | html %]</a></h1><!-- Begin Suggestions Resident Search Box -->
<div id="header_search">
	<div id="suggestions_search" class="residentsearch">
    <p class="tip">Suggestions search:</p>
	<form action="/cgi-bin/koha/acqui/newordersuggestion.pl" method="get">
    <input type="hidden" name="booksellerid" value="[% booksellerid | html %]" />
	<label for="searchtitle">Title:</label> <input type="text" id="searchtitle" name="title" size="10" value="[% title | html %]" />
    <label for="searchauthor">Author:</label> <input type="text" id="searchauthor" name="author" size="10" value="[% author | html %]" />
    <label for="searchpublishercode">Publisher:</label> <input type="text" id="searchpublishercode" name="publishercode" size="10" value="[% publishercode | html %]" />
    <input type="submit" class="submit" value="Search" />
        </form>
	</div>

    [% INCLUDE 'patron-search-box.inc' %]
    [% INCLUDE 'catalogue-search-box.inc' %]

			<ul>
            <li><a href="#suggestions_search">Search suggestions</a></li>
            [% IF ( CAN_user_circulate_circulate_remaining_permissions ) %]<li><a class="keep_text" href="#circ_search">Check out</a></li>[% END %]
            [% IF ( CAN_user_catalogue ) %]<li><a class="keep_text" href="#catalog_search">Search the catalog</a></li>[% END %]
            </ul>
</div>
</div><!-- /gradient -->
<!-- End Suggestions Resident Search Box -->

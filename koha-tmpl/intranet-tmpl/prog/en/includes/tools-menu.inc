[% USE Koha %]

<div id="navmenu">
<div id="navmenulist">
<ul>
    <li><a href="/cgi-bin/koha/tools/tools-home.pl">Tools home</a></li>
</ul>
[% IF ( CAN_user_tools_manage_patron_lists || CAN_user_clubs || CAN_user_tools_moderate_comments || CAN_user_tools_import_patrons  || CAN_user_tools_edit_notices || CAN_user_tools_edit_notice_status_triggers || CAN_user_tools_label_creator || CAN_user_tools_delete_anonymize_patrons  || CAN_user_tools_edit_patrons || CAN_user_tools_moderate_tags || ( CAN_user_tools_batch_upload_patron_images && Koha.Preference('patronimages') ) ) %]
<h5>Patrons and circulation</h5>
<ul>
    [% IF ( CAN_user_tools_manage_patron_lists ) %]
	<li><a href="/cgi-bin/koha/patron_lists/lists.pl">Patron lists</a></li>
    [% END %]
    [% IF (CAN_user_clubs) %]
        <li><a href="/cgi-bin/koha/clubs/clubs.pl">Patron clubs</a></li>
    [% END %]
    [% IF ( CAN_user_tools_moderate_comments ) %]
	<li><a href="/cgi-bin/koha/reviews/reviewswaiting.pl">Comments</a></li>
    [% END %]
    [% IF ( CAN_user_tools_import_patrons ) %]
	<li><a href="/cgi-bin/koha/tools/import_borrowers.pl">Import patrons</a></li>
    [% END %]
    [% IF ( CAN_user_tools_edit_notices ) %]
    <li><a href="/cgi-bin/koha/tools/letter.pl">Notices &amp; slips</a></li>
    [% END %]
    [% IF ( CAN_user_tools_edit_notice_status_triggers ) %]
	<li><a href="/cgi-bin/koha/tools/overduerules.pl">Overdue notice/status triggers</a></li>
    [% END %]
    [% IF ( CAN_user_tools_label_creator ) %]
    <li><a href="/cgi-bin/koha/patroncards/home.pl">Patron card creator</a></li>
    [% END %]
    [% IF ( CAN_user_tools_delete_anonymize_patrons ) %]
    <li><a href="/cgi-bin/koha/tools/cleanborrowers.pl">Batch patron deletion and anonymization</a></li>
    [% END %]
    [% IF ( CAN_user_tools_edit_patrons ) %]
    <li><a href="/cgi-bin/koha/tools/modborrowers.pl">Batch patron modification</a></li>
    [% END %]
    [% IF ( CAN_user_tools_batch_extend_due_dates ) %]
    <li><a href="/cgi-bin/koha/tools/batch_extend_due_dates.pl">Batch extend due dates</a></li>
    [% END %]
    [% IF ( CAN_user_tools_moderate_tags ) %]
    <li><a href="/cgi-bin/koha/tags/review.pl">Tag moderation</a></li>
    [% END %]
    [% IF ( CAN_user_tools_batch_upload_patron_images && Koha.Preference('patronimages') ) %]
	<li><a href="/cgi-bin/koha/tools/picture-upload.pl">Upload patron images</a></li>
    [% END %]
</ul>
[% END %]
[% IF ( CAN_user_tools_items_batchdel || CAN_user_tools_items_batchmod || CAN_user_tools_records_batchdel  || CAN_user_tools_records_batchmod || CAN_user_tools_export_catalog || CAN_user_tools_inventory  || CAN_user_tools_label_creator || CAN_user_tools_rotating_collections  || ( CAN_user_stockrotation_manage_rotas && Koha.Preference('StockRotation') )  || CAN_user_tools_marc_modification_templates || CAN_user_tools_stage_marc_import  || CAN_user_tools_manage_staged_marc || CAN_user_tools_upload_local_cover_images ) %]
<h5>Catalog</h5>
<ul>
    [% IF ( CAN_user_tools_items_batchdel ) %]
	<li><a href="/cgi-bin/koha/tools/batchMod.pl?del=1">Batch item deletion</a></li>
    [% END %]
    [% IF ( CAN_user_tools_items_batchmod ) %]
	<li><a href="/cgi-bin/koha/tools/batchMod.pl">Batch item modification</a></li>
    [% END %]
    [% IF CAN_user_tools_records_batchdel %]
      <li><a href="/cgi-bin/koha/tools/batch_delete_records.pl">Batch record deletion</a></li>
    [% END %]
    [% IF CAN_user_tools_records_batchmod %]
      <li><a href="/cgi-bin/koha/tools/batch_record_modification.pl">Batch record modification</a></li>
    [% END %]
    [% IF CAN_user_tools_items_batchmod %]
      <li><a href="/cgi-bin/koha/tools/automatic_item_modification_by_age.pl">Automatic item modifications by age</a></li>
    [% END %]
    [% IF ( CAN_user_tools_export_catalog ) %]
    <li><a href="/cgi-bin/koha/tools/export.pl">Export data</a></li>
    [% END %]
    [% IF ( CAN_user_tools_inventory ) %]
        <li><a href="/cgi-bin/koha/tools/inventory.pl">Inventory</a></li>
    [% END %]
    [% IF ( CAN_user_tools_label_creator ) %]
	<li><a href="/cgi-bin/koha/labels/label-home.pl">Label creator</a></li>
	<li><a href="/cgi-bin/koha/labels/spinelabel-home.pl">Quick spine label creator</a></li>
    [% END %]
    [% IF ( CAN_user_tools_rotating_collections ) %]
    <li><a href="/cgi-bin/koha/rotating_collections/rotatingCollections.pl">Rotating collections</a></li>
    [% END %]
    [% IF ( CAN_user_stockrotation_manage_rotas && Koha.Preference('StockRotation') ) %]
    <li><a href="/cgi-bin/koha/tools/stockrotation.pl">Stock rotation</a></li>
    [% END %]
    [% IF ( CAN_user_tools_marc_modification_templates ) %]
        <li><a href="/cgi-bin/koha/tools/marc_modification_templates.pl">Manage MARC modification templates</a></li>
    [% END %]
    [% IF ( CAN_user_tools_stage_marc_import ) %]
	<li><a href="/cgi-bin/koha/tools/stage-marc-import.pl">Stage MARC for import</a></li>
    [% END %]
    [% IF ( CAN_user_tools_manage_staged_marc ) %]
	<li><a href="/cgi-bin/koha/tools/manage-marc-import.pl">Staged MARC management</a></li>
    [% END %]
    [% IF ( CAN_user_tools_upload_local_cover_images ) %]
    <li><a href="/cgi-bin/koha/tools/upload-cover-image.pl">Upload local cover image</a></li>
    [% END %]
</ul>
[% END %]
[% IF ( CAN_user_tools_edit_calendar || CAN_user_tools_manage_csv_profiles || CAN_user_tools_view_system_logs || CAN_user_tools_edit_additional_contents  || CAN_user_tools_schedule_tasks || CAN_user_tools_edit_quotes || ( Koha.ArePluginsEnabled() && CAN_user_plugins_tool )  || CAN_user_tools_upload_general_files || CAN_user_tools_access_files ) %]
<h5>Additional tools</h5>
<ul>
    [% IF ( CAN_user_tools_edit_calendar ) %]
	<li><a href="/cgi-bin/koha/tools/holidays.pl">Calendar</a></li>
    [% END %]
    [% IF ( CAN_user_tools_manage_csv_profiles ) %]
	<li><a href="/cgi-bin/koha/tools/csv-profiles.pl">CSV profiles</a></li>
    [% END %]
    [% IF ( CAN_user_tools_view_system_logs ) %]
	<li><a href="/cgi-bin/koha/tools/viewlog.pl">Log viewer</a></li>
    [% END %]
    [% IF ( CAN_user_tools_edit_additional_contents ) %]
    <li><a href="/cgi-bin/koha/tools/additional-contents.pl?category=news">News</a></li>
    <li><a href="/cgi-bin/koha/tools/additional-contents.pl?category=html_customizations">HTML customizations</a></li>
    [% END %]
    [% IF ( CAN_user_tools_schedule_tasks ) %]
	<li><a href="/cgi-bin/koha/tools/scheduler.pl">Task scheduler</a></li>
    [% END %]
    [% IF ( CAN_user_tools_edit_quotes ) %]
       <li><a href="/cgi-bin/koha/tools/quotes.pl">Quote editor</a></li>
    [% END %]
    [% IF ( Koha.ArePluginsEnabled() && CAN_user_plugins_tool ) %]
        <li><a href="/cgi-bin/koha/plugins/plugins-home.pl?method=tool">Tool plugins</a></li>
    [% END %]
    [% IF ( CAN_user_tools_upload_general_files ) %]
       <li><a href="/cgi-bin/koha/tools/upload.pl">Upload any file</a></li>
    [% END %]
    [% IF ( CAN_user_tools_access_files ) %]
    <li><a href="/cgi-bin/koha/tools/access_files.pl">Access files</a></li>
    [% END %]
    [% IF ( Koha.Preference('OPACReportProblem') && CAN_user_problem_reports ) %]
        <li><a href="/cgi-bin/koha/tools/problem-reports.pl">OPAC problem reports</a></li>
    [% END %]
</ul>
[% END %]
</div></div>

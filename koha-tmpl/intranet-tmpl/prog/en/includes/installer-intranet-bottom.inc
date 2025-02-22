[% USE raw %]
[% USE Asset %]
        [% Asset.js("lib/jquery/jquery-2.2.3.min.js") | $raw %]
        [% Asset.js("lib/jquery/jquery-migrate-1.3.0.min.js") | $raw %]
        [% Asset.js("lib/jquery/jquery-ui-1.11.4.min.js") | $raw %]
        [% Asset.js("lib/bootstrap/bootstrap.min.js") | $raw %]
        [% Asset.js("lib/jquery/plugins/jquery.validate.min.js") | $raw %]
        <!-- installer-intranet-bottom.inc -->
        <script>
            function _(s) { return s } // dummy function for gettext
            [%# Prevent XFS attacks -%]
            $(document).ready(function() {
               if (self === top) {
                   var antiClickjack = document.getElementById("antiClickjack");
                   antiClickjack.parentNode.removeChild(antiClickjack);
               } else {
                   top.location = self.location;
               }
            });
        </script>
        <!-- / installer-intranet-bottom.inc -->
        [% INCLUDE 'calendar.inc' %]
        [% jsinclude | $raw # Parse the page template's JavaScript block if necessary %]
    </body>
</html>

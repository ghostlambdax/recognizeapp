window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["admin_index-queue"] = (function($, window, undefined) {
    $document.on('turbolinks:load', function() {
        function showTable(evt, showdiv, hidediv) {
            evt.preventDefault();
            $(showdiv).show();
            $(hidediv).hide();
            // Note: Datatable columns needs to be adjusted since the #failed_jobs table
            //       is hidden at default and and does not take full width
            if (showdiv == '#failed_jobs'){
                $table = $('#failed_jobs table');
                $table.DataTable().columns.adjust().draw();
            }
        }

        function toggleButtonColor(evt, current_button, next_button){
            evt.preventDefault();
            $(current_button).removeClass("button-warning");
            $(current_button).addClass("button-highlight");
            $(next_button).removeClass("button-highlight");
            $(next_button).addClass("button-warning");
        }
        $('#active-queue').click(function(e){
            if($(this).hasClass('button-warning')){
                toggleButtonColor(e, '#active-queue', '#failed-queue');
            }
            showTable(e, '#active_jobs', '#failed_jobs');
        });

        $('#failed-queue').click(function(e){
            if($(this).hasClass('button-warning')){
                toggleButtonColor(e, '#failed-queue', '#active-queue');
            }
            showTable(e, '#failed_jobs', '#active_jobs');
        });
        return function() {
        };
    });
})(jQuery, window);





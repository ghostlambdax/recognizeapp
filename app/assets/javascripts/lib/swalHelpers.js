(function () {
    window.R = window.R || {};
    window.R.ui = window.R.ui || {};

    window.R.ui.swalHelpers = {
        success: function (title, text) {
            Swal.fire({
                icon: 'success',
                title: title,
                text: text
            });
        }


    }

})();
